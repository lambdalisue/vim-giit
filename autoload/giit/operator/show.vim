let s:Argument = vital#giit#import('Argument')
let s:GitTerm = vital#giit#import('Git.Term')
let s:GitProperty = vital#giit#import('Git.Property')


" Public ---------------------------------------------------------------------
function! giit#operator#show#execute(git, args) abort
  let args = a:args.clone()
  call args.set_p(0, 'show')
  call args.set_p(1, s:normalize_object(a:git, args.get_p(1, ':' . giit#expand('%'))))
  call args.pop('-o|--opener')
  call args.pop('-s|--selection')
  call args.pop('-p|--patch')
  call args.lock()
  return giit#process#execute(a:git, args)
endfunction


" Private --------------------------------------------------------------------
function! s:normalize_object(git, object) abort
  " git show does not allow commit range so translate
  let [commit, relpath] = s:GitTerm.split_treeish(a:object)
  if commit =~# '^.\{-}\.\.\..\{-}$'
    " git diff <lhs>...<rhs> : <lhs>...<rhs> vs <rhs>
    let [lhs, rhs] = s:GitTerm.split_range(commit, {})
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let commit = s:GitProperty.find_common_ancestor(a:git, lhs, rhs)
  elseif commit =~# '^.\{-}\.\..\{-}$'
    let commit = s:GitTerm.split_range(commit, {})[0]
  endif
  return s:GitTerm.build_treeish(commit, relpath)
endfunction
