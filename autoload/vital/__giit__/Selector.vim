function! s:_vital_loaded(V) abort
  let s:String = a:V.import('Data.String')
  let s:Guard = a:V.import('Vim.Guard')
  let s:Buffer = a:V.import('Vim.Buffer')
endfunction

function! s:_vital_depends() abort
  return ['Data.String', 'Vim.Guard', 'Vim.Buffer']
endfunction


function! s:get() abort
  return b:_vital_interface_selector
endfunction

function! s:attach(name, ...) abort
  let selector = extend(deepcopy(s:selector), {
        \ 'name': a:name,
        \ 'bufnr': bufnr('%'),
        \ 'selectable': 1,
        \ 'candidates': [],
        \ 'available_indices': [],
        \ 'selected_indexmap': {},
        \ 'previous_input': '',
        \ 'prefix': '> ',
        \})
  let selector = extend(selector, get(a:000, 0, {}))
  lockvar selector.name
  lockvar selector.bufnr

  " Replace manipulation mappings to prevent modification on candidate lines
  nnoremap <silent><buffer> o A
  nnoremap <silent><buffer> O A
  nnoremap <silent><buffer> p :<C-u>call <SID>_on_paste()<CR>
  nnoremap <silent><buffer> P :<C-u>call <SID>_on_paste()<CR>
  nnoremap <silent><buffer><expr> dd
        \ line('.') == 1 ? '0D' : ''
  nnoremap <silent><buffer><expr> x
        \ line('.') == 1 ? 'x' : ''
  nnoremap <silent><buffer><expr> c
        \ line('.') == 1 ? 'c' : ''
  nnoremap <silent><buffer><expr> C
        \ line('.') == 1 ? 'C' : ''
  inoremap <silent><buffer> <CR> <Nop>
  inoremap <silent><buffer><expr> <del>
        \ virtcol('.') <= len(getline('.')) ? '<del>' : ''
  inoremap <silent><buffer><expr> <C-h>
        \ virtcol('.') > len(<SID>get().prefix) + 1 ? '<C-h>' : ''
  inoremap <silent><buffer><expr> <BS>
        \ virtcol('.') > len(<SID>get().prefix) + 1 ? '<BS>' : ''

  " Define <Plug> mappings so that developers could use these mappings
  " to select/toggle or whatever
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-select) :<C-u>call <SID>_on_candidate_select()<CR>', a:name)
  execute printf('vnoremap <silent><buffer> <Plug>(%s-selector-select) :call <SID>_on_candidate_select()<CR>', a:name)
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-unselect) :<C-u>call <SID>_on_candidate_unselect()<CR>', a:name)
  execute printf('vnoremap <silent><buffer> <Plug>(%s-selector-unselect) :call <SID>_on_candidate_unselect()<CR>', a:name)
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-toggle) :<C-u>call <SID>_on_candidate_toggle()<CR>', a:name)
  execute printf('vnoremap <silent><buffer> <Plug>(%s-selector-toggle) :call <SID>_on_candidate_toggle()<CR>', a:name)
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-select-each) :call <SID>_on_candidate_select_each()<CR>', a:name)
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-unselect-each) :call <SID>_on_candidate_unselect_each()<CR>', a:name)
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-toggle-each) :<C-u>call <SID>_on_candidate_toggle_each()<CR>', a:name)
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-toggle-all) :<C-u>call <SID>_on_candidate_toggle_all()<CR>', a:name)
  execute printf('nnoremap <silent><buffer> <Plug>(%s-selector-gg) ggj', a:name)

  " Define autocmd to regulate the behaviour
  augroup vital-interface-selector-attach
    autocmd! * <buffer>
    autocmd BufEnter     <buffer> call s:_on_BufEnter()
    autocmd BufLeave     <buffer> call s:_on_BufLeave()
    autocmd InsertEnter  <buffer> call s:_on_InsertEnter()
    autocmd InsertLeave  <buffer> call s:_on_InsertLeave()
    autocmd TextChanged  <buffer> call s:_on_TextChanged()
    autocmd CursorMoved  <buffer> call s:_on_CursorMoved()
    autocmd CursorMovedI <buffer> call s:_on_CursorMovedI()
    autocmd CursorHoldI  <buffer> call s:_on_CursorHoldI()
    autocmd ColorScheme  <buffer> call s:get().define_highlight()
  augroup END

  " This is a selector buffer
  setlocal buftype=nofile

  " Draw
  call selector.define_highlight()
  call selector.define_syntax()
  call selector.redraw()

  " Call BufEnter autocmd which configure global options
  call s:_on_BufEnter()

  let b:_vital_interface_selector = selector
  return selector
