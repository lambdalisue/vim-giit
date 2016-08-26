let s:Git = vital#giit#import('Git')
let s:Path = vital#giit#import('System.Filepath')

if !exists('s:refs')
  let s:refs = {}
endif

function! giit#core#expand(expr) abort
  let path = giit#meta#get_at(a:expr, 'filename', '')
  if empty(path)
    let path = expand(a:expr)
  endif
  return s:Path.remove_last_separator(path)
endfunction

function! giit#core#get(...) abort
  let expr = get(a:000, 0, '%')
  let refinfo = s:get_refinfo(expr)
  return s:refs[refinfo.refname]
endfunction

function! giit#core#get_or_fail(...) abort
  let expr = get(a:000, 0, '%')
  let git = giit#core#get(expr)
  if !empty(git.worktree)
    return git
  endif
  call giit#throw(printf(
        \ 'No git repository for a buffer "%s" is found.',
        \ expand(expr),
        \))
endfunction


function! s:get_available_refname(refname, git) abort
  let refname = a:refname
  let pseudo = { 'worktree': a:git.worktree }
  let ref = get(s:refs, refname, pseudo)
  let index = 1
  while !empty(ref.worktree) && ref.worktree !=# a:git.worktree
    let refname = a:refname . '~' . index
    let ref = get(s:refs, refname, pseudo)
    let index += 1
  endwhile
  return refname
endfunction

function! s:new_refinfo(expr) abort
  let git = {
        \ 'worktree': '',
        \ 'repository': '',
        \ 'commondir': '',
        \}
  let bufname = bufname(a:expr)
  let buftype = getbufvar(a:expr, '&buftype', '')

  " Use refname directly
  if bufname =~# '^giit:\%(//\)\?\zs[^:\\/]\+'
    let refname = matchstr(bufname, '^giit:\%(//\)\?\zs[^:\\/]\+')
    return {
          \ 'refname': refname,
          \ 'buftype': buftype,
          \ 'bufname': bufname,
          \ 'cwd': getcwd(),
          \}
  endif

  " Use filename of the buffer if the buffer is a file like buffer
  let path = giit#core#expand(a:expr)
  if empty(git.worktree)
    if index(['nofile', 'quickfix', 'help'], buftype) == -1
      let git = s:Git.get(path)
      let git = empty(git.worktree) && path !=# resolve(path)
            \ ? s:Git.get(resolve(path))
            \ : git
    endif
  endif

  " Use a current working directory
  let cwd = getcwd()
  if empty(git.worktree)
    let git = s:Git.get(cwd)
    let git = empty(git.worktree) && cwd !=# resolve(cwd)
          \ ? s:Git.get(resolve(cwd))
          \ : git
  endif

  " Build refname from git instance and cache
  if empty(git.worktree)
    let refname = ''
  else
    let refname = s:get_available_refname(
          \ fnamemodify(git.worktree, ':t'),
          \ git,
          \)
    let s:refs[refname] = git
  endif

  " Return refinfo
  return {
        \ 'refname': refname,
        \ 'buftype': buftype,
        \ 'bufname': empty(bufname) ? '' : s:Path.abspath(bufname),
        \ 'cwd': cwd,
        \}
endfunction

function! s:get_refinfo(expr) abort
  let bufname = bufname(a:expr)
  let buftype = getbufvar(a:expr, '&buftype', '')
  let refinfo = getbufvar(a:expr, 'giit_refinfo', {})
  let refname = matchstr(bufname, '^giit:\%(//\)\?\zs[^:\\/]\+')
  let cwd = getcwd()

  " Use cached refinfo in a giit pseudo buffer
  if !empty(refname) && !empty(refinfo)
    return refinfo
  endif

  " Use cached refinfo when the cache is fresh enough
  if empty(refname) && index(['nofile', 'quickfix', 'help'], buftype) == -1
    " File like
    if !empty(refinfo) && !empty(bufname) && s:Path.abspath(bufname) ==# refinfo.bufname
      return refinfo
    endif
  else
    if !empty(refinfo) && cwd ==# refinfo.cwd
      return refinfo
    endif
  endif

  " Create a new refinfo
  let refinfo = s:new_refinfo(a:expr)
  if bufexists(bufnr(a:expr))
    call setbufvar(a:expr, 'giit_refinfo', refinfo)
  endif
  return refinfo
endfunction
