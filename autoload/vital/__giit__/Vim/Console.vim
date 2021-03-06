function! s:_vital_created(module) abort
  let s:config = {
        \ 'debug': -1,
        \ 'batch': 0,
        \}
endfunction

function! s:get_config() abort
  return deepcopy(s:config)
endfunction

function! s:set_config(config) abort
  let s:config = extend(s:config, a:config)
endfunction

function! s:is_batch() abort
  if type(s:config.batch) == 2
    return s:config.batch()
  else
    return s:config.batch
  endif
endfunction

function! s:is_debug() abort
  if type(s:config.debug) == 2
    return s:config.debug()
  else
    return s:config.debug == -1 ? &verbose : s:config.debug
  endif
endfunction

" echo({hl}[, {msg} ...])
function! s:echo(hl, ...) abort
  let msg = join(map(copy(a:000), 's:_ensure_string(v:val)'))
  execute 'echohl' a:hl
  try
    echo msg
  finally
    echohl None
  endtry
endfunction

" echomsg({hl}[, {msg} ...])
function! s:echomsg(hl, ...) abort
  let msg = join(map(copy(a:000), 's:_ensure_string(v:val)'))
  execute 'echohl' a:hl
  try
    echomsg msg
  finally
    echohl None
  endtry
endfunction

" input({hl}, {msg} [, {text} [, {completion}]])
function! s:input(hl, msg, ...) abort
  if s:is_batch()
    return ''
  endif
  let msg = s:_ensure_string(a:msg)
  execute 'echohl' a:hl
  call inputsave()
  try
    if empty(get(a:000, 1, ''))
      return input(msg, get(a:000, 0, ''))
    else
      return input(msg, get(a:000, 0, ''), get(a:000, 1, ''))
    endif
  finally
    echohl None
    call inputrestore()
  endtry
endfunction

" inputlist({hl}, {textlist})
function! s:inputlist(hl, textlist) abort
  if s:is_batch()
    return 0
  endif
  let textlist = map(copy(a:textlist), 's:_ensure_string(v:val)')
  execute 'echohl' a:hl
  call inputsave()
  try
    return inputlist(textlist)
  finally
    echohl None
    call inputrestore()
  endtry
endfunction

" debug([{msg}...])
function! s:debug(...) abort
  if !s:is_debug()
    return
  endif
  call call('s:echomsg', ['Comment'] + a:000)
endfunction

" warn([{msg}...])
function! s:warn(...) abort
  call call('s:echomsg', ['WarningMsg'] + a:000)
endfunction

" error([{msg}...])
function! s:error(...) abort
  let v:errmsg = join(map(
        \ copy(a:000),
        \ 'type(v:val) == 1 ? v:val : string(v:val)',
        \))
  call call('s:echomsg', ['ErrorMsg'] + a:000)
endfunction

" ask({msg} [, {default} [, {completion}]])
function! s:ask(msg, ...) abort
  if s:is_batch()
    return ''
  endif
  let result = s:input(
        \ 'Question',
        \ a:msg,
        \ get(a:000, 0, ''),
        \ get(a:000, 1, ''),
        \)
  redraw
  return result
endfunction

" select({msg}, {candidates} [, {canceled}])
function! s:select(msg, candidates, ...) abort
  let canceled = get(a:000, 0, '')
  if s:is_batch()
    return canceled
  endif
  let candidates = map(
        \ copy(a:candidates),
        \ 'v:key+1 . ''. '' . s:_ensure_string(v:val)'
        \)
  let result = s:inputlist('Question', extend([a:msg], candidates))
  redraw
  return result == 0 ? canceled : a:candidates[result-1]
endfunction

" confirm({msg} [, {default}])
function! s:confirm(msg, ...) abort
  if s:is_batch()
    return 0
  endif
  let completion = printf(
        \ 'customlist,%s',
        \ s:_get_function_name(function('s:_confirm_complete'))
        \)
  let result = s:input(
        \ 'Question',
        \ printf('%s (y[es]/n[o]): ', a:msg),
        \ get(a:000, 0, ''),
        \ completion,
        \)
  while result !~? '^\%(y\%[es]\|n\%[o]\)$'
    redraw
    if result ==# ''
      call s:echo('WarningMsg', 'Canceled.')
      break
    endif
    call s:echo('WarningMsg', 'Invalid input.')
    let result = s:input(
          \ 'Question',
          \ printf('%s (y[es]/n[o]): ', a:msg),
          \ get(a:000, 0, ''),
          \ completion,
          \)
  endwhile
  redraw
  return result =~? 'y\%[es]'
endfunction

" capture({command})
if exists('*execute')
  let s:capture = function('execute')
else
  function! s:capture(command) abort
    try
      redir => content
      silent execute a:command
    finally
      redir END
    endtry
    return split(content, '\r\?\n', 1)
  endfunction
endif

if has('patch-7.4.1738')
  function! s:clear() abort
    messages clear
  endfunction
else
  " @vimlint(EVL102, 1, l:i)
  function! s:clear() abort
    for i in range(201)
      echomsg ''
    endfor
  endfunction
  " @vimlint(EVL102, 0, l:i)
endif

function! s:_confirm_complete(arglead, cmdline, cursorpos) abort
  return filter(['yes', 'no'], 'v:val =~# ''^'' . a:arglead')
endfunction

function! s:_ensure_string(x) abort
  return type(a:x) == 1 ? a:x : string(a:x)
endfunction

if has('patch-7.4.1842')
  function! s:_get_function_name(fn) abort
    return get(a:fn, 'name')
  endfunction
else
  function! s:_get_function_name(fn) abort
    return matchstr(string(a:fn), 'function(''\zs.*\ze''')
  endfunction
endif