endfunction

function! s:get_candidates(...) abort
  let selector = s:get()
  return call(selector.get_selected_candidates, a:000, selector)
endfunction

" instance -------------------------------------------------------------------
let s:selector = {}

function! s:selector.init() abort
  let name = self.name
  execute printf('nmap <buffer> gg <Plug>(%s-selector-gg)', name)
  execute printf('nmap <buffer> * <Plug>(%s-selector-toggle-all)', name)
  execute printf('vmap <buffer> * <Plug>(%s-selector-toggle)', name)
  execute printf('nmap <buffer> ! <Plug>(%s-selector-toggle-each)', name)
  execute printf('vmap <buffer> ! <Plug>(%s-selector-toggle)', name)
  execute printf('nmap <buffer> J <Plug>(%s-selector-toggle)j', name)
  execute printf('nmap <buffer> K <Plug>(%s-selector-toggle)k', name)
  execute printf('nmap <buffer> <Space> <Plug>(%s-selector-toggle)', name)
  execute printf('vmap <buffer> <Space> <Plug>(%s-selector-toggle)', name)

  setlocal nolist nospell
  setlocal nowrap nofoldenable
  setlocal nonumber norelativenumber
  setlocal foldcolumn=0 colorcolumn=0
endfunction

function! s:selector.focus_silently() abort
  if !bufexists(self.bufnr)
    throw printf(
          \ 'vital: Interface.Selector: A buffer:%d does not exist',
          \ self.bufnr,
          \)
  endif
  if bufwinnr(self.bufnr) == -1
    return {}
  endif
  let bufnum = bufnr('%')
  if bufnum != self.bufnr
    execute printf('noautocmd keepjumps %dwincmd w', bufwinnr(self.bufnr))
  endif
  let focus = {
        \ 'bufnr': bufnum
        \}
  if bufnum != self.bufnr
    function! focus.restore() abort
      execute printf('noautocmd keepjumps %dwincmd w', bufwinnr(self.bufnr))
    endfunction
  else
    function! focus.restore() abort
    endfunction
  endif
  return focus
endfunction

function! s:selector.redraw() abort
  let input = self.get_input()
  let content = map(
        \ copy(self.available_indices),
        \ 'self.format_candidate(v:val, self.candidates[v:val])'
        \)
  let content = extend([self.prefix . input], content)
  silent call s:Buffer.edit_content(content)
endfunction

function! s:selector.redraw_lines(fline, lline) abort
  let findex = self.get_index_from_linenum(a:fline)
  let lindex = self.get_index_from_linenum(a:lline)
  let content = map(
        \ range(findex, lindex),
        \ 'self.format_candidate(v:val, self.candidates[v:val])'
        \)
  let saved_view = winsaveview()
  try
    call setpos('.', [0, a:fline, 1, 0])
    execute printf('silent keepjumps normal! %ddd', a:lline - a:fline)
    silent call s:Buffer.read_content(content)
  finally
    call winrestview(saved_view)
  endtry
endfunction

function! s:selector.define_highlight() abort
  highlight default link vitalComponentSelectorInput Constant
  highlight default link vitalComponentSelectorPrefix Text
  highlight default link vitalComponentSelectorSelected Statement
  highlight default link vitalComponentSelectorMatch Title
  highlight default link vitalComponentSelectorNotMatch Comment
endfunction

function! s:selector.define_syntax() abort
  syntax clear
  syntax sync maxlines=0
  syntax match vitalComponentSelectorNotMatch /.*/
        \ contains=vitalComponentSelectorMatch
  syntax match vitalComponentSelectorSelected /^\*.*$/
        \ contains=vitalComponentSelectorMatch
  syntax match vitalComponentSelectorInput /\%^.*$/
        \ contains=vitalComponentSelectorPrefix
  execute printf(
        \ 'syntax match vitalComponentSelectorPrefix /^%s/ contained',
        \ escape(s:String.escape_pattern(self.prefix), '/'),
        \)
  let patterns = self.get_patterns()
  if !empty(patterns)
    let patterns = map(
          \ patterns,
          \ 's:String.escape_pattern(v:val)',
          \)
    let pattern = printf('%s\%%(%s\)',
          \ join(patterns, '\|'),
          \ &ignorecase ? '\c' : '\C',
          \)
    execute printf(
          \ 'syntax match vitalComponentSelectorMatch /%s/ contained',
          \ escape(pattern, '/'),
          \)
  endif
endfunction

function! s:selector.set_input(input) abort
  let saved_view = winsaveview()
  try
    keepjumps normal! ggdd
    call append(0, self.prefix . a:input)
  finally
    keepjumps call winrestview(saved_view)
  endtry
