let s:Path = vital#giit#import('System.Filepath')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Config = vital#giit#import('Data.Dict.Config')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#expand(expr) abort
  if empty(a:expr)
    return ''
  endif
  let git = giit#core#get()
  let path = giit#meta#get_at(a:expr, 'filename', expand(a:expr))
  return s:Path.remove_last_separator(path)
endfunction

function! giit#trigger_modified() abort
  call giit#util#doautocmd('User', 'GiitModifiedPre')
  call giit#util#doautocmd('User', 'GiitModifiedPost')
endfunction

function! giit#command(bang, range, qargs) abort
  let scheme = matchstr(a:qargs,  '^\w\+')
  return s:Exception.call(
        \ function('giit#scheme#call'),
        \ [
        \   scheme,
        \   'operation#{}#command',
        \   [a:bang, a:range, a:qargs]
        \ ],
        \)
endfunction

function! giit#execute(git, args) abort
  let scheme = a:args.get_p(0, '')
  return s:Exception.call(
        \ function('giit#scheme#call'),
        \ [
        \   scheme,
        \   'operation#{}#execute',
        \   [a:git, a:args]
        \ ],
        \)
endfunction

function! giit#complete(git, args) abort
  let scheme = a:args.get_p(0, '')
  return s:Exception.call(
        \ function('giit#scheme#call'),
        \ [
        \   scheme,
        \   'operation#{}#execute',
        \   [a:git, a:args]
        \ ],
        \)
endfunction



" Default variable -----------------------------------------------------------
call s:Config.define('giit', {
      \ 'test': 0,
      \ 'debug': -1,
      \ 'develop': 1,
      \ 'complete_threshold': 30,
      \})


" Autocmd --------------------------------------------------------------------
augroup giit_internal
  autocmd! *
  autocmd User GiitModifiedPost nested call s:Observer.update_all()
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
