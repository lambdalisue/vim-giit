let s:Argument = vital#giit#import('Argument')
let s:GitTerm = vital#giit#import('Git.Term')
let s:GitProperty = vital#giit#import('Git.Property')


" Public ---------------------------------------------------------------------
function! giit#operator#diff#execute(git, args) abort
  let args = a:args.clone()
  call args.set_p(0, 'diff')
  call args.set_p(1, s:normalize_commit(a:git, args.get_p(1, '')))
  call args.set_p(2, args.get_p(2, giit#expand('%')))
  call args.pop('-o|--opener')
  call args.pop('-s|--selection')
  call args.pop('-p|--patch')
  call args.lock()
  return giit#process#execute(a:git, args)
endfunction


" Private --------------------------------------------------------------------
function! s:normalize_commit(git, commit) abort
  if a:commit =~# '^.\{-}\.\.\..\{-}$'
    " git diff <lhs>...<rhs> : <lhs>...<rhs> vs <rhs>
    let [lhs, rhs] = s:GitTerm.split_range(a:commit, {})
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let lhs = s:GitProperty.find_common_ancestor(a:git, lhs, rhs)
    return lhs . '..' . rhs
  else
    return a:commit
  endif
endfunction