endfunction

function! s:selector.get_input() abort
  let prefix_length = len(self.prefix)
  let input = getline(1)
  if len(input) <= prefix_length
    return ''
  endif
  let input = input[prefix_length : ]
  return substitute(input, '^\s\+\|\s\+$', '', 'g')
endfunction

function! s:selector.get_patterns(...) abort
  let input = a:0 > 0 ? a:1 : self.get_input()
  return filter(split(input), '!empty(v:val)')
endfunction

function! s:selector.assign_candidates(candidates) abort
  let self.candidates = a:candidates
  let focus = self.focus_silently()
  if empty(focus)
    return
  endif
  try
    call self.filter_candidates(self.previous_input, 1)
  finally
    call focus.restore()
  endtry
endfunction

function! s:selector.extend_candidates(candidates) abort
  let offset = len(self.candidates)
  call extend(self.candidates, a:candidates)
  let focus = self.focus_silently()
  if empty(focus)
    return
  endif
  let saved_view = winsaveview()
  try
    let available_indices = s:_filter_candidates(
          \ range(len(a:candidates)),
          \ a:candidates,
          \ self.get_patterns(),
          \ &ignorecase,
          \)
    let available_content = map(
          \ copy(available_indices),
          \ 'self.format_candidate(v:val+offset, a:candidates[v:val])',
          \)
    call extend(
          \ self.available_indices,
          \ map(available_indices, 'offset+v:val')
          \)
    silent call s:Buffer.read_content(available_content, {
          \ 'line': '$',
          \})
  finally
    keepjumps call winrestview(saved_view)
    call focus.restore()
  endtry
endfunction

function! s:selector.filter_candidates(...) abort
  let input = a:0 > 0 ? a:1 : self.get_input()
  let force = a:0 > 1 ? a:2 : 0
  if self.get_input() !=# input
    call self.set_input(input)
  endif
  if empty(input)
    let self.previous_input = input
    let self.available_indices = range(len(self.candidates))
    call self.define_syntax()
    call self.redraw()
    return
  elseif !force && input =~# '\m^' . s:String.escape_pattern(self.previous_input)
    let self.previous_input = input
    let self.available_indices = s:_filter_candidates(
          \ self.available_indices,
          \ self.candidates,
          \ self.get_patterns(input),
          \ &ignorecase,
          \)
    call self.define_syntax()
    call self.redraw()
    return
  else
    let self.previous_input = input
    let self.available_indices = s:_filter_candidates(
          \ range(len(self.candidates)),
          \ self.candidates,
          \ self.get_patterns(input),
          \ &ignorecase,
          \)
    call self.define_syntax()
    call self.redraw()
    return
  endif
endfunction

function! s:selector.format_candidate(index, candidate) abort
  let selected = get(self.selected_indexmap, a:index)
  return (selected ? '* ' : '  ') . get(a:candidate, 'abbr', a:candidate.word)
endfunction

function! s:selector.select_candidate(index) abort
  if !self.selectable
    return
  endif
  let self.selected_indexmap[a:index] = 1
endfunction

function! s:selector.unselect_candidate(index) abort
  if !self.selectable
    return
  endif
  if has_key(self.selected_indexmap, a:index)
    unlet self.selected_indexmap[a:index]
  endif
endfunction

function! s:selector.toggle_candidate(index) abort
  if !self.selectable
    return
  endif
  if has_key(self.selected_indexmap, a:index)
    unlet self.selected_indexmap[a:index]
  else
    let self.selected_indexmap[a:index] = 1
  endif
endfunction

function! s:selector.get_index_from_vindex(vindex) abort
  return get(self.available_indices, a:vindex, 0)
endfunction

function! s:selector.get_index_from_linenum(linenum) abort
  let vindex = a:linenum - 2
  let vindex = vindex < 0 ? 0 : vindex
  return self.get_index_from_vindex(vindex)
endfunction

function! s:selector.get_available_candidates() abort
  return map(
        \ copy(self.available_indices),
        \ 'self.candidates[v:val]',
        \)
endfunction

function! s:selector.get_selected_candidates(...) abort
  if empty(self.selected_indexmap)
    if empty(self.available_indices)
      return []
    endif
    let fline = get(a:000, 0, line('.'))
    let eline = get(a:000, 1, fline)
    if fline == 1 && eline == 1
      return []
    endif
    let findex = self.get_index_from_linenum(fline)
    let eindex = self.get_index_from_linenum(eline)
    return map(
          \ range(findex, eindex),
          \ 'self.candidates[v:val]',
          \)
  else
    return filter(
          \ copy(self.candidates),
          \ 'get(self.selected_indexmap, v:key)',
          \)
  endif
