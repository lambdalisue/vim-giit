let s:Argument = vital#giit#import('Argument')


" Entry point ----------------------------------------------------------------
function! giit#command#lcd#execute(range, qargs) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:qargs)
  let path = args.get('-r|--repository')
        \ ? git.repository
        \ : git.worktree
  execute printf('lcd %s', fnameescape(path))
endfunction

function! giit#command#lcd#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^--\?'
    return giit#util#list#filter(a:arglead, [
          \ '-r', '--repository',
          \])
  endif
  return []
endfunction

