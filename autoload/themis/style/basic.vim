" themis: style: basic: Basic style.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:func_t = type(function('type'))
let s:special_names = [
\   'before',
\   'after',
\   'before_each',
\   'after_each',
\ ]
let s:describe_pattern = '^__.\+__$'

let s:event = {}

function s:load_nested_bundle(bundle, runner) abort
  let before_loading_bundle = a:runner.get_loading_bundle()
  call a:runner.set_loading_bundle(a:bundle)
  let suite = copy(a:bundle.suite)
  call filter(suite, 'v:key =~# s:describe_pattern')
  for name in s:names_by_defined_order(suite)
    " call suite[name]()
    " Above code doesn't work on old Vim
    call call(suite[name], [], suite)
  endfor

  for child in a:bundle.children
    call s:load_nested_bundle(child, a:runner)
  endfor
  call a:runner.set_loading_bundle(before_loading_bundle)
endfunction

function s:event.before_suite(bundle) abort
  if has_key(a:bundle.suite, 'before')
    call a:bundle.suite.before()
  endif
endfunction

function s:event.before_test(bundle, entry) abort
  if has_key(a:bundle.suite, 'before_each')
    call a:bundle.suite.before_each()
  endif
endfunction

function s:event.after_suite(bundle) abort
  if has_key(a:bundle.suite, 'after')
    call a:bundle.suite.after()
  endif
endfunction

function s:event.after_test(bundle, entry) abort
  if has_key(a:bundle.suite, 'after_each')
    call a:bundle.suite.after_each()
  endif
endfunction


let s:style = {
\   'event': s:event,
\ }

function s:style.get_test_names(bundle) abort
  let suite = copy(a:bundle.suite)
  call filter(suite, 'type(v:val) == s:func_t')
  call filter(suite, 'index(s:special_names, v:key) < 0')
  call filter(suite, 'v:key !~# s:describe_pattern')
  return s:names_by_defined_order(suite)
endfunction

function s:names_by_defined_order(suite) abort
  let s:suite_for_sort = a:suite
  let result = sort(keys(a:suite), 's:test_compare')
  unlet s:suite_for_sort
  return result
endfunction

function s:test_compare(a, b) abort
  let a_order = s:to_i(themis#util#funcname(s:suite_for_sort[a:a]))
  let b_order = s:to_i(themis#util#funcname(s:suite_for_sort[a:b]))
  return a_order ==# b_order ? 0 : b_order < a_order ? 1 : -1
endfunction

function s:to_i(value) abort
  return a:value =~# '^\d\+$' ? str2nr(a:value) : a:value
endfunction

function s:style.can_handle(filename) abort
  return fnamemodify(a:filename, ':e') ==? 'vim'
endfunction

function s:style.load_script(filename, runner) abort
  source `=a:filename`
  call s:load_nested_bundle(a:runner.get_loading_bundle(), a:runner)
endfunction

function themis#style#basic#new() abort
  return deepcopy(s:style)
endfunction
