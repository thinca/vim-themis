" themis: reporter: Report with xUnit style.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:reporter = {}

function! s:reporter.init(runner)
  let self.stats = a:runner.supporter('stats')
endfunction

function! s:reporter.pass(report)
  call themis#logn('.')
endfunction

function! s:reporter.fail(report)
  call themis#logn('F')
endfunction

function! s:reporter.pending(report)
  call themis#logn('P')
endfunction

function! s:reporter.end(runner)
  call themis#log("\n")
  call themis#log(self.stats.stat())
endfunction

function! s:reporter.error(phase, stacktrace, error_line, exception)
  call themis#log(printf('Error occurred in %s.', a:phase))
  let tracelines = map(a:stacktrace, 'themis#util#funcinfo_format(v:val)')
  call themis#log(tracelines)
  call themis#log(a:error_line)
  call themis#log(a:exception)
endfunction

function! s:print_message(message)
  for line in split(a:message, "\n")
    call themis#log('# ' . line)
  endfor
endfunction

function! themis#reporter#dot#new()
  return deepcopy(s:reporter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
