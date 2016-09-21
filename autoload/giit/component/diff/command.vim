let s:Argument = vital#giit#import('Argument')
let s:GitTerm = vital#giit#import('Git.Term')


function! giit#component#diff#command#command(range, qargs) abort
  let git = giit#core#require()
  let args = s:Argument.new(a:qargs)

  if len(args.list_p()) < 3
    " Giit diff [options] [<commit>:<filename>]
    let object = args.pop_p(1, '')
    let [commit, relpath] = s:GitTerm.split_treeish(object)
  else
    " Giit diff [options] [<commit>] [<filename>]
    let commit  = args.pop_p(1, '')
    let relpath = args.pop_p(1, '')
  endif
  let relpath = git.relpath(giit#expand(relpath))
  call args.set_p(1, commit)
  call args.set_p(2, relpath)

  let bufname = giit#util#buffer#bufname(git, args)
  let bufname = substitute(bufname, '^giit:', 'giit://', '')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ args.get('-p|--patch') ? ':patch' : '',
        \ giit#term#build_object(
        \   args.get_p(1, ''),
        \   args.get_p(2, ''),
        \ ),
        \)
  return giit#util#buffer#open(args, bufname)
endfunction

function! giit#component#diff#command#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#util#complete#filter(a:arglead, [
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
