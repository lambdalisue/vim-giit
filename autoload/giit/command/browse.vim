let s:File = vital#giit#import('System.File')
let s:Argument = vital#giit#import('Argument')


" Entry point ----------------------------------------------------------------
function! giit#command#browse#execute(range, qargs) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:qargs)
  let params = giit#operator#browse#build_params(args)
  let result = giit#operator#browse#execute(git, params)
  if empty(result.output)
    return
  endif
  call s:File.open(result.output)
endfunction

function! giit#command#browse#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

