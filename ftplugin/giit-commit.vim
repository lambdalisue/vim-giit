if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal nobuflisted
setlocal winfixheight
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

nnoremap <buffer><silent>       <Plug>(giit-switch-status)
      \ :<C-u>Giit status<CR>

nnoremap <buffer><silent><expr> <Plug>(giit-toggle-amend)
      \ bufname('%') =~# '\<amend\>'
      \   ? ':<C-u>Giit commit<CR>'
      \   : ':<C-u>Giit commit --amend<CR>'

nmap <buffer><nowait> <C-^> <Plug>(giit-switch-status)
nmap <buffer><nowait> <C-s> <Plug>(giit-toggle-amend)
