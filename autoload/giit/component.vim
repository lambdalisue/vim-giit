let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#autocmd(event, ...) abort
  let base = get(a:000, 0, 0)
  if base
    let fname = 's:on_' . a:event
    return s:Exception.call(function(fname), [])
  else
    let name = matchstr(expand('<afile>'), 'giit://[^:]\+:\zs[^:/]\+\ze')
    let fname = printf(
          \ 'giit#component#%s#autocmd',
          \ substitute(name, '-', '_', 'g'),
          \)
    return s:Exception.call(function(fname), [a:event])
  endif
endfunction


function! s:on_BufNew() abort
  call giit#core#get('')
endfunction

function! s:on_BufAdd() abort
  call giit#core#get(expand('%'))
endfunction
