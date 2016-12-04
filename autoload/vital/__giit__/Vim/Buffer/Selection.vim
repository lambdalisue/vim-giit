" Original from mattn/emmet-vim
" https://github.com/mattn/emmet-vim/blob/master/autoload/emmet/util.vim#L75-L79
function! s:set_current_selection(selection, ...) abort
  let options = extend({
        \ 'prefer_visual': 0,
        \}, get(a:000, 0, {})
        \)
  let line_start = get(a:selection, 0, line('.'))
  let line_end = get(a:selection, 1, line_start)
  if line_start == line_end && !options.prefer_visual
    call setpos('.', [0, line_start, 1, 0])
  else
    call setpos('.', [0, line_end, 1, 0])
    keepjumps normal! v
    call setpos('.', [0, line_start, 1, 0])
  endif
endfunction

function! s:get_current_selection() abort
  let is_visualmode = mode() =~# '^\c\%(v\|CTRL-V\|s\)$'
  let selection = is_visualmode ? [line("'<"), line("'>")] : [line('.')]
  return selection
endfunction

function! s:parse(str) abort
  return map(split(a:str, '-'), 'str2nr(v:val)')
endfunction

function! s:format(selection) abort
  return join(map(a:selection, 'string(v:val)'), '-')
endfunction
