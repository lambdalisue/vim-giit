function! giit#selection#parse(str) abort
  return map(split(a:str, '-'), 'str2nr(v:val)')
endfunction

function! giit#selection#current() abort
  let is_visualmode = mode() =~# '^\c\%(v\|CTRL-V\|s\)$'
  let selection = is_visualmode ? [line("'<"), line("'>")] : [line('.')]
  return selection
endfunction
