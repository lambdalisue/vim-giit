let s:Argument = vital#giit#import('Argument')


" Entry point ----------------------------------------------------------------
function! giit#command#edit#execute(range, qargs) abort
  let args = s:Argument.new(a:qargs)
  let bufname = giit#expand(args.get_p(1, '%'))
  return giit#component#open(args, bufname, {
        \ 'opener': args.get('-o|--opener', ''),
        \ 'selection': args.get('--selection', '')
        \})
endfunction

function! giit#command#edit#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#util#list#filter(a:arglead, [
          \ '-o', '--opener=',
          \])
  else
    return giit#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
  endif
endfunction
