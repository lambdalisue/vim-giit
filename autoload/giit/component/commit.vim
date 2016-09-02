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
  let args = s:adjust(git, expand('<afile>'))
  let result = giit#operation#commit#execute(git, args)
  if !args.options.dry
    let result.status = !result.status
  endif
  if result.status
    call giit#operation#throw(result)
  endif
  call giit#meta#set('args', args)
  call s:init(args)
  call s:Buffer.edit_content(git.core.readfile('COMMIT_EDITMSG'))
  call giit#util#doautocmd('BufRead')
  setlocal filetype=giit-commit
endfunction

function! s:on_BufWriteCmd() abort
  let git = giit#core#get_or_fail()
  let args = giit#meta#require('args')
  let content = getline(1, '$')
  call git.core.writefile(content, 'COMMIT_EDITMSG')
  call s:set_working_commitmsg(git, args, giit#operation#commit#cleanup(
        \ content, args.get('--cleanup', 'strip')
        \))
  setlocal nomodified
endfunction


" private --------------------------------------------------------------------
function! s:adjust(git, bufname) abort
  let extra  = matchstr(a:bufname, '^giit:[^:]\+:[^:]\+:\zs[^/]\+')

  let args = giit#meta#get('args', s:Argument.new())
  let args.options = get(args, 'options', {})
  let args.options.dry = extra =~# '\<dry\>'
  let args.options.amend = extra =~# '\<amend\>'
  let args.options.message = join(s:get_working_commitmsg(a:git, args), "\n")
  return args.lock()
endfunction

function! s:init(args) abort
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
  augroup END

  setlocal buftype=acwrite nobuflisted
  if a:args.options.dry
    setlocal nomodifiable
  else
    setlocal modifiable
  endif
endfunction

function! s:exception_handler(exception) abort
  setlocal buftype&
  setlocal filetype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction

function! s:get_working_commitmsg(git, args) abort
  let name = a:args.options.amend ? 'amend' : '_'
  let cache = a:git.cache.get('WORKING_COMMIT_EDITMSG', {})
  return get(cache, name, [])
endfunction

function! s:set_working_commitmsg(git, args, message) abort
  let name = a:args.options.amend ? 'amend' : '_'
  let cache = a:git.cache.get('WORKING_COMMIT_EDITMSG', {})
  let cache[name] = a:message
  call a:git.cache.set('WORKING_COMMIT_EDITMSG', cache)
endfunction

function! s:commit(git, args) abort
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
