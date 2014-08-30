" themis: Utility functions.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

function! themis#util#callstacklines(throwpoint, ...)
  let infos = call('themis#util#callstack', [a:throwpoint] + a:000)
  return map(infos, 'themis#util#funcinfo_format(v:val)')
endfunction

function! themis#util#callstack(throwpoint, ...)
  let this_stacks = themis#util#parse_callstack(expand('<sfile>'))[: -2]
  let throwpoint_stacks = themis#util#parse_callstack(a:throwpoint)
  let start = a:0 ? len(this_stacks) + a:1 : 0
  if len(throwpoint_stacks) <= start ||
  \  this_stacks[0] != throwpoint_stacks[0]
    let start = 0
  endif
  let error_stack = throwpoint_stacks[start :]
  return map(error_stack, 'themis#util#funcinfo(v:val)')
endfunction

function! themis#util#parse_callstack(callstack)
  let callstack_line = matchstr(a:callstack, '^\%(function\s\+\)\?\zs.*')
  if callstack_line =~# ',.*\d'
    let pat = '^\(.\+\),.\{-}\(\d\+\)'
    let [callstack_line, line] = matchlist(callstack_line, pat)[1 : 2]
  else
    let line = 0
  endif
  let stack_info = split(callstack_line, '\.\.')
  call map(stack_info, '{"function": v:val, "line": 0}')
  let stack_info[-1].line = line - 0
  return stack_info
endfunction

function! themis#util#funcinfo_format(funcinfo)
  if a:funcinfo.signature ==# ''
    " This is a file.
    return printf('%s Line:%d', a:funcinfo.file, a:funcinfo.line)
  endif
  let result = a:funcinfo.signature
  if a:funcinfo.line
    let result .= '  Line:' . a:funcinfo.line
  endif
  return result . '  (' . a:funcinfo.file . ')'
endfunction

function! themis#util#funcinfo(stack)
  let f = a:stack.function
  let line = a:stack.line
  if themis#util#is_funcname(f)
    let body = themis#util#funcbody(f, 1)
    let signature = matchstr(body[0], '^\s*\zs.*')
    let file = matchstr(body[1], '^\s*Last set from\s*\zs.*$')
    let file = substitute(file, '[/\\]\+', '/', 'g')
    return {
    \   'funcname': f,
    \   'signature': signature,
    \   'file': file,
    \   'line': line,
    \ }
  elseif filereadable(f)
    return {
    \   'funcname': f,
    \   'signature': '',
    \   'file': f,
    \   'line': line,
    \ }
  else
    return {}
  endif
endfunction

function! themis#util#funcbody(func, verbose)
  let func = type(a:func) == type(function('type')) ?
  \          themis#util#funcname(a:func) : a:func
  let fname = func =~# '^\d\+' ? '{' . func . '}' : func
  let verbose = a:verbose ? 'verbose' : ''
  redir => body
  silent execute verbose 'function' fname
  redir END
  return split(body, "\n")
endfunction

function! themis#util#funcline(target, lnum)
  if themis#util#is_funcname(a:target)
    let body = themis#util#funcbody(a:target, 0)
    " XXX: More improve speed
    for line in body[1 : -2]
      if line =~# '^' . a:lnum
        let num_width = a:lnum < 1000 ? 3 : len(a:lnum)
        return line[num_width :]
      endif
    endfor
  elseif filereadable(a:target)
    let lines = readfile(a:target, '', a:lnum)
    return empty(lines) ? '' : lines[-1]
  endif
  return ''
endfunction

function! themis#util#error_info(stacktrace)
  let tracelines = map(copy(a:stacktrace), 'themis#util#funcinfo_format(v:val)')
  let tail = a:stacktrace[-1]
  if has_key(tail, 'funcname')
    let line_str = themis#util#funcline(tail.funcname, tail.line)
    let error_line = printf('%d: %s', tail.line, line_str)
    let tracelines += [error_line]
  endif
  return join(tracelines, "\n")
endfunction

function! themis#util#is_funcname(name)
  return a:name =~# '\v^%(\d+|%(\u|g:\u|s:|\<SNR\>\d+_)\w+|\h\w*%(#\w+)+)$'
endfunction

function! themis#util#funcname(funcref)
  return matchstr(string(a:funcref), '^function(''\zs.*\ze'')$')
endfunction

function! themis#util#get_full_title(obj, ...)
  let obj = a:obj
  let titles = a:0 ? a:1 : []
  call insert(titles, obj.get_title())
  while has_key(obj, 'parent')
    let obj = obj.parent
    call insert(titles, obj.get_title())
  endwhile
  return join(filter(titles, 'v:val !=# ""'), ' ')
endfunction

function! themis#util#sortuniq(list)
  call sort(a:list)
  let i = len(a:list) - 1
  while 0 < i
    if a:list[i] == a:list[i - 1]
      call remove(a:list, i)
    endif
    let i -= 1
  endwhile
  return a:list
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
