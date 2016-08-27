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

" Repo instance---------------------------------------------------------------
let s:repo = {}

function! s:repo.expand(relpath) abort
  let relpath = s:Path.realpath(a:relpath)
  if s:Path.is_absolute(relpath)
    throw printf(
          \ 'vital: Git: repo.expand(): It requires a relative path but "%s" has specified',
          \ a:relpath,
          \)
  endif
  let path1 = s:Path.join(self.__owner__.repository, relpath)
  let path2 = empty(self.__owner__.commondir)
        \ ? ''
        \ : s:Path.join(self.__owner__.commondir, relpath)
  return filereadable(path1) || isdirectory(path1)
        \ ? path1
        \ : filereadable(path2) || isdirectory(path2) ? path2 : path1
endfunction

function! s:repo.readfile(relpath) abort
  let path = self.expand(a:relpath)
  return filereadable(path) ? readfile(path) : []
endfunction

function! s:repo.readline(relpath) abort
  return get(self.readfile(a:relpath), 0, '')
endfunction

function! s:repo.filereadable(relpath) abort
  let path = self.expand(a:relpath)
  return filereadable(path)
endfunction

function! s:repo.isdirectory(relpath) abort
  let path = self.expand(a:relpath)
  return isdirectory(path)
endfunction

function! s:repo.getftime(relpath) abort
  let path = self.expand(a:relpath)
  return getftime(path)
endfunction

" Git instance ---------------------------------------------------------------
let s:git = {}

function! s:git.relpath(abspath) abort
  let abspath = s:Path.realpath(expand(a:abspath))
  if s:Path.is_relative(abspath)
    throw printf(
          \ 'vital: Git: git.relpath(): It requires a relative path but "%s" has specified',
          \ a:abspath,
          \)
  endif
  let prefix = s:String.escape_pattern(
        \ self.worktree . s:Path.separator()
        \)
  if abspath !~# '^' . prefix
    throw printf(
          \ 'vital: Git: git.relpath(): A path "%s" does not belongs to a git working tree "%s"',
          \ a:abspath,
          \ self.worktree,
          \)
  endif
  return matchstr(abspath, '^' . prefix . '\zs.*')
endfunction

function! s:git.abspath(relpath) abort
  let relpath = s:Path.realpath(a:relpath)
  if s:Path.is_absolute(relpath)
    throw printf(
          \ 'vital: Git: git.abspath(): It requires an absolute path but "%s" has specified',
          \ a:relpath,
          \)
  endif
  return s:Path.join(self.worktree, relpath)
endfunction

function! s:git.get_cached_content(slug, dependencies, ...) abort
  let dependencies = sort(filter(
        \ type(a:dependencies) != type([]) ? [a:dependencies] : copy(a:dependencies),
        \ 'self.repo.filereadable(v:val)',
        \))
  let cached = self.cache.get(a:slug . ':' . string(dependencies), {})
  if empty(cached)
    return get(a:000, 0)
  endif
  let uptimes = map(copy(dependencies), 'self.repo.getftime(v:val)')
  for index in range(len(uptimes))
    if uptimes[index] == -1 || uptimes[index] > cached.uptimes[index]
      return get(a:000, 0)
    endif
  endfor
  return cached.content
endfunction

function! s:git.set_cached_content(slug, dependencies, content) abort
  let dependencies = sort(filter(
        \ type(a:dependencies) != type([]) ? [a:dependencies] : copy(a:dependencies),
        \ 'self.repo.filereadable(v:val)',
        \))
  let uptimes = map(copy(dependencies), 'self.repo.getftime(v:val)')
  call self.cache.set(a:slug . ':' . string(dependencies), {
        \ 'uptimes': uptimes,
        \ 'content': a:content,
        \})
endfunction


