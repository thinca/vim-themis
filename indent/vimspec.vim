" Vimspec indent plugin
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('b:did_indent')
  finish
endif

runtime! indent/vim.vim

let b:did_indent = 1

let &l:indentexpr = 'GetVimspecIndent(' . string(&l:indentexpr) . ')'
setlocal indentkeys+==End

if exists('*GetVimspecIndent')
  finish
endif

function GetVimspecIndent(orig_indentexpr) abort
  try
    " Old Vim's indent plugin has a bug that uses =~
    let ignorecase_save = &ignorecase
    set noignorecase
    let indent = eval(a:orig_indentexpr)
  finally
    let &ignorecase = ignorecase_save
  endtry

  let base_lnum = prevnonblank(v:lnum - 1)
  let line = getline(base_lnum)
  if line =~# '^\s*\%([aA]fter\|[bB]efore\|[cC]ontext\|[dD]escribe\|[iI]t\)\>'
    let indent += s:shiftwidth()
  endif
  if getline(v:lnum) =~# '^\s*End\>'  " 'end' is already processed
    let indent -= s:shiftwidth()
  endif

  return indent
endfunction

if exists('*shiftwidth')
  function s:shiftwidth() abort
    return shiftwidth()
  endfunction
else
  function s:shiftwidth() abort
    return &l:shiftwidth == 0 ? &l:tabstop : &l:shiftwidth
  endfunction
endif
