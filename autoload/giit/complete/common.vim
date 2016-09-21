function! giit#complete#common#opener(arglead, cmdline, cursorpos) abort
  if a:arglead !~# '^\%(-o\|--opener=\)'
    return []
  endif
  let candidates = [
        \ 'split',
        \ 'vsplit',
        \ 'tabedit',
        \]
  let prefix = a:arglead =~# '^-o' ? '-o' : '--opener='
  return giit#util#complete#filter(a:arglead, map(candidates, 'prefix . v:val'))
endfunction
