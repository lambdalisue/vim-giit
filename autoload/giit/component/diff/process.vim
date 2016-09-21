let s:GitTerm = vital#giit#import('Git.Term')

function! giit#component#diff#process#execute(git, args) abort
  let args = a:args.clone()

  " git diff did not allow A...B type assignment in old version so translate
  let commit = args.pop_p(1, '')
  call args.set_p(1, s:normalize_commit(a:git, commit))
  call args.lock()

  return giit#process#execute(a:git, args)
endfunction


" NOTE:
" git diff command does not understand A...B type assignment so translate
" it to an exact revision
function! s:normalize_commit(git, commit) abort
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
