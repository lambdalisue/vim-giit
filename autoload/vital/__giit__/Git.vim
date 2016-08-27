function! s:_vital_loaded(V) abort
  let s:String = a:V.import('Data.String')
  let s:Path = a:V.import('System.Filepath')
  let s:Cache = a:V.import('System.Cache.Memory')
  let s:registry = s:Cache.new()
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Data.String',
        \ 'System.Filepath',
        \ 'System.Cache.Memory',
        \]
endfunction


" Public ---------------------------------------------------------------------
function! s:get(path) abort
  let dirpath = s:_normalize(a:path)
  if s:registry.has(dirpath)
    return s:registry.get(dirpath)
  endif
  " Find a repository meta
  let meta = s:_retrieve(dirpath)
  " Get or create a git instance from meta
  if empty(meta)
    let git = {}
  elseif s:registry.has(meta.worktree)
    let git = s:registry.get(meta.worktree)
  else
    let git = s:_new(meta)
    call s:registry.set(meta.worktree, git)
  endif
  call s:registry.set(dirpath, git)
  return git
endfunction

function! s:expire(...) abort
  let git = get(a:000, 0)
  if type(git) == type(0)
    call s:registry.clear()
    return
  endif
  let pattern = s:String.escape_pattern(
        \ git.worktree . s:Path.separator()
        \)
  for key in s:registry.keys()
    if key =~# '^' . pattern
      call s:registry.remove(key)
    endif
  endfor
  call s:registry.remove(git.worktree)
endfunction

function! s:relpath(git, abspath) abort
  let abspath = s:Path.realpath(expand(a:abspath))
  if s:Path.is_relative(abspath)
    return abspath
  endif
  let pattern = s:String.escape_pattern(a:git.worktree . s:Path.separator())
  return abspath =~# '^' . pattern
        \ ? matchstr(abspath, '^' . pattern . '\zs.*')
        \ : abspath
endfunction

function! s:abspath(git, relpath) abort
  let relpath = s:Path.realpath(expand(a:relpath))
  if s:Path.is_absolute(relpath)
    return relpath
  endif
  return s:Path.join(a:git.worktree, relpath)
endfunction


" Private --------------------------------------------------------------------
function! s:_normalize(path) abort
  let path = expand(a:path)
  let dirpath = isdirectory(path) ? path : fnamemodify(path, ':p:h')
  return simplify(s:Path.abspath(s:Path.realpath(path)))
endfunction

function! s:_retrieve(path) abort
  let dirpath = s:_normalize(a:path)

  " Find worktree
  let dgit = finddir('.git', fnameescape(dirpath) . ';')
  let dgit = empty(dgit) ? '' : fnamemodify(dgit, ':p:h')
  let fgit = findfile('.git', fnameescape(dirpath) . ';')
  let fgit = empty(fgit) ? '' : fnamemodify(fgit, ':p')
  let worktree = len(dgit) > len(fgit) ? dgit : fgit
  let worktree = empty(worktree) ? '' : fnamemodify(worktree, ':h')
  if empty(worktree)
    return {}
  endif

  " Find repository
  let repository = s:Path.join(worktree, '.git')
  if filereadable(repository)
    " A '.git' may be a file which was created by '--separate-git-dir' option
    let lines = readfile(repository)
    if empty(lines)
      throw printf(
            \ 'vital: Git: An invalid .git file has found at "%s".',
            \ repository,
            \)
    endif
    let gitdir = matchstr(lines[0], '^gitdir:\s*\zs.\+$')
    let is_abs = s:Path.is_absolute(gitdir)
    let repository = is_abs ? gitdir : repository[:-5] . gitdir
    let repository = empty(repository) ? '' : fnamemodify(repository, ':p:h')
  endif

  " Find commondir
  let commondir = ''
  if filereadable(s:Path.join(repository, 'commondir'))
    let commondir = readfile(s:Path.join(repository, 'commondir'))[0]
    let commondir = s:Path.join(repository, commondir)
  endif

  return {
        \ 'worktree': simplify(worktree),
        \ 'repository': simplify(repository),
        \ 'commondir': simplify(commondir),
        \}
endfunction

function! s:_new(meta) abort
  let git = copy(a:meta)
  let git.cache = s:Cache.new()
  let git.expire = function('s:expire', [git])
  let git.relpath = function('s:relpath', [git])
  let git.abspath = function('s:abspath', [git])
  lockvar git.worktree
  lockvar git.repository
  lockvar git.commondir
  lockvar 1 git.cache
  lockvar git.expire
  lockvar git.relpath
  lockvar git.abspath
  return git
endfunction
