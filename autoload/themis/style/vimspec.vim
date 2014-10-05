" themis: style: vimspec: Spec style.
" Version: 1.3
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:func_t = type(function('type'))

function! s:translate_script(lines)
  let result = [
  \   'let s:__themis_vimspec_bundles = []',
  \ ]
  let context_stack = []
  let c = 0
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
      if empty(context_stack)
        let result += [
        \   printf('let s:__themis_vimspec_bundles += [themis#bundle(%s)]', string(description)),
        \ ]
      else
        let result += [
        \   printf('let s:__themis_vimspec_bundles += [themis#bundle#new(%s, s:__themis_vimspec_bundles[-1])]', string(description)),
        \ ]
      endif
      let context_stack += [['describe', lnum]]
      continue
    endif

    let tokens = matchlist(line, '^\s*\([Ii]t\)\s*\(.*\)$')
    if !empty(tokens)
      let [command, example] = tokens[1 : 2]
      if example ==# ''
        throw printf('vimspec:%d::%s must take an argument', lnum, command)
      endif
      let result += [
      \   printf('let s:__themis_vimspec_bundles[-1].suite_descriptions["_%05d"] = %s', c, string(example)),
      \   printf('function! s:__themis_vimspec_bundles[-1].suite._%05d()', c),
      \ ]
      let context_stack += [['example', lnum]]
      let c += 1
      continue
    endif

    let tokens = matchlist(line, '^\s*\([Bb]efore\|[Aa]fter\)\%(\s\+\(.*\)\)\?$')
    if !empty(tokens)
      let [command, timing] = tokens[1 : 2]
      if timing ==# ''
        let timing = 'each'
      endif
      if timing !~# '^\%(each\|all\)$'
        throw printf('vimspec:%d:Invalid argument for "%s"', lnum, command)
      endif
      let hook_point = printf('%s_%s', tolower(command), timing)
      let result += [
      \   printf('function! s:__themis_vimspec_bundles[-1]._vimspec_%s()', hook_point),
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
      let context = remove(context_stack, -1)[0]
      if context ==# 'describe'
        let result += ['call remove(s:__themis_vimspec_bundles, -1)']
      elseif context ==# 'example' || context ==# 'hook'
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


let s:event = {
\   '_converted_files': []
\ }

function! s:event.before_suite(bundle)
  call s:call_hook(a:bundle, '_vimspec_before_all')
endfunction

function! s:event.before_test(bundle, name)
  if has_key(a:bundle, 'parent')
    call self.before_test(a:bundle.parent, a:name)
  endif
  call s:call_hook(a:bundle, '_vimspec_before_each')
endfunction

function! s:event.after_test(bundle, name)
  call s:call_hook(a:bundle, '_vimspec_after_each')
  if has_key(a:bundle, 'parent')
    call self.after_test(a:bundle.parent, a:name)
  endif
endfunction

function! s:event.after_suite(bundle)
  call s:call_hook(a:bundle, '_vimspec_after_all')
endfunction

function! s:event.finish(runner)
  for file in self._converted_files
    if filereadable(file)
      call delete(file)
    endif
  endfor
endfunction

function! s:call_hook(bundle, point)
  if has_key(a:bundle, a:point)
    call call(a:bundle[a:point], [], a:bundle.suite)
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

let &cpo = s:save_cpo
unlet s:save_cpo
