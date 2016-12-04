let s:String = vital#giit#import('Data.String')
let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')
let s:Action = vital#giit#import('Action')
let s:Exception = vital#giit#import('Vim.Exception')
let s:GitCache = vital#giit#import('Git.Cache')


" Entry point ----------------------------------------------------------------
function! giit#component#commit#BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let params = s:build_params(git)
  let result = giit#operator#commit#execute(git, params)
  if result.status
    throw giit#process#error(result)
  endif
  call giit#meta#set('params', params)

  call s:init(params)
  call s:assign_candidates(
        \ git,
        \ giit#operator#status#parse_content(git, result.content)
        \)
  call giit#util#vim#doautocmd('BufRead')
  setlocal filetype=giit-status
endfunction


" Private --------------------------------------------------------------------
function! s:build_params(git) abort
  let params = giit#meta#get('params', {})
  return params
endfunction

function! s:init(args) abort
  if exists('b:giit_initialized')
    return
  endif
  let b:giit_initialized = 1

  " Attach modules
  call s:Anchor.attach()
  call s:Observer.attach()

  let action = s:Action.attach('giit', {
        \ 'get_candidates': function('s:get_candidates'),
        \})
  call action.init()

  setlocal buftype=nofile
  setlocal bufhidden=delete
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

function! s:get_commitmsg(git, args) abort
  let args = a:args.clone()
  let cache = a:git.cache.get('WORKING_COMMIT_EDITMSG', {})
  let cname = args.get('--amend') ? 'amend' : '_'
  let content = get(cache, cname, [])

  let tempfile = tempname()
  try
    if !empty(content)
      call writefile(content, tempfile)
      call args.set('-F|--file', tempfile)
      " Remove conflicting options
      call args.pop('-C|--reuse-message')
      call args.pop('-m|--message')
    endif

    let result = giit#process#execute(a:git, args)
    if !result.status
      " NOTE: Operation should be fail while GIT_EDITOR=false
      throw giit#process#error(result)
    endif
    return a:git.core.readfile('COMMIT_EDITMSG')
  finally
    call delete(tempfile)
  endtry
endfunction

function! s:set_commitmsg(git, args, content) abort
  let args = a:args.clone()
  let cache = a:git.cache.get('WORKING_COMMIT_EDITMSG', {})
  let cname = args.get('--amend') ? 'amend' : '_'
  let cache[cname] = giit#process#commit#cleanup_commitmsg(
        \ a:content,
        \ args.get('--cleanup', 'strip')
        \)
  call a:git.core.writefile(a:content, 'COMMIT_EDITMSG')
  call a:git.cache.set('WORKING_COMMIT_EDITMSG', cache)
endfunction

function! s:commit_commitmsg(git, args) abort
  let args = a:args.clone()
  let content = giit#operator#commit#cleanup_commitmsg(
        \ a:git.core.readfile('COMMIT_EDITMSG'),
        \ args.get('--cleanup', 'strip'),
        \)
  let tempfile = tempname()
  try
    call writefile(content, tempfile)
    call args.set('--no-edit', 1)
    call args.set('-F|--file', tempfile)
    call args.pop('-C|--reuse-message')
    call args.pop('-m|--message')
    call args.pop('-e|--edit')
    let result = giit#process#execute(a:git, args)
    call a:git.cache.remove('WORKING_COMMIT_EDITMSG')
    call giit#process#inform(result)

    if &filetype ==# 'giit-commit'
      execute 'Giit status'
    endif
  finally
    call delete(tempfile)
  endtry
endfunction
