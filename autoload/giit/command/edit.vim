let s:Argument = vital#giit#import('Argument')


" SYNOPSIS
" Giit edit [options] [<filename>]
function! giit#command#edit#command(range, qargs) abort
  let git = giit#core#get()
  let args = s:Argument.new(a:qargs)

  " Open a corresponding component
  return giit#component#open(git, args)
endfunction

function! giit#command#edit#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \])
  else
    return giit#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
  endif
endfunction
