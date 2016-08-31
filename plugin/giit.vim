if exists('g:loaded_giit')
  finish
endif
let g:loaded_giit = 1

if !has('patch-7.4.2137')
  echohl ErrorMsg
  echomsg 'giit: giit requires Vim 7.4.2137 or later'
  echohl None
  finish
endif

let s:is_windows = has('win16') || has('win32') || has('win64')

command! -nargs=* -bang -range
      \ -complete=customlist,giit#operation#complete
      \ Giit
      \ call giit#operation#command(<q-args>, <q-bang>, [<line1>, <line2>])


augroup giit-internal
  autocmd! *
  autocmd BufReadCmd giit:* nested call giit#component#autocmd('BufReadCmd')
  if !s:is_windows
    " NOTE: autocmd for 'xxxxx:*' is trittered for 'xxxxx://' in Windows
    autocmd BufReadCmd giit:*/* nested call giit#component#autocmd('BufReadCmd')
  endif
augroup END
