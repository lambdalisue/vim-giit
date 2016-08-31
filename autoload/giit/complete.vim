let s:String = vital#giit#import('Data.String')


" Complete function ----------------------------------------------------------
function! giit#complete#opener(arglead, cmdline, cursorpos) abort
  if a:arglead !~# '^\%(-o\|--opener=\)'
    return []
  endif
  let candidates = [
        \ 'split',
        \ 'vsplit',
        \ 'tabedit',
        \]
  let prefix = a:arglead =~# '^-o' ? '-o' : '--opener='
  return giit#complete#filter(a:arglead, map(candidates, 'prefix . v:val'))
endfunction


" Utility --------------------------------------------------------------------
function! giit#complete#filter(arglead, candidates, ...) abort
  let hidden_pattern = get(a:000, 0, '')
  let pattern = '^' . s:String.escape_pattern(a:arglead)
  let candidates = copy(a:candidates)
  if !empty(hidden_pattern)
    call filter(candidates, 'v:val !~# hidden_pattern')
  endif
  call filter(candidates, 'v:val =~# pattern')
  return candidates
endfunction
