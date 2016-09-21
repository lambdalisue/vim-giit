let s:GitTerm = vital#giit#import('Git.Term')

function! giit#component#show#process#execute(git, args) abort
  let args = a:args.clone()

  " git show does not allow commit range so translate
  let object = args.pop_p(1, '')
  let [commit, relpath] = s:GitTerm.split_treeish(object)
  let commit = s:normalize_commit(a:git, commit)
  let object = s:GitTerm.build_treeish(commit, relpath)
  call args.set_p(1, object)
  call args.lock()

  return giit#process#execute(a:git, args)
endfunction


" Private --------------------------------------------------------------------
" NOTE:
" most of git command does not understand A...B type assignment so translate
" it to an exact revision
function! s:normalize_commit(git, commit) abort
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
