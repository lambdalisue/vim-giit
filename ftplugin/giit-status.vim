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

let s:Action = vital#giit#import('Action')
let action = s:Action.get()
call action.smart_map('n', '<Return>', '<Plug>(giit-edit)')
call action.smart_map('n', 'ee', '<Plug>(giit-edit)')
call action.smart_map('n', 'EE', '<Plug>(giit-edit-right)')
call action.smart_map('n', 'dd', '<Plug>(giit-diff)', '0D')
call action.smart_map('n', 'ds', '<Plug>(giit-diff-split)')
call action.smart_map('nv', '<<', '<Plug>(giit-index-stage)')
call action.smart_map('nv', '>>', '<Plug>(giit-index-unstage)')
call action.smart_map('nv', '--', '<Plug>(giit-index-toggle)')
call action.smart_map('nv', '==', '<Plug>(giit-index-discard)')

call neocomplete#custom#source('_', 'disabled_filetypes', {'giit-status': 1})
