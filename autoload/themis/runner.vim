" themis: Test runner
" Version: 1.5.2dev
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {}

function! s:runner.init() abort
  call self.init_bundle()
  let self._emitter = themis#emitter#new()
  let self._supporters = {}
  let self._styles = {}
  for style_name in themis#module#list('style')
    let self._styles[style_name] = themis#module#style(style_name)
  endfor

  let style_event = deepcopy(s:style_event)
  let style_event.runner = self
  call self.add_event(style_event)
endfunction

function! s:runner.start(paths, options) abort
  try
    let save_runtimepath = &runtimepath

    let paths = type(a:paths) == type([]) ? a:paths : [a:paths]

    call s:load_themisrc(paths)

    let options = themis#option#merge(themis#option(), a:options)

    call self.load_plugins(options.runtimepath)

    let files = self.get_target_files(paths, options)
    call self.load(files)

    let self.target_pattern = join(a:options.target, '\m\|')
    let reporter = themis#module#reporter(options.reporter)
    return self.run(reporter)
  finally
    let &runtimepath = save_runtimepath
  endtry
endfunction

function! s:runner.get_target_files(paths, options) abort
  let files = s:paths2files(a:paths, a:options.recursive)

  let exclude_options = filter(copy(a:options.exclude), '!empty(v:val)')
  let exclude_pattern = join(exclude_options, '\|\m')
  if !empty(exclude_pattern)
    call filter(files, 'v:val !~# exclude_pattern')
  endif
  return files
endfunction

function! s:runner.load_plugins(runtimepaths) abort
  let appended = [getcwd()]
  if !empty(a:runtimepaths)
    for rtp in a:runtimepaths
      let appended += s:append_rtp(rtp)
    endfor
  endif

  let plugins = globpath(join(appended, ','), 'plugin/**/*.vim', 1)
  for plugin in split(plugins, "\n")
    execute 'source' fnameescape(plugin)
  endfor
endfunction

function! s:runner.load(files) abort
  let files_with_styles = {}
  for file in a:files
    let style = s:can_handle(values(self._styles), file)
    if style !=# ''
      let files_with_styles[file] = style
    endif
  endfor

  if empty(files_with_styles)
    throw 'themis: Target file not found.'
  endif

  try
    call self.load_scripts(files_with_styles)
    call self.emit('script_loaded', self)
  catch
    call self.on_error('script loading', v:exception, v:throwpoint)
  endtry
endfunction

function! s:runner.run(reporter) abort
  let stats = self.supporter('stats')
  call self.add_event(a:reporter)
  call self.emit('init', self)
  let error_count = 0
  try
    call self.run_all()
    let error_count = stats.fail()
  catch
    call self.on_error('running', v:exception, v:throwpoint)
    let error_count = 1
  finally
    call self.emit('finish', self)
  endtry
  return error_count
endfunction

function! s:runner.init_bundle() abort
  let self.root_bundle = themis#bundle#new()
endfunction

function! s:runner.load_scripts(files_with_styles) abort
  for [filename, style_name] in items(a:files_with_styles)
    if !filereadable(filename)
      throw printf('themis: Target file was not found: %s', filename)
    endif
    let style = self._styles[style_name]
    let base = themis#bundle#new('', self.root_bundle)
    let base.style = style
    call themis#_set_base_bundle(base)
    call style.load_script(filename, base)
    call themis#_unset_base_bundle()
  endfor
endfunction

function! s:runner.collect_test_names(bundle) abort
  let a:bundle.test_names = self.get_test_names(a:bundle)
  call filter(a:bundle.children, 'self.collect_test_names(v:val)')
  return !empty(a:bundle.test_names) || !empty(a:bundle.children)
endfunction

function! s:runner.run_all() abort
  call self.collect_test_names(self.root_bundle)
  call self.emit('start', self)
  call self.run_bundle(self.root_bundle)
  call self.emit('end', self)
endfunction

function! s:runner.run_bundle(bundle) abort
  let test_names = a:bundle.test_names
  call self.emit('before_suite', a:bundle)
  call self.run_suite(a:bundle, test_names)
  for child in a:bundle.children
    call self.run_bundle(child)
  endfor
  call self.emit('after_suite', a:bundle)
endfunction

function! s:runner.run_suite(bundle, test_names) abort
  for name in a:test_names
    call self.emit('start_test', a:bundle, name)
    call self.run_test(a:bundle, name)
  endfor
endfunction

