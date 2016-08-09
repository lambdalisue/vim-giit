let s:Dict = vital#giit#import('Data.Dict')
let s:Buffer = vital#giit#import('Vim.Buffer')
let s:BufferManager = vital#giit#import('Vim.BufferManager')


function! giit#util#buffer#bufname(git, scheme, ...) abort
  let nofile = get(a:000, 0, 0)
  let refname = fnamemodify(a:git.worktree, ':t')
  let pattern = nofile ? 'giit:%s:%s' : 'giit://%s:%s'
  return printf(pattern, refname, a:scheme)
endfunction

function! giit#util#buffer#open(name, ...) abort
  let options = extend({
        \ 'opener': '',
        \ 'window': '',
        \ 'selection': [],
        \}, get(a:000, 0, {})
        \)
  " Open or focus a buffer
  let opener = empty(options.opener) ? 'edit' : options.opener
  if empty(options.window)
    let loaded = s:Buffer.open(a:name, opener)
  else
    let bm = s:get_buffer_manager(options.window)
    let loaded = bm.open(a:name, {
          \ 'opener': opener,
          \ 'range': get(options, 'range', 'tabpage'),
          \}).loaded
  endif
  " Make sure that the focus is correct even for preview window
  let preview = 0
  if s:is_preview_opener(opener)
    let preview = bufnr('%')
    noautocmd keepjumps keepalt wincmd P
  endif
  " Move cursor if required
  if !empty(options.selection)
    call giit#util#select(options.selection)
  endif
  " Build result dictionary
  let result = {
        \ 'loaded': loaded,
        \ 'bufnum': bufnr('%'),
        \ 'preview': preview,
        \}
  return result
endfunction

function! giit#util#buffer#finalize(ret) abort
  if a:ret.preview
    execute printf(
          \ 'noautocmd keepjumps %dwincmd w',
          \ bufwinnr(a:ret.preview)
          \)
    let a:ret.preview = 0
  endif
  return a:ret
endfunction

" Private --------------------------------------------------------------------
function! s:get_buffer_manager(window) abort
  let vname = '_buffer_manager_' . a:window
  if !has_key(s:, vname)
    let s:{vname} = s:BufferManager.new()
  endif
  return s:{vname}
endfunction


" Obsolute -------------------------------------------------------------------
" https://github.com/vim-jp/vital.vim/pull/447

function! s:is_preview_opener(opener) abort
  if a:opener =~# '\<ptag\?!\?\>'
    return 1
  elseif a:opener =~# '\<ped\%[it]!\?\>'
    return 1
  elseif a:opener =~# '\<ps\%[earch]!\?\>'
    return 1
  endif
  return 0
endfunction
