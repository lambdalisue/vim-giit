let s:cascades = {}


function! s:new(name) abort
  let doom = extend(deepcopy(s:doom), {
        \ 'name': a:name,
        \})
  return doom
endfunction


let s:doom = {
      \ 'companies': [],
      \ 'properties': {},
      \}

function! s:doom.involve(expr, ...) abort
  let property = extend({
        \ 'keep': 0,
        \}, get(a:000, 0, {})
        \)
  let bufnr = bufnr(a:expr)
  let self.companies += [bufnr]
  let self.properties[string(bufnr)] = property
  call setbufvar(bufnr, '_vital_doom_' . self.name, self)

  execute printf('augroup vital-internal-vim-buffer-doom-%s', self.name)
  execute printf('autocmd! * <buffer=%d>', bufnr)
  execute printf('autocmd WinLeave <buffer=%d> call s:_on_WinLeave(''%s'')', bufnr, self.name)
  execute printf('autocmd WinEnter * call s:_on_WinEnter(''%s'')', self.name)
  execute 'augroup END'
endfunction

function! s:doom.annihilate() abort
  for bufnr in self.companies
    execute printf('augroup vital-internal-vim-buffer-doom-%s', self.name)
    execute printf('autocmd! * <buffer=%d>', bufnr)
    execute 'augroup END'

    let winnr = bufwinnr(bufnr)
    let property = self.properties[string(bufnr)]
    if property.keep || !bufexists(bufnr) || winnr == -1 || getbufvar(bufnr, '&modified')
      continue
    endif
    execute printf('%dclose', winnr)
  endfor
endfunction

function! s:_on_WinLeave(name) abort
  let vname = '_vital_doom_' . a:name
  if exists('b:' . vname)
    let s:cascades[a:name] = {
          \ 'nwin': winnr('$'),
          \ 'doom': get(b:, vname),
          \}
  endif
endfunction

function! s:_on_WinEnter(name) abort
  if has_key(s:cascades, a:name)
    if winnr('$') < s:cascades[a:name].nwin
      call s:cascades[a:name].doom.annihilate()
    endif
    unlet s:cascades[a:name]
  endif
endfunction