endfunction

" mapping --------------------------------------------------------------------
function! s:_on_paste() abort
  if line('.') != 1
    return
  endif
  let cliptext = getreg(v:register)
  try
    call setreg(v:register, get(split(cliptext, "\n"), 0))
    normal! p
  finally
    call setreg(v:register, cliptext)
  endtry
endfunction

function! s:_on_candidate_select() range abort
  let selector = s:get()
  if !selector.selectable || (a:firstline == 1 && a:lastline == 1)
    return
  endif
  let indices = map(
        \ range(a:firstline, a:lastline),
        \ 'selector.get_index_from_linenum(v:val)',
        \)
  for index in indices
    call selector.select_candidate(index)
  endfor
  call selector.redraw_lines(a:firstline, a:lastline)
endfunction

function! s:_on_candidate_unselect() range abort
  let selector = s:get()
  if !selector.selectable || (a:firstline == 1 && a:lastline == 1)
    return
  endif
  let indices = map(
        \ range(a:firstline, a:lastline),
        \ 'selector.get_index_from_linenum(v:val)',
        \)
  for index in indices
    call selector.unselect_candidate(index)
  endfor
  call selector.redraw_lines(a:firstline, a:lastline)
endfunction

function! s:_on_candidate_toggle() range abort
  let selector = s:get()
  if !selector.selectable || (a:firstline == 1 && a:lastline == 1)
    return
  endif
  let indices = map(
        \ range(a:firstline, a:lastline),
        \ 'selector.get_index_from_linenum(v:val)',
        \)
  for index in indices
    call selector.toggle_candidate(index)
  endfor
  call selector.redraw_lines(a:firstline, a:lastline)
endfunction

function! s:_on_candidate_select_each() range abort
  let selector = s:get()
  if !selector.selectable
    return
  endif
  for index in selector.available_indices
    call selector.select_candidate(index)
  endfor
  call selector.redraw()
endfunction

function! s:_on_candidate_unselect_each() range abort
  let selector = s:get()
  if !selector.selectable
    return
  endif
  for index in selector.available_indices
    call selector.unselect_candidate(index)
  endfor
  call selector.redraw()
endfunction

function! s:_on_candidate_toggle_each() abort
  let selector = s:get()
  if !selector.selectable
    return
  endif
  for index in selector.available_indices
    call selector.toggle_candidate(index)
  endfor
  call selector.redraw()
endfunction

function! s:_on_candidate_toggle_all() abort
  let selector = s:get()
  if !selector.selectable
    return
  endif
  " Count the number of selected/unselected
  let selected = 0
  let unselected = 0
  for index in selector.available_indices
    if has_key(selector.selected_indexmap, index)
      let selected += 1
    else
      let unselected += 1
    endif
  endfor
  if selected > unselected
    call s:_on_candidate_unselect_each()
  else
    call s:_on_candidate_select_each()
  endif
endfunction

" autocmd --------------------------------------------------------------------
function! s:_on_BufEnter() abort
  if exists('b:_vital_interface_selector_guard')
    return
  endif
  let b:_vital_interface_selector_guard = s:Guard.store(['&updatetime'])
  set updatetime=100
endfunction

function! s:_on_BufLeave() abort
  if !exists('b:_vital_interface_selector_guard')
    return
  endif
  call b:_vital_interface_selector_guard.restore()
  unlet! b:_vital_interface_selector_guard
endfunction

function! s:_on_InsertEnter() abort
  let v:char = '.'
  call s:_on_CursorMovedI()
endfunction

function! s:_on_InsertLeave() abort
  let selector = s:get()
  if empty(selector.get_input())
    let cursor = getpos('.')
    let cursor[1] = 2
    call setpos('.', cursor)
  endif
endfunction

function! s:_on_TextChanged(...) abort
  let selector = s:get()
  call selector.filter_candidates()
endfunction

function! s:_on_CursorMoved() abort
  if line('.') > 1
    let selector = s:get()
    let prefix_length = len(selector.prefix)
    let cursor = getpos('.')
    if cursor[2] <= prefix_length
      let cursor[2] = prefix_length +1
      call setpos('.', cursor)
    endif
    return
  endif
  call s:_on_CursorMovedI()
endfunction

function! s:_on_CursorMovedI() abort
  let selector = s:get()
  let prefix_length = len(selector.prefix)
  let cursor = getpos('.')
  if cursor[1] == 1 && cursor[2] > prefix_length
    return
  endif
  let cursor[1] = 1
  let cursor[2] = prefix_length + 1
  call setpos('.', cursor)
