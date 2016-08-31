let s:Path = vital#giit#import('System.Filepath')
let s:GitTerm = vital#giit#import('Git.Term')


" NOTE:
" git requires an unix relative path from the repository often
function! giit#util#normalize#relpath(git, path) abort
  if empty(a:path)
    return ''
  endif
  let path = giit#expand(a:path)
  let relpath = s:Path.is_absolute(path)
        \ ? a:git.relpath(path)
        \ : path
  return s:Path.unixpath(relpath)
endfunction

" NOTE:
" system requires a real absolute path often
function! giit#util#normalize#abspath(git, path) abort
  let path = giit#expand(a:path)
  return s:Path.realpath(a:git.abspath(path))
endfunction

" NOTE:
" most of git command does not understand A...B type assignment so translate
" it to an exact revision
function! giit#util#normalize#commit(git, commit) abort
  if a:commit =~# '^.\{-}\.\.\..\{-}$'
    " git diff <lhs>...<rhs> : <lhs>...<rhs> vs <rhs>
    let [lhs, rhs] = s:GitTerm.split_range(a:commit, {})
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    return a:git.util.find_common_ancestor(lhs, rhs)
  elseif a:commit =~# '^.\{-}\.\..\{-}$'
    return s:GitTerm.split_range(a:commit, {})[0]
  else
    return a:commit
  endif
endfunction

" NOTE:
" git diff command does not understand A...B type assignment so translate
" it to an exact revision
function! giit#util#normalize#commit_for_diff(git, commit) abort
  if a:commit =~# '^.\{-}\.\.\..\{-}$'
    " git diff <lhs>...<rhs> : <lhs>...<rhs> vs <rhs>
    let [lhs, rhs] = s:GitTerm.split_range(a:commit, {})
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let lhs = a:git.util.find_common_ancestor(lhs, rhs)
    return lhs . '..' . rhs
  else
    return a:commit
  endif
endfunction
