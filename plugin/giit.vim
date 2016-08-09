if exists('g:loaded_giit')
  finish
endif
let g:loaded_giit = 1

"if !has('patch-7.4.2137')
"  echohl ErrorMsg
"  echomsg 'giit: giit requires Vim 7.4.2137 or later'
"  echohl None
"  finish
"endif

command! -nargs=* -range -bang
      \ -complete=customlist,giit#operation#complete
      \ Giit
      \ call giit#operation#command(<q-bang>, [<line1>, <line2>], <q-args>)
