let s:t_dict = type({})

function! s:_vital_loaded(V) abort
  let s:INI = a:V.import('Text.INI')
  let s:Path = a:V.import('System.Filepath')
  let s:GitRepository = a:V.import('Git.Repository')
endfunction

function! s:_vital_depends() abort
  return ['Text.INI', 'System.Filepath', 'Git.Repository']
endfunction


" Public ---------------------------------------------------------------------
function! s:get_git_version() abort
  let result = s:GitProcess.execute({}, ['--version'])
  return result.status
        \ ? ''
        \ : matchstr(result.output, '^git version \zs.*$')
endfunction

function! s:resolve_ref(git, ref) abort
  let content = s:GitRepository.readline(a:git, s:Path.realpath(a:ref))
  if content =~# '^ref:\s'
    " recursively resolve ref
    return s:resolve_ref(a:git, substitute(content, '^ref:\s', '', ''))
  elseif empty(content)
    " ref is missing in traditional directory, the ref should be written in
    " packed-ref then
    let filter_code = printf(
          \ 'v:val[0] !=# "#" && v:val[-%d:] ==# a:ref',
          \ len(a:ref)
          \)
    let packed_refs = filter(
          \ s:GitRepository.readfile(a:git, 'packed-refs'),
          \ filter_code
          \)
    let content = get(split(get(packed_refs, 0, '')), 0, '')
  endif
  return content
endfunction

function! s:get_local_hash(git, branch) abort
  if a:branch ==# 'HEAD'
    let HEAD = s:GitRepository.readline(a:git, 'HEAD')
    let ref = substitute(HEAD, '^ref:\s', '', '')
  else
    let ref = s:Path.join('refs', 'heads', a:branch)
  endif
  return s:resolve_ref(a:git, ref)
endfunction

function! s:get_remote_hash(git, remote, branch) abort
  let ref = join(['refs', 'remotes', a:remote, a:branch], '/')
  return s:resolve_ref(a:git, ref)
endfunction

function! s:get_repository_config(git) abort
  let content = s:GitRepository.readfile(a:git, 'config')
  return empty(content) ? {} : s:INI.parse(join(content, "\n"))
endfunction

function! s:get_branch_remote(config, local_branch) abort
  " a name of remote which the {local_branch} connect
  let section = get(a:config, printf('branch "%s"', a:local_branch), {})
  if empty(section)
    return ''
  endif
  return get(section, 'remote', '')
endfunction

function! s:get_branch_merge(config, local_branch, ...) abort
  " a branch name of remote which {local_branch} connect
  let truncate = get(a:000, 0, 0)
  let section = get(a:config, printf('branch "%s"', a:local_branch), {})
  if empty(section)
    return ''
  endif
  let merge = get(section, 'merge', '')
  return truncate ? substitute(merge, '\v^refs/heads/', '', '') : merge
endfunction

function! s:get_remote_fetch(config, remote) abort
  " a url of {remote}
  let section = get(a:config, printf('remote "%s"', a:remote), {})
  if empty(section)
    return ''
  endif
  return get(section, 'fetch', '')
endfunction

function! s:get_remote_url(config, remote) abort
  " a url of {remote}
  let section = get(a:config, printf('remote "%s"', a:remote), {})
  if empty(section)
    return ''
  endif
  return get(section, 'url', '')
endfunction

function! s:get_comment_char(config, ...) abort
  let default = get(a:000, 0, '#')
  let section = get(a:config, 'core', {})
  if empty(section)
    return default
  endif
  return get(section, 'commentchar', default)
endfunction

function! s:get_local_branch(git) abort
  let HEAD = s:GitRepository.readline(a:git, 'HEAD')
  let branch_name = HEAD =~# 'refs/heads/'
        \ ? matchstr(HEAD, 'refs/heads/\zs.\+$')
        \ : HEAD[:7]
  let branch_hash = s:get_local_hash(a:git, branch_name)
  return {
        \ 'name': branch_name,
        \ 'hash': branch_hash,
        \}
endfunction

function! s:get_remote_branch(git, ...) abort
  let local = a:0 > 0 ? a:1 : s:get_local_branch(a:git).name
  let config = s:get_repository_config(a:git)
  let merge = s:get_branch_merge(config, local)
  let remote = s:get_branch_remote(config, local)
  let remote_url = s:get_remote_url(config, remote)
  let branch_name = merge =~# 'refs/heads/'
        \ ? matchstr(merge, 'refs/heads/\zs.\+$')
        \ : merge[:7]
  let branch_hash = s:get_remote_hash(a:git, remote, branch_name)
  return {
        \ 'remote': remote,
        \ 'name': branch_name,
        \ 'hash': branch_hash,
        \ 'url': remote_url,
        \}
endfunction

function! s:get_last_commitmsg(git) abort
  let result = s:GitProcess.execute(a:git, [
        \ 'log', '-1', '--pretty=%B',
        \])
  if result.status
    return result
  endif
  return result.content
endfunction

function! s:count_commits_ahead_of_remote(git) abort
  let result = s:GitProcess.execute(a:git, [
        \ 'log', '--oneline', '@{upstream}..'
        \])
  if result.status
    return result
  endif
  return len(filter(result.content, '!empty(v:val)'))
endfunction

function! s:count_commits_behind_remote(git) abort
  let result = s:GitProcess.execute(a:git, [
        \ 'log', '--oneline', '..@{upstream}'
        \])
  if result.status
    return result
  endif
  return len(filter(result.content, '!empty(v:val)'))
endfunction

function! s:find_common_ancestor(git, commit1, commit2) abort
  let lhs = empty(a:commit1) ? 'HEAD' : a:commit1
  let rhs = empty(a:commit2) ? 'HEAD' : a:commit2
  let result = s:GitProcess.execute(a:git, [
        \ 'merge-base', lhs, rhs
        \])
  if result.status
    return result
  endif
  return substitute(result.output, '\r\?\n$', '', '')
endfunction
