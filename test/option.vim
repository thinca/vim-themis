let s:option = themis#suite('option')

function! s:option.default()
  let def1 = themis#option#default()
  let def2 = themis#option#default()
  Assert NotSame(def1, def2)
endfunction

function! s:option.empty_options()
  let options = themis#option#empty_options()
  for v in values(options)
    Assert IsList(v)
    Assert LengthOf(v, 0, string(v))
  endfor
endfunction

function! s:option.merge()
  let base = {
  \   'foo': 10,
  \   'bar': ['value1'],
  \ }
  let overwriter = {
  \   'buz': 20,
  \   'bar': ['value2'],
  \ }
  let expect = {
  \   'foo': 10,
  \   'buz': 20,
  \   'bar': ['value1', 'value2'],
  \ }
  let actual = themis#option#merge(base, overwriter)
  Assert Equals(actual, expect)
  Assert NotEquals(actual, base)
endfunction
