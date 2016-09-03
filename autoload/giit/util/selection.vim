function! giit#util#selection#select(selection, ...) abort
  " Original from mattn/emmet-vim
  " https://github.com/mattn/emmet-vim/blob/master/autoload/emmet/util.vim#L75-L79
  let prefer_visual = get(a:000, 0, 0)
  let line_start = get(a:selection, 0, line('.'))
  let line_end = get(a:selection, 1, line_start)
  if line_start == line_end && !prefer_visual
    call setpos('.', [0, line_start, 1, 0])
  else
    call setpos('.', [0, line_end, 1, 0])
    keepjumps normal! v
    call setpos('.', [0, line_start, 1, 0])
  endif
endfunction

function! giit#util#selection#parse(str) abort
  return map(split(a:str, '-'), 'str2nr(v:val)')
endfunction

function! giit#util#selection#get_current_selection() abort
  let is_visualmode = mode() =~# '^\c\%(v\|CTRL-V\|s\)$'
  let selection = is_visualmode ? [line("'<"), line("'>")] : [line('.')]
  return selection
endfunction

function! giit#util#selecton#to_string(selection) abort
  return join(map(a:selection 'string(v:val)'), '-')
endfunction
