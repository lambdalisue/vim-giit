function! s:validate_commit(commit, options) abort
  " https://www.kernel.org/pub/software/scm/git/docs/git-check-commit-format.html
  if a:commit =~# '/\.' || a:commit =~# '.lock/' || a:commit =~# '\.lock$'
    call s:_throw('no slash-separated component can begin with a dot or end with the sequence .lock')
  elseif a:commit =~# '\.\.'
    call s:_throw('no two consective dots .. are allowed')
  elseif a:commit =~# '[ ~^:]'
    call s:_throw('no space, tilde ~, caret ^, or colon : are allowed')
  elseif a:commit =~# '[?[]' || (a:commit =~# '\*' && !get(a:options, 'refspec-pattern'))
    call s:_throw('no question ?, asterisk *, or open bracket [ are allowed')
  elseif (a:commit =~# '^/' || a:commit =~# '/$' || a:commit =~# '//\+') && !(get(a:options, 'normalize') || get(a:options, 'print'))
    call s:_throw('cannot begin or end with a slash /, or contain multiple consective slashes')
  elseif a:commit =~# '\.$'
    call s:_throw('cannot end with a dot .')
  elseif a:commit =~# '@{'
    call s:_throw('cannot contain a sequence @{')
  elseif a:commit =~# '\'
    call s:_throw('cannot contain a backslash \')
  endif
endfunction

function! s:split_commitish(commitish, options) abort
  " https://www.kernel.org/pub/software/scm/git/docs/gitrevisions.html#_specifying_revisions
  " http://stackoverflow.com/questions/4044368/what-does-tree-ish-mean-in-git
  if a:commitish =~# '@{.*}$'
    let [commit, misc] = matchlist(a:commitish, '\(.\{-}\)\(@{.*}\)$')[1 : 2]
  elseif a:commitish =~# '\^[\^0-9]*$'
    let [commit, misc] = matchlist(a:commitish, '\(.\{-}\)\(\^[\^0-9]*\)$')[1 : 2]
  elseif a:commitish =~# '\~[\~0-9]*$'
    let [commit, misc] = matchlist(a:commitish, '\(.\{-}\)\(\~[\~0-9]*\)$')[1 : 2]
  elseif a:commitish =~# '\^{.*}$'
    let [commit, misc] = matchlist(a:commitish, '\(.\{-}\)\(\^{.*}\)$')[1 : 2]
  elseif a:commitish =~# ':/.*$'
    let [commit, misc] = matchlist(a:commitish, '\(.\{-}\)\(:/.*\)$')[1 : 2]
  else
    let commit = a:commitish
    let misc = ''
  endif
  call s:validate_commit(commit, a:options)
  return [commit, misc]
endfunction

function! s:split_treeish(treeish, options) abort
  " https://www.kernel.org/pub/software/scm/git/docs/gitrevisions.html#_specifying_revisions
  " http://stackoverflow.com/questions/4044368/what-does-tree-ish-mean-in-git
  if a:treeish =~# '^:[0-3]:.*$'
    let commitish = ''
    let path = matchstr(a:treeish, '^:[0-3]:\zs.*$')
  elseif a:treeish =~# ':.*$'
    let [commitish, path] = matchlist(a:treeish, '\(.\{-}\):\(.*\)$')[1 : 2]
  else
    let commitish = a:treeish
    let path = ''
  endif
  " Validate
  if get(a:options, '_allow_range')
    call s:split_range(commitish, a:options)
  else
    call s:split_commitish(commitish, a:options)
  endif
  return [commitish, path]
endfunction

function! s:split_range(range, options) abort
  if a:range =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:range, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
  elseif a:range =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:range, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
  else
    let lhs = a:range
    let rhs = ''
  endif
  call s:split_commitish(lhs, a:options)
  call s:split_commitish(rhs, a:options)
  return [lhs, rhs]
endfunction

function! s:_throw(msg) abort
  throw printf('vital: Git.Term: ValidationError: %s', a:msg)
endfunction
