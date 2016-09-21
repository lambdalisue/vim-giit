function! giit#util#complete#filter(arglead, candidates, ...) abort
  let hidden_pattern = get(a:000, 0, '')
  let pattern = '^' . s:String.escape_pattern(a:arglead)
  let candidates = copy(a:candidates)
  if !empty(hidden_pattern)
    call filter(candidates, 'v:val !~# hidden_pattern')
  endif
  call filter(candidates, 'v:val =~# pattern')
  return candidates
endfunction

function! giit#util#complete#get_slug_expr() abort
  return 'matchstr(expand(''<sfile>''), ''\zs[^. ]\+$'')'
endfunction

