let s:Config = vital#giit#import('Data.Dict.Config')
let s:Git = vital#giit#import('Git')
let s:Path = vital#giit#import('System.Filepath')


" Public ---------------------------------------------------------------------
function! giit#expand(expr) abort
  if empty(a:expr)
    return ''
  endif
  let git = giit#core#get()
  let path = expand(a:expr)
  let pinfo = giit#component#parse_bufname(bufname(a:expr))
  if empty(git) || empty(pinfo)
    return simplify(s:Path.abspath(path))
  endif
  return simplify(s:Git.abspath(git, pinfo.path))
endfunction


" Default variable -----------------------------------------------------------
call s:Config.define('giit', {
      \ 'test': 0,
      \ 'debug': -1,
      \ 'develop': 1,
      \ 'complete_threshold': 30,
      \})
