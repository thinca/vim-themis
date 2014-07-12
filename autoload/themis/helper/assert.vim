" themis: helper: Assert utilities.
" Version: 1.0
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:helper = {}

function! s:helper.skip(mes)
  throw 'themis: report: SKIP:' . s:message(a:mes)
endfunction

function! s:helper.todo(mes)
  throw 'themis: report: todo:' . s:message(a:mes)
endfunction

function! s:helper.fail(...)
  throw s:failure(a:0 ? a:1 : '')
endfunction

function! s:helper.true(value)
  if a:value isnot 1
    throw s:failure([
    \   'The true value was expected, but it was not the case.',
    \   'expected: true',
    \   '     got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:helper.false(value)
  if a:value isnot 0
    throw s:failure([
    \   'The false value was expected, but it was not the case.',
    \   'expected: false',
    \   '     got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:helper.truthy(value)
  let t = type(a:value)
  if !(t == type(0) || t == type('')) || !a:value
    throw s:failure([
    \   'The truthy value was expected, but it was not the case.',
    \   'expected: truthy',
    \   '     got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:helper.falsy(value)
  let t = type(a:value)
  if !(t != type(0) || t != type('') || !a:value)
    throw s:failure([
    \   'The falsy value was expected, but it was not the case.',
    \   'expected: falsy',
    \   '     got: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! s:helper.compare(left, expr, right)
  let expr_str = join([string(a:left), a:expr, string(a:right)])
  try
    let result = eval(join(['a:left', a:expr, 'a:right']))
  catch /^Vim(let):E691:/
    let result = 0
  catch
    throw s:failure([
    \   'comparison failed: ' . expr_str,
    \   v:exception,
    \ ])
  endtry
  if !result
    throw s:failure([
    \   'not matched: ' . expr_str,
    \ ])
  endif
  return 1
endfunction

function! s:helper.equals(actual, expect)
  if !s:equals(a:expect, a:actual)
    throw s:failure([
    \   'The equivalent values were expected, but it was not the case.',
    \   'expected: ' . string(a:expect),
    \   '     got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:helper.not_equals(actual, expect)
  if s:equals(a:expect, a:actual)
    throw s:failure([
    \   'Not the equivalent values were expected, but it was not the case.',
    \   'expected: ' . string(a:expect),
    \   '     got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:helper.same(actual, expect)
  if a:expect isnot# a:actual
    throw s:failure([
    \   'The same values were expected, but it was not the case.',
    \   'expected: ' . string(a:expect),
    \   '     got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:helper.not_same(actual, expect)
  if a:expect is# a:actual
    throw s:failure([
    \   'Not the same values were expected, but it was not the case.',
    \   'expected: ' . string(a:expect),
    \   '     got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

function! s:helper.match(actual, pattern)
  if !s:match(a:actual, a:pattern)
    throw s:failure([
    \   "Match was expected, but didn't match: ",
    \   'target: ' . string(a:actual),
    \   'pattern: ' . string(a:pattern),
    \ ])
  endif
  return 1
endfunction

function! s:helper.not_match(actual, pattern)
  if s:match(a:actual, a:pattern)
    throw s:failure([
    \   "Not match was expected, but matched: ",
    \   'target: ' . string(a:actual),
    \   'pattern: ' . string(a:pattern),
    \ ])
  endif
  return 1
endfunction

function! s:helper.is_number(value)
  return s:check_type(a:value, 'Number', 0)
endfunction

function! s:helper.is_not_number(value)
  return s:check_type(a:value, 'Number', 1)
endfunction

function! s:helper.is_string(value)
  return s:check_type(a:value, 'String', 0)
endfunction

function! s:helper.is_not_string(value)
  return s:check_type(a:value, 'String', 1)
endfunction

function! s:helper.is_func(value)
  return s:check_type(a:value, 'Funcref', 0)
endfunction

function! s:helper.is_not_func(value)
  return s:check_type(a:value, 'Funcref', 1)
endfunction

function! s:helper.is_list(value)
  return s:check_type(a:value, 'List', 0)
endfunction

function! s:helper.is_not_list(value)
  return s:check_type(a:value, 'List', 1)
endfunction

function! s:helper.is_dict(value)
  return s:check_type(a:value, 'Dictionary', 0)
endfunction

function! s:helper.is_not_dict(value)
  return s:check_type(a:value, 'Dictionary', 1)
endfunction

function! s:helper.is_float(value)
  return s:check_type(a:value, 'Float', 0)
endfunction

function! s:helper.is_not_float(value)
  return s:check_type(a:value, 'Float', 1)
endfunction

function! s:helper.exists(expr)
  if !exists(a:expr)
    throw s:failure([
    \   printf('expected: exists(%s)', string(a:expect)),
    \          '     got: ' . string(a:actual),
    \ ])
  endif
  return 1
endfunction

" TODO: validate()
function! s:helper.validate(expr, rule)
  let result = s:validate(a:expr, a:rule)
  if !empty(result)
    throw s:failure([
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


function! s:message(m)
  let t = type(a:m)
  return t == type([]) ? join(a:m, "\n") :
  \      t == type('') ? a:m : string(a:m)
endfunction

function! s:failure(m)
  return 'themis: report: failure:' . s:message(a:m)
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
\   type(0): 'Number',
\   type(''): 'String',
\   type(function('type')): 'Funcref',
\   type([]): 'List',
\   type({}): 'Dictionary',
\   type(0.0): 'Float',
\ }
function! s:type(value)
  return s:type_names[type(a:value)]
endfunction

function! s:check_type(value, expect_type, not)
  let got_type = s:type(a:value)
  let success = got_type == a:expect_type
  if a:not
    let success = !success
  endif
  if !success
    throw s:failure([
    \   'expect type: ' . a:expect_type,
    \   '   got type: ' . got_type,
    \   '  got value: ' . string(a:value),
    \ ])
  endif
  return 1
endfunction

function! themis#helper#assert#new(runner)
  return deepcopy(s:helper)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
