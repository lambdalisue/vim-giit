let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#autocmd(event) abort
  let name = matchstr(expand('<afile>'), 'giit:\%(//\)\?[^:]\+:\zs[^:/]\+\ze')
  let fname = giit#util#fname('component', name, 'autocmd')
  return s:Exception.call(function(fname), [a:event])
endfunction

function! giit#component#bufname(git, scheme, ...) abort
  let nofile = get(a:000, 0, 0)
  let refname = fnamemodify(a:git.worktree, ':t')
  let pattern = nofile ? 'giit:%s:%s' : 'giit://%s:%s'
  return printf(pattern, refname, a:scheme)
endfunction
