let s:Argument = vital#giit#import('Argument')
let s:GitTerm = vital#giit#import('Git.Term')


function! giit#component#show#command#command(range, qargs) abort
  let git = giit#core#require()
  let args = s:Argument.new(a:qargs)

  if len(args.list_p()) < 3
    " Giit show [options] [<commit>:<filename>]
    let object = args.pop_p(1, '')
    let [commit, relpath] = s:GitTerm.split_treeish(object)
  else
    " Giit show [options] [<commit>] [<filename>]
    let commit  = args.pop_p(1, '')
    let relpath = args.pop_p(1, '')
  endif
  let relpath = git.relpath(giit#expand(relpath))
  let object  = s:GitTerm.build_treeish(commit, relpath)
  call args.set_p(1, object)

  let bufname = giit#util#buffer#bufname(git, args)
  let bufname = substitute(bufname, '^giit:', 'giit://', '')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ args.get('-p|--patch') ? ':patch' : '',
        \ args.get_p(1, ''),
        \)
  return giit#util#buffer#open(bufname, args)
endfunction

function! giit#component#show#command#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#complete#util#filter(a:arglead, [
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
