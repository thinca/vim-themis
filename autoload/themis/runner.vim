" themis: Test runner
" Version: 1.5dev
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:runner = {}

function! s:runner.init() abort
  call self.init_bundle()
  let self._events = []
  let self._suppporters = {}
  let self._styles = {}
  for style_name in themis#module#list('style')
    let self._styles[style_name] = themis#module#style(style_name)
  endfor

  let style_event = deepcopy(s:style_event)
  let style_event.runner = self
  call self.add_event(style_event)
endfunction

function! s:runner.run(paths, options) abort
  let paths = type(a:paths) == type([]) ? a:paths : [a:paths]

  call s:load_themisrc(paths)

  let options = themis#option#merge(themis#option(), a:options)

  let files = s:paths2files(paths, options.recursive)

  let excludes = join(filter(copy(options.exclude), '!empty(v:val)'), '\|\m')
  if !empty(excludes)
    call filter(files, 'v:val !~# excludes')
  endif

  let files_with_styles = {}
  for file in files
    let style = s:can_handle(values(self._styles), file)
    if style !=# ''
      let files_with_styles[file] = style
    endif
  endfor

  if empty(files_with_styles)
    throw 'themis: Target file not found.'
  endif

  let error_count = 0
  let save_runtimepath = &runtimepath

  let appended = [getcwd()]
  if !empty(options.runtimepath)
    for rtp in options.runtimepath
      let appended += s:append_rtp(rtp)
    endfor
  endif

  let plugins = globpath(join(appended, ','), 'plugin/**/*.vim', 1)
  for plugin in split(plugins, "\n")
    execute 'source' fnameescape(plugin)
  endfor

  let self.target_pattern = join(options.target, '\m\|')

  let stats = self.supporter('stats')
  let reporter = themis#module#reporter(options.reporter)
  call self.add_event(reporter)
  try
    call self.load_scripts(files_with_styles)
    call self.emit('script_loaded', self)
    call self.run_all()
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
    call self.emit('finish', self)
  endtry
  return error_count
endfunction

function! s:runner.init_bundle() abort
  let self.root_bundle = themis#bundle#new()
  let self.bundle_stacks = [self.root_bundle]
endfunction

function! s:runner.get_current_bundle() abort
  return self.bundle_stacks[-1]
endfunction

function! s:runner.in_bundle(bundle) abort
  let self.bundle_stacks += [a:bundle]
endfunction

function! s:runner.out_bundle() abort
  call remove(self.bundle_stacks, -1)
endfunction

function! s:runner.add_new_bundle(title) abort
  return self.add_bundle(themis#bundle#new(a:title))
endfunction

function! s:runner.add_bundle(bundle) abort
  if has_key(self, '_current')
    let a:bundle.filename = self._current.filename
    let a:bundle.style_name = self._current.style_name
  endif
  call self.get_current_bundle().add_child(a:bundle)
  return a:bundle
endfunction

function! s:runner.load_scripts(files_with_styles) abort
  let self.phase = 'script loading'
  for [filename, style_name] in items(a:files_with_styles)
    if !filereadable(filename)
      throw printf('themis: Target file was not found: %s', filename)
    endif
    let style = self._styles[style_name]
    let self._current = {
    \   'filename': filename,
    \   'style_name': style_name,
    \ }
    call style.load_script(filename)
    unlet self._current
  endfor
  unlet self.phase
endfunction

function! s:runner.collect_test_names(bundle) abort
  let a:bundle.test_names = self.get_test_names(a:bundle)
  let is_empty = empty(a:bundle.test_names)
  for child in a:bundle.children
    call self.collect_test_names(child)
    let is_empty = is_empty && child.is_empty
  endfor
  let a:bundle.is_empty = is_empty
endfunction

function! s:runner.run_all() abort
  call self.collect_test_names(self.root_bundle)
  call self.emit('start', self)
  call self.run_bundle(self.root_bundle)
  call self.emit('end', self)
endfunction

function! s:runner.run_bundle(bundle) abort
  if a:bundle.is_empty
    return
  endif
  let test_names = a:bundle.test_names
  let has_style = a:bundle.get_style_name() !=# ''
  call self.in_bundle(a:bundle)
  if has_style
    call self.emit('before_suite', a:bundle)
  endif
  call self.run_suite(a:bundle, test_names)
  for child in a:bundle.children
    call self.run_bundle(child)
  endfor
  if has_style
    call self.emit('after_suite', a:bundle)
  endif
  call self.out_bundle()
endfunction

function! s:runner.run_suite(bundle, test_names) abort
  for name in a:test_names
    let report = themis#report#new(a:bundle, name)
    try
      call self.emit('before_test', a:bundle, name)
      let start_time = reltime()
      call a:bundle.run_test(name)
      let end_time = reltime(start_time)
      let report.result = 'pass'
      let report.time = str2float(reltimestr(end_time))
      call self.emit('after_test', a:bundle, name)
    catch
      call s:test_fail(report, v:exception, v:throwpoint)
    finally
      call self.emit(report.result, report)
    endtry
  endfor
endfunction

function! s:runner.get_test_names(bundle) abort
  let style = get(self._styles, a:bundle.get_style_name(), {})
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

function! s:runner.get_current_style() abort
  return get(self._styles, self.get_current_bundle().get_style_name(), {})
endfunction

function! s:runner.supporter(name) abort
  if !has_key(self._suppporters, a:name)
    let self._suppporters[a:name] = themis#module#supporter(a:name, self)
  endif
  return self._suppporters[a:name]
endfunction

function! s:runner.add_event(event) abort
  call add(self._events, a:event)
  call s:call(a:event, 'init', [self])
endfunction

function! s:runner.total_test_count(...) abort
  let bundle = a:0 ? a:1 : self.root_bundle
  return len(self.get_test_names(bundle))
  \    + s:sum(map(copy(bundle.children), 'self.total_test_count(v:val)'))
endfunction

function! s:runner.emit(name, ...) abort
  let self.phase = a:name
  for event in self._events
    call s:call(event, a:name, a:000)
  endfor
  unlet self.phase
endfunction

function! s:call(obj, key, args) abort
  if has_key(a:obj, a:key)
    call call(a:obj[a:key], a:args, a:obj)
  elseif has_key(a:obj, '_')
    call call(a:obj['_'], [a:key, a:args], a:obj)
  endif
endfunction

let s:style_event = {}
function! s:style_event._(event, args) abort
  let current_style = self.runner.get_current_style()
  if !empty(current_style)
    if has_key(current_style, 'event')
      call s:call(current_style.event, a:event, a:args)
    end
  else
    for style in values(self.runner._styles)
      call s:call(style.event, a:event, a:args)
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
