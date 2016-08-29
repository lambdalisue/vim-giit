let s:Path = vital#giit#import('System.Filepath')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Exception = vita#giit#import('Vim.Exception')
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
  let path = giit#meta#get_at(a:expr, 'filename', '')
  if empty(path)
    let path = expand(a:expr)
  endif
  return s:Path.remove_last_separator(path)
endfunction


call giit#define_variables('', {
      \ 'test': 0,
      \ 'complete_threshold': 30,
      \})
call s:Prompt.set_config({
      \ 'batch': g:giit#test,
      \})
call s:Exception.register(
      \ giit#exception#define(),
      \)

" Automatically start observation when it's sourced
augroup giit_internal
  autocmd! *
  autocmd User GiitModifiedPost nested call s:BufferObserver.update_all()
augroup END
