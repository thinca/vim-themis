" themis: Test bundle.
" Version: 1.5.2dev
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

let s:save_cpo = &cpo
set cpo&vim

let s:bundle = {
\   'suite': {},
\   'suite_descriptions': {},
\   'children': [],
\ }

function! s:bundle.get_title() abort
  if self.title !=# ''
    return self.title
  endif
  let filename = get(self, 'filename', '')
  if filename !=# ''
    return fnamemodify(filename, ':t')
  endif
  return ''
endfunction

function! s:bundle.get_test_full_title(name) abort
  return themis#util#get_full_title(self, [self.get_test_title(a:name)])
endfunction

function! s:bundle.get_test_title(name) abort
  let description = self.get_description(a:name)
  return description !=# '' ? description : a:name
endfunction

function! s:bundle.get_description(name) abort
  return get(self.suite_descriptions, a:name, '')
endfunction

function! s:bundle.get_style() abort
  if has_key(self, 'style')
    return self.style
  endif
  if has_key(self, 'parent')
    return self.parent.get_style()
  endif
  return {}
endfunction

function! s:bundle.add_child(bundle) abort
  if has_key(a:bundle, 'parent')
    call a:bundle.parent.remove_child(a:bundle)
  endif
  let self.children += [a:bundle]
  let a:bundle.parent = self
endfunction

function! s:bundle.get_child(title) abort
  for child in self.children
    if child.title ==# a:title
      return child
    endif
  endfor
  return {}
endfunction

function! s:bundle.remove_child(child) abort
  call filter(self.children, 'v:val isnot a:child')
endfunction

function! s:bundle.get_test_entries() abort
  if !has_key(self, 'test_entries')
    let self.test_entries = self.all_test_entries()
  endif
  return self.test_entries
endfunction

function! s:bundle.select_tests_recursive(pattern) abort
  call filter(self.children, 'v:val.select_tests_recursive(a:pattern)')
  call self.select_tests(a:pattern)
  return !self.is_empty()
endfunction

function! s:bundle.select_tests(pattern) abort
  let test_entries = self.all_test_entries()
  call filter(test_entries, 'self.get_test_full_title(v:val) =~# a:pattern')
  let self.test_entries = test_entries
endfunction

function! s:bundle.all_test_entries() abort
  let style = self.get_style()
  if empty(style)
    return []
  endif
  return style.get_test_names(self)
endfunction

function! s:bundle.is_empty() abort
  return empty(self.test_entries) && empty(self.children)
endfunction

function! s:bundle.run_test(name) abort
  call self.suite[a:name]()
endfunction

function! themis#bundle#new(...) abort
  let bundle = deepcopy(s:bundle)
  let bundle.title = 1 <= a:0 ? a:1 : ''
  if 2 <= a:0 && has_key(a:2, 'add_child')
    call a:2.add_child(bundle)
  endif
  return bundle
endfunction

function! themis#bundle#is_bundle(obj) abort
  return type(a:obj) == type({}) &&
  \   get(a:obj, 'run_test') is s:bundle.run_test
endfunction

call themis#func_alias({'themis/Bundle': s:bundle})


let &cpo = s:save_cpo
unlet s:save_cpo
