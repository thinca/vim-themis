" themis: helper: Assert utilities.
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:T = g:themis#vital.import('Vim.Type')
let s:type_names = copy(s:T.type_names)
" Tweak type names
let s:type_names[s:T.types.func] = 'funcref'
let s:type_names[s:T.types.dict] = 'dictionary'

let s:type_aliases = {
\   'dict': 'dictionary',
\   'func': 'funcref',
\   'function': 'funcref',
\ }

let s:func_aliases = {
\   'equal': 'equals',
\   'not_equal': 'not_equals',
\ }

" Note: v:true and v:false were added at Vim 7.4.1154
let s:true = get(v:, 'true', 1)
let s:false = get(v:, 'false', 0)

for s:aliased_type in keys(s:type_aliases)
  let s:func_aliases['is_' . s:aliased_type] =
  \   'is_' . s:type_aliases[s:aliased_type]
  let s:func_aliases['is_not_' . s:aliased_type] =
  \   'is_not_' . s:type_aliases[s:aliased_type]
endfor

function s:assert_fail(mes) abort
  throw themis#failure(a:mes)
endfunction

function s:assert_todo(...) abort
  throw 'themis: report: todo:' . themis#message(a:0 ? a:1 : 'TODO')
endfunction

function s:assert_skip(mes) abort
  throw 'themis: report: SKIP:' . themis#message(a:mes)
endfunction

