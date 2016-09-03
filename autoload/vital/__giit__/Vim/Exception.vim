let s:handlers = []

function! s:_vital_loaded(V) abort
  let s:Prompt = a:V.import('Vim.Prompt')
  let s:Guard = a:V.import('Vim.Guard')
  call s:register(s:get_default_handler())
endfunction

function! s:_vital_depends() abort
  return ['Vim.Prompt', 'Vim.Guard']
endfunction

function! s:_throw(category, msg) abort
  if a:category ==# 'Info'
    let v:statusmsg = a:msg
  elseif a:category ==# 'Warning'
    let v:warningmsg = a:msg
  elseif a:category =~# '^\%(Error\|Critical\)$'
    let v:errmsg = a:msg
  endif
  return printf(
        \ 'vital: Vim.Exception: %s: %s',
        \ a:category,
        \ a:msg,
        \)
endfunction

function! s:info(msg) abort
  return s:_throw('Info', a:msg)
endfunction

function! s:warn(msg) abort
  return s:_throw('Warning', a:msg)
endfunction

function! s:error(msg) abort
  return s:_throw('Error', a:msg)
endfunction

function! s:critical(msg) abort
  return s:_throw('Critical', a:msg)
endfunction

function! s:handle(...) abort
  let l:exception = get(a:000, 0, v:exception)
  for Handler in reverse(copy(s:handlers))
    if call(Handler, [l:exception])
      return
    endif
  endfor
  throw l:exception
endfunction

function! s:call(funcref, args, ...) abort
  let guard = s:Guard.store([[s:handlers]])
  let instance = get(a:000, 0, 0)
  try
    if type(instance) == type({})
      return call(a:funcref, a:args, instance)
    else
      return call(a:funcref, a:args)
    endif
  catch /^vital: Vim\.Exception: /
    call s:handle()
  finally
    call guard.restore()
  endtry
endfunction

function! s:register(handler) abort
  call add(s:handlers, a:handler)
endfunction

function! s:unregister(handler) abort
  let index = index(s:handlers, a:handler)
  if index != -1
    call remove(s:handlers, index)
  endif
endfunction

function! s:get_default_handler() abort
  return function('s:_default_handler')
endfunction


" Handler --------------------------------------------------------------------
function! s:_default_handler(exception) abort
  let m = matchlist(a:exception, '^vital: Vim\.Exception: \(\w\+\): \(.*\)')
  if len(m)
    let category = m[1]
    let message = m[2]
    if category ==# 'Info'
      redraw
      for line in split(message, '\r\?\n')
        call s:Prompt.echo('None', line)
      endfor
      call s:Prompt.debug(v:throwpoint)
      return 1
    elseif category ==# 'Warning'
      redraw
      for line in split(message, '\r\?\n')
        call s:Prompt.warn(line)
      endfor
      call s:Prompt.debug(v:throwpoint)
      return 1
    elseif category ==# 'Error'
      redraw
      for line in split(message, '\r\?\n')
        call s:Prompt.error(line)
      endfor
      for line in split(v:throwpoint, '\r\?\n')
        call s:Prompt.debug(line)
      endfor
      return 1
    elseif category ==# 'Critical'
      redraw
      for line in split(message, '\r\?\n')
        call s:Prompt.debug(line)
      endfor
      for line in split(v:throwpoint, '\r\?\n')
        call s:Prompt.debug(line)
      endfor
    endif
    throw message
  endif
  return 0
endfunction
