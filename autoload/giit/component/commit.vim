let s:Path = vital#giit#import('System.Filepath')
let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#commit#autocmd(event) abort
  return call('s:on_' . a:event, [])
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = giit#meta#get('args', s:Argument.new())
  call args.set_p(0, 'commit')
  call args.set('-e|--edit', 1)
  let result = giit#operation#status#execute(git, args)
  let result.status = !result.status
  if result.status
    call giit#operation#throw(result)
  endif
  call giit#meta#set('args', args)
  call s:init()

  call s:Buffer.edit_content(git.core.readfile('COMMIT_EDITMSG'))
  call giit#util#doautocmd('BufRead')
endfunction


" private --------------------------------------------------------------------
function! s:init() abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  " Attach modules
  call s:Anchor.attach()
  call s:Observer.attach()

  " Register autocmd
  augroup giit-internal-component-commit
    autocmd! * <buffer>
    "autocmd BufWipeout <buffer> call s:on_BufWipeout()
  augroup END


  setlocal buftype=nowrite nobuflisted
  setlocal filetype=gitcommit
endfunction

function! s:exception_handler(exception) abort
  setlocal buftype&
  setlocal filetype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction

function! s:commit(git, options) abort
  "let options = s:Dict.omit(a:options, [
  "      \ 'patch',
  "      \ 'reuse-message',
  "      \ 'reedit-message',
  "      \ 'file',
  "      \ 'message',
  "      \ 'edit',
  "      \ 'no-edit',
  "      \])
  "let options.file = s:Path.join(a:git.repository, 'COMMIT_EDITMSG')
  "let options.cleanup = get(options, 'cleanup', 'strip')
  "let result = giit#operation#commit#execute(a:git, options)
  "call giit#operation#inform(result, a:options)
endfunction