function! s:runner.run_test(bundle, test_name) abort
  let report = themis#report#new(a:bundle, a:test_name)
  try
    call self.emit_before_test(a:bundle, a:test_name)
    let start_time = reltime()
    call a:bundle.run_test(a:test_name)
    let end_time = reltime(start_time)
    let report.result = 'pass'
    let report.time = str2float(reltimestr(end_time))
    call self.emit_after_test(a:bundle, a:test_name)
  catch
    call s:test_fail(report, v:exception, v:throwpoint)
  finally
    call self.emit(report.result, report)
  endtry
endfunction

function! s:runner.emit_before_test(bundle, test_name) abort
  if has_key(a:bundle, 'parent')
    call self.emit_before_test(a:bundle.parent, a:test_name)
  endif
  call self.emit('before_test', a:bundle, a:test_name)
endfunction

function! s:runner.emit_after_test(bundle, test_name) abort
  call self.emit('after_test', a:bundle, a:test_name)
  if has_key(a:bundle, 'parent')
    call self.emit_after_test(a:bundle.parent, a:test_name)
  endif
endfunction

function! s:runner.get_test_names(bundle) abort
  let style = a:bundle.get_style()
  if empty(style)
    return []
  endif
  let names = style.get_test_names(a:bundle)
  if get(self, 'target_pattern', '') !=# ''
    let pat = self.target_pattern
    call filter(names, 'a:bundle.get_test_full_title(v:val) =~# pat')
  endif
  return names
endfunction

function! s:runner.supporter(name) abort
  if !has_key(self._supporters, a:name)
    let self._supporters[a:name] = themis#module#supporter(a:name, self)
  endif
  return self._supporters[a:name]
endfunction

function! s:runner.add_event(listener) abort
  call self._emitter.add_listener(a:listener)
endfunction

function! s:runner.total_test_count(...) abort
  let bundle = a:0 ? a:1 : self.root_bundle
  return len(self.get_test_names(bundle))
  \    + s:sum(map(copy(bundle.children), 'self.total_test_count(v:val)'))
endfunction

function! s:runner.emit(name, ...) abort
  call call(self._emitter.emit, [a:name] + a:000, self._emitter)
endfunction

function! s:runner.on_error(phase, exception, throwpoint) abort
  let phase = self._emitter.emitting()
  if phase ==# ''
    let phase = a:phase
  endif
  if a:exception =~# '^themis:'
    let info = {
    \   'exception': matchstr(a:exception, '\C^themis:\s*\zs.*'),
    \ }
  else
    let info = {
    \   'exception': a:exception,
    \   'stacktrace': themis#util#callstack(a:throwpoint, -1),
    \ }
  endif
  call self.emit('error', a:phase, info)
endfunction

let s:style_event = {}
function! s:style_event._(event, args) abort
  if themis#bundle#is_bundle(get(a:args, 0))
    let bundle = a:args[0]
    let style = bundle.get_style()
    if has_key(style, 'event')
      call themis#emitter#fire(style.event, a:event, a:args)
    endif
  else
    for style in values(self.runner._styles)
      if has_key(style, 'event')
        call themis#emitter#fire(style.event, a:event, a:args)
      endif
    endfor
  endif
endfunction

function! s:test_fail(report, exception, throwpoint) abort
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

function! s:append_rtp(path) abort
  let appended = []
  if isdirectory(a:path)
    let path = substitute(a:path, '\\\+', '/', 'g')
    let path = substitute(path, '/$', '', 'g')
    let &runtimepath = escape(path, '\,') . ',' . &runtimepath
    let appended += [path]
    let after = path . '/after'
    if isdirectory(after)
      let &runtimepath .= ',' . after
      let appended += [after]
    endif
  endif
  return appended
endfunction

function! s:load_themisrc(paths) abort
  let themisrcs = themis#util#find_files(a:paths, '.themisrc')
  for themisrc in themisrcs
    execute 'source' fnameescape(themisrc)
  endfor
endfunction

function! s:paths2files(paths, recursive) abort
  let files = []
  let target_pattern = a:recursive ? '**/*' : '*'
  for path in a:paths
    if isdirectory(path)
      let files += split(globpath(path, target_pattern, 1), "\n")
    else
      let files += [path]
    endif
  endfor
  let mods =  ':p:gs?\\?/?'
  return filter(map(files, 'fnamemodify(v:val, mods)'), '!isdirectory(v:val)')
endfunction

function! s:can_handle(styles, file) abort
  for style in a:styles
    if style.can_handle(a:file)
      return style.name
    endif
  endfor
  return ''
endfunction

function! s:sum(list) abort
  return empty(a:list) ? 0 : eval(join(a:list, '+'))
endfunction

function! themis#runner#new() abort
  let runner = deepcopy(s:runner)
  call runner.init()
  return runner
endfunction

call themis#func_alias({'themis/Runner': s:runner})


let &cpo = s:save_cpo
unlet s:save_cpo
