let s:Argument = vital#giit#import('Argument')


" SYNOPSIS
" Giit log [options]
function! giit#command#log#command(range, qargs) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:qargs)

  " Open a corresponding component
  call giit#component#open(git, args)
endfunction

function! giit#command#log#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction
