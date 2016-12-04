let s:Path = vital#giit#import('System.Filepath')
let s:Cache = vital#giit#import('System.Cache.Memory')
let s:Git = vital#giit#import('Git')
let s:Console = vital#giit#import('Vim.Console')
let s:Exception = vital#giit#import('Vim.Exception')


if !exists('s:registry')
  " <worktree>: <instance>
  let s:registry = s:Cache.new()
endif
if !exists('s:reference')
  " <path or refname>: <worktree>
  let s:reference = s:Cache.new()
endif


" Public ---------------------------------------------------------------------
function! giit#core#get(...) abort
  let expr = get(a:000, 0, '%')
  return s:get_at(expr)
endfunction

function! giit#core#get_or_fail(...) abort
  let expr = get(a:000, 0, '%')
  let git = s:get_at(expr)
  if !empty(git)
    return git
  endif
  throw s:Exception.warn(printf(
        \ 'giit: No git repository for a buffer "%s" is found.',
        \ expand(expr)
        \))
endfunction


" Private --------------------------------------------------------------------
function! s:get_at(expr) abort
  let cached = s:get_cached_instance(a:expr)
  if cached isnot# v:null
    call s:Console.debug(printf(
          \ 'giit: A cached git instanse is used for %s', cached.refname
          \))
    return cached
  endif
  let pinfo = giit#component#parse_bufname(bufname(a:expr))
  if empty(pinfo)
    let git = {}
    let pinfo.path = expand(a:expr)
  else
    let git = s:get_from_cache(pinfo.refname)
  endif
  if empty(git) && s:is_file_buffer(a:expr)
    let git = s:get_from_bufname(pinfo.path)
  endif
  if empty(git)
    let git = s:get_from_cwd(bufnr(a:expr))
  endif
  call s:set_cached_instance(a:expr, git)
  return git
endfunction

function! s:is_file_buffer(expr) abort
  return getbufvar(a:expr, '&buftype', '') =~# '^\%(\|nowrite\|acwrite\)$'
endfunction

function! s:get_cached_instance(expr) abort
  let refinfo = getbufvar(a:expr, 'giit', {})
  if empty(refinfo)
    return v:null
  endif
  " Check if the refinfo is fresh enough
  if refinfo.bufname !=# simplify(bufname(a:expr))
    return v:null
  elseif refinfo.buftype !=# getbufvar(a:expr, '&buftype', '')
    return v:null
  elseif refinfo.cwd !=# simplify(getcwd())
    return v:null
  endif
  " refinfo is fresh enough, use a cached git instance
  return s:get_from_cache(refinfo.refname)
endfunction

function! s:set_cached_instance(expr, git) abort
  call setbufvar(a:expr, 'giit', {
        \ 'refname': a:git.refname,
        \ 'bufname': simplify(bufname(a:expr)),
        \ 'buftype': getbufvar(a:expr, '&buftype', ''),
        \ 'cwd': simplify(getcwd()),
        \})
endfunction

function! s:get_available_refname(refname, git) abort
  let refname = a:refname
  let pseudo = { 'worktree': a:git.worktree }
  let ref = s:reference.get(refname, pseudo)
  let index = 1
  while !empty(ref.worktree) && ref.worktree !=# a:git.worktree
    let refname = a:refname . '~' . index
    let ref = s:reference.get(refname, pseudo)
    let index += 1
  endwhile
  return refname
endfunction

function! s:get_from_cache(reference) abort
  if s:registry.has(a:reference)
    return s:registry.get(a:reference)
  elseif s:reference.has(a:reference)
    return s:registry.get(s:reference.get(a:reference), {})
  endif
  return {}
endfunction

function! s:get_from_path(path) abort
  " Try to find from a cache registry
  let path = simplify(fnamemodify(a:path, ':p'))
  let curr = path
  let prev = ''
  while prev !=# curr
    let git = s:get_from_cache(curr)
    if !empty(git)
      return git
    endif
    " Go up
    let prev = curr
    let curr = fnamemodify(curr, ':h')
  endwhile
  " Scan file system
  let git = s:Git.retrieve(path)
  if empty(git)
    return {}
  endif
  let git.refname = s:get_available_refname(
        \ fnamemodify(git.worktree, ':t'),
        \ git,
        \)
  call s:registry.set(git.worktree, git)
  call s:reference.set(path, git.worktree)
  call s:reference.set(git.refname, git.worktree)
  return git
endfunction

function! s:get_from_bufname(path) abort
  let git = s:get_from_path(a:path)
  if !empty(git)
    return git
  endif

  " Resolve symbol link
  let sympath = simplify(resolve(a:path))
  if sympath !=# a:path
    let git = s:get_from_path(sympath)
    if !empty(git)
      return git
    endif
  endif

  " Not found
  return {}
endfunction

function! s:get_from_cwd(bufnr) abort
  let winnr = bufwinnr(a:bufnr)
  let cwdpath = winnr == -1
        \ ? simplify(getcwd())
        \ : simplify(getcwd(winnr))
  return s:get_from_path(cwdpath)
endfunction
