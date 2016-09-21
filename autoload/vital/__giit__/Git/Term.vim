function! s:validate_commit(commit) abort
  " https://www.kernel.org/pub/software/scm/git/docs/git-check-commit-format.html
  if a:commit =~# '/\.' || a:commit =~# '.lock/' || a:commit =~# '\.lock$'
    call s:_throw('no slash-separated component can begin with a dot or end with the sequence .lock', a:commit)
  elseif a:commit =~# '\.\.'
    call s:_throw('no two consective dots .. are allowed', a:commit)
  elseif a:commit =~# '[ ~^:]'
    call s:_throw('no space, tilde ~, caret ^, or colon : are allowed', a:commit)
  elseif a:commit =~# '[?[]' || a:commit =~# '\*'
    call s:_throw('no question ?, asterisk *, or open bracket [ are allowed', a:commit)
  elseif a:commit =~# '^/' || a:commit =~# '/$' || a:commit =~# '//\+'
    call s:_throw('cannot begin or end with a slash /, or contain multiple consective slashes', a:commit)
  elseif a:commit =~# '\.$'
    call s:_throw('cannot end with a dot .', a:commit)
  elseif a:commit =~# '@{'
    call s:_throw('cannot contain a sequence @{', a:commit)
  elseif a:commit =~# '\'
    call s:_throw('cannot contain a backslash \', a:commit)
  endif
endfunction

function! s:split_commitish(commitish) abort
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
  call s:validate_commit(commit)
  return [commit, misc]
endfunction

function! s:split_treeish(treeish, ...) abort
  let options = extend({
        \ 'allow_range': 0,
        \}, get(a:000, 0, {})
        \)
  " https://www.kernel.org/pub/software/scm/git/docs/gitrevisions.html#_specifying_revisions
  " http://stackoverflow.com/questions/4044368/what-does-tree-ish-mean-in-git
  if a:treeish =~# '^:[0-3]:.*$'
    let commitish = ''
    let path = matchstr(a:treeish, '^:[0-3]:\zs.*$')
  elseif a:treeish =~# ':.*$'
    let [commitish, path] = matchlist(a:treeish, '\(.\{-}\):\(.*\)$')[1 : 2]
  else
    return ['', a:treeish]
  endif
  " Validate
  if options.allow_range
    call s:split_range(commitish)
  else
    call s:split_commitish(commitish)
  endif
  return [commitish, path]
endfunction

function! s:build_treeish(commitish, path) abort
  return empty(a:path)
        \ ? a:commitish
        \ : a:commitish . ':' . a:path
endfunction

function! s:split_range(range) abort
  if a:range =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = matchlist(a:range, '^\(.\{-}\)\.\.\.\(.*\)$')[1 : 2]
  elseif a:range =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = matchlist(a:range, '^\(.\{-}\)\.\.\(.*\)$')[1 : 2]
  else
    let lhs = a:range
    let rhs = ''
  endif
  call s:split_commitish(lhs)
  call s:split_commitish(rhs)
  return [lhs, rhs]
endfunction

function! s:_throw(msg, commit) abort
  throw printf('vital: Git.Term: ValidationError: %s (%s)', a:msg, a:commit)
endfunction
