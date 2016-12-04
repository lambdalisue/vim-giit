let s:Argument = vital#giit#import('Argument')
let s:Git = vital#giit#import('Git')
let s:GitTerm = vital#giit#import('Git.Term')


" Entry point ----------------------------------------------------------------
function! giit#command#show#execute(range, qargs) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:qargs)
  let args = s:normalize_commit_and_path(git, args)

  let bufname = giit#component#build_bufname(git, 'show', {
        \ 'file': 1,
        \ 'object': args.get_p(1, ':' . expand('%')),
        \ 'extras': [
        \   args.get('-p|--patch') ? 'patch' : '',
        \ ],
        \})
  return giit#component#open(args, bufname, {
        \ 'opener': args.pop('-o|--opener', ''),
        \ 'selection': args.pop('-s|--selection', '')
        \})
endfunction

function! giit#command#show#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#util#list#filter(a:arglead, [
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


" Private --------------------------------------------------------------------
function! s:normalize_commit_and_path(git, args) abort
  if len(a:args.list_p()) < 3
    " Giit show [options] [<commit>:<filename>]
    let object = a:args.pop_p(1, ':%')
    let [commit, relpath] = s:GitTerm.split_treeish(object)
  else
    " Giit show [options] [<commit>] [<filename>]
    let commit  = a:args.pop_p(1, '')
    let relpath = a:args.pop_p(1, '%')
  endif
  let relpath = s:Git.relpath(a:git, giit#expand(relpath))
  let object  = s:GitTerm.build_treeish(commit, relpath)
  call a:args.set_p(1, object)
  return a:args
endfunction
