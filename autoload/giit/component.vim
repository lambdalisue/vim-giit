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

function! giit#component#split_object(object) abort
  let m = matchlist(a:object, '^\(:\?[^:]*\):\(.\+\)$')
  if empty(m)
    return [a:object, '']
  endif
  return m[1:2]
endfunction

function! giit#component#build_object(commit, filename) abort
  return empty(a:filename)
        \ ? a:commit
        \ : a:commit . ':' . a:filename
endfunction
