" themis: Test runner
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {
\   'events': [],
\   '_suppporters': {},
\ }

function! s:runner.run(scripts, options)
  let scripts = type(a:scripts) == type([]) ? a:scripts : [a:scripts]
  let self.style = themis#module#style(a:options.style, self)
  call filter(scripts, 'self.style.can_handle(v:val)')
  if empty(scripts)
    throw 'themis: Target file not found.'
  endif

  let error_count = 0
  let save_runtimepath = &runtimepath
  if !empty(a:options.runtimepath)
    let &runtimepath =
    \   join(map(copy(a:options.runtimepath), 'escape(v:val, "\\,")'), ',')
    \   . ',' . &runtimepath
  endif
  let stats = self.supporter('stats')
  call self.init_bundle()
  let reporter = themis#module#reporter(a:options.reporter)
  call self.add_event(reporter)
  try
    call self.load_scripts(a:scripts)
    call self.emit('script_loaded', self)
    call self.emit('start', self)
    call self.run_all()
    call self.emit('end', self)
    let error_count = stats.fail()
  catch
    let phase = get(self,  'phase', 'core')
    if v:exception =~# '^themis:'
      let info = {
      \   'exception': matchstr(v:exception, '\C^themis:\s*\zs.*'),
      \ }
    else
      let info = {
      \   'exception': v:exception,
      \   'stacktrace': themis#util#callstack(v:throwpoint, -1),
      \ }
    endif
    call self.emit('error', phase, info)
    let error_count = 1
  finally
    let &runtimepath = save_runtimepath
  endtry
  return error_count
endfunction

function! s:runner.init_bundle()
  let self.bundle = themis#bundle#new()
  let self.current_bundle = self.bundle
endfunction

function! s:runner.add_new_bundle(title)
  return self.add_bundle(themis#bundle#new(a:title))
endfunction

function! s:runner.add_bundle(bundle)
  if has_key(self, '_filename')
    let a:bundle.filename = self._filename
  endif
  call self.current_bundle.add_child(a:bundle)
  return a:bundle
endfunction

function! s:runner.load_scripts(scripts)
  let self.phase = 'script loading'
  for script in a:scripts
    if !filereadable(script)
      throw printf('themis: Target file was not found: %s', script)
    endif
    let self._filename = script
    call self.style.load_script(script)
  endfor
  unlet self.phase
endfunction

function! s:runner.run_all()
  call self.run_bundle(self.bundle)
endfunction

function! s:runner.run_bundle(bundle)
  let self.current_bundle = a:bundle
  call self.emit('before_suite', a:bundle)
  call self.run_suite(a:bundle)
  for child in a:bundle.children
    call self.run_bundle(child)
  endfor
  call self.emit('after_suite', a:bundle)
endfunction

function! s:runner.run_suite(bundle)
  for name in self.style.get_test_names(a:bundle)
    let report = themis#report#new(a:bundle, name)
    call self.emit('before_test', a:bundle, name)
    try
      let start_time = reltime()
      call a:bundle.run_test(name)
      let end_time = reltime(start_time)
      let report.result = 'pass'
      let report.time = str2float(reltimestr(end_time))
    catch
      call s:test_fail(report, v:exception, v:throwpoint)
    finally
      call self.emit(report.result, report)
      call self.emit('after_test', a:bundle, name)
    endtry
  endfor
endfunction

function! s:runner.supporter(name)
  if !has_key(self._suppporters, a:name)
    let self._suppporters[a:name] = themis#module#supporter(a:name, self)
  endif
  return self._suppporters[a:name]
endfunction

function! s:runner.add_event(event)
  call add(self.events, a:event)
  call s:call(a:event, 'init', [self])
endfunction

function! s:runner.total_test_count(...)
  let bundle = a:0 ? a:1 : self.bundle
  return len(self.style.get_test_names(bundle))
  \    + s:sum(map(copy(bundle.children), 'self.total_test_count(v:val)'))
endfunction

function! s:runner.emit(name, ...)
  let self.phase = a:name
  for event in self.events
    call s:call(event, a:name, a:000)
  endfor
  unlet self.phase
endfunction

function! s:call(obj, key, args)
  if has_key(a:obj, a:key)
    call call(a:obj[a:key], a:args, a:obj)
  endif
endfunction

function! s:test_fail(report, exception, throwpoint)
  if a:exception =~? '^themis:\_s*report:'
    let result = matchstr(a:exception, '\c^themis:\_s*report:\_s*\zs.*')
    let [a:report.type, a:report.message] =
    \   matchlist(result, '\v^%((\w+):\s*)?(.*)')[1 : 2]
  else
    let callstack = themis#util#callstacklines(a:throwpoint, -1)
    " TODO: More info to report
    let a:report.exception = a:exception
    let a:report.message = join(callstack, "\n") . "\n" . a:exception
  endif

  if get(a:report, 'type', '') =~# '^\u\+$'
    let a:report.result = 'pending'
  else
    let a:report.result = 'fail'
  endif
endfunction

function! s:sum(list)
  return empty(a:list) ? 0 : eval(join(a:list, '+'))
endfunction

function! themis#runner#new()
  let runner = deepcopy(s:runner)
  return runner
endfunction


let &cpo = s:save_cpo
unlet s:save_cpo
