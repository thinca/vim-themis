" themis: helper: Assert utilities.
" Version: 1.5.3
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:aliases = {
\   'equal': 'equals',
\   'not_equal': 'not_equals',
\   'is_func': 'is_function',
\   'is_not_func': 'is_not_function',
\   'is_dict': 'is_dictionary',
\   'is_not_dict': 'is_not_dictionary',
\ }

function! s:assert_fail(mes) abort
  throw themis#failure(a:mes)
endfunction

function! s:assert_todo(...) abort
  throw 'themis: report: todo:' . themis#message(a:0 ? a:1 : 'TODO')
endfunction

function! s:assert_skip(mes) abort
  throw 'themis: report: SKIP:' . themis#message(a:mes)
endfunction

function! s:assert_true(value, ...) abort
  if a:value isnot 1
    throw s:failure([
    \   'The true value was expected, but it was not the case.',
    \   '',
    \   '    expected: true',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_false(value, ...) abort
  if a:value isnot 0
    throw s:failure([
    \   'The false value was expected, but it was not the case.',
    \   '',
    \   '    expected: false',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_truthy(value, ...) abort
  let t = type(a:value)
  if !(t == type(0) || t == type('')) || !a:value
    throw s:failure([
    \   'The truthy value was expected, but it was not the case.',
    \   '',
    \   '    expected: truthy',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_falsy(value, ...) abort
  let t = type(a:value)
  if (t != type(0) && t != type('')) || a:value
    throw s:failure([
    \   'The falsy value was expected, but it was not the case.',
    \   '',
    \   '    expected: falsy',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_compare(left, expr, right, ...) abort
  let expr_str = join([string(a:left), a:expr, string(a:right)])
  try
    let result = eval(join(['a:left', a:expr, 'a:right']))
  catch /^Vim(let):E691:/
    let result = 0
  catch
    throw s:failure([
    \   'Unexpected error occurred while evaluating the comparing:',
    \   '',
    \   '    expression: ' . expr_str,
    \   '    error: ' . v:exception,
    \ ], a:000)
  endtry
  if !result
    throw s:failure([
    \   'The right expression was expected, but it was not the case.',
    \   '',
    \   '    expression: ' . expr_str,
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_equals(actual, expect, ...) abort
  if !s:equals(a:expect, a:actual)
    throw s:failure([
    \   'The equivalent values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_not_equals(actual, expect, ...) abort
  if s:equals(a:expect, a:actual)
    throw s:failure([
    \   'Not the equivalent values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_same(actual, expect, ...) abort
  if a:expect isnot# a:actual
    throw s:failure([
    \   'The same values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_not_same(actual, expect, ...) abort
  if a:expect is# a:actual
    throw s:failure([
    \   'Not the same values were expected, but it was not the case.',
    \   '',
    \   '    expected: ' . string(a:expect),
    \   '         got: ' . string(a:actual),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_match(actual, pattern, ...) abort
  if !s:match(a:actual, a:pattern)
    throw s:failure([
    \   'Match was expected, but did not match.',
    \   '',
    \   '    target: ' . string(a:actual),
    \   '    pattern: ' . string(a:pattern),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_not_match(actual, pattern, ...) abort
  if s:match(a:actual, a:pattern)
    throw s:failure([
    \   'Not match was expected, but matched.',
    \   '',
    \   '    target: ' . string(a:actual),
    \   '    pattern: ' . string(a:pattern),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_is_number(value, ...) abort
  return s:check_type(a:value, 'Number', 0, a:000)
endfunction

function! s:assert_is_not_number(value, ...) abort
  return s:check_type(a:value, 'Number', 1, a:000)
endfunction

function! s:assert_is_string(value, ...) abort
  return s:check_type(a:value, 'String', 0, a:000)
endfunction

function! s:assert_is_not_string(value, ...) abort
  return s:check_type(a:value, 'String', 1, a:000)
endfunction

function! s:assert_is_function(value, ...) abort
  return s:check_type(a:value, 'Funcref', 0, a:000)
endfunction

function! s:assert_is_not_function(value, ...) abort
  return s:check_type(a:value, 'Funcref', 1, a:000)
endfunction

function! s:assert_is_list(value, ...) abort
  return s:check_type(a:value, 'List', 0, a:000)
endfunction

function! s:assert_is_not_list(value, ...) abort
  return s:check_type(a:value, 'List', 1, a:000)
endfunction

function! s:assert_is_dictionary(value, ...) abort
  return s:check_type(a:value, 'Dictionary', 0, a:000)
endfunction

function! s:assert_is_not_dictionary(value, ...) abort
  return s:check_type(a:value, 'Dictionary', 1, a:000)
endfunction

function! s:assert_is_float(value, ...) abort
  return s:check_type(a:value, 'Float', 0, a:000)
endfunction

function! s:assert_is_not_float(value, ...) abort
  return s:check_type(a:value, 'Float', 1, a:000)
endfunction

function! s:assert_type_of(value, names, ...) abort
  return s:check_type(a:value, a:names, 0, a:000)
endfunction

function! s:assert_length_of(value, length, ...) abort
  call s:assert_type_of(a:value, ['String', 'List', 'Dictionary'])
  let got_length = len(a:value)
  if got_length != a:length
    throw s:failure([
    \   'The length of value was expected to the specified length, but it was not the case.',
    \   '',
    \   '    expected length: ' . a:length,
    \   '         got length: ' . got_length,
    \   '          got value: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_has_key(value, key, ...) abort
  let t = type(a:value)
  if t == type({})
    if !has_key(a:value, a:key)
      throw s:failure([
      \   'The dictionary was expected to have a key, but it did not have.',
      \   '',
      \   '      dictionary: ' . string(a:value),
      \   '    expected key: ' . string(a:key),
      \ ], a:000)
    endif
  elseif t == type([])
    if (a:key < 0 || len(a:value) <= a:key)
      throw s:failure([
      \   'The array was expected to have a index, but it did not have.',
      \   '',
      \   '             array: ' . string(a:value),
      \   '      array length: ' . len(a:value),
      \   '    expected index: ' . string(a:key),
      \ ], a:000)
    endif
  else
    throw s:failure([
    \   'The first argument was expected to an array or a dict, but it did not have.',
    \   '',
    \   '    value: ' . string(a:value),
    \   '     type: ' . s:type(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_key_exists(value, key, ...) abort
  call call('s:assert_is_dictionary', [a:value] + a:000)
  if !has_key(a:value, a:key)
    throw s:failure([
    \   'It was expected that a key exists in the dictionary, but it did not exist.',
    \   '',
    \   '      dictionary: ' . string(a:value),
    \   '    expected key: ' . string(a:key),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_key_not_exists(value, key, ...) abort
  call call('s:assert_is_dictionary', [a:value] + a:000)
  if has_key(a:value, a:key)
    throw s:failure([
    \   'It was expected that a key does not exist in the dictionary, but it did exist.',
    \   '',
    \   '      dictionary: ' . string(a:value),
    \   '    expected key: ' . string(a:key),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_exists(expr, ...) abort
  if !exists(a:expr)
    throw s:failure([
    \   'The target was expected to exist, but it did not exist.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_empty(expr, ...) abort
  if !empty(a:expr)
    throw s:failure([
    \   'The target was expected to be empty, but it wasn''t.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:assert_not_empty(expr, ...) abort
  if empty(a:expr)
    throw s:failure([
    \   'The target was expected not to be empty, but it was.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function! s:equals(a, b) abort
  if s:is_invalid_string_as_num(a:a, a:b) ||
  \  s:is_invalid_string_as_num(a:b, a:a)
    return 0
  endif
  return s:is_comparable(a:a, a:b) && a:a ==# a:b
endfunction

function! s:is_invalid_string_as_num(a, b) abort
  return type(a:a) == type('') &&
  \      type(a:b) == type(0) && a:a !~# '^-\?\d\+$'
endfunction

function! s:is_comparable(a, b) abort
  let tname1 = s:type(a:a)
  let tname2 = s:type(a:b)
  return s:_is_comparable(tname1, tname2) && s:_is_comparable(tname2, tname1)
endfunction

function! s:_is_comparable(tname1, tname2) abort
  if a:tname1 ==# 'list' || a:tname1 ==# 'dictionary' || a:tname1 ==# 'funcref'
    return a:tname1 ==# a:tname2
  endif
  return 1
endfunction

function! s:match(str, pattern) abort
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
function! s:type(value) abort
  return s:type_names[type(a:value)]
endfunction

function! s:check_type(value, expected_types, not, additional_message) abort
  let got_type = s:type(a:value)
  let expected_types = s:type(a:expected_types) ==# 'list' ?
  \                    copy(a:expected_types) : [a:expected_types]
  call map(expected_types, 'tolower(v:val)')
  call map(expected_types, 'v:val ==# "dict" ? "dictionary" : v:val')
  let success = 0 <= index(expected_types, got_type)

  let [expect, but] = ['', ' not']
  if a:not
    let success = !success
    let [expect, but] = [' not', '']
  endif

  if !success
    if 2 <= len(expected_types)
      let msg = 'The type of value was%s expected to be one of %s'
      let type_names =
      \     join(expected_types[: -2], ', ') . ' or ' . expected_types[-1]
    else
      let msg = 'The type of value was%s expected to be %s'
      let type_names = expected_types[0]
    endif
    throw s:failure([
    \   printf(msg . ', but it was%s the case.', expect, type_names, but),
    \   '',
    \   '    expected type: ' . type_names,
    \   '         got type: ' . got_type,
    \   '        got value: ' . string(a:value),
    \ ], a:additional_message)
  endif
  return 1
endfunction

function! s:failure(mes, additional) abort
  if empty(a:additional)
    return themis#failure(a:mes)
  endif
  return themis#failure(a:mes + [''] + a:additional)
endfunction

function! s:redir(cmd) abort
  let [save_verbose, save_verbosefile] = [&verbose, &verbosefile]
  set verbose=0 verbosefile=
  redir => res
    silent! execute a:cmd
  redir END
  let [&verbose, &verbosefile] = [save_verbose, save_verbosefile]
  return res
endfunction

function! s:get_functions(sid) abort
  let prefix = '<SNR>' . a:sid . '_'
  let funcs = s:redir('function')
  let filter_pat = '^\s*function ' . prefix
  let map_pat = prefix . '\w\+'
  return map(filter(split(funcs, "\n"),
  \          '0 <= stridx(v:val, prefix) && v:val =~# filter_pat'),
  \          'matchstr(v:val, map_pat)')
endfunction

function! s:sid() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_\w\+$')
endfunction

function! s:make_helper() abort
  let functions = s:get_functions(s:sid())
  let assert_pat = '^<SNR>\d\+_assert_'
  call filter(functions, 'v:val =~# assert_pat')
  let helper = {}
  for func in functions
    let name = matchstr(func, '<SNR>\d\+_assert_\zs\w\+')
    let helper[name] = function(func)
  endfor
  for [name, from] in items(s:aliases)
    let helper[name] = helper[from]
  endfor
  return helper
endfunction

let s:helper = s:make_helper()

function! themis#helper#assert#new(runner) abort
  return deepcopy(s:helper)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
