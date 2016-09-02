let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#diff#autocmd(event) abort
  return call('s:on_' . a:event, [])
endfunction



" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = s:adjust(git, expand('<afile>'))
  let result = giit#operation#diff#execute(git, args)
  if result.status
    call giit#operation#throw(result)
  endif
  call giit#meta#set('args', args)
  call giit#meta#set('commit', args.options.commit)
  call giit#meta#set('filename', args.options.filename)
  call s:init(args)
  call s:Buffer.edit_content(result.content)
  call giit#util#doautocmd('BufRead')
  " overwrite filetype
  setlocal filetype=diff
endfunction


" private --------------------------------------------------------------------
function! s:adjust(git, bufname) abort
  let extra  = matchstr(a:bufname, '^giit://[^:]\+:[^:]\+:\zs[^/]\+')
  let object = matchstr(a:bufname, '^giit://[^:]\+:[^/]\+/\zs.*$')
  let [commit, filename] = giit#component#split_object(object)

  let args = giit#meta#get('args', s:Argument.new())
  let args.options = get(args, 'options', {})
  let args.options.patch  = extra =~# '\<patch\>'
  let args.options.cached = extra =~# '\<cached\>'
  let args.options.commit = commit
  let args.options.filename = a:git.abspath(filename)
  return args.lock()
endfunction

function! s:init(args) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  if a:args.options.patch
    augroup giit-internal-component-diff
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
  augroup giit-internal-component-diff
    autocmd! * <buffer>
  augroup END
  setlocal buftype&
  setlocal filetype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction
