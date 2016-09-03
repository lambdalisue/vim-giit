let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


" Entry point ----------------------------------------------------------------
function! giit#component#diff#autocmd(event) abort
  return call('s:on_' . a:event, [])
endfunction


function! giit#component#diff#bufname(git, args) abort
  let bufname = giit#component#common#bufname(a:git, a:args)
  let bufname = substitute(bufname, '^giit:', 'giit://', '')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ a:args.get('-p|--patch') ? ':patch' : '',
        \ giit#operator#build_object(
        \   a:args.get_p(1, ''),
        \   a:args.get_p(2, ''),
        \ ),
        \)
  return bufname
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = s:adjust(git, expand('<afile>'))
  let result = giit#operator#execute(git, args)
  if result.status
    throw giit#operator#error(result)
  endif
  call giit#meta#set('commit', args.get_p(1, ''))
  call giit#meta#set('filename', git.abspath(args.get_p(2, '')))

  call s:init(args)
  call s:Buffer.edit_content(result.content)
  call giit#util#doautocmd('BufRead')
  setlocal filetype=diff
endfunction


" Private --------------------------------------------------------------------
function! s:adjust(git, bufname) abort
  let object = matchstr(a:bufname, '^giit://[^:]\+:[^/]\+/\zs.*$')
  let extra  = matchstr(a:bufname, '^giit://[^:]\+:[^:]\+:\zs[^/]\+')
  let [commit, filename] = giit#operator#split_object(object)

  let args = giit#meta#get('args', s:Argument.new())
  let args = args.clone()
  call args.set_p(0, 'diff')
  call args.set_p(1, commit)
  call args.set_p(2, filename)
  call args.set('--cached', extra =~# '\<cached\>')
  call args.set('-p|--patch', extra =~# '\<patch\>')
  return args.lock()
endfunction

function! s:init(args) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  if a:args.get('-p|--patch')
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
