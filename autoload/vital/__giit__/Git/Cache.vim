function! s:_vital_loaded(V) abort
  let s:Path = a:V.import('System.Filepath')
  let s:Cache = a:V.import('System.Cache.Memory')
  let s:GitRepository = a:V.import('Git.Repository')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'System.Filepath',
        \ 'System.Cache.Memory',
        \ 'Git.Repository',
        \]
endfunction


" Public ---------------------------------------------------------------------
function! s:get_slug_expr() abort
  return 'matchstr(expand(''<sfile>''), ''\zs[^. ]\+$'')'
endfunction

function! s:get_cache(git) abort
  if !has_key(a:git, 'cache')
    let a:git.cache = s:Cache.new()
    lockvar 1 a:git.cache
  endif
  return a:git.cache
endfunction

function! s:get_cached_content(git, name, depends, ...) abort
  let cache = s:get_cache(a:git)
  let depends = type(a:depends) == type([]) ? a:depends : [a:depends]
  let default = a:0 > 0 ? a:1 : {}
  call sort(filter(
        \ map(depends, 's:Path.realpath(v:val)'),
        \ 's:GitRepository.filereadable(a:git, v:val)',
        \))
  let cached = cache.get(a:name . ':' . string(depends), {})
  if empty(cached)
    return default
  endif
  for index in range(len(depends))
    let uptime = s:GitRepository.getftime(a:git, depends[index])
    if uptime == -1 || uptime > cached.uptimes[index]
      return default
    endif
  endfor
  return cached.content
endfunction

function! s:set_cached_content(git, name, depends, content) abort
  let cache = s:get_cache(a:git)
  let depends = type(a:depends) == type([]) ? a:depends : [a:depends]
  call sort(filter(
        \ map(depends, 's:Path.realpath(v:val)'),
        \ 's:GitRepository.filereadable(a:git, v:val)',
        \))
  let uptimes = map(copy(depends), 's:GitRepository.getftime(a:git, v:val)')
  call cache.set(a:name . ':' . string(depends), {
        \ 'uptimes': uptimes,
        \ 'content': a:content,
        \})
endfunction
