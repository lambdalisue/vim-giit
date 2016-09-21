let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


" Entry point ----------------------------------------------------------------
function! giit#component#commit#buffer#BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#require()
  let args = s:adjust(git, expand('<afile>'))
  let content = s:get_commitmsg(git, args)

  call s:init(args)
  call s:Buffer.edit_content(content)
  call giit#util#vim#doautocmd('BufRead')
  setlocal filetype=giit-commit
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufWriteCmd() abort
  let git = giit#core#require()
  let args = s:adjust(git, expand('<afile>'))
  call s:set_commitmsg(git, args, getline(1, '$'))
  setlocal nomodified
endfunction

function! s:on_WinLeave() abort
  let s:params_on_winleave = {
        \ 'git': giit#core#require(),
        \ 'args': giit#meta#require('args'),
        \ 'nwin': winnr('$'),
        \}
endfunction

function! s:on_WinEnter() abort
  if exists('s:params_on_winleave')
    if winnr('$') < s:params_on_winleave.nwin
      call s:commit_commitmsg(
            \ s:params_on_winleave.git,
            \ s:params_on_winleave.args,
            \)
    endif
    unlet s:params_on_winleave
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:adjust(git, bufname) abort
  let extra  = matchstr(a:bufname, '^giit:[^:]\+:[^:]\+:\zs[^/]\+')

  let args = giit#meta#get('args', s:Argument.new())
  let args = args.clone()
  call args.set_p(0, 'commit')
  call args.set('-e|--edit', 1)
  call args.set('--amend', extra =~# '\<amend\>')
  call args.pop('--short')
  call args.pop('--branch')
  call args.pop('--porcelain')
  call args.pop('--long')
  call args.pop('--no-edit')
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
    autocmd WinLeave    <buffer> call s:on_WinLeave()
    autocmd WinEnter    *        call s:on_WinEnter()
  augroup END

  setlocal buftype=acwrite nobuflisted

  nnoremap <buffer><silent><expr> <Plug>(giit-commit-switch)
        \ bufname('%') =~# '\<amend\>'
        \   ? ':<C-u>Giit commit<CR>'
        \   : ':<C-u>Giit commit --amend<CR>'
  nnoremap <buffer><silent> <Plug>(giit-commit)
        \ :<C-u>call <SID>commit_commitmsg(giit#core#require(), giit#meta#require('args'))<CR>
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

    let result = giit#operator#execute(a:git, args)
    if !result.status
      " NOTE: Operation should be fail while GIT_EDITOR=false
      throw giit#util#command#error(result)
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
  let cache[cname] = giit#component#commit#util#cleanup_commitmsg(
        \ a:content,
        \ args.get('--cleanup', 'strip')
        \)
  call a:git.core.writefile(a:content, 'COMMIT_EDITMSG')
  call a:git.cache.set('WORKING_COMMIT_EDITMSG', cache)
endfunction

function! s:commit_commitmsg(git, args) abort
  let args = a:args.clone()
  let content = giit#component#commit#util#cleanup_commitmsg(
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
    let result = giit#operator#execute(a:git, args)
    call a:git.cache.remove('WORKING_COMMIT_EDITMSG')
    call giit#process#inform(result)

    if &filetype ==# 'giit-commit'
      execute 'Giit status'
    endif
  finally
    call delete(tempfile)
  endtry
endfunction
