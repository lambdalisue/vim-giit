let s:Selection = vital#giit#import('Vim.Buffer.Selection')


function! giit#selection#parse(expr) abort
  return s:Selection.parse(a:expr)
endfunction

function! giit#selection#get_current_selection() abort
  if exists('b:giit_get_current_selection')
    return b:giit_get_current_selection()
  endif
  return s:Selection.get_current_selection()
endfunction

function! giit#selection#set_current_selection(selection) abort
  if exists('b:giit_set_current_selection')
    return b:giit_set_current_selection(a:selection)
  endif
  return s:Selection.set_current_selection(a:selection)
endfunction
