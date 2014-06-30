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
endfunction

function! themis#util#funcbody(func, verbose)
  let fname = a:func =~# '^\d\+' ? '{' . a:func . '}' : a:func
  let verbose = a:verbose ? 'verbose' : ''
  redir => body
  silent execute verbose 'function' fname
  redir END
  return split(body, "\n")
endfunction

function! themis#util#funcline(func, line)
  let body = themis#util#funcbody(a:func, 0)
  let line = body[a:line]
  let num_width = a:line < 1000 ? 3 : len(a:line)
  return line[num_width :]
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
