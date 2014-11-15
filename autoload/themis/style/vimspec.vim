" themis: style: vimspec: Spec style.
" Version: 1.3
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:func_t = type(function('type'))

function! s:translate_script(lines)
  let result = [
  \   'let s:themis_vimspec_bundles = []',
  \   'let s:themis_vimspec_scopes = themis#style#vimspec#new_scope()',
  \ ]
  let context_stack = []
  let current_func_id = 0
  let current_scope_id = 0
  let lnum = 0

  for line in a:lines
    let lnum += 1

    let tokens = matchlist(line, '^\s*\([Dd]escribe\|[Cc]ontext\)\s*\(.*\)$')
    if !empty(tokens)
      let [command, description] = tokens[1 : 2]
      if description ==# ''
        throw printf('vimspec:%d::%s must take an argument', lnum, command)
      endif
      if description =~# '^\s*\([''"]\).*\1\s*$'
        let description = eval(description)
      endif

      let bundle_new = printf(
      \   empty(context_stack) ?
      \     'themis#bundle(%s)' :
      \     'themis#bundle#new(%s, s:themis_vimspec_bundles[-1])',
      \   string(description)
      \ )

      let funcname = printf('s:themis_vimspec_scope_%d', current_scope_id)
      let result += [
      \   printf('function! %s()', funcname),
      \   printf('let s:themis_vimspec_bundles += [%s]', bundle_new),
      \   'let s:themis_vimspec_bundles[-1]._vimspec_hooks = {}',
      \ ]
      let context_stack += [['describe', lnum, funcname, current_scope_id]]
      let current_scope_id += 1
      continue
    endif

    let tokens = matchlist(line, '^\s*\([Ii]t\)\s*\(.*\)$')
    if !empty(tokens)
      let [command, example] = tokens[1 : 2]
      if example ==# ''
        throw printf('vimspec:%d::%s must take an argument', lnum, command)
      endif
      if empty(context_stack) || context_stack[-1][0] !=# 'describe'
        throw printf('vimspec:%d::%s must put on :describe or :context block',
        \            lnum, command)
      endif
      let scope = context_stack[-1][3]
      let result += [
      \   printf('let s:themis_vimspec_bundles[-1].suite_descriptions["T_%05d"] = %s', current_func_id, string(example)),
      \   printf('function! s:themis_vimspec_bundles[-1].suite.T_%05d()', current_func_id),
      \   printf('execute s:themis_vimspec_scopes.extend("s:themis_vimspec_scopes.scope(%d)")', scope),
      \ ]
      let context_stack += [['example', lnum]]
      let current_func_id += 1
      continue
    endif

    let tokens = matchlist(line, '^\s*\([Bb]efore\|[Aa]fter\)\%(\s\+\(.*\)\)\?$')
    if !empty(tokens)
      let [command, timing] = tokens[1 : 2]
      if empty(context_stack) || context_stack[-1][0] !=# 'describe'
        throw printf('vimspec:%d::%s must put on :describe or :context block',
        \            lnum, command)
      endif
      if timing ==# ''
        let timing = 'each'
      endif
      if timing !~# '^\%(each\|all\)$'
        throw printf('vimspec:%d:Invalid argument for "%s"', lnum, command)
      endif
      let hook_point = printf('%s_%s', tolower(command), timing)
      let scope = context_stack[-1][3]
      let result += [
      \   printf('function! s:themis_vimspec_bundles[-1]._vimspec_hooks.%s()', hook_point),
      \   printf('execute s:themis_vimspec_scopes.extend("s:themis_vimspec_scopes.scope(%d)")', scope),
      \ ]
      let context_stack += [['hook', lnum]]
      continue
    endif

    let tokens = matchlist(line, '^\s*\([Ee]nd\)\s*$')
    if !empty(tokens)
      if empty(context_stack)
        let command = tokens[1]
        throw printf('vimspec:%d:There is :%s, but not opened', lnum, command)
      endif
      let [context, lnum; rest] = remove(context_stack, -1)
      if context ==# 'describe'
        let [funcname, scope_id] = rest
        let parent_scope = empty(context_stack) ? -1 : context_stack[-1][3]
        let result += [
        \   printf('call s:themis_vimspec_scopes.push(copy(l:), %d, %d)', scope_id, parent_scope),
        \   'call remove(s:themis_vimspec_bundles, -1)',
        \   'endfunction',
        \   printf('call %s()', funcname),
        \ ]
      elseif context ==# 'hook'
        let scope = context_stack[-1][3]
        let result += [
        \   printf('call s:themis_vimspec_scopes.back(%d, l:)', scope),
        \   'endfunction',
        \ ]
      elseif context ==# 'example'
        let result += ['endfunction']
      endif
      continue
    endif

    let result += [line]
  endfor

  if !empty(context_stack)
    let opened_lnum = context_stack[0][1]
    throw printf('vimspec:%d:This declaration is not closed.', opened_lnum)
  endif

  return result
