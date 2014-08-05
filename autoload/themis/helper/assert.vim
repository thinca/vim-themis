" themis: helper: Assert utilities.
" Version: 1.1
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:helper = {}

function! s:assert_fail(mes)
  throw themis#failure(a:mes)
endfunction

function! s:assert_todo(...)
  throw 'themis: report: todo:' . themis#message(a:0 ? a:1 : '')
endfunction

function! s:assert_skip(mes)
  throw 'themis: report: SKIP:' . themis#message(a:mes)
endfunction

function! s:assert_true(value)
  if a:value isnot 1
    throw themis#failure([
    \   'The true value was expected, but it was not the case.',
    \   '',
    \   '    expected: true',
    \   '         got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:assert_false(value)
  if a:value isnot 0
    throw themis#failure([
    \   'The false value was expected, but it was not the case.',
    \   '',
    \   '    expected: false',
    \   '         got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:assert_truthy(value)
  let t = type(a:value)
  if !(t == type(0) || t == type('')) || !a:value
    throw themis#failure([
    \   'The truthy value was expected, but it was not the case.',
    \   '',
    \   '    expected: truthy',
    \   '         got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:assert_falsy(value)
  let t = type(a:value)
  if !(t != type(0) || t != type('') || !a:value)
    throw themis#failure([
    \   'The falsy value was expected, but it was not the case.',
    \   '',
    \   '    expected: falsy',
    \   '         got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:assert_compare(left, expr, right)
  let expr_str = join([string(a:left), a:expr, string(a:right)])
  try
    let result = eval(join(['a:left', a:expr, 'a:right']))
  catch /^Vim(let):E691:/
    let result = 0
  catch
    throw themis#failure([
    \   'Unexpected error occurred while evaluating the comparing:',
    \   '',
    \   '    expression: ' . expr_str,
    \   '    error: ' . v:exception,
    \ ])
  endtry
  if !result
    throw themis#failure([
    \   'The right expression was expected, but it was not the case.',
    \   '',
    \   '    expression: ' . expr_str,
    \ ])
  endif
  return 1
endfunction

function! s:assert_equals(actual, expect)
  if !s:equals(a:expect, a:actual)
    throw themis#failure([
    \   'The equivalent values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:assert_not_equals(actual, expect)
  if s:equals(a:expect, a:actual)
    throw themis#failure([
    \   'Not the equivalent values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:assert_same(actual, expect)
  if a:expect isnot# a:actual
    throw themis#failure([
    \   'The same values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:assert_not_same(actual, expect)
  if a:expect is# a:actual
    throw themis#failure([
    \   'Not the same values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:assert_match(actual, pattern)
  if !s:match(a:actual, a:pattern)
    throw themis#failure([
    \   'Match was expected, but did not match.',
    \   '',
    \   '    target: ' . string(a:actual),
    \   '    pattern: ' . string(a:pattern),
    \ ])
  endif
  return 1
endfunction

function! s:assert_not_match(actual, pattern)
  if s:match(a:actual, a:pattern)
    throw themis#failure([
    \   'Not match was expected, but matched.',
    \   '',
    \   '    target: ' . string(a:actual),
    \   '    pattern: ' . string(a:pattern),
    \ ])
  endif
  return 1
endfunction

function! s:assert_is_number(value)
  return s:check_type(a:value, 'Number', 0)
endfunction

function! s:assert_is_not_number(value)
  return s:check_type(a:value, 'Number', 1)
endfunction

function! s:assert_is_string(value)
  return s:check_type(a:value, 'String', 0)
endfunction

function! s:assert_is_not_string(value)
  return s:check_type(a:value, 'String', 1)
endfunction

function! s:assert_is_func(value)
  return s:check_type(a:value, 'Funcref', 0)
endfunction

function! s:assert_is_not_func(value)
  return s:check_type(a:value, 'Funcref', 1)
endfunction

function! s:assert_is_list(value)
  return s:check_type(a:value, 'List', 0)
endfunction

function! s:assert_is_not_list(value)
  return s:check_type(a:value, 'List', 1)
endfunction

function! s:assert_is_dict(value)
  return s:check_type(a:value, 'Dictionary', 0)
endfunction

function! s:assert_is_not_dict(value)
  return s:check_type(a:value, 'Dictionary', 1)
endfunction

function! s:assert_is_float(value)
  return s:check_type(a:value, 'Float', 0)
endfunction

function! s:assert_is_not_float(value)
  return s:check_type(a:value, 'Float', 1)
endfunction

function! s:assert_type_of(value, names)
  return s:check_type(a:value, a:names, 0)
endfunction

function! s:assert_length_of(value, length)
  call s:assert_type_of(a:value, ['String', 'List', 'Dictionary'])
  let got_length = len(a:value)
  if got_length != a:length
    throw themis#failure([
    \   'The length of value was expected to the specified length, but it was not the case.',
    \   '',
    \   '    expected length: ' . a:length,
    \   '         got length: ' . got_length,
    \   '          got value: ' . string(a:value),
    \ ])
  endif
