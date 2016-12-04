let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Exception = vital#giit#import('Vim.Exception')
let s:GitTerm = vital#giit#import('Git.Term')


" Entry point ----------------------------------------------------------------
function! giit#component#diff#BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = giit#meta#get_or_fail('args')
  let result = giit#operator#diff#execute(git, args)
  if result.status
    throw giit#process#error(result)
  endif

  call s:init(args)
  call s:Buffer.edit_content(result.content)
  call giit#util#vim#doautocmd('BufRead')
  setlocal filetype=diff
endfunction


" private --------------------------------------------------------------------
function! s:init(args) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  if a:args.get('-p|--patch')
    augroup giit-internal-component-diff
      "autocmd BufWriteCmd <buffer> call s:on_BufWriteCmd()
    augroup END
    setlocal bufhidden=
    setlocal buftype=acwrite
    setlocal modifiable
  else
    setlocal bufhidden=delete
    setlocal buftype=nowrite
    setlocal nomodifiable
  endif
endfunction

function! s:exception_handler(exception) abort
  augroup giit-internal-component-diff
    autocmd! * <buffer>
  augroup END
  setlocal buftype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction
