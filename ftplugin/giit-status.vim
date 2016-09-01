if exists('b:did_ftplugin')
  finish
endif
let b:did_ftplugin = 1

setlocal winfixheight
setlocal nolist nospell
setlocal nowrap nofoldenable
setlocal nonumber norelativenumber
setlocal foldcolumn=0 colorcolumn=0

nnoremap <buffer><silent> <Plug>(giit-switch-commit) :<C-u>Giit commit<CR>
nmap <buffer><nowait> <C-^> <Plug>(giit-switch-commit)
