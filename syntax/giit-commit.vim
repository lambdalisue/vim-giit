if exists('b:current_syntax')
  finish
endif
runtime! syntax/gitcommit.vim

let b:current_syntax = 'giit-commit'
