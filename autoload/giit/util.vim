let s:List = vital#giit#import('Data.List')


function! giit#util#doautocmd(name, ...) abort
  let pattern = get(a:000, 0, '')
  let expr = empty(pattern)
        \ ? '#' . a:name
        \ : '#' . a:name . '#' . pattern
  let eis = split(&eventignore, ',')
  if index(eis, a:name) >= 0 || index(eis, 'all') >= 0 || !exists(expr)
    " the specified event is ignored or not exists
    return
  endif
  let is_pseudo_required = empty(pattern) && !exists('#' . a:name . '#*')
  if is_pseudo_required
    " NOTE:
    " autocmd XXXXX <pattern> exists but not sure if current buffer name
    " match with the <pattern> so register empty autocmd to prevent
    " 'No matching autocommands' warning
    augroup giit_internal_util_doautocmd
      autocmd! *
      execute 'autocmd ' . a:name . ' * :'
    augroup END
  endif
  let nomodeline = has('patch-7.4.438') && a:name ==# 'User'
        \ ? '<nomodeline> '
        \ : ''
  try
    execute 'doautocmd ' . nomodeline . a:name . ' ' . pattern
  finally
    if is_pseudo_required
      augroup giit_internal_util_doautocmd
        autocmd! *
      augroup END
    endif
  endtry
endfunction

function! giit#util#syncbind() abort
  " NOTE:
  " Somehow syncbind does not just after opening a buffer so use
  " CursorHold and CursorMoved to call a bit later again
  augroup giit_internal_util_syncbind
    autocmd!
    autocmd CursorHold   * call s:syncbind()
    autocmd CursorHoldI  * call s:syncbind()
    autocmd CursorMoved  * call s:syncbind()
    autocmd CursorMovedI * call s:syncbind()
  augroup END
  syncbind
endfunction

function! s:syncbind() abort
  augroup giit_internal_util_syncbind
    autocmd! *
  augroup END
  syncbind
endfunction

function! giit#util#collapse(list) abort
  return filter(s:List.flatten(a:list), '!empty(v:val)')
endfunction
