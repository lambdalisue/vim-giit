let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#show#autocmd(event) abort
  return call('s:on_' . a:event, [])
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let bufinfo = s:build_bufinfo(git, expand('<afile>'))
  let content = s:execute_command(git, bufinfo)

  call giit#meta#set('commit', bufinfo.commit)
  call giit#meta#set('filename', git.abspath(bufinfo.filename))

  call s:init(bufinfo)
  call s:Buffer.edit_content(content)
  call giit#util#doautocmd('BufRead')
endfunction


" private --------------------------------------------------------------------
function! s:build_bufinfo(git, bufname) abort
  let extra  = matchstr(a:bufname, '^giit://[^:]\+:[^:]\+:\zs[^/]\+')
  let object = matchstr(a:bufname, '^giit://[^:]\+:[^/]\+/\zs.*$')
  let [commit, filename] = giit#component#split_object(object)
  let bufinfo = {}
  let bufinfo.patch  = extra =~# '\<patch\>'
  let bufinfo.commit = commit
  let bufinfo.filename = filename
  return bufinfo
endfunction

function! s:execute_command(git, bufinfo) abort
  let args = giit#meta#get('args', s:Argument.new())
  let raws = giit#util#collapse([
        \ 'show',
        \ giit#component#build_object(
        \   a:bufinfo.commit,
        \   a:bufinfo.filename,
        \ ),
        \ args.raw,
        \])
  let result = a:git.execute(raws, {
        \ 'encode_output': 0,
        \})
  if result.status
    call giit#operation#throw(result)
  endif
  return result.content
endfunction

function! s:init(info) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  if a:info.patch
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
