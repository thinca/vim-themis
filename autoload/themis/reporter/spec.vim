" themis: reporter: Report with spec style.
" Version: 1.2
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

scriptencoding utf-8

let s:save_cpo = &cpo
set cpo&vim

if has('win32')
  let s:pass_symbol = 'o'
  let s:fail_symbol = 'x'
else
  let s:pass_symbol = '✓'
  let s:fail_symbol = '✖'
endif

let s:reporter = {}

function! s:reporter.init(runner)
  let self.stats = a:runner.supporter('stats')
  let self.indent = 0
endfunction

function! s:reporter.start(runner)
endfunction

function! s:reporter.before_suite(bundle)
  call self.print(a:bundle.get_title())
  let self.indent += 1
endfunction

function! s:reporter.after_suite(bundle)
  let self.indent -= 1
endfunction

function! s:reporter.pass(report)
  call self.print(printf('[%s] %s', s:pass_symbol, a:report.get_title()))
endfunction

function! s:reporter.fail(report)
  call self.print(printf('[%s] %s', s:fail_symbol, a:report.get_title()))
  call self.print(a:report.message, '    ')
endfunction

function! s:reporter.pending(report)
  call self.print(printf('[-] %s', a:report.get_title()))
  call self.print(a:report.message, '    ')
endfunction

function! s:reporter.error(phase, info)
  call themis#log(printf('Error occurred in %s.', a:phase))
  if has_key(a:info, 'stacktrace')
    call themis#log(themis#util#error_info(a:info.stacktrace))
  endif
  call themis#log(a:info.exception)
endfunction

function! s:reporter.end(runner)
  call themis#log('')
  call self.print(self.stats.stat())
endfunction


function! s:reporter.print(message, ...)
  let prefix = a:0 ? a:1 : ''
  for line in split(a:message, "\n")
    call themis#log(prefix . repeat('  ', self.indent - 1) . line)
  endfor
endfunction

function! themis#reporter#spec#new()
  return deepcopy(s:reporter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
