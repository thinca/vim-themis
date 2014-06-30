" A testing framework for Vim script.
" Version: 1.0
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

let s:version = '1.0'

let s:default_options = {
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

function! themis#run(scripts, ...)
  let s:current_runner = themis#runner#new()
  try
    let options = get(a:000, 0, themis#default_options())
    return s:current_runner.run(a:scripts, options)
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
  let helper = themis#helper#{a:name}#new(runner)
  return helper
endfunction

function! themis#exception(type, message)
  return printf('themis: %s: %s', a:type, s:to_string(a:message))
endfunction

function! themis#log(expr, ...)
  let mes = s:to_string(a:expr) . "\n"
  call call('themis#logn', [mes] + a:000)
endfunction

function! themis#logn(expr, ...)
  let string = s:to_string(a:expr)
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

function! s:to_string(expr)
  let t = type(a:expr)
  return t == type('') ? a:expr :
  \      t == type([]) ? join(map(a:expr, 's:to_string(v:val)'), "\n") :
  \                      string(a:expr)
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