endfunction

function! s:assert_has_key(value, key)
  let t = type(a:value)
  if t == type({})
    if !has_key(a:value, a:key)
      throw themis#failure([
      \   'The dictionary was expected to have a key, but it did not have.',
      \   '',
      \   '      dictionary: ' . string(a:value),
      \   '    expected key: ' . string(a:key),
      \ ])
    endif
  elseif t == type([])
    if (a:key < 0 || len(a:value) <= a:key)
      throw themis#failure([
      \   'The array was expected to have a index, but it did not have.',
      \   '',
      \   '             array: ' . string(a:value),
      \   '      array length: ' . len(a:value),
      \   '    expected index: ' . string(a:key),
      \ ])
    endif
  else
    throw themis#failure([
    \   'The first argument was expected to an array or a dict, but it did not have.',
    \   '',
    \   '    value: ' . string(a:value),
    \   '     type: ' . s:type(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:assert_exists(expr)
  if !exists(a:expr)
    throw themis#failure([
    \   'The target was expected to exist, but it did not exist.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ])
  endif
  return 1
endfunction

" TODO: validate()
function! s:assert_validate(expr, rule)
  let result = s:validate(a:expr, a:rule)
  if !empty(result)
    throw themis#failure([
    \   'expected rule: ' . string(a:rule),
    \   '    got value: ' . string(a:expr),
    \ ])
  endif
  return 1
endfunction

function! s:validate(expr, rule)
  let rule_type = type(a:rule)

  if rule_type == type([])
    for r in a:rule
      let result = s:validate(a:expr, r)
      if empty(result)
        return ''
      endif
    endfor
    return 'does not match to rule'
  endif

  if rule_type == type('')
    let rule = {
    \   'type': matchstr(rule_str, '^\w\+'),
    \   'omittable': matchstr(rule_str, '?$') ==# '?',
    \ }
  elseif rule_type == type({})
    let rule = a:rule
  else
    return 'invalid rule: ' . string(a:rule)
  endif

  for [key, rule_of_key] in items(rule)
  endfor
endfunction


function! s:equals(a, b)
  return type(a:a) == type(a:b) && a:a ==# a:b
endfunction

function! s:match(str, pattern)
  return type(a:str) == type('') &&
  \      type(a:pattern) == type('') &&
  \      a:str =~# a:pattern
endfunction

let s:type_names = {
\   type(0): 'number',
\   type(''): 'string',
\   type(function('type')): 'funcref',
\   type([]): 'list',
\   type({}): 'dictionary',
\   type(0.0): 'float',
\ }
function! s:type(value)
  return s:type_names[type(a:value)]
endfunction

function! s:check_type(value, expected_types, not)
  let got_type = s:type(a:value)
  let expected_types = s:type(a:expected_types) ==# 'list' ?
  \                    copy(a:expected_types) : [a:expected_types]
  call map(expected_types, 'tolower(v:val)')
  call map(expected_types, 'v:val ==# "dict" ? "dictionary" : v:val')
  let success = 0 <= index(expected_types, got_type)
  if a:not
    let success = !success
  endif
  if !success
    if 2 <= len(expected_types)
      let msg = 'The type of value was expected to be one of %s'
      let arg = join(expected_types[: -2], ', ') . ' or ' . expected_types[-1]
    else
      let msg = 'The type of value was expected to be %s'
      let arg = expected_types[0]
    endif
    throw themis#failure([
    \   printf(msg, arg) . ', but it was not the case.',
    \   '',
    \   '    expected type: ' . arg,
    \   '         got type: ' . got_type,
    \   '        got value: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:redir(cmd)
  let [save_verbose, save_verbosefile] = [&verbose, &verbosefile]
  set verbose=0 verbosefile=
  redir => res
    silent! execute a:cmd
  redir END
  let [&verbose, &verbosefile] = [save_verbose, save_verbosefile]
  return res
endfunction

function! s:get_functions(sid)
  let prefix = '<SNR>' . a:sid . '_'
  let funcs = s:redir('function')
  let filter_pat = '^\s*function ' . prefix
  let map_pat = prefix . '\w\+'
  return map(filter(split(funcs, "\n"),
  \          '0 <= stridx(v:val, prefix) && v:val =~# filter_pat'),
  \          'matchstr(v:val, map_pat)')
endfunction

function! s:sid()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_\w\+$')
endfunction

function! s:make_helper()
  let functions = s:get_functions(s:sid())
  let assert_pat = '^<SNR>\d\+_assert_'
  call filter(functions, 'v:val =~# assert_pat')
  let helper = {}
  for func in functions
    let name = matchstr(func, '<SNR>\d\+_assert_\zs\w\+')
    let helper[name] = function(func)
  endfor
  return helper
endfunction

let s:helper = s:make_helper()

function! themis#helper#assert#new(runner)
  return deepcopy(s:helper)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
