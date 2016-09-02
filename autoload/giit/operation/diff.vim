let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:GitTerm = vital#giit#import('Git.Term')
let s:Argument = vital#giit#import('Argument')


" SYNOPSIS
" Giit diff [options] [<commit>:<filename>]
" Giit diff [options] [<commit>] [<filename>]
" Giit diff [options] [<commit1>..<commit2>:<filename>]
" Giit diff [options] [<commit1>..<commit2>] [<filename>]
" Giit diff [options] [<commit1>...<commit2>:<filename>]
" Giit diff [options] [<commit1>...<commit2>] [<filename>]
function! giit#operation#diff#command(args) abort
  let git = giit#core#get_or_fail()
  let args = s:adjust(git, a:args)

  let bufname = printf('%s%s%s/%s',
        \ giit#component#bufname(git, 'diff'),
        \ args.options.patch ? ':patch' : '',
        \ args.options.cached ? ':cached' : '',
        \ giit#component#build_object(
        \   args.options.commit,
        \   git.relpath(args.options.filename),
        \ ),
        \)
  call s:Anchor.focus_if_available(args.options.opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, {
          \ 'opener': args.options.opener,
          \})
  finally
    call guard.restore()
  endtry
  call giit#meta#set('args', args)
  edit
  call context.end()
endfunction

function! giit#operation#diff#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \])
  elseif a:arglead =~# '^[^:]*:'
    let m = matchlist(a:arglead, '^\([^:]*:\)\(.*\)$')
    let [prefix, arglead] = m[1:2]
    let candidates = giit#complete#filename#tracked(arglead, a:cmdline, a:cursorpos)
    return map(candidates, 'prefix . v:val')
  else
    let args = s:Argument.new(substitute(a:cmdline, '\S\+$', '', ''))
    if len(args.list_p()) >= 3
      return giit#complete#filename#tracked(a:arglead, a:cmdline, a:cursorpos)
    else
      return giit#complete#commit#any(a:arglead, a:cmdline, a:cursorpos)
    endif
  endif
endfunction

function! giit#operation#diff#execute(git, args) abort
  let args = giit#util#collapse([
        \ 'diff',
        \ a:args.options.commit,
        \ a:args.options.filename,
        \ a:args.raw,
        \])
  return a:git.execute(args, {
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


function! s:adjust(git, args) abort
  let args = a:args.clone()
  if len(args.list_p()) < 2
    let [commit, filename] = giit#component#split_object(args.pop_p(0, ''))
  else
    let commit   = args.pop_p(0, '')
    let filename = args.pop_p(0, '')
  endif

  let args.options = {}
  let args.options.opener = args.pop('-o|--opener', '')
  let args.options.patch = args.pop('-p|--patch')
  let args.options.cached = args.pop('-c|--cached')
  let args.options.commit = commit
  let args.options.filename = a:git.abspath(giit#expand(filename))
  return args.lock()
endfunction
