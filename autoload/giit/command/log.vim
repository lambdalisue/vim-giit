let s:Argument = vital#giit#import('Argument')


" SYNOPSIS
" Giit log [options]
function! giit#command#log#command(range, qargs) abort
  let git = giit#core#require()
  let args = s:Argument.new(a:qargs)

  " Open a corresponding component
  call giit#component#open(git, args, a:range)
endfunction

function! giit#command#log#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction
