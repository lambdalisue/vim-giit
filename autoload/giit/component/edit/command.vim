let s:Argument = vital#giit#import('Argument')


" SYNOPSIS
" Giit edit [options] [<filename>]
function! giit#component#edit#command#command(range, qargs) abort
  let git = giit#core#get()
  let args = s:Argument.new(a:qargs)

  let bufname = git.abspath(giit#expand(args.get_p(1, '%')))
  return giit#util#buffer#open(args, bufname)
endfunction

function! giit#component#edit#command#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#util#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \])
  else
    return giit#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
  endif
endfunction
