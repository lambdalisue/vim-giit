let s:String = vital#giit#import('Data.String')


function! giit#util#list#cleanup(candidates) abort
  return filter(copy(a:candidates), '!empty(v:val)')
endfunction

function! giit#util#list#filter(arglead, candidates, ...) abort
  let hidden_pattern = get(a:000, 0, '')
  let pattern = '^' . s:String.escape_pattern(a:arglead)
  let candidates = copy(a:candidates)
  if !empty(hidden_pattern)
    call filter(candidates, 'v:val !~# hidden_pattern')
  endif
  call filter(candidates, 'v:val =~# pattern')
  return candidates
endfunction