function s:assert_true(value, ...) abort
  if a:value isnot 1 && a:value isnot s:true
    throw s:failure([
    \   'The true value was expected, but it was not the case.',
    \   '',
    \   '    expected: true',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_false(value, ...) abort
  if a:value isnot 0 && a:value isnot s:false
    throw s:failure([
    \   'The false value was expected, but it was not the case.',
    \   '',
    \   '    expected: false',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_truthy(value, ...) abort
  let t = type(a:value)
  if !(t == type(0) || t == type('') || t == type(s:true)) || !a:value
    throw s:failure([
    \   'The truthy value was expected, but it was not the case.',
    \   '',
    \   '    expected: truthy',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_falsy(value, ...) abort
  let t = type(a:value)
  if (t != type(0) && t != type('') && t != type(s:false)) || a:value
    throw s:failure([
    \   'The falsy value was expected, but it was not the case.',
    \   '',
    \   '    expected: falsy',
    \   '         got: ' . string(a:value),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_compare(left, expr, right, ...) abort
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

function s:assert_equals(actual, expect, ...) abort
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

function s:assert_not_equals(actual, expect, ...) abort
  if s:equals(a:expect, a:actual)
    throw s:failure([
    \   'Not the equivalent values were expected, but it was not the case.',
    \   '',
    \   '    not expected: ' . string(a:expect),
    \   '             got: ' . string(a:actual),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_same(actual, expect, ...) abort
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

function s:assert_not_same(actual, expect, ...) abort
  if a:expect is# a:actual
    throw s:failure([
    \   'Not the same values were expected, but it was not the case.',
    \   '',
    \   '    not expected: ' . string(a:expect),
    \   '             got: ' . string(a:actual),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_match(actual, pattern, ...) abort
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

function s:assert_not_match(actual, pattern, ...) abort
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

for [s:type_value, s:type_name] in items(s:type_names)
  execute printf(join([
  \   'function s:assert_is_%s(value, ...) abort',
  \   '  return s:check_type(a:value, %s, 0, a:000)',
  \   'endfunction',
  \ ], "\n"), s:type_name, string(s:type_name))
  execute printf(join([
  \   'function s:assert_is_not_%s(value, ...) abort',
  \   '  return s:check_type(a:value, %s, 1, a:000)',
  \   'endfunction',
  \ ], "\n"), s:type_name, string(s:type_name))
endfor

function s:assert_type_of(value, names, ...) abort
  return s:check_type(a:value, a:names, 0, a:000)
endfunction

function s:assert_length_of(value, length, ...) abort
  call s:assert_type_of(a:value, ['String', 'List', 'Dictionary', 'Blob'])
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

function s:assert_includes(value, target, ...) abort
  if !s:includes(a:value, a:target, a:000)
    throw s:failure([
    \   'The value was expected to include the target, but it was not the case.',
    \   '',
    \   '                  value: ' . string(a:value),
    \   '    expected to include: ' . string(a:target),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_not_includes(value, target, ...) abort
  if s:includes(a:value, a:target, a:000)
    throw s:failure([
    \   'The value was expected to not include the target, but it was not the case.',
    \   '',
    \   '                  value: ' . string(a:value),
    \   '    expected to include: ' . string(a:target),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_has_key(value, key, ...) abort
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

function s:assert_key_exists(value, key, ...) abort
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

function s:assert_key_not_exists(value, key, ...) abort
  call call('s:assert_is_dictionary', [a:value] + a:000)
  if has_key(a:value, a:key)
    throw s:failure([
    \   'It was expected that a key does not exist in the dictionary, but it did exist.',
    \   '',
    \   '          dictionary: ' . string(a:value),
    \   '    not expected key: ' . string(a:key),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_exists(expr, ...) abort
  if !exists(a:expr)
    throw s:failure([
    \   'The target was expected to exist, but it did not exist.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_not_exists(expr, ...) abort
  if exists(a:expr)
    throw s:failure([
    \   'The target was expected to not exist, but it did exist.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_cmd_exists(expr, ...) abort
  let cmd = a:expr[0] ==# ':' ? a:expr : ':' . a:expr
  if exists(cmd) != 2
    throw s:failure([
    \   'The Ex command was expected to exist, but it did not exist.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_cmd_not_exists(expr, ...) abort
  let cmd = a:expr[0] ==# ':' ? a:expr : ':' . a:expr
  if exists(cmd) == 2
    throw s:failure([
    \   'The Ex command was expected to not exist, but it did exist.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_empty(expr, ...) abort
  if !empty(a:expr)
    throw s:failure([
    \   'The target was expected to be empty, but it wasn''t.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function s:assert_not_empty(expr, ...) abort
  if empty(a:expr)
    throw s:failure([
    \   'The target was expected not to be empty, but it was.',
    \   '',
    \   '    target: ' . string(a:expr),
    \ ], a:000)
  endif
  return 1
endfunction

function s:equals(a, b) abort
  if s:is_invalid_string_as_num(a:a, a:b) ||
  \  s:is_invalid_string_as_num(a:b, a:a)
    return 0
  endif
  return s:T.is_comparable(a:a, a:b) && a:a ==# a:b
endfunction

function s:is_invalid_string_as_num(a, b) abort
  return type(a:a) == type('') &&
  \      type(a:b) == type(0) && a:a !~# '^-\?\d\+$'
endfunction

function s:match(str, pattern) abort
  return type(a:str) == type('') &&
  \      type(a:pattern) == type('') &&
  \      a:str =~# a:pattern
endfunction

function s:type(value) abort
  return s:type_names[type(a:value)]
endfunction

function s:check_type(value, expected_types, not, additional_message) abort
  let got_type = s:type(a:value)
  let expected_types = s:type(a:expected_types) ==# 'list' ?
  \                    copy(a:expected_types) : [a:expected_types]
  call map(expected_types, 'tolower(v:val)')
  call map(expected_types, 'get(s:type_aliases, v:val, v:val)')
  let success = 0 <= index(expected_types, got_type)

  let [expect, but] = ['', ' not']
  if a:not
    let success = !success
    let [expect, but] = [' not', '']
  endif
  let pad = repeat(' ', len(expect))

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
    \   printf('    %s expected type:%s %s', pad, expect, type_names),
    \   printf('    %s      got type: %s', pad, got_type),
    \   printf('    %s     got value: %s', pad, string(a:value)),
    \ ], a:additional_message)
  endif
  return 1
endfunction

function s:includes(value, target, additional_message) abort
  let t_v = type(a:value)
  let t_t = type(a:target)
  if t_v == type('') && t_t == type('')
    return 0 <= stridx(a:value, a:target)
  endif
  if t_v == type([])
    for V in a:value
      if V is# a:target
        return 1
      endif
    endfor
    return 0
  endif
  if t_v == type({})
    if t_t == type([])
      for Key in a:target
        if !has_key(a:value, Key)
          return 0
        endif
      endfor
      return 1
    endif
    if t_t == type({})
      let not_exist = []
      for [k, V] in items(a:target)
        if get(a:value, k, not_exist) isnot# V
          return 0
        endif
      endfor
      return 1
    endif
  endif
  if t_v == get(v:, 't_blob', -1)
    if t_t == type(0)
      return 0 <= index(a:value, a:target)
    endif
    if t_t == v:t_blob
      if empty(a:target)
        return 1
      endif
      let endpos = len(a:value) - len(a:target)
      let startpos = 0
      while startpos <= endpos
        let pos = index(a:value, a:target[0], startpos)
        if pos < 0
          return 0
        endif
        let i = 0
        for n in a:target
          if a:value[pos + i] != n
            let i = -1
            break
          endif
          let i += 1
        endfor
        if 0 <= i
          return 1
        endif
        let startpos = pos + 1
      endwhile
      return 0
    endif
  endif
  throw s:failure([
  \   'Unsupported value was passed to includes matcher.',
  \   '',
  \   printf('     value: %s', string(a:value)),
  \   printf('    target: %s', string(a:target)),
  \ ], a:additional_message)
endfunction

function s:failure(mes, additional) abort
  if empty(a:additional)
    return themis#failure(a:mes)
  endif
  return themis#failure(a:mes + [''] + a:additional)
endfunction

function s:redir(cmd) abort
  let [save_verbose, save_verbosefile] = [&verbose, &verbosefile]
  set verbose=0 verbosefile=
  redir => res
    silent! execute a:cmd
  redir END
  let [&verbose, &verbosefile] = [save_verbose, save_verbosefile]
  return res
endfunction

function s:get_functions(sid) abort
  let prefix = '<SNR>' . a:sid . '_'
  let funcs = s:redir('function')
  let filter_pat = '^\s*function ' . prefix
  let map_pat = prefix . '\w\+'
  return map(filter(split(funcs, "\n"),
  \          '0 <= stridx(v:val, prefix) && v:val =~# filter_pat'),
  \          'matchstr(v:val, map_pat)')
endfunction

function s:sid() abort
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_\w\+$')
endfunction

function s:make_helper() abort
  let functions = s:get_functions(s:sid())
  let assert_pat = '^<SNR>\d\+_assert_'
  call filter(functions, 'v:val =~# assert_pat')
  let helper = {}
  for func in functions
    let name = matchstr(func, '<SNR>\d\+_assert_\zs\w\+')
    let helper[name] = function(func)
  endfor
  for [name, from] in items(s:func_aliases)
    let helper[name] = helper[from]
  endfor
  return helper
endfunction

let s:helper = s:make_helper()

function themis#helper#assert#new(runner) abort
  return deepcopy(s:helper)
endfunction
