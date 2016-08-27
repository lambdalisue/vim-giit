let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:DictOption = vital#giit#import('Data.Dict.Option')
let s:GitTerm = vital#giit#import('Git.Term')
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

function! giit#operation#diff#execute(git, options) abort
  let args = s:build_args(a:git, a:options)
  return a:git.execute(args, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#diff#command(bang, range, args) abort
  let parser  = s:get_parser()
  let options = parser.parse(a:bang, a:range, a:args)
  if empty(options)
    return
  endif
  let git = giit#core#get_or_fail()
  if !empty(options.__unknown__)
    let options.filename = options.__unknown__[0]
  endif
  call giit#component#diff#open(git, options)
endfunction

function! giit#operation#diff#complete(arglead, cmdline, cursorpos) abort
  let parser = s:get_parser()
  return parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction


function! s:build_args(git, options) abort
  let options = giit#operation#show#correct(a:git, a:options)
  let args = s:DictOption.translate(options, {
        \ 'unified': 1,
        \ 'minimal': 1,
        \ 'patience': 1,
        \ 'histogram': 1,
        \ 'diff-algorithm': 1,
        \ 'submodule': 1,
        \ 'word-diff-regex': 1,
        \ 'no-renames': 1,
        \ 'full-index': 1,
        \ 'binary': 1,
        \ 'abbrev': 1,
        \ 'B': 1,
        \ 'M': 1,
        \ 'C': 1,
        \ 'find-copies-harder': 1,
        \ 'irreversible-delete': 1,
        \ 'l': 1,
        \ 'diff-filter': 1,
        \ 'S': 1,
        \ 'G': 1,
        \ 'pickaxe-all': 1,
        \ 'O': 1,
        \ 'R': 1,
        \ 'relative': 1,
        \ 'text': 1,
        \ 'ignore-space-at-eol': 1,
        \ 'ignore-space-change': 1,
        \ 'ignore-all-space': 1,
        \ 'ignore-blank-lines': 1,
        \ 'inter-hunk-context': 1,
        \ 'function-context': 1,
        \ 'ignore-submodules': 1,
        \ 'src-prefix': 1,
        \ 'dst-prefix': 1,
        \ 'no-prefix': 1,
        \ 'numstat': 1,
        \ 'no-index': 1,
        \ 'cached': 1,
        \})
  let args = ['diff', '--no-color'] + args + [
        \ options.commit,
        \ '--',
        \ options.filename,
        \]
  return filter(args, '!empty(v:val)')
endfunction

function! s:get_parser() abort
  if !exists('s:parser')
    let s:parser = s:ArgumentParser.new({
          \ 'name': 'Gita diff',
          \ 'description': 'Show changes between commits, commit and working tree, etc',
          \ 'complete_threshold': g:giit#complete_threshold,
          \ 'unknown_description': '<path>',
          \ 'complete_unknown': function('giit#util#complete#filename'),
          \})
    call s:parser.add_argument(
          \ '--unified', '-U',
          \ 'generate diffs with <N> lines of context', {
          \   'pattern': '^\d\+$',
          \})
    call s:parser.add_argument(
          \ '--minimal',
          \ 'spend extra time to make sure the smallest possible diff is produced', {
          \   'conflicts': ['patience', 'histogram', 'diff-algorithm'],
          \})
    call s:parser.add_argument(
          \ '--patience',
          \ 'generate a diff using the "patience diff" algorithm', {
          \   'conflicts': ['minimal', 'histogram', 'diff-algorithm'],
          \})
    call s:parser.add_argument(
          \ '--histogram',
          \ 'generate a diff using the "histogram diff" algorithm', {
          \   'conflicts': ['minimal', 'patience', 'diff-algorithm'],
          \})
    call s:parser.add_argument(
          \ '--diff-algorithm', [
          \   'choices a diff algorighm. the variants are as follows:',
          \   '- myres     the basic greedy diff algorithm',
          \   '- minimal   spend extra time to make sure the smallest possible diff is produced',
          \   '- patience  use "patience diff" algorithm',
          \   '- histogram this algorithm extends the patience algorithm to "support low-occurrence common elements"',
          \ ], {
          \   'choices': ['default', 'myres', 'minimal', 'patience', 'histogram'],
          \   'conflicts': ['minimal', 'patience', 'histogram'],
          \ }
          \)
    "call s:parser.add_argument(
    "      \ '--submodule', [
    "      \   'specify how differences in submodules are shown.',
    "      \   '- log       lists the commits in the range like git-submodule summary does',
    "      \   '- short     shows the name of the commits at the beginning and end of the range',
    "      \ ], {
    "      \   'on_default': 'log',
    "      \   'choices': ['log', 'short'],
    "      \   'conflicts': ['ignore-submodules'],
    "      \ }
    "      \)
    call s:parser.add_argument(
          \ '--ignore-submodules', [
          \   'ignore changes to submodules in the diff generation',
          \   '- none       consider the submodule modified when it either contains untracked or modified files or its HEAD differs',
          \   '- untracked  submodules are not considered dirty when they only contain untracked content',
          \   '- dirty      ignores all changes to the work tree of submodules',
          \   '- all        hides all changes to submodules',
          \ ], {
          \   'on_default': 'all',
          \   'choices': ['none', 'untracked', 'dirty', 'all'],
          \   'conflicts': ['submodule'],
          \ }
          \)
    "call s:parser.add_argument(
    "      \ '--word-diff',
    "      \ 'WIP: show a word diff', {
    "      \   'on_default': 'plain',
    "      \   'choices': ['color', 'plain', 'porcelain', 'none'],
    "      \   'conflicts': ['--color-words'],
    "      \})
    "call s:parser.add_argument(
    "      \ '--word-diff-regex',
    "      \ 'use regex to decide what a word is instead of considering runs of non-whitespace to be a word', {
    "      \   'type': s:ArgumentParser.types.value,
    "      \})
    "call s:parser.add_argument(
    "      \ '--color-words',
    "      \ 'WIP: equivalent to --word-diff=color plus (if aregex was specified)', {
    "      \   'type': s:ArgumentParser.types.value,
    "      \})
    call s:parser.add_argument(
          \ '--no-renames',
          \ 'turn off rename detection',
          \)
    call s:parser.add_argument(
          \ '--check',
          \ 'warn if changes introduce whitespace errors.',
          \)
    call s:parser.add_argument(
          \ '--full-index',
          \ 'instead of the first handful of characters, show the full pre- and post-image blob object names on the "index" line',
          \)
    "call s:parser.add_argument(
    "      \ '--binary',
    "      \ 'in addition to --full-index, output a binary diff that can be applied with git-apply',
    "      \)
    call s:parser.add_argument(
          \ '-B',
          \ 'break complete rewrite changes into pairs of delete and create.', {
          \   'pattern': '^\d\+\(/\d\+\)\?$',
          \})
    call s:parser.add_argument(
          \ '--find-renames', '-M',
          \ 'detect renames. if <n> is specified, it is a threshold on the similarity index', {
          \   'on_default': '50%',
          \   'pattern': '^\d\+%\?$',
          \})
    call s:parser.add_argument(
          \ '--find-copies', '-C',
          \ 'detect copies as well as renames. it has the same meaning as for -M<n>', {
          \   'on_default': '50%',
          \   'pattern': '^\d\+%\?$',
          \})
    call s:parser.add_argument(
          \ '--find-copies-harder',
          \ 'try harder to find copies. this is a very expensive operation for large projects',
          \)
    call s:parser.add_argument(
          \ '--irreversible-delete', '-D',
          \ 'omit the preimage for deletes, i.e. print only the header but not the diff between the preivmage and /dev/null.',
          \)
    call s:parser.add_argument(
          \ '-S',
          \ 'look for differences that change the number of occurrences of the specified string in a file', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '-G',
          \ 'look for differences whose patch text contains added/removed lines that match regex', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '--pickaxe-all',
          \ 'when -S or -G finds a change, show all the changes in that changeset, not just the files', {
          \   'superordinates': ['S', 'G'],
          \})
    call s:parser.add_argument(
          \ '--pickaxe-regex',
          \ 'treat the string given to -S as an extended POSIX regular expression to match', {
          \   'superordinates': ['S'],
          \})
    call s:parser.add_argument(
          \ '-R',
          \ 'swap two inputs; that is, show differences from index or on-disk file to tree contents',
          \)
    call s:parser.add_argument(
          \ '--relative',
          \ 'make path relative to the specified path', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '--text', '-a',
          \ 'treat all files as text',
          \)
    call s:parser.add_argument(
          \ '--ignore-space-at-eol',
          \ 'ignore changes in whitespace at EOL',
          \)
    call s:parser.add_argument(
          \ '--ignore-space-change', '-b',
          \ 'ignore changes in amount of whitespace',
          \)
    call s:parser.add_argument(
          \ '--ignore-all-space', '-w',
          \ 'ignore whitespace when comparing lines',
          \)
    call s:parser.add_argument(
          \ '--ignore-blank-lines',
          \ 'ignore changes whose lines are all blank',
          \)
    call s:parser.add_argument(
          \ '--inter-hunk-context',
          \ 'show the context between diff hunks, up to the specified number of lines', {
          \   'pattern': '^\d\+$',
          \})
    call s:parser.add_argument(
          \ '--function-context', '-W',
          \ 'show whole surarounding functions of changes',
          \)
    call s:parser.add_argument(
          \ '--src-prefix',
          \ 'show the given source prefix instead of "a/"', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '--dst-prefix',
          \ 'show the given destination prefix instead of "a/"', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '--no-prefix',
          \ 'do not show any source or destination prefix',
          \)
    call s:parser.add_argument(
          \ '--cached',
          \ 'compare with a content in the index',
          \)
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
          \ '--split', '-s', [
          \   'open two buffer to compare by vimdiff rather than to open a single diff file.',
          \   'see ":help &diffopt" if you would like to control default split direction',
          \])
    call s:parser.add_argument(
          \ 'commit', [
          \   'a commit which you want to diff.',
          \   'if nothing is specified, it diff a content between an index and working tree or HEAD when --cached is specified.',
          \   'if <commit> is specified, it diff a content between the named <commit> and working tree or an index.',
          \   'if <commit1>..<commit2> is specified, it diff a content between the named <commit1> and <commit2>',
          \   'if <commit1>...<commit2> is specified, it diff a content of a common ancestor of commits and <commit2>',
          \ ], {
          \   'complete': function('giit#util#complete#commit'),
          \})
  endif
  return s:parser
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
