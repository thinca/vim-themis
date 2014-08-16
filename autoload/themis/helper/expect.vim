let s:save_cpo = &cpo
set cpo&vim

let s:expect = {
\   '_negate' : 0,
\   'not' : {
\     '_negate' : 1
\   }
\ }

function! themis#helper#expect#_create_expect(actual)
  let expect = deepcopy(s:expect)
  let expect._actual = a:actual
  let expect.not._actual = a:actual
  return expect
endfunction

function! s:matcher_impl(name, f, ...) dict
  let result = call(a:f, [self._actual] + a:000)
  if self._negate
    let result = !result
  endif
  if result
    return {'and' : self}
  else
    throw printf('themis: report: failure: Expected %s %s%s%s.',
    \       string(self._actual),
    \       (self._negate ? 'not ' : ''),
    \       substitute(a:name, '_', ' ', 'g'),
    \       (a:0 > 0) ? (' ' . string(join(a:000, ', '))) : '')
  endif
endfunction

let s:fid = 0
function! s:expr_to_func(pred, ...)
  let s:fid += 1
  execute join([
  \ 'function! s:' . s:fid . '(...)',
  \ '  return ' . a:pred,
  \ 'endfunction'], "\n")
  return function('s:' . s:fid)
endfunction

let s:matchers = {}
function! themis#helper#expect#define_matcher(name, predicate)
  if type(a:predicate) ==# type('')
    let s:matchers[a:name] = s:expr_to_func(a:predicate)
  elseif type(a:predicate) ==# type(function('function'))
    let s:matchers[a:name] = a:predicate
  endif
  execute join([
  \ 'function! s:expect.' . a:name . '(...)',
  \ '  return call("s:matcher_impl", ['. string(a:name) . ', s:matchers.' . a:name . '] + a:000, self)',
  \ 'endfunction'], "\n")
  let s:expect.not[a:name] = s:expect[a:name]
endfunction

call themis#helper#expect#define_matcher('to_be_true', 'a:1 is 1')
call themis#helper#expect#define_matcher('to_be_false', 'a:1 is 0')
call themis#helper#expect#define_matcher('to_be_truthy', '(type(a:1) == type(0) || type(a:1) == type("")) && a:1')
call themis#helper#expect#define_matcher('to_be_falsy', '(type(a:1) != type(0) || type(a:1) != type("")) && !a:1')
call themis#helper#expect#define_matcher('to_be_greater_than', 'a:1 ># a:2')
call themis#helper#expect#define_matcher('to_be_less_than', 'a:1 <# a:2')
call themis#helper#expect#define_matcher('to_be_greater_than_or_equal', 'a:1 >=# a:2')
call themis#helper#expect#define_matcher('to_be_less_than_or_equal', 'a:1 <=# a:2')
call themis#helper#expect#define_matcher('to_equal', 'a:1 ==# a:2')
call themis#helper#expect#define_matcher('to_be_same', 'a:1 is a:2')
call themis#helper#expect#define_matcher('to_match', 'type(a:1) == type("") && type(a:2) == type("") && a:1 =~# a:2')
call themis#helper#expect#define_matcher('to_have_length', '(type(a:1) ==# type("") || type(a:1) == type([]) || type(a:1) == type({})) && len(a:1) == a:2')
call themis#helper#expect#define_matcher('to_exist', function('exists'))
call themis#helper#expect#define_matcher('to_have_key', 'type(a:1) ==# type([]) ? 0 <= a:2 && a:2 < len(a:1) : has_key(a:1, a:2)')

call themis#helper#expect#define_matcher('to_be_number', 'type(a:1) ==# type(0)')
call themis#helper#expect#define_matcher('to_be_string', 'type(a:1) ==# type("")')
call themis#helper#expect#define_matcher('to_be_func', 'type(a:1) ==# type(function("function"))')
call themis#helper#expect#define_matcher('to_be_list', 'type(a:1) ==# type([])')
call themis#helper#expect#define_matcher('to_be_dict', 'type(a:1) ==# type({})')
call themis#helper#expect#define_matcher('to_be_float', 'type(a:1) ==# type(0.0)')

function! themis#helper#expect#new(_)
  return function('themis#helper#expect#_create_expect')
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
