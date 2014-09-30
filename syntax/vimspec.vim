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

syntax keyword vimspecCommand describe Describe skipwhite nextgroup=vimString
syntax keyword vimspecCommand context Context skipwhite nextgroup=vimString
syntax keyword vimspecCommand before Before
syntax keyword vimspecCommand after After
syntax keyword vimspecCommand end End
syntax keyword vimspecCommand it It skipwhite nextgroup=vimString


highlight default link vimspecCommand  vimCommand


let b:current_syntax = 'vimspec'

let &cpo = s:cpo_save
unlet s:cpo_save
