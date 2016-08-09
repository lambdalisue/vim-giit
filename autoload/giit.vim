let s:Prompt = vital#giit#import('Vim.Prompt')
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

function! giit#throw(msg) abort
  throw printf('giit: %s', a:msg)
endfunction

function! giit#handle_exception() abort
  call s:Prompt.error(v:exception)
  call s:Prompt.debug(v:throwpoint)
endfunction


call giit#define_variables('', {
      \ 'test': 0,
      \ 'complete_threshold': 30,
      \})
call s:Prompt.set_config({
      \ 'batch': g:giit#test,
      \})

" Automatically start observation when it's sourced
augroup giit_internal
  autocmd! *
  autocmd User GiitModifiedPost nested call s:BufferObserver.update_all()
augroup END
