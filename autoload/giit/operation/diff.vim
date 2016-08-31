let s:GitTerm = vital#giit#import('Git.Term')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')

let s:WORKTREE = '@@'

function! giit#operation#diff#correct(git, options) abort
  if get(a:options, '__corrected__')
    return a:options
  endif

  if get(a:options, 'patch')
    " 'patch' mode requires:
    " - Existence of INDEX, namely no commit or --cached
    let commit = get(a:options, 'commit', '')
    if empty(commit)
      " INDEX vs HEAD
      let a:options.cached = 0
      let a:options.reverse = 0
    elseif commit =~# '^.\{-}\.\.\.?.*$'
      " RANGE is not allowed
      call giit#throw(printf(
            \ 'A commit range "%s" is not allowed for PATCH mode.',
            \ commit,
            \))
    else
      " COMMIT vs INDEX
      let a:options.cached = 1
      let a:options.reverse = 1
    endif
  else
    let a:options.cached = get(a:options, 'cached', 0)
    let a:options.reverse = get(a:options, 'reverse', 0)
  endif

  let commit = get(a:options, 'commit', '')
  let commit = empty(commit)
        \ ? commit
        \ : giit#util#normalize#commit_for_diff(a:git, commit)

  let filename = get(a:options, 'filename', '')
  let filename = empty(filename)
        \ ? filename
        \ : giit#util#normalize#relpath(a:git, filename)

  let object = empty(filename)
        \ ? commit
        \ : commit . ':' . filename

  let a:options.commit = commit
  let a:options.filename = filename
  let a:options.object = object
  let a:options.__corrected__ = 1
  return a:options
endfunction

function! giit#operation#diff#execute(git, args) abort
  let commit   = a:args.p.get(0, '')
  let filename = a:args.p.get(1, '')
  if a:args.pop('-p|--patch')
    if commit =~# '^.\{-}\.\.\.\?.*$'
      throw s:Exception.warn(printf(
            \ 'A commit range %s is not allowed for PATCH mode',
            \ commit,
            \))
    elseif empty(commit)
      call a:args.pop('--cached')
      call a:args.pop('--reverse')
    else
      call a:args.set('--cached', 1)
      call a:args.set('--reverse', 1)
    endif
  endif
  call a:args.p.apply(0, function('giit#util#normalize#commit_for_diff', [a:git]))
  call a:args.p.apply(1, function('giit#util#normalize#relpath', [a:git]))
  call a:args.set('--no-color', 1)
  return a:git.execute(a:args.raw, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#diff#command(bang, range, args) abort
  let git = giit#core#get_or_fail()
  let args = s:build_args(git, a:args)
  call giit#component#diff#open(git, args)
endfunction

function! giit#operation#diff#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! giit#operation#diff#split_commit(git, options) abort
  let options = giit#operation#diff#correct(a:git, a:options)
  let commit = options.commit
  if empty(commit)
    " git diff          : INDEX vs TREE
    " git diff --cached :  HEAD vs INDEX
    let lhs = options.cached ? 'HEAD' : ''
    let rhs = options.cached ? '' : s:WORKTREE
  elseif commit =~# '^.\{-}\.\.\..*$'
    " git diff <lhs>...<rhs> : <lhs>...<rhs> vs <rhs>
    let [lhs, rhs] = s:GitTerm.split_range(commit, options)
    let lhs = commit
    let rhs = empty(rhs) ? 'HEAD' : rhs
  elseif commit =~# '^.\{-}\.\.\..*$'
    " git diff <lhs>..<rhs> : <lhs> vs <rhs>
    let [lhs, rhs] = s:GitTerm.split_range(commit, options)
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
  else
    " git diff <ref>          : <ref> vs TREE
    " git diff --cached <ref> : <ref> vs INDEX
    let lhs = commit
    let rhs = options.cached ? '' : s:WORKTREE
  endif
  return [lhs, rhs]
endfunction


function! s:build_args(git, args) abort
  let args = s:Argument.parse(a:args)
  let commit = args.get(0, '')
  let filename = args.get(1, '')
  if args.pop('-p|--patch')
    if commit =~# '^.\{-}\.\.\.\?.*$'
      throw s:Exception.warn(printf(
            \ 'A commit range %s is not allowed for PATCH mode',
            \ commit,
            \))
    elseif empty(commit)
      call args.pop('--cached')
      call args.pop('--reverse')
    else
      call args.set('--cached', 1)
      call args.set('--reverse', 1)
    endif
  endif
  call args.apply(0, function('giit#util#normalize#commit_for_diff', [a:git]))
  call args.apply(1, function('giit#util#normalize#relpath', [a:git]))
  call args.set('--no-color', 1)
  return args
endfunction

function! s:open2(git, options) abort
  let options = extend({
        \ 'patch': 0,
        \ 'cached': 0,
        \ 'reverse': 0,
        \ 'opener': '',
        \ 'selection': [],
        \}, a:options)
  let filename = empty(options.filename)
        \ ? giit#util#normalize#relpath(a:git, giit#expand('%'))
        \ : options.filename
  let [lhs, rhs] = giit#operation#diff#split_commit(a:git, a:options)
  let vertical = matchstr(&diffopt, 'vertical')
  let loptions = {
        \ 'patch': !options.reverse && options.patch,
        \ 'commit': lhs,
        \ 'filename': filename,
        \ 'worktree': lhs ==# s:WORKTREE,
        \}
  let roptions = {
        \ 'silent': 1,
        \ 'patch': options.reverse && options.patch,
        \ 'commit': rhs,
        \ 'filename': filename,
        \ 'worktree': rhs ==# s:WORKTREE,
        \}

  call s:BufferAnchor.focus_if_available(options.opener)
  let ret1 = giit#component#show#open(a:git,
        \ extend(options.reverse ? loptions : roptions, {
        \  'opener': options.opener,
        \  'window': 'diff2_rhs',
        \  'selection': options.selection,
        \ }
        \))
  diffthis

  let ret2 = giit#component#show#open(a:git,
        \ extend(options.reverse ? roptions : loptions, {
        \  'opener': vertical ==# 'vertical'
        \    ? 'leftabove vertical split'
        \    : 'leftabove split',
        \  'window': 'diff2_lhs',
        \  'selection': options.selection,
        \ }
        \))
  diffthis
  diffupdate

  let doom = s:BufferDoom.new()
  let sign = xor(ret1.loaded, ret2.loaded)
  call doom.involve(ret1.bufnum, { 'keep': !ret1.loaded && sign })
  call doom.involve(ret2.bufnum, { 'keep': !ret2.loaded && sign })
endfunction
