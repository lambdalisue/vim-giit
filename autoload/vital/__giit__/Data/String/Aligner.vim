scriptencoding utf-8

function! s:_vital_loaded(V) abort
  let s:LuaString = a:V.import('Vim.Lua.String')
endfunction

function! s:_vital_depends() abort
  return ['Vim.Lua.String']
endfunction

function! s:_vital_created(module) abort
  if has('lua')
    let a:module['align'] = function('s:_align_lua')
  elseif !has('nvim') && has('python')
    let a:module['align'] = function('s:_align_python')
  elseif !has('nvim') && has('python3')
    let a:module['align'] = function('s:_align_python3')
  else
    let a:module['align'] = function('s:_align_vim')
  endif
endfunction

function! s:_align_vim(matrix) abort
  let cols = range(len(a:matrix[0]))
  " Find longest length of each columns
  let longests = map(copy(cols), '0')
  for row_matrix in a:matrix
    call map(longests, 'max([v:val, strwidth(row_matrix[v:key])])')
  endfor
  " Add padding to each columns
  let whitespaces = repeat(' ', max(longests))
  for row_matrix in a:matrix
    let paddings = map(copy(longests), 'v:val - strwidth(row_matrix[v:key])')
    call map(row_matrix, 'v:val . (paddings[v:key] > 0 ? whitespaces[:paddings[v:key]-1] : '''')')
  endfor
  return a:matrix
endfunction

if has('lua')
  function! s:_align_lua(matrix) abort
    call s:LuaString.expose()
    lua << EOF
do
  local M = vital_vim_lua_string
  local matrix = vim.eval('a:matrix')
  local longests = {}
  local length = 0
  -- Find longest lengths of each column
  for r = 0, #matrix-1 do
    for c = 0, #matrix[r]-1 do
      length = M.strwidth(matrix[r][c])
      if (longests[c] == nil or longests[c] < length) then
        longests[c] = length
      end
    end
  end
  -- Add padding to each columns
  for r = 0, #matrix-1 do
    for c = 0, #matrix[r]-1 do
      padding = longests[c] - M.strwidth(matrix[r][c])
      if padding > 0 then
        matrix[r][c] = matrix[r][c] .. string.rep(' ', padding)
      end
    end
  end
end
EOF
    return a:matrix
  endfunction
endif

if !has('nvim') && has('python')
  python import vim
  function! s:_align_python(matrix) abort
    if empty(a:matrix)
      return []
    endif
    python << EOF
def _temporary_scope():
  strwidth = vim.Function('strwidth')
  matrix = vim.bindeval('a:matrix')
  # Find longest lengths of each column
  longests = [0] * len(matrix[0])
  for r, row_matrix in enumerate(matrix):
    for c, value in enumerate(row_matrix):
      longests[c] = max(longests[c], strwidth(value))
  # Add padding to each columns
  whitespaces = ' ' * max(longests)
  for r, row_matrix in enumerate(matrix):
    for c, value in enumerate(row_matrix):
      padding = longests[c] - strwidth(value)
      if padding:
        matrix[r][c] += whitespaces[:padding]
_temporary_scope()
del _temporary_scope
EOF
    return a:matrix
  endfunction
endif

if !has('nvim') && has('python3')
  python3 import vim
  function! s:_align_python3(matrix) abort
    if empty(a:matrix)
      return []
    endif
    python3 << EOF
def _temporary_scope():
  strwidth = vim.Function('strwidth')
  matrix = vim.bindeval('a:matrix')
  # Find longest lengths of each column
  longests = [0] * len(matrix[0])
  for r, row_matrix in enumerate(matrix):
    for c, value in enumerate(row_matrix):
      longests[c] = max(longests[c], strwidth(value))
  # Add padding to each columns
  whitespaces = b' ' * max(longests)
  for r, row_matrix in enumerate(matrix):
    for c, value in enumerate(row_matrix):
      padding = longests[c] - strwidth(value)
      if padding:
        matrix[r][c] += whitespaces[:padding]
_temporary_scope()
del _temporary_scope
EOF
    return a:matrix
  endfunction
endif
