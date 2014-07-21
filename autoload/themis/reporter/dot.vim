" themis: reporter: Report with xUnit style.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:reporter = {}

function! s:reporter.init(runner)
  let self.stats = a:runner.supporter('stats')
  let self.fails = []
endfunction

function! s:reporter.pass(report)
  call themis#logn('.')
endfunction

function! s:reporter.fail(report)
  let self.fails += [a:report]
  call themis#logn('F')
endfunction

function! s:reporter.pending(report)
  call themis#logn('P')
endfunction

function! s:reporter.end(runner)
  call themis#log("\n")

  if !empty(self.fails)
    let n = 1
    for report in self.fails
      call s:print_report(n, report)
      let n += 1
      call themis#log('')
    endfor
  endif

  call themis#log(self.stats.stat())
endfunction

function! s:reporter.error(phase, info)
  call themis#log(printf('Error occurred in %s.', a:phase))
  if has_key(a:info, 'stacktrace')
    call themis#log(themis#util#error_info(a:info.stacktrace))
  endif
  call themis#log(a:info.exception)
endfunction

function! s:print_report(n, report)
  call themis#log(printf('%3d) %s', a:n, a:report.get_full_title()))
  call themis#log(map(split(a:report.message, "\n"), '"     " . v:val'))
endfunction

function! themis#reporter#dot#new()
  return deepcopy(s:reporter)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
