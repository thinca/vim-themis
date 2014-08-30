" Themis option utilities.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:default_options = {
\   'target': [],
\   'recursive': 0,
\   'style': 'basic',
\   'reporter': 'tap',
\   'runtimepath': [],
\   'exclude': [],
\ }

function! themis#option#default()
  return deepcopy(s:default_options)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
