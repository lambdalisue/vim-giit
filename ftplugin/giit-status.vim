if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal winfixheight

nnoremap <buffer><silent> <Plug>(giit-switch-commit) :<C-u>Giit commit<CR>
nmap <buffer><nowait> <C-^> <Plug>(giit-switch-commit)

