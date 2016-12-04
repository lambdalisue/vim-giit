if exists('g:loaded_giit')
  finish
endif
let g:loaded_giit = 1

let s:is_windows = has('win16') || has('win32') || has('win64')
let s:Console = vital#giit#import('Vim.Console')
let s:Emitter = vital#giit#import('Emitter')
let s:Exception = vital#giit#import('Vim.Exception')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')


" Command --------------------------------------------------------------------
command! -nargs=* -bang -range
      \ -complete=customlist,giit#command#complete
      \ Giit
      \ call giit#command#execute(<q-bang>, [<line1>, <line2>], <q-args>)


" Exception ------------------------------------------------------------------
function! s:exception_handler(exception) abort
  let m = matchlist(
        \ a:exception,
        \ '^vital: Git\.Term: ValidationError: \(.*\)',
        \)
  if !empty(m)
    call s:Console.warn('giit: ' . m[1])
    return 1
  endif
  return 0
endfunction

call s:Exception.register(
      \ function('s:exception_handler')
      \)


" Console --------------------------------------------------------------------
function! s:console_is_batch() abort
  return g:giit#test
endfunction

function! s:console_is_debug() abort
  return g:giit#debug == -1 ? &verbose : g:giit#debug
endfunction

call s:Console.set_config({
      \ 'batch': function('s:console_is_batch'),
      \ 'debug': function('s:console_is_debug'),
      \})


" Observer -------------------------------------------------------------------
function! s:modified_listener(...) abort
  "call s:Exception.call(s:Observer.update, [], s:Observer)
  call s:Observer.update()
endfunction

call s:Emitter.subscribe('giit:modified', function('s:modified_listener'))


" Autocmd --------------------------------------------------------------------
function! s:on_BufWritePre() abort
  if empty(&buftype) && !empty(giit#core#get())
    let b:_giit_internal_modified = &modified
  endif
endfunction

function! s:on_BufWritePost() abort
  if exists('b:_giit_internal_modified')
    if b:_giit_internal_modified && !&modified
      call s:Emitter.emit('giit:modified')
    endif
    unlet b:_giit_internal_modified
  endif
endfunction

augroup giit-internal
  autocmd! *
  autocmd BufWritePre  * call s:on_BufWritePre()
  autocmd BufWritePost * nested call s:on_BufWritePost()
  autocmd BufReadCmd giit:* nested call giit#component#autocmd('BufReadCmd')
  " NOTE: autocmd for 'xxxxx:*' is triggered for 'xxxxx://' in Windows
  if !s:is_windows
    autocmd BufReadCmd giit:*/* nested call giit#component#autocmd('BufReadCmd')
  endif
augroup END