endfunction

function! s:_on_CursorHoldI() abort
  let selector = s:get()
  call selector.filter_candidates()
endfunction

" utils ----------------------------------------------------------------------
function! s:_throw(...) abort
  let strlist = map(copy(a:000), 'type(v:val) == 1 ? v:val : string(v:val)')
  throw printf('vital: Selector: %s', join(strlist))
endfunction

function! s:_debug(...) abort
  if &verbose > 0
    let strlist = map(a:000, 'type(v:val) == 1 ? v:val : string(v:val)')
    try
      echohl Comment
      echomsg printf('vital: Selector: %s', join(strlist))
    finally
      echohl None
    endtry
  endif
endfunction

" Note:
" Using stridx() is faster than using =~# but using stridx() + tolower() * 2
" is slower than using =~?
function! s:_filter_candidates_vim(indices, candidates, patterns, ignorecase) abort
  if a:ignorecase
    let patterns = map(copy(a:patterns), 'escape(v:val, ''^$~.*[]\"'')')
    for pattern in patterns
      call filter(
            \ a:indices,
            \ 'a:candidates[v:val].word =~? ''\m'' . pattern'
            \)
    endfor
  else
    for pattern in a:patterns
      call filter(
            \ a:indices,
            \ 'stridx(a:candidates[v:val].word, pattern) != -1'
            \)
    endfor
  endif
  return a:indices
endfunction
if has('lua')
  function! s:_filter_candidates_lua(indices, candidates, patterns, ignorecase) abort
    lua << EOF
do
  local patterns = vim.eval('a:patterns')
  local candidates = vim.eval('a:candidates')
  local indices = vim.eval('a:indices')
  if (vim.eval('a:ignorecase') == 1) then
    for j = #indices-1, 0, -1 do
      for i = 0, #patterns-1 do
        if (string.find(string.lower(candidates[indices[j]].word), string.lower(patterns[i]), 1, true) == nil) then
          indices[j] = nil
          break
        end
      end
    end
  else
    for j = #indices-1, 0, -1 do
      for i = 0, #patterns-1 do
        if (string.find(candidates[indices[j]].word, patterns[i], 1, true) == nil) then
          indices[j] = nil
          break
        end
      end
    end
  end
end
EOF
    return a:indices
  endfunction
endif
if !has('nvim') && has('python')
  function! s:_filter_candidates_python(indices, candidates, patterns, ignorecase) abort
    python << EOF
import vim
def _temporary_scope():
  patterns = vim.bindeval('a:patterns')
  candidates = vim.bindeval('a:candidates')
  indices = vim.bindeval('a:indices')
  if int(vim.eval('a:ignorecase')) == 1:
    indices[:] = [
      i for i in indices
      if all(p.lower() in candidates[i]['word'].lower() for p in patterns)
    ]
  else:
    indices[:] = [
      i for i in indices
      if all(p in candidates[i]['word'] for p in patterns)
    ]
_temporary_scope()
del _temporary_scope
EOF
    return a:indices
  endfunction
endif
if !has('nvim') && has('python3')
  function! s:_filter_candidates_python3(indices, candidates, patterns, ignorecase) abort
    python3 << EOF
import vim
def _temporary_scope():
  patterns = vim.bindeval('a:patterns')
  candidates = vim.bindeval('a:candidates')
  indices = vim.bindeval('a:indices')
  if int(vim.eval('a:ignorecase')) == 1:
    indices[:] = [
      i for i in indices
      if all(p.lower() in candidates[i]['word'].lower() for p in patterns)
    ]
  else:
    indices[:] = [
      i for i in indices
      if all(p in candidates[i]['word'] for p in patterns)
    ]
_temporary_scope()
del _temporary_scope
EOF
    return a:indices
  endfunction
endif

" NOTE:
" In vim:  lua < python < python3 < vim
" In nvim: vim << python < python3
" https://gist.github.com/7bd3235de531c5dfac05a2f2fe7ddbf0#file-test2-vim
if has('lua')
  function! s:_filter_candidates(...) abort
    return call('s:_filter_candidates_lua', a:000)
  endfunction
elseif !has('nvim') && has('python')
  function! s:_filter_candidates(...) abort
    return call('s:_filter_candidates_python', a:000)
  endfunction
elseif !has('nvim') && has('python3')
  function! s:_filter_candidates(...) abort
    return call('s:_filter_candidates_python3', a:000)
  endfunction
else
  function! s:_filter_candidates(...) abort
    return call('s:_filter_candidates_vim', a:000)
  endfunction
endif
