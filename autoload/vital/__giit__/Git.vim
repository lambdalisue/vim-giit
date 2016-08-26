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

function! s:relpath(git, path) abort
  let path = s:Path.realpath(expand(a:path))
  if s:Path.is_relative(path)
    return path
  endif
  if empty(a:git.worktree)
    return s:Path.relpath(path)
  endif
  let prefix = s:String.escape_pattern(
        \ a:git.worktree . s:Path.separator()
        \)
  let rpath = resolve(path)
  return path =~# '^' . prefix
        \ ? matchstr(path, '^' . prefix . '\zs.*')
        \ : rpath =~# '^' . prefix
        \   ? matchstr(rpath, '^' . prefix . '\zs.*')
        \   : path
endfunction

function! s:abspath(git, path) abort
  let path = s:Path.realpath(a:path)
  if s:Path.is_absolute(path)
    return path
  endif
  if empty(a:git.worktree)
    return s:Path.abspath(path)
  endif
  return s:Path.join(a:git.worktree, path)
endfunction

function! s:readfile(git, path) abort
  let relpath = s:relpath(a:git, a:path)
  let path = s:Path.join(a:git.repository, relpath)
  let path = !filereadable(path) && !empty(a:git.commondir)
        \ ? s:Path.join(a:git.commondir, relpath)
        \ : path
  return filereadable(path) ? readfile(path) : []
endfunction

function! s:readline(git, path) abort
  return get(s:readfile(a:git, a:path), 0, '')
endfunction

function! s:filereadable(git, path) abort
  let relpath = s:relpath(a:git, a:path)
  let path = s:Path.join(a:git.repository, relpath)
  let path = !filereadable(path) && !empty(a:git.commondir)
        \ ? s:Path.join(a:git.commondir, relpath)
        \ : path
  return filereadable(path)
endfunction

function! s:isdirectory(git, path) abort
  let relpath = s:relpath(a:git, a:path)
  let path = s:Path.join(a:git.repository, relpath)
  let path = !isdirectory(path) && !empty(a:git.commondir)
        \ ? s:Path.join(a:git.commondir, relpath)
        \ : path
  return isdirectory(path)
endfunction

function! s:getftime(git, path) abort
  let relpath = s:relpath(a:git, a:path)
  let path = s:Path.join(a:git.repository, relpath)
  let path = !filereadable(path) && !isdirectory(path) && !empty(a:git.commondir)
        \ ? s:Path.join(a:git.commondir, relpath)
        \ : path
  return getftime(path)
endfunction

function! s:get_cached_content(git, slug, dependencies, ...) abort
  let dependencies = sort(filter(
        \ type(a:dependencies) != type([]) ? [a:dependencies] : copy(a:dependencies),
        \ 's:filereadable(a:git, v:val)',
        \))
  let cached = a:git.cache.get(a:slug . ':' . string(dependencies), {})
  if empty(cached)
    return get(a:000, 0)
  endif
  let uptimes = map(copy(dependencies), 's:getftime(a:git, v:val)')
  for index in range(len(uptimes))
    if uptimes[index] == -1 || uptimes[index] > cached.uptimes[index]
      return get(a:000, 0)
    endif
  endfor
  return cached.content
endfunction

function! s:set_cached_content(git, slug, dependencies, content) abort
  let dependencies = sort(filter(
        \ type(a:dependencies) != type([]) ? [a:dependencies] : copy(a:dependencies),
        \ 's:filereadable(a:git, v:val)',
        \))
  let uptimes = map(copy(dependencies), 's:getftime(a:git, v:val)')
  call a:git.cache.set(a:slug . ':' . string(dependencies), {
        \ 'uptimes': uptimes,
        \ 'content': a:content,
        \})
endfunction


function! s:_normalize(path) abort
  return simplify(s:Path.abspath(s:Path.realpath(a:path)))
endfunction

function! s:_fnamemodify(path, mods) abort
  if empty(a:path)
    return ''
  endif
  return s:Path.remove_last_separator(fnamemodify(a:path, a:mods))
endfunction

function! s:_find_worktree(dirpath) abort
  let dgit = s:_fnamemodify(finddir('.git',  fnameescape(a:dirpath) . ';'), ':p:h')
  let fgit = s:_fnamemodify(findfile('.git', fnameescape(a:dirpath) . ';'), ':p')
  " use deepest dotgit found
  let dotgit = strlen(dgit) >= strlen(fgit) ? dgit : fgit
  return strlen(dotgit) ? s:_fnamemodify(dotgit, ':h') : ''
endfunction

function! s:_find_repository(worktree) abort
  let dotgit = s:Path.join([s:_fnamemodify(a:worktree, ':p'), '.git'])
  if isdirectory(dotgit)
    return dotgit
  elseif filereadable(dotgit)
    " in case if the found '.git' is a file which was created via
    " '--separate-git-dir' option
    let lines = readfile(dotgit)
    if !empty(lines)
      let gitdir = matchstr(lines[0], '^gitdir:\s*\zs.\+$')
      let is_abs = s:Path.is_absolute(gitdir)
      return s:_fnamemodify((is_abs ? gitdir : dotgit[:-5] . gitdir), ':p:h')
    endif
  endif
  return ''
endfunction

function! s:_find(path) abort
  let path = s:_normalize(a:path)
  let dirpath = isdirectory(path) ? path : fnamemodify(path, ':h')
  let worktree = s:_find_worktree(dirpath)
  let repository = len(worktree) ? s:_find_repository(worktree) : ''
  let meta = {
        \ 'worktree': simplify(s:Path.realpath(resolve(worktree))),
        \ 'repository': simplify(s:Path.realpath(resolve(repository))),
        \ 'commondir': '',
        \}
  " Check if the repository is a pseudo repository or original one
  if !empty(repository) && filereadable(s:Path.join(repository, 'commondir'))
    let commondir = readfile(s:Path.join(repository, 'commondir'))[0]
    let meta.commondir = simplify(s:Path.join(repository, commondir))
  endif
  return meta
endfunction

function! s:_new(meta) abort
  let git = deepcopy(a:meta)
  let git.cache = s:Cache.new()
  lockvar git.worktree
  lockvar git.repository
  lockvar git.commondir
  return git
endfunction