" Public ---------------------------------------------------------------------
function! s:get(path) abort
  let path = s:_normalize(a:path)
  let uptime = getftime(path)
  let cached = s:registry.get(path, {})
  if empty(cached) || uptime == -1 || uptime > cached.uptime
    let meta = s:_find(path)
    if empty(meta.worktree)
      let git = s:_new(meta)
      call s:registry.set(path, {
            \ 'uptime': uptime,
            \ 'git': git,
            \})
      return git
    else
      let uptime = getftime(meta.worktree)
      let cached = s:registry.get(meta.worktree, {})
      if empty(cached) || uptime == -1 || uptime > cached.uptime
        let git = s:_new(meta)
        call s:registry.set(path, {
              \ 'uptime': uptime,
              \ 'git': git,
              \})
        call s:registry.set(meta.worktree, {
              \ 'uptime': uptime,
              \ 'git': git,
              \})
        return git
      else
        call s:registry.set(path, {
              \ 'uptime': uptime,
              \ 'git': cached.git,
              \})
        return cached.git
      endif
    endif
  else
    return cached.git
  endif
endfunction

function! s:clear(path) abort
  let path = s:_normalize(a:path)
  let cached = s:registry.get(path)
  let root = empty(cached)
        \ ? path
        \ : empty(cached.git.worktree)
        \   ? path
        \   : cached.git.worktree
  let keys = filter(
        \ copy(s:registry.keys()),
        \ printf('v:val =~# ''^%s''', s:String.escape_pattern(root))
        \)
  for key in keys
    call s:registry.remove(key)
  endfor
endfunction


" Private --------------------------------------------------------------------
function! s:_normalize(path) abort
  return simplify(s:Path.abspath(s:Path.realpath(a:path)))
endfunction

function! s:_fnamemodify(path, mods) abort
  if empty(a:path)
    return ''
  endif
  return s:Path.remove_last_separator(fnamemodify(a:path, a:mods))
endfunction

function! s:_find(dirpath) abort
  let meta = {
        \ 'worktree': '',
        \ 'repository': '',
        \ 'commondir': '',
        \}
  " Find a worktree from an absolute directory path {dirpath}
  let dgit = s:_fnamemodify(finddir('.git',  fnameescape(a:dirpath) . ';'), ':p:h')
  let fgit = s:_fnamemodify(findfile('.git', fnameescape(a:dirpath) . ';'), ':p')
  " Use deepest dotgit found
  let dotgit = strlen(dgit) >= strlen(fgit) ? dgit : fgit
  let meta.worktree = simplify(strlen(dotgit) ? s:_fnamemodify(dotgit, ':h') : '')
  if empty(meta.worktree)
    return meta
  endif
  " Find a dot git directory
  let meta.repository = s:Path.join(meta.worktree, '.git')
  if filereadable(meta.repository)
    " A '.git' may be a file which was created by '--separate-git-dir' option
    let lines = readfile(meta.repository)
    if empty(lines)
      throw printf(
            \ 'vital: Git: An invalid .git file has found at "%s".',
            \ meta.repository,
            \)
    endif
    let gitdir = matchstr(lines[0], '^gitdir:\s*\zs.\+$')
    let is_abs = s:Path.is_absolute(gitdir)
    let meta.repository = simplify(s:_fnamemodify(
          \ (is_abs ? gitdir : meta.repository[:-5] . gitdir),
          \ ':p:h'
          \))
  endif
  " Check if the repository found is a linked or an original
  if filereadable(s:Path.join(meta.repository, 'commondir'))
    let commondir = readfile(s:Path.join(meta.repository, 'commondir'))[0]
    let meta.commondir = simplify(s:Path.join(meta.repository, commondir))
  endif
  return meta
endfunction

function! s:_new(meta) abort
  if empty(a:meta.worktree)
    return {}
  endif
  let git = extend(deepcopy(a:meta), s:git)
  let git.repo = extend({'__owner__': git}, s:repo)
  let git.cache = s:Cache.new()
  lockvar git.worktree
  lockvar git.repository
  lockvar git.commondir
  return git
endfunction
