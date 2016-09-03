let s:Argument = vital#giit#import('Argument')


" SYNOPSIS
" Giit show [options] [<commit>:<filename>]
" Giit show [options] [<commit>] [<filename>]
function! giit#command#show#command(range, qargs) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:qargs)

  if len(args.list_p()) < 3
    " Giit show [options] [<commit>:<filename>]
    let object = args.pop_p(1, '')
    let [commit, relpath] = giit#operator#split_object(object)
  else
    " Giit show [options] [<commit>] [<filename>]
    let commit  = args.pop_p(1, '')
    let relpath = args.pop_p(1, '')
  endif
  let relpath = git.relpath(giit#expand(relpath))
  let object  = giit#operator#build_object(commit, relpath)
  call args.set_p(1, object)

  " Open a corresponding component
  call giit#component#open(git, args)
endfunction

function! giit#command#show#complete(arglead, cmdline, cursorpos) abort
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
