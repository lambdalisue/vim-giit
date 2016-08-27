let s:ArgumentParser = vital#giit#import('ArgumentParser')


function! giit#operation#show#correct(git, options) abort
  if get(a:options, '__corrected__')
    return a:options
  endif

  let commit = get(a:options, 'commit', '')
  let commit = empty(commit) || commit =~# '^:'
        \ ? commit
        \ : giit#util#normalize#commit(a:git, commit)

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

function! giit#operation#show#execute(git, options) abort
  let args = s:build_args(a:git, a:options)
  return a:git.execute(args, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#show#command(bang, range, args) abort
  let parser  = s:get_parser()
  let options = parser.parse(a:bang, a:range, a:args)
  if empty(options)
    return
  endif
  let git = giit#core#get_or_fail()
  if !empty(options.__unknown__)
    let options.filename = options.__unknown__[0]
  endif
  call giit#component#show#open(git, options)
endfunction

function! giit#operation#show#complete(arglead, cmdline, cursorpos) abort
  let parser = s:get_parser()
  return parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction


function! s:build_args(git, options) abort
  let options = giit#operation#show#correct(a:git, a:options)
  let args = [
        \ 'show',
        \ options.object,
        \]
  return filter(args, '!empty(v:val)')
endfunction

function! s:get_parser() abort
  if !exists('s:parser')
    let s:parser = s:ArgumentParser.new({
          \ 'name': 'Giit show',
          \ 'description': 'Show a content of a commit or a file',
          \ 'complete_threshold': g:giit#complete_threshold,
          \ 'unknown_description': '<path>',
          \ 'complete_unknown': function('giit#util#complete#filename'),
          \})
    call s:parser.add_argument(
          \ '--worktree', '-w',
          \ 'open a content of a file in working tree', {
          \   'conflicts': ['ancestor', 'ours', 'theirs'],
          \})
    call s:parser.add_argument(
          \ '--ancestors', '-1',
          \ 'open a content of a file in a common ancestor during merge', {
          \   'conflicts': ['worktree', 'ours', 'theirs'],
          \})
    call s:parser.add_argument(
          \ '--ours', '-2',
          \ 'open a content of a file in our side during merge', {
          \   'conflicts': ['worktree', 'ancestors', 'theirs'],
          \})
    call s:parser.add_argument(
          \ '--theirs', '-3',
          \ 'open a content of a file in thier side during merge', {
          \   'conflicts': ['worktree', 'ancestors', 'ours'],
          \})
    call s:parser.add_argument(
          \ '--opener', '-o',
          \ 'a way to open a new buffer such as "edit", "split", etc.', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '--selection',
          \ 'a line number or range of the selection', {
          \   'pattern': '^\%(\d\+\|\d\+-\d\+\)$',
          \})
    call s:parser.add_argument(
          \ 'commit', [
          \   'a commit which you want to see.',
          \   'if nothing is specified, it show a content of the index.',
          \   'if <commit> is specified, it show a content of the named <commit>.',
          \   'if <commit1>..<commit2> is specified, it show a content of the named <commit1>',
          \   'if <commit1>...<commit2> is specified, it show a content of a common ancestor of commits',
          \], {
          \   'complete': function('giit#util#complete#commitish'),
          \})
  endif
  return s:parser
endfunction
