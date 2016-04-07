" themis: A report of test.
" Version: 1.5.2dev
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:Report = {
\   'result': 'yet',
\ }

function! s:Report.is_success() abort
  return self.result ==# 'pass'
endfunction

function! s:Report.get_full_title() abort
  return themis#util#get_full_title(self)
endfunction

function! s:Report.get_title() abort
  return self.parent.get_test_title(self.entry)
endfunction

function! s:Report.get_message() abort
  return get(self, 'message', '')
endfunction

function! themis#report#new(bundle, entry) abort
  let report = deepcopy(s:Report)
  let report.parent = a:bundle
  let report.entry = a:entry
  return report
endfunction

call themis#func_alias({'themis/Report': s:Report})


let &cpo = s:save_cpo
unlet s:save_cpo
