" themis: A report of test.
" Version: 1.1
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

" FIXME: Duplicate function in bundle
function! s:report.get_full_title()
  let title = ''
  if has_key(self, 'parent')
    let t = self.parent.get_full_title()
    if !empty(t)
      let title = t . ' '
    endif
  endif
  return title . self.get_title()
endfunction

function! s:report.get_title()
  let description = self.parent.get_description(self.name)
  return empty(description) ? get(self, 'name', '') : description
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
