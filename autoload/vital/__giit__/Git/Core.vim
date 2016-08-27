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
        \ 'readfile',
        \ 'readline',
        \ 'filereadable',
        \ 'isdirectory',
        \ 'getftime',
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


" Private --------------------------------------------------------------------
function! s:_expand(path) abort
  return expand(escape(a:path, '\'))
endfunction
