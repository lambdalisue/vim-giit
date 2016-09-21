let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')
let s:GitTerm = vital#giit#import('Git.Term')


" Entry point ----------------------------------------------------------------
function! giit#component#diff#buffer#BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#require()
  let args = s:adjust(git, expand('<afile>'))
  let result = giit#operator#execute(git, args)
  if result.status
    throw giit#process#error(result)
  endif
  call giit#meta#set('commit', args.get_p(1, ''))
  call giit#meta#set('filename', git.abspath(args.get_p(2, '')))

  call s:init(args)
  call s:Buffer.edit_content(result.content)
  call giit#util#vim#doautocmd('BufRead')
  setlocal filetype=diff
endfunction


" Private --------------------------------------------------------------------
function! s:adjust(git, bufname) abort
  let object = matchstr(a:bufname, '^giit://[^:]\+:[^/]\+/\zs.*$')
  let extra  = matchstr(a:bufname, '^giit://[^:]\+:[^:]\+:\zs[^/]\+')
  let [commit, filename] = s:GitTerm.split_treeish(object)

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

  setlocal buftype=nowrite
  setlocal nomodifiable
endfunction

function! s:exception_handler(exception) abort
  setlocal buftype&
  setlocal filetype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction
