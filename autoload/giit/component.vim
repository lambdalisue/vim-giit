let s:Guard = vital#giit#import('Vim.Guard')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Exception = vital#giit#import('Vim.Exception')

function! giit#component#open(git, args) abort
  let scheme  = a:args.get_p(0, '')
  let config  = giit#scheme#call(
        \ scheme,
        \ 'component#{}#build_config',
        \ [a:git, a:args],
        \)
  let bufname  = giit#scheme#call(
        \ scheme,
        \ 'component#{}#build_bufname',
        \ [a:git, a:args],
        \)

  call s:Anchor.focus_if_available(config.opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, config)
  finally
    call guard.restore()
  endtry
  call giit#meta#set('args', a:args)
  edit
  call context.end()
endfunction

function! giit#component#autocmd(event) abort
  let scheme = matchstr(expand('<afile>'), 'giit:\%(//\)\?[^:]\+:\zs[^:/]\+\ze')
  let fname  = giit#scheme#fname(scheme, 'component#{}#autocmd')
  return s:Exception.call(function(fname), [a:event])
endfunction


" Utility --------------------------------------------------------------------
function! giit#component#split_object(object) abort
  let m = matchlist(a:object, '^\(:\?[^:]*\):\(.\+\)$')
  if empty(m)
    return [a:object, '']
  endif
  return m[1:2]
endfunction

function! giit#component#build_object(commit, filename) abort
  return empty(a:filename)
        \ ? a:commit
        \ : a:commit . ':' . a:filename
endfunction


" Fallback -------------------------------------------------------------------
function! giit#component#build_config(git, args) abort
  let config = {}
  let config.group     = ''
  let config.opener    = a:args.pop('-o|--opener', '')
  let config.selection = a:args.pop('--selection', '')
  return config
endfunction

function! giit#component#build_bufname(git, args) abort
  let scheme  = a:args.pos_p(0, '')
  let refname = fnamemodify(a:git.worktree, ':t')
  let pattern = 'giit://%s:%s'
  return printf(pattern, refname, scheme)
endfunction
