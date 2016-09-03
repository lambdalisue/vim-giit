let s:Path = vital#giit#import('System.Filepath')
let s:Formatter = vital#giit#import('Data.String.Formatter')
let s:Config = vital#giit#import('Data.Dict.Config')
let s:GitTerm = vital#giit#import('Git.Term')
let s:Exception = vital#giit#import('Vim.Exception')


" browse [options] [<commit>] [<path>]
function! giit#operator#browse#execute(git, args) abort
  let args = a:args.clone()
  let mode = args.get('-m|--mode', '')

  " Commit
  let commit = a:args.get_p(1, '')
  let config = a:git.util.get_repository_config()
  if commit =~# '^.\{-}\.\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(commit)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
    let remote = config.get_branch_remote(commit1)
    let commit1 = a:git.util.find_common_ancestor(commit1, commit2)
  elseif commit =~# '^.\{-}\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(commit)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
    let remote = config.get_branch_remote(commit1)
  else
    let commit1 = empty(commit) ? 'HEAD' : commit
    let commit2 = ''
    let remote = config.get_branch_remote(commit1)
  endif
  let remote = empty(remote) ? 'origin' : remote
  let remote_url = config.get_remote_url(remote)
  let remote_url = empty(remote_url)
        \ ? config.get_remote_url('origin')
        \ : remote_url
  let rev1 = a:git.get_remote_hash(remote, commit1)
  let rev2 = a:git.get_remote_hash(remote, commit2)

  " Path
  let relpath = a:git.get_p(2, '')
  let relpath = s:Path.unixpath(a:git.relpath(relpath))

  " Get selected region
  let selection = giit#util#selection#parse(a:git.get('--selection'))
  let line_start = get(selection, 0, 0)
  let line_end   = get(selection, 1, 0)
  let line_end   = line_start == line_end ? 0 : line_end

  " create a URL
  let data = {
        \ 'path':       relpath,
        \ 'commit1':    commit1,
        \ 'commit2':    commit2,
        \ 'revision1':  rev1,
        \ 'revision2':  rev2,
        \ 'remote':     remote,
        \ 'line_start': line_start,
        \ 'line_end':   line_end,
        \}
  let format_map = {
        \ 'pt': 'path',
        \ 'c1': 'commit1',
        \ 'c2': 'commit2',
        \ 'r1': 'rev1',
        \ 'r2': 'rev2',
        \ 'ls': 'line_start',
        \ 'le': 'line_end',
        \}
  let translation_patterns = extend(
        \ deepcopy(g:giit#operator#browse#translation_patterns),
        \ g:giit#operator#browse#extra_translation_patterns,
        \)
  let url = s:translate_url(
        \ remote_url,
        \ empty(relpath) ? '^' : mode,
        \ translation_patterns,
        \ empty(relpath),
        \)
  if empty(url)
    throw s:Exception.warn(printf(
          \ 'Warning: No url translation pattern for "%s:%s" is found.',
          \ remote, commit1,
          \))
  endif
  return s:Formatter.format(url, format_map, data)
endfunction


function! s:find_commit_meta(git, commit) abort
  let config = a:git.util.get_repository_config()
  if a:commit =~# '^.\{-}\.\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(a:commit)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
    let remote = config.get_branch_remote(commit1)
    let commit1 = a:git.util.find_common_ancestor(commit1, commit2)
  elseif a:commit =~# '^.\{-}\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(a:commit)
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
    let remote = config.get_branch_remote(commit1)
  else
    let commit1 = empty(a:commit) ? 'HEAD' : a:commit
    let commit2 = ''
    let remote = config.get_branch_remote(commit1)
  endif
  let remote = empty(remote) ? 'origin' : remote
  let remote_url = config.get_remote_url(remote)
  let remote_url = empty(remote_url)
        \ ? config.get_remote_url('origin')
        \ : remote_url
  return [commit1, commit2, remote, remote_url]
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
