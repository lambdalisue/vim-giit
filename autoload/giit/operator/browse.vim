let s:Path = vital#giit#import('System.Filepath')
let s:Formatter = vital#giit#import('Data.String.Formatter')
let s:Config = vital#giit#import('Data.Dict.Config')
let s:GitTerm = vital#giit#import('Git.Term')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#operator#browse#execute(git, args) abort
  let path = a:args.get_p(1, '')
  let mode = a:args.get('-m|--mode', empty(path) ? '^' : '_')
endfunction


function! s:find_commit_meta(git, commit) abort
  let config = a:git.util.get_repository_config()
  if a:commit =~# '^.\{-}\.\.\..*$'
    let [lhs, rhs] = s:GitTerm.split_range(a:commit)
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let remote = config.get_branch_remote(lhs)
    let lhs = a:git.util.find_common_ancestor(lhs, rhs)
  elseif a:commit =~# '^.\{-}\.\..*$'
    let [lhs, rhs] = s:GitTerm.split_range(a:commit)
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let remote = config.get_branch_remote(lhs)
  else
    let lhs = empty(a:commit) ? 'HEAD' : a:commit
    let rhs = ''
    let remote = config.get_branch_remote(lhs)
  endif
  let remote = empty(remote) ? 'origin' : remote
  let remote_url = config.get_remote_url(remote)
  let remote_url = empty(remote_url)
        \ ? config.get_remote_url('origin')
        \ : remote_url
  return [lhs, rhs, remote, remote_url]
endfunction

function! s:translate_url(url, scheme_name, translation_patterns, repository) abort
  let symbol = a:repository ? '^' : '_'
  for [domain, info] in items(a:translation_patterns)
    for pattern in info[0]
      let pattern = substitute(pattern, '\C' . '%domain', domain, 'g')
      if a:url =~# pattern
        let scheme = get(info[1], a:scheme_name, info[1][symbol])
        let repl = substitute(a:url, '\C' . pattern, scheme, 'g')
        return repl
      endif
    endfor
  endfor
  return ''
endfunction

function! s:find_url(git, commit, filename, options) abort
  let relpath = s:Path.unixpath(a:git.relpath(a:filename))
  " normalize commit to figure out remote, commit, and remote_url
  let [commit1, commit2, remote, remote_url] = s:find_commit_meta(a:git, a:commit)
  let revision1 = a:git.get_remote_hash(remote, commit1)
  let revision2 = a:git.get_remote_hash(remote, commit2)

  " get selected region
  if has_key(a:options, 'selection')
    let line_start = get(a:options.selection, 0, 0)
    let line_end   = get(a:options.selection, 1, 0)
  else
    let line_start = 0
    let line_end = 0
  endif
  let line_end = line_start == line_end ? 0 : line_end

  " create a URL
  let data = {
        \ 'path':       relpath,
        \ 'commit1':    commit1,
        \ 'commit2':    commit2,
        \ 'revision1':  revision1,
        \ 'revision2':  revision2,
        \ 'remote':     remote,
        \ 'line_start': line_start,
        \ 'line_end':   line_end,
        \}
  let format_map = {
        \ 'pt': 'path',
        \ 'c1': 'commit1',
        \ 'c2': 'commit2',
        \ 'r1': 'revision1',
        \ 'r2': 'revision2',
        \ 'ls': 'line_start',
        \ 'le': 'line_end',
        \}
  let translation_patterns = extend(
        \ deepcopy(g:giit#operator#browse#translation_patterns),
        \ g:giit#operator#browse#extra_translation_patterns,
        \)
  let url = s:translate_url(
        \ remote_url,
        \ empty(a:filename) ? '^' : get(a:options, 'scheme', '_'),
        \ translation_patterns,
        \ empty(a:filename),
        \)
  if empty(url)
    throw s:Exception.warn(printf(
          \ 'Warning: No url translation pattern for "%s:%s" is found.',
          \ remote, commit1,
          \))
  endif
  return s:Formatter.format(url, format_map, data)
endfunction


call s:Config.define('giit#operator#browse', {
      \ 'translation_patterns': {
      \   'github.com': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '^':     'https://\1/\2/\3/tree/%c1/',
      \       '_':     'https://\1/\2/\3/blob/%c1/%pt%{#L|}ls%{-L|}le',
      \       'exact': 'https://\1/\2/\3/blob/%r1/%pt%{#L|}ls%{-L|}le',
      \       'blame': 'https://\1/\2/\3/blame/%c1/%pt%{#L|}ls%{-L|}le',
      \     },
      \   ],
      \   'bitbucket.org': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '^':     'https://\1/\2/\3/branch/%c1/',
      \       '_':     'https://\1/\2/\3/src/%c1/%pt%{#cl-|}ls',
      \       'exact': 'https://\1/\2/\3/src/%r1/%pt%{#cl-|}ls',
      \       'blame': 'https://\1/\2/\3/annotate/%c1/%pt',
      \       'diff':  'https://\1/\2/\3/diff/%pt?diff1=%c1&diff2=%c2',
      \     },
      \   ],
      \ },
      \ 'extra_translation_patterns': {},
      \})
