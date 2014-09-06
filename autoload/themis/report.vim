" themis: A report of test.
" Version: 1.2
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:report = {
\   'result': 'yet',
\ }

function! s:report.is_success()
  return self.result ==# 'pass'
endfunction

function! s:report.get_full_title()
  return themis#util#get_full_title(self)
endfunction

function! s:report.get_title()
  return self.parent.get_test_title(self.name)
endfunction

function! s:report.get_message()
  return get(self, 'message', '')
endfunction

function! themis#report#new(bundle, name)
  let report = deepcopy(s:report)
  let report.parent = a:bundle
  let report.name = a:name
  return report
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
