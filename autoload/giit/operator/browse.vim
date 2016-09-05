let s:Path = vital#giit#import('System.Filepath')
let s:Formatter = vital#giit#import('Data.String.Formatter')
let s:Config = vital#giit#import('Data.Dict.Config')
let s:GitTerm = vital#giit#import('Git.Term')
let s:Exception = vital#giit#import('Vim.Exception')


" browse [options] [<commit>] [<path>]
function! giit#operator#browse#execute(git, args) abort
  let args = a:args.clone()

  let scheme    = args.get('-s|--scheme', '_')
  let commit    = args.get_p(1, '')
  let filename  = args.get_p(2, '')
  let selection = giit#util#selection#parse(args.get('--selection', ''))
  let exact     = args.get('-e|--exact')

  let url = s:find_url(a:git, scheme, commit, filename, selection, exact)
  return {
        \ 'status': 0,
        \ 'success': 1,
        \ 'args': args.raw,
        \ 'output': url,
        \ 'content':[url],
        \}
endfunction


function! s:find_url(git, scheme, commit, filename, selection, exact) abort
  let relpath = s:Path.unixpath(a:git.relpath(a:filename))
  " normalize commit to figure out remote, commit, and remote_url
  let [commit1, commit2, remote, remote_url] = s:find_commit_meta(a:git, a:commit)
  let revision1 = a:git.util.get_remote_hash(remote, commit1)
  let revision2 = a:git.util.get_remote_hash(remote, commit2)

  " normalize selection to define line_start/line_end
  let line_start = get(a:selection, 0, 0)
  let line_end   = get(a:selection, 1, 0)
  let line_end   = line_start == line_end ? 0 : line_end

  let rev1 = a:exact ? revision1 : commit1
  let rev2 = a:exact ? revision2 : commit2

  let params = {
        \ 'path': relpath,
        \ 'rev1': rev1,
        \ 'rev2': rev2,
        \ 'revision1': revision1,
        \ 'revision2': revision2,
        \ 'commit1': commit1,
        \ 'commit2': commit2,
        \ 'remote': remote,
        \ 'line_start': line_start,
        \ 'line_end':   line_end,
        \}
  let url = giit#util#url#format(a:scheme, remote_url, rev1, relpath, params)
  if empty(url)
    throw s:Exception.warn(printf(
          \ 'Warning: No url translation pattern for "%s:%s" (%s) is found.',
          \ remote, rev1, remote_url,
          \))
  endif
  return url
endfunction

function! s:find_commit_meta(git, commit) abort
  let config = a:git.util.get_repository_config()
  if a:commit =~# '^.\{-}\.\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(a:commit, {})
    let commit1 = empty(commit1) ? 'HEAD' : commit1
    let commit2 = empty(commit2) ? 'HEAD' : commit2
    let remote = config.get_branch_remote(commit1)
    let commit1 = a:git.util.find_common_ancestor(commit1, commit2)
  elseif a:commit =~# '^.\{-}\.\..*$'
    let [commit1, commit2] = s:GitTerm.split_range(a:commit, {})
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
