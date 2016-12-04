let s:Path = vital#giit#import('System.Filepath')
let s:GitTerm = vital#giit#import('Git.Term')
let s:Exception = vital#giit#import('Vim.Exception')
let s:Selection = vital#giit#import('Vim.Buffer.Selection')
let s:Formatter = vital#giit#import('Data.String.Formatter')
let s:Config = vital#giit#import('Data.Dict.Config')
let s:Git = vital#giit#import('Git')
let s:GitProperty = vital#giit#import('Git.Property')

let s:t_string = type('')
let s:params = {
      \ 'scheme': '_',
      \ 'commit': '',
      \ 'path': '',
      \ 'exact': 0,
      \ 'selection': [],
      \}


" Public ---------------------------------------------------------------------
function! giit#operator#browse#execute(git, params) abort
  let params = extend(copy(s:params), a:params)
  let selection = type(params.selection) == s:t_string
        \ ? s:Selection.parse(params.selection)
        \ : params.selection
  let args = [
        \ params.scheme,
        \ params.commit,
        \ empty(params.path) ? giit#expand('%') : params.path,
        \ selection,
        \ params.exact
        \]
  let url = call('s:find_url', [a:git] + args)
  return {
        \ 'status': 0,
        \ 'success': 1,
        \ 'args': args,
        \ 'output': url,
        \ 'content':[url],
        \}
endfunction

function! giit#operator#browse#build_params(args) abort
  let params = {
        \ 'commit': a:args.get_p(1, ''),
        \ 'path': a:args.get_p(2, ''),
        \ 'scheme': a:args.get('-c|--scheme', '_'),
        \ 'exact': a:args.get('-e|--exact'),
        \ 'selection': a:args.get(
        \   '-s|--selection',
        \   s:Selection.get_current_selection()
        \ ),
        \}
  return params
endfunction



" Private --------------------------------------------------------------------
function! s:format(scheme, remote_url, params) abort
  let format_map = {
        \ 'pt': 'path',
        \ 'rm': 'remote',
        \ 'r1': 'rev1',
        \ 'r2': 'rev2',
        \ 'c1': 'commit1',
        \ 'c2': 'commit2',
        \ 'h1': 'revision1',
        \ 'h2': 'revision2',
        \ 'ls': 'line_start',
        \ 'le': 'line_end',
        \}
  let patterns = g:giit#operator#browse#translation_patterns
  let patterns = extend(
        \ deepcopy(patterns),
        \ g:giit#operator#browse#extra_translation_patterns
        \)
  let baseurl = s:build_baseurl(a:scheme, a:remote_url, patterns)
  if empty(baseurl)
    return ''
  endif
  return s:Formatter.format(baseurl, format_map, a:params)
endfunction

function! s:find_url(git, scheme, commit, path, selection, exact) abort
  let relpath = s:Path.unixpath(s:Git.relpath(a:git, a:path))
  " normalize commit to figure out remote, commit, and remote_url
  let [commit1, commit2, remote, remote_url] = s:find_commit_meta(a:git, a:commit)
  let revision1 = s:GitProperty.get_remote_hash(a:git, remote, commit1)
  let revision2 = s:GitProperty.get_remote_hash(a:git, remote, commit2)

  " normalize selection to define line_start/line_end
  let line_start = get(a:selection, 0, 0)
  let line_end   = get(a:selection, 1, 0)
  let line_end   = line_start == line_end ? 0 : line_end

  let rev1 = a:exact ? revision1 : commit1
  let rev2 = a:exact ? revision2 : commit2

  let url = s:format(a:scheme, remote_url, {
        \ 'path': relpath,
        \ 'rev1': rev1,
        \ 'rev2': rev2,
        \ 'revision1': revision1,
        \ 'revision2': revision2,
        \ 'commit1': commit1,
        \ 'commit2': commit2,
        \ 'remote': remote,
        \ 'line_start': line_start,
        \ 'line_end': line_end,
        \})
  if !empty(url)
    return url
  endif
  throw s:Exception.warn(printf(
        \ 'Warning: No url translation pattern for "%s:%s" (%s) is found.',
        \ remote, rev1, remote_url,
        \))
endfunction

function! s:find_commit_meta(git, commit) abort
  let config = s:GitProperty.get_repository_config(a:git)
  if a:commit =~# '^.\{-}\.\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(a:commit, {})
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
    let remote = s:GitProperty.get_branch_remote(config, commit1)
    let commit1 = s:GitProperty.find_common_ancestor(a:git, commit1, commit2)
  elseif a:commit =~# '^.\{-}\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(a:commit, {})
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
    let remote = s:GitProperty.get_branch_remote(config, commit1)
  else
    let commit1 = empty(a:commit) ? 'HEAD' : a:commit
    let commit2 = ''
    let remote = s:GitProperty.get_branch_remote(config, commit1)
  endif
  let remote = empty(remote) ? 'origin' : remote
  let remote_url = s:GitProperty.get_remote_url(config, remote)
  let remote_url = empty(remote_url)
        \ ? s:GitProperty.get_remote_url(config, 'origin')
        \ : remote_url
  return [commit1, commit2, remote, remote_url]
endfunction

function! s:build_baseurl(scheme, remote_url, translation_patterns) abort
  for [domain, info] in items(a:translation_patterns)
    for pattern in info[0]
      let pattern = substitute(pattern, '\C' . '%domain', domain, 'g')
      if a:remote_url =~# pattern
        let repl = get(info[1], a:scheme, a:remote_url)
        return substitute(a:remote_url, '\C' . pattern, repl, 'g')
      endif
    endfor
  endfor
  return ''
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
      \       '^':     'https://\1/\2/\3/tree/%r1/',
      \       '_':     'https://\1/\2/\3/blob/%r1/%pt%{#L|}ls%{-L|}le',
      \       'blame': 'https://\1/\2/\3/blame/%r1/%pt%{#L|}ls%{-L|}le',
      \     },
      \   ],
      \   'bitbucket.org': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '^':     'https://\1/\2/\3/branch/%r1/',
      \       '_':     'https://\1/\2/\3/src/%r1/%pt%{#cl-|}ls',
      \       'blame': 'https://\1/\2/\3/annotate/%r1/%pt',
      \       'diff':  'https://\1/\2/\3/diff/%pt?diff1=%h1&diff2=%h2',
      \     },
      \   ],
      \ },
      \ 'extra_translation_patterns': {},
      \})
