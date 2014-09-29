" Syntax file for vimspec
" Version: 1.2
" Author : thinca <thinca+vim@gmail.com>
" License: zlib License

if exists('b:current_syntax')
  finish
endif

let s:cpo_save = &cpo
set cpo&vim

runtime! syntax/vim.vim

syntax keyword vimVimspecCommand describe Describe skipwhite nextgroup=vimString
syntax keyword vimVimspecCommand context Context skipwhite nextgroup=vimString
syntax keyword vimVimspecCommand before Before
syntax keyword vimVimspecCommand after After
syntax keyword vimVimspecCommand end End
syntax keyword vimVimspecCommand it It skipwhite nextgroup=vimString


highlight default link vimVimspecCommand  vimCommand


let b:current_syntax = 'vimspec'

let &cpo = s:cpo_save
unlet s:cpo_save
