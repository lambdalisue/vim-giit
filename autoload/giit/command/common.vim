let s:Argument = vital#giit#import('Argument')


function! giit#command#common#command(range, qargs) abort
  let args = s:Argument.new(a:qargs)
  let options = {}
  let options.quiet = args.pop('-q|--quiet')

  let git = giit#core#get()
  let result = giit#operator#execute(git, args)
  if !options.quiet
    call giit#operator#inform(result)
  endif
  return result
endfunction

function! giit#command#common#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction
