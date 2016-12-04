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

" Action
call giit#action#include([
      \ 'edit',
      \ 'show',
      \ 'diff',
      \ 'index',
      \ 'checkout',
      \])
call giit#action#smart_map('n', '<Return>', '<Plug>(giit-edit)')
call giit#action#smart_map('nv', '<<', '<Plug>(giit-index-stage)')
call giit#action#smart_map('nv', '>>', '<Plug>(giit-index-unstage)')
call giit#action#smart_map('nv', '--', '<Plug>(giit-index-toggle)')
call giit#action#smart_map('nv', '==', '<Plug>(giit-index-discard)')
