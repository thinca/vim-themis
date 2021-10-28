" A testing framework for Vim script.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

" If user makes a typo such as "themis#suite()",
" this script will be reloaded.  Then the following error occurs.
" E127: Cannot redefine function themis#run: It is in use
" This avoids it.
if exists('s:version')
  finish
endif

let g:themis#vital = vital#themis#new()

let s:version = '1.6.0'

function themis#version() abort
  return s:version
endfunction

function themis#run(paths, options) abort
  let s:current_runner = themis#runner#new()
  try
    return s:current_runner.start(a:paths, a:options)
  finally
    unlet! s:current_runner
  endtry
endfunction

" -- Utilities for test

function s:runner() abort
  if !exists('s:current_runner')
    throw 'themis: Test is not running.'
  endif
  return s:current_runner
endfunction

function themis#bundle(title) abort
  let base_bundle = s:runner().get_loading_bundle()
  let new_bundle = themis#bundle#new(a:title)
  call base_bundle.add_child(new_bundle)
  return new_bundle
endfunction

function themis#suite(...) abort
  let title = get(a:000, 0, '')
  return themis#bundle(title).suite
endfunction

function themis#helper(name) abort
  try
    return themis#helper#{a:name}#new(s:runner())
  catch /Vim(return):E117:/
    throw 'themis: Unknown helper: ' . a:name
  endtry
endfunction

function themis#option(...) abort
  if !exists('s:custom_options')
    let s:custom_options = themis#option#default()
  endif
  if a:0 == 0
    return s:custom_options
  endif
  let name = a:1
  if a:0 == 1
    return get(s:custom_options, name, '')
  endif
  if has_key(s:custom_options, name)
    if type(s:custom_options[name]) == type([])
      let value = type(a:2) == type([]) ? a:2 : [a:2]
      let s:custom_options[name] += value
    else
      let s:custom_options[name] = a:2
    endif
  endif
endfunction

function themis#func_alias(dict) abort
  call themis#util#func_alias(a:dict, [])
endfunction

function themis#exception(type, message) abort
  return printf('themis: %s: %s', a:type, themis#message(a:message))
endfunction

function themis#log(expr, ...) abort
  let mes = themis#message(a:expr) . "\n"
  call call('themis#logn', [mes] + a:000)
endfunction

function themis#logn(expr, ...) abort
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

function themis#message(expr) abort
  let t = type(a:expr)
  return
  \  t == type('') ? a:expr :
  \  t == type([]) ? join(map(copy(a:expr), 'themis#message(v:val)'), "\n") :
  \                  string(a:expr)
endfunction

function themis#failure(expr) abort
  return 'themis: report: failure: ' . themis#message(a:expr)
endfunction
