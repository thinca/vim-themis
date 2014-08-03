" themis: Utility functions.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

function! themis#util#callstacklines(throwpoint, ...)
  let infos = call('themis#util#callstack', [a:throwpoint] + a:000)
  return map(infos, 'themis#util#funcinfo_format(v:val)')
endfunction

function! themis#util#callstack(throwpoint, ...)
  let this_callstack = split(expand('<sfile>'), '\.\.')[: -2]
  let throwpoint_stack = split(a:throwpoint, '\.\.')
  let start = a:0 ? len(this_callstack) + a:1 : 0
  if len(throwpoint_stack) <= start ||
  \  this_callstack[0] isnot throwpoint_stack[0]
    let start = 0
  endif
  let error_stack = throwpoint_stack[start :]
  return map(error_stack, 'themis#util#funcinfo(v:val)')
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

function! themis#util#funcinfo(func)
  let f = matchstr(a:func, '^\%(function\s\+\)\?\zs.*')
  let line = 0
  if f =~# ',.*\d'
    let [f, line] = matchlist(f, '^\(.\+\),.\{-}\(\d\+\)')[1 : 2]
  endif
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


let &cpo = s:save_cpo
unlet s:save_cpo
