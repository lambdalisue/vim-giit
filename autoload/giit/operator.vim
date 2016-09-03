let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#operator#execute(git, args) abort
  let scheme = substitute(a:args.get_p(0, ''), '-', '_', 'g')
  try
    return call(
          \ printf('giit#operator#%s#execute', scheme),
          \ [a:git, a:args]
          \)
  catch /^Vim\%((\a\+)\)\=:E117/
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
  endtry
  return giit#operator#common#execute(a:git, a:args)
endfunction


" Utility --------------------------------------------------------------------
function! giit#operator#inform(result) abort
  redraw | echo
  if a:result.status
    call s:Prompt.echo('WarningMsg', 'Fail: ' . join(a:result.args))
  endif
  for line in a:result.content
    call s:Prompt.echo('None', line)
  endfor
endfunction

function! giit#operator#error(result) abort
  return s:Exception.error(printf(
        \ "Fail: %s\n%s",
        \ join(a:result.args),
        \ join(a:result.content, "\n")
        \))
endfunction

function! giit#operator#split_object(object) abort
  let m = matchlist(a:object, '^\(:[0-3]\|[^:]*\):\(.\+\)$')
  if empty(m)
    return [a:object, '']
  endif
  return m[1:2]
endfunction

function! giit#operator#build_object(commit, relpath) abort
  return empty(a:relpath)
        \ ? a:commit
        \ : a:commit . ':' . a:relpath
endfunction
