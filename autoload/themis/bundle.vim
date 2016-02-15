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

call themis#func_alias({'themis/Bundle': s:bundle})


let &cpo = s:save_cpo
unlet s:save_cpo
