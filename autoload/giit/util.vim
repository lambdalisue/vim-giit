function! giit#util#doautocmd(name, ...) abort
  let pattern = get(a:000, 0, '')
  let expr = empty(pattern)
        \ ? '#' . a:name
        \ : '#' . a:name . '#' . pattern
  let eis = split(&eventignore, ',')
  if index(eis, a:name) >= 0 || index(eis, 'all') >= 0 || !exists(expr)
    " the specified event is ignored or not exists
    return
  endif
  let is_pseudo_required = empty(pattern) && !exists('#' . a:name . '#*')
  if is_pseudo_required
    " NOTE:
    " autocmd XXXXX <pattern> exists but not sure if current buffer name
    " match with the <pattern> so register empty autocmd to prevent
    " 'No matching autocommands' warning
    augroup giit_internal_util_doautocmd
      autocmd! *
      execute 'autocmd ' . a:name . ' * :'
    augroup END
  endif
  let nomodeline = has('patch-7.4.438') && a:name ==# 'User'
        \ ? '<nomodeline> '
        \ : ''
  try
    execute 'doautocmd ' . nomodeline . a:name . ' ' . pattern
  finally
    if is_pseudo_required
      augroup giit_internal_util_doautocmd
        autocmd! *
      augroup END
    endif
  endtry
endfunction

function! giit#util#syncbind() abort
  " NOTE:
  " Somehow syncbind does not just after opening a buffer so use
  " CursorHold and CursorMoved to call a bit later again
  augroup giit_internal_util_syncbind
    autocmd!
    autocmd CursorHold   * call s:syncbind()
    autocmd CursorHoldI  * call s:syncbind()
    autocmd CursorMoved  * call s:syncbind()
    autocmd CursorMovedI * call s:syncbind()
  augroup END
  syncbind
endfunction

function! s:syncbind() abort
  augroup giit_internal_util_syncbind
    autocmd! *
  augroup END
  syncbind
endfunction

function! giit#util#slug() abort
  return 'matchstr(expand(''<sfile>''), ''\zs[^. ]\+$'')'
endfunction

function! giit#util#fname(...) abort
  let trees = map(copy(a:000), 'substitute(v:val, ''-'', ''_'', ''g'')')
  return 'giit#' . join(trees, '#')
endfunction

if has('lua')
  function! giit#util#all(array) abort
    let result = [0]
    lua << EOF
do
  local function empty(x)
    return (not x or x == 0 or x == '' or (type(x) == 'userdata' and #x == 0))
  end
  local function all(array)
    for i = 0, #array - 1 do
      if empty(array[i]) then
        return 0
      end
    end
    return 1
  end
  local array = vim.eval('a:array')
  local result = vim.eval('result')
  result[0] = all(array)
end
EOF
    return float2nr(result[0])
  endfunction

  function! giit#util#any(array) abort
    let result = [0]
    lua << EOF
do
  local function empty(x)
    return (not x or x == 0 or x == '' or (type(x) == 'userdata' and #x == 0))
  end
  local function any(array)
    for i = 0, #array - 1 do
      if not empty(array[i]) then
        return 1
      end
    end
    return 0
  end
  local array = vim.eval('a:array')
  local result = vim.eval('result')
  result[0] = any(array)
end
EOF
    return float2nr(result[0])
  endfunction
else
  function! giit#util#all(array) abort
    return len(filter(copy(a:array), 'empty(v:val)')) == 0
  endfunction

  function! giit#util#any(array) abort
    return len(filter(copy(a:array), '!empty(v:val)')) > 0
  endfunction
endif
