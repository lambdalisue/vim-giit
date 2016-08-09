let s:Path = vital#giit#import('System.Filepath')
let s:Git = vital#giit#import('Git')
let s:GitInfo = vital#giit#import('Git.Info')
let s:GitTerm = vital#giit#import('Git.Term')

" NOTE:
" git requires an unix relative path from the repository often
function! giit#util#normalize#relpath(git, path) abort
  let path = giit#core#expand(a:path)
  return s:Path.unixpath(s:Git.relpath(a:git, path))
endfunction

" NOTE:
" system requires a real absolute path often
function! giit#util#normalize#abspath(git, path) abort
  let path = giit#core#expand(a:path)
  return s:Path.realpath(s:Git.abspath(a:git, path))
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
    return s:GitInfo.find_common_ancestor(a:git, lhs, rhs)
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
    let lhs = s:GitInfo.find_common_ancestor(a:git, lhs, rhs)
    return lhs . '..' . rhs
  else
    return a:commit
  endif
endfunction
