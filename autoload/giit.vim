let s:Path = vital#giit#import('System.Filepath')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Exception = vital#giit#import('Vim.Exception')
let s:BufferObserver = vital#giit#import('Vim.Buffer.Observer')


function! giit#define_variables(prefix, defaults) abort
  let prefix = empty(a:prefix) ? 'g:giit' : 'g:giit#' . a:prefix
  for [key, value] in items(a:defaults)
    let name = prefix . '#' . key
    if !exists(name)
      execute 'let ' . name . ' = ' . string(value)
    endif
    unlet value
  endfor
endfunction

function! giit#trigger_modified() abort
  call giit#util#doautocmd('User', 'GiitModifiedPre')
  call giit#util#doautocmd('User', 'GiitModifiedPost')
endfunction

function! giit#expand(expr) abort
  if empty(a:expr)
    return ''
  endif
  let git = giit#core#get()
  let path = giit#meta#get_at(a:expr, 'filename', expand(a:expr))
  let path = empty(git) ? s:Path.abspath(path) : git.abspath(path)
  return s:Path.remove_last_separator(path)
endfunction


" Default variable -----------------------------------------------------------
call giit#define_variables('', {
      \ 'test': 0,
      \ 'debug': -1,
      \ 'complete_threshold': 30,
      \})


" Autocmd --------------------------------------------------------------------
augroup giit_internal
  autocmd! *
  autocmd User GiitModifiedPost nested call s:BufferObserver.update_all()
augroup END


" Exception ------------------------------------------------------------------
function! s:exception_handler(exception) abort
  let m = matchlist(
        \ a:exception,
        \ '^vital: Git\.Term: ValidationError: \(.*\)',
        \)
  if !empty(m)
    call s:Prompt.warn('giit: ' . m[1])
    return 1
  endif
  return 0
endfunction
call s:Exception.register(
      \ function('s:exception_handler')
      \)

" Prompt ---------------------------------------------------------------------
function! s:prompt_is_batch() abort
  return g:giit#test
endfunction
function! s:prompt_is_debug() abort
  return g:giit#debug == -1 ? &verbose : g:giit#debug
endfunction
call s:Prompt.set_config({
      \ 'batch': function('s:prompt_is_batch'),
      \ 'debug': function('s:prompt_is_debug'),
      \})
