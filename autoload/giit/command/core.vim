let s:Argument = vital#giit#import('Argument')
let s:Emitter = vital#giit#import('Emitter')


" Entry point ----------------------------------------------------------------
function! giit#command#core#execute(range, qargs) abort
  let git = giit#core#get()
  let args = s:Argument.new(a:qargs)
  let quiet = args.pop('-q|--quiet')
  let result = giit#process#execute(git, args)
  if !quiet
    call giit#process#inform(result)
  endif
  call s:Emitter.emit('giit:modified')
  return result
endfunction

function! giit#command#core#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction
