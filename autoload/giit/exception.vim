let s:Prompt = vital#giit#import('Vim.Prompt')

let s:handler = {}
function! s:handler.handle(exception) abort
  let m = matchlist(
        \ a:exception,
        \ '^vital: Git\.Term: ValidationError: \(.*\)',
        \)
  if !empty(m)
    call s:Prompt.warn('giit: ' . m[1])
    return 1
  endif
  return 0
endfunction


function! giit#exception#define() abort
  return s:handler
endfunction
