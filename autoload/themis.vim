" A testing framework for Vim script.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

" If user makes a typo such as "themis#sutie()",
" this script will be reloaded.  Then the following error occurs.
" E127: Cannot redefine function themis#run: It is in use
" This avoids it.
if exists('s:version')
  finish
endif

let s:version = '1.1'

let s:default_options = {
\   'target': [],
\   'recursive': 0,
\   'style': 'basic',
\   'reporter': 'tap',
\   'runtimepath': [],
\   'exclude': [],
\ }
function! themis#default_options()
  return deepcopy(s:default_options)
endfunction

function! themis#version()
  return s:version
endfunction

function! themis#run(paths, ...)
  let s:current_runner = themis#runner#new()
  try
    let options = get(a:000, 0, themis#default_options())
    return s:current_runner.run(a:paths, options)
  finally
    unlet! s:current_runner
  endtry
endfunction

" -- Utilities for test

function! s:runner()
  if !exists('s:current_runner')
    throw 'themis: Test is not running.'
  endif
  return s:current_runner
endfunction

function! themis#bundle(title)
  return s:runner().add_new_bundle(a:title)
endfunction

function! themis#suite(...)
  let title = get(a:000, 0, '')
  return themis#bundle(title).suite
endfunction

function! themis#helper(name)
  let runner = s:runner()
  let Helper = themis#helper#{a:name}#new(runner)
  return Helper
endfunction

function! themis#exception(type, message)
  return printf('themis: %s: %s', a:type, themis#message(a:message))
endfunction

function! themis#log(expr, ...)
  let mes = themis#message(a:expr) . "\n"
  call call('themis#logn', [mes] + a:000)
endfunction

function! themis#logn(expr, ...)
  let string = themis#message(a:expr)
  if !empty(a:000)
    let string = call('printf', [string] + a:000)
  endif
  if exists('g:themis#cmdline')
    verbose echon string
  else
    for line in split(string, "\n")
      echomsg line
    endfor
  endif
endfunction

function! themis#message(expr)
  let t = type(a:expr)
  return
  \  t == type('') ? a:expr :
  \  t == type([]) ? join(map(copy(a:expr), 'themis#message(v:val)'), "\n") :
  \                  string(a:expr)
endfunction

function! themis#failure(expr)
  return 'themis: report: failure: ' . themis#message(a:expr)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
