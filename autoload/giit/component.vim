let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#autocmd(event) abort
  let name = matchstr(expand('<afile>'), 'giit:\%(//\)\?[^:]\+:\zs[^:/]\+\ze')
  let fname = printf(
        \ 'giit#component#%s#autocmd',
        \ substitute(name, '-', '_', 'g'),
        \)
  return s:Exception.call(function(fname), [a:event])
endfunction
