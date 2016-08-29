let s:handlers = []

function! s:_vital_loaded(V) abort
  let s:Prompt = a:V.import('Vim.Prompt')
  call s:register(s:get_default_handler())
endfunction

function! s:_vital_depends() abort
  return ['Vim.Prompt']
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
  for Handler in s:handlers
    if call(Handler, [l:exception])
      return
    endif
  endfor
  throw l:exception
endfunction

function! s:call(funcref, args, ...) abort
  let instance = get(a:000, 0, 0)
  try
    if type(instance) == type({})
      return call(a:funcref, a:args, instance)
    else
      return call(a:funcref, a:args)
    endif
  catch /^vital: Vim\.Exception: /
    call s:handle()
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
      call s:Prompt.echo('None', message)
      call s:Prompt.debug(v:throwpoint)
      return 1
    elseif category ==# 'Warning'
      call s:Prompt.warn(message)
      call s:Prompt.debug(v:throwpoint)
      return 1
    elseif category ==# 'Error'
      call s:Prompt.error(message)
      call s:Prompt.debug(v:throwpoint)
      return 1
    elseif category ==# 'Critical'
      call s:Prompt.debug(message)
      call s:Prompt.debug(v:throwpoint)
    endif
    throw message
  endif
  return 0
endfunction
