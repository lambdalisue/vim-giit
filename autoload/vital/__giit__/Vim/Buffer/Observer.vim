let s:name = sha256(expand('<sfile>'))
let s:registry = {}

function! s:attach(...) abort dict
  let function_or_command = get(a:000, 0, 'edit')
  let bufnum = string(bufnr('%'))
  let s:registry[bufnum] = {
        \ 'callback': function_or_command,
        \ 'args': a:000[1 : ],
        \}
  return s:registry[bufnum]
endfunction

function! s:is_attached() abort
  let bufnum = string(bufnr('%'))
  return has_key(s:registry, bufnum)
endfunction

function! s:update() abort
  let bufnum = string(bufnr('%'))
  let info = get(s:registry, bufnum, {})
  if !empty(info)
    if type(info.callback) == type('')
      execute info.callback
    else
      call call(info.callback, info.args, info)
    endif
  endif
endfunction

function! s:update_all() abort
  let winnum_saved = winnr()
  try
    for bufnum in keys(s:registry)
      let winnum = bufwinnr(str2nr(bufnum))
      if winnum > 0
        silent execute printf('noautocmd keepjumps %dwincmd w', winnum)
        call s:update()
      elseif bufexists(str2nr(bufnum))
        execute printf('augroup _vital_interface_observer_%s', s:name)
        execute printf('autocmd! * <buffer=%s>', bufnum)
        execute printf(
              \ 'autocmd WinEnter <buffer=%s> nested call s:_on_WinEnter()',
              \ bufnum,
              \)
        execute printf(
              \ 'autocmd BufWinEnter <buffer=%s> nested call s:_on_WinEnter()',
              \ bufnum,
              \)
        execute 'augroup END'
      else
        " no longer exists
        silent unlet s:registry[bufnum]
      endif
    endfor
  finally
    silent execute printf('noautocmd keepjumps %dwincmd w', winnum_saved)
  endtry
endfunction

function! s:_on_WinEnter() abort
  if !exists(printf('#_vital_interface_observer_%s', s:name))
    return
  endif
  execute printf('augroup _vital_interface_observer_%s', s:name)
  execute 'autocmd! * <buffer>'
  execute 'augroup END'
  call s:update()
endfunction

function! s:_execute(command) abort
  execute a:command
endfunction
