function! s:_vital_loaded(V) abort
  let s:Path = a:V.import('System.Filepath')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'System.Filepath',
        \]
endfunction


" Bind instance --------------------------------------------------------------
function! s:bind(git) abort
  if has_key(a:git, 'core')
    return a:git
  endif
  let methods = [
        \ 'expand',
        \ 'writefile',
        \ 'readfile',
        \ 'readline',
        \ 'filereadable',
        \ 'isdirectory',
        \ 'getftime',
        \ 'get_cached_content',
        \ 'set_cached_content',
        \]
  let a:git.core = {}
  for method in methods
    let a:git.core[method] = function('s:' . method, [a:git])
  endfor
  lockvar a:git.core
  return a:git
endfunction


" Public ---------------------------------------------------------------------
function! s:expand(git, relpath) abort
  let relpath = s:Path.realpath(s:_expand(a:relpath))
  if s:Path.is_absolute(relpath)
    throw printf(
          \ 'vital: Git.Core.expand(): It requires a relative path but "%s" has specified',
          \ a:relpath,
          \)
  endif
  let path1 = s:Path.join(a:git.repository, relpath)
  let path2 = empty(a:git.commondir)
        \ ? ''
        \ : s:Path.join(a:git.commondir, relpath)
  return filereadable(path1) || isdirectory(path1)
        \ ? path1
        \ : filereadable(path2) || isdirectory(path2) ? path2 : path1
endfunction

function! s:writefile(git, content, relpath, ...) abort
  let flags = get(a:000, 0, '')
  let path = s:expand(a:git, a:relpath)
  if filewritable(path)
    call writefile(a:content, path, flags)
    return 1
  endif
  return 0
endfunction

function! s:readfile(git, relpath) abort
  let path = s:expand(a:git, a:relpath)
  return filereadable(path) ? readfile(path) : []
endfunction

function! s:readline(git, relpath) abort
  return get(s:readfile(a:git, a:relpath), 0, '')
endfunction

function! s:filereadable(git, relpath) abort
  let path = s:expand(a:git, a:relpath)
  return filereadable(path)
endfunction

function! s:isdirectory(git, relpath) abort
  let path = s:expand(a:git, a:relpath)
  return isdirectory(path)
endfunction

function! s:getftime(git, relpath) abort
  let path = s:expand(a:git, a:relpath)
  return getftime(path)
endfunction

function! s:set_cached_content(git, name, depends, content) abort
  let depends = type(a:depends) == type([]) ? a:depends : [a:depends]
  call sort(filter(
        \ map(depends, 's:Path.realpath(v:val)'),
        \ 's:filereadable(a:git, v:val)',
        \))
  let uptimes = map(copy(depends), 's:getftime(a:git, v:val)')
  call a:git.cache.set(a:name . ':' . string(depends), {
        \ 'uptimes': uptimes,
        \ 'content': a:content,
        \})
endfunction

function! s:get_cached_content(git, name, depends, ...) abort
  let depends = type(a:depends) == type([]) ? a:depends : [a:depends]
  let default = a:0 > 0 ? a:1 : {}
  call sort(filter(
        \ map(depends, 's:Path.realpath(v:val)'),
        \ 's:filereadable(a:git, v:val)',
        \))
  let cached = a:git.cache.get(a:name . ':' . string(depends), {})
  if empty(cached)
    return default
  endif
  for index in range(len(depends))
    let uptime = s:getftime(a:git, depends[index])
    if uptime == -1 || uptime > cached.uptimes[index]
      return default
    endif
  endfor
  return cached.content
endfunction

" Private --------------------------------------------------------------------
function! s:_expand(path) abort
  return expand(escape(a:path, '\'))
endfunction
