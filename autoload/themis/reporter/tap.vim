" themis: reporter: Report with TAP(Test Anything Protocol).
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:reporter = {}

function! s:reporter.init(runner)
  let self.stats = a:runner.supporter('stats')
endfunction

function! s:reporter.start(runner)
  call themis#log('1..' . a:runner.total_test_count())
endfunction

function! s:reporter.before_suite(bundle)
  " call themis#log('# ' . a:bundle.filename)
endfunction

function! s:reporter.pass(report)
  let title = a:report.get_full_title()
  let mes = printf('ok %d - %s', self.stats.count(), title)
  call themis#log(mes)
endfunction

function! s:reporter.fail(report)
  let title = a:report.get_full_title()
  let mes = printf('not ok %d - %s', self.stats.count(), title)
  call themis#log(mes)
  call s:print_message(a:report.message)
endfunction

function! s:reporter.pending(report)
  let title = a:report.get_full_title()
  let mes = printf('ok %d - %s # SKIP', self.stats.count(), title)
  call themis#log(mes)
  call s:print_message(a:report.message)
endfunction

function! s:reporter.error(phase, info)
  call themis#log(printf('Bail out!  Error occurred in %s.', a:phase))
  if has_key(a:info, 'stacktrace')
    call s:print_message(themis#util#error_info(a:info.stacktrace))
  endif
  call s:print_message(a:info.exception)
endfunction

function! s:reporter.end(runner)
  call themis#log('')
  call s:print_message(self.stats.stat())
endfunction


function! s:print_message(message)
  let lines = type(a:message) == type([]) ? a:message : split(a:message, "\n")
  for line in lines
    call themis#log('# ' . line)
  endfor
endfunction

function! themis#reporter#tap#new()
  return deepcopy(s:reporter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