endfunction

function! s:compile_specfile(specfile_path, result_path)
  let slines = readfile(a:specfile_path)
  let rlines = s:translate_script(slines)
  call writefile(rlines, a:result_path)
endfunction


let s:ScopeKeeper = {'scopes': {}}

function! s:ScopeKeeper.push(scope, scope_id, parent)
  let self.scopes[a:scope_id] = {'scope': a:scope, 'parent': a:parent}
endfunction

function! s:ScopeKeeper.back(id, back_scope)
  let scope = self.scopes[a:id].scope
  for [k, Val] in items(a:back_scope)
    if k !=# 'self'
      let scope[k] = Val
    endif
    unlet Val
  endfor
endfunction

function! s:ScopeKeeper.scope(id)
  let all = {}
  let id = a:id
  while has_key(self.scopes, id)
    call extend(all, self.scopes[id].scope, 'keep')
    let id = self.scopes[id].parent
  endwhile
  if has_key(all, 'self')
    call remove(all, 'self')
  endif
  return all
endfunction

function! s:ScopeKeeper.extend(val)
   return join([
   \   printf('for [s:__key, s:__val] in items(%s)', a:val),
   \   '  let {s:__key} = s:__val',
   \   '  unlet s:__key s:__val',
   \   'endfor',
   \ ], "\n")
endfunction

function! themis#style#vimspec#new_scope()
  return deepcopy(s:ScopeKeeper)
endfunction


let s:event = {
\   '_converted_files': []
\ }

function! s:event.before_suite(bundle)
  call s:call_hook(a:bundle, 'before_all')
endfunction

function! s:event.before_test(bundle, name)
  if has_key(a:bundle, 'parent')
    call self.before_test(a:bundle.parent, a:name)
  endif
  call s:call_hook(a:bundle, 'before_each')
endfunction

function! s:event.after_test(bundle, name)
  call s:call_hook(a:bundle, 'after_each')
  if has_key(a:bundle, 'parent')
    call self.after_test(a:bundle.parent, a:name)
  endif
endfunction

function! s:event.after_suite(bundle)
  call s:call_hook(a:bundle, 'after_all')
endfunction

function! s:event.finish(runner)
  for file in self._converted_files
    if filereadable(file)
      call delete(file)
    endif
  endfor
endfunction

function! s:call_hook(bundle, point)
  if has_key(get(a:bundle, '_vimspec_hooks', {}), a:point)
    call call(a:bundle._vimspec_hooks[a:point], [], a:bundle.suite)
  endif
endfunction


let s:style = {
\   'event': s:event,
\ }

function! s:style.get_test_names(bundle)
  let expr = 'type(a:bundle.suite[v:val]) == s:func_t'
  return sort(filter(keys(a:bundle.suite), expr))
endfunction

function! s:style.can_handle(filename)
  return fnamemodify(a:filename, ':e') ==? 'vimspec'
endfunction

function! s:style.load_script(filename)
  let compiled_specfile_path = tempname()
  call add(self.event._converted_files, compiled_specfile_path)
  try
    call s:compile_specfile(a:filename, compiled_specfile_path)
    execute 'source' fnameescape(compiled_specfile_path)
  catch /^vimspec:/
    let pat = '\v^vimspec:(\d+):(.*)'
    let [lnum, message] = matchlist(v:exception, pat)[1 : 2]
    throw themis#exception('style-vimspec', [
    \   printf('Error occurred in %s:%d', a:filename, lnum),
    \   message,
    \ ])
  endtry
endfunction

function! themis#style#vimspec#new()
  return deepcopy(s:style)
endfunction

call themis#func_alias({'vital/style.vimspec.ScopeKeeper': s:ScopeKeeper})

let &cpo = s:save_cpo
unlet s:save_cpo
