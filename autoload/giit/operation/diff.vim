let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:GitTerm = vital#giit#import('Git.Term')
let s:Exception = vital#giit#import('Vim.Exception')
let s:WORKTREE = '@@'


" SYNOPSIS
" o git diff [options] [<commit>] [--] [<path>...]
" o git diff [options] --cached [<commit>] [--] [<path>...]
" x git diff [options] <commit> <commit> [--] [<path>...]
" x git diff [options] <blob> <blob>
" x git diff [options] [--no-index] [--] <path> <path>
function! giit#operation#diff#command(args) abort
  let git = giit#core#get_or_fail()
  let opener   = a:args.pop('-o|--opener', '')
  let commit   = a:args.get_p(0)
  let filename = a:args.apply_p(1, { value -> git.relpath(giit#expand(value)) })
  let object = empty(filename)
        \ ? commit
        \ : commit . ':' . git.relpath(filename)
  let bufname = giit#component#bufname(git, 'diff')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ empty(a:args.pop('-p|--patch')) ? '' : ':patch',
        \ object,
        \)
  call s:Anchor.focus_if_available(opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, {
          \ 'opener': opener,
          \})
  finally
    call guard.restore()
  endtry
  call giit#meta#set('args', a:args)
  call giit#util#doautocmd('BufReadCmd')
  call context.end()
endfunction

function! giit#operation#diff#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! giit#operation#diff#execute(git, args) abort
  let args = a:args.clone()
  call args.apply_p(0, { v -> s:normalize_commit(a:git, v) })
  call args.apply_p(1, { v -> a:git.abspath(v) })
  if args.pop('-p|--patch')
    let commit = args.get_p(0)
    if commit =~# '^.\{-}\.\.\.\?.*$'
      throw s:Exception.warn(printf(
            \ 'A commit range %s is not allowed for PATCH mode',
            \ commit,
            \))
    elseif empty(commit)
      call args.pop('--cached')
      call args.pop('--reverse')
    else
      call args.set('--cached', 1)
      call args.set('--reverse', 1)
    endif
  endif
  call filter(args.raw, '!empty(v:val)')
  return a:git.execute(['diff'] + args.raw, {
        \ 'encode_output': 0,
        \})
endfunction

function! s:normalize_commit(git, commit) abort
  if a:commit =~# '^.\{-}\.\.\..\{-}$'
    " git diff <lhs>...<rhs> : <lhs>...<rhs> vs <rhs>
    let [lhs, rhs] = s:GitTerm.split_range(a:commit, {})
    let lhs = empty(lhs) ? 'HEAD' : lhs
    let rhs = empty(rhs) ? 'HEAD' : rhs
    let lhs = a:git.util.find_common_ancestor(lhs, rhs)
    return lhs . '..' . rhs
  else
    return a:commit
  endif
endfunction
