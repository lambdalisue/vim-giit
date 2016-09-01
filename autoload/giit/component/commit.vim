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

  let uptime1 = git.core.getftime('COMMIT_EDITMSG')
  let uptime2 = git.core.getftime('index')
  if uptime1 < uptime2 || v:cmdbang
    let args = giit#meta#get('args', s:Argument.new())
    let content = giit#operation#commit#cleanup(
          \ git.cache.get('WORKING_COMMIT_EDITMSG', []),
          \ args.get('--cleanup', 'strip')
          \)
    call args.set('-e|--edit', 1)
    call args.set('-m|--message', join(content, "\n"))
    let result = giit#operation#commit#execute(git, args)
    let result.status = !result.status
    if result.status
      call giit#operation#throw(result)
    endif
    call giit#meta#set('args', args)
  endif
  call s:init()
  call s:Buffer.edit_content(git.core.readfile('COMMIT_EDITMSG'))
  setlocal filetype=gitcommit
endfunction

function! s:on_BufWriteCmd() abort
  let git = giit#core#get_or_fail()
  let content = getline(1, '$')
  call git.cache.set('WORKING_COMMIT_EDITMSG', content)
  call git.core.writefile(content, 'COMMIT_EDITMSG')
  setlocal nomodified
endfunction

function! s:on_BufWinLeave() abort
  echomsg 'commit: BufWinLeave'
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
    autocmd BufWriteCmd <buffer> call s:on_BufWriteCmd()
    autocmd BufWinLeave <buffer> call s:on_BufWinLeave()
  augroup END

  setlocal buftype=acwrite nobuflisted
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
