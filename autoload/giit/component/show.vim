let s:Buffer = vital#giit#import('Vim.Buffer')
let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#show#autocmd(event) abort
  if !exists('*s:on_' . a:event)
    throw s:Exception.critical(printf(
          \ 'giit: No autocmd "%s" is found on "show" component',
          \ a:event,
          \))
  endif
  let bufname = expand('<afile>')
  let object = matchstr(bufname, '^giit://.*:show\%(:patch\)\?/\zs.*$')
  let patch  = bufname =~# '^giit://.*:show:patch/'
  return call('s:on_' . a:event, [object, patch])
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd(object, patch) abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = giit#meta#get('args', s:Argument.new())
  call args.set_p(0, 'show')
  call args.set_p(1, a:object)
  let result = giit#operation#show#execute(git, args)
  if result.status
    call giit#operation#throw(result)
  endif
  call s:Buffer.edit_content(result.content)
  call giit#meta#set('args', args)
  call giit#meta#set('commit', matchstr(a:object, '^[^:]*\ze'))
  call giit#meta#set('filename', matchstr(a:object, '^[^:]*:\zs.*'))
  call giit#util#doautocmd('BufRead')
  call s:init(a:object, a:patch)
endfunction


" private --------------------------------------------------------------------
function! s:init(object, patch) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  if a:patch
    augroup giit-internal-component-show
      "autocmd BufWriteCmd <buffer> call s:on_BufWriteCmd()
    augroup END
    setlocal buftype=acwrite
    setlocal modifiable
  else
    setlocal buftype=nowrite
    setlocal nomodifiable
  endif
endfunction

function! s:exception_handler(exception) abort
  augroup giit-internal-component-show
    autocmd! * <buffer>
  augroup END
  setlocal buftype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction
