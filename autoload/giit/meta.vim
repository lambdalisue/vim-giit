let s:Cache = vital#giit#import('System.Cache.Memory')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#meta#get_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.get, a:000, meta)
endfunction

function! giit#meta#set_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.set, a:000, meta)
endfunction

function! giit#meta#has_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.has, a:000, meta)
endfunction

function! giit#meta#remove_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.remove, a:000, meta)
endfunction

function! giit#meta#clear_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.clear, a:000, meta)
endfunction

function! giit#meta#get_or_fail_at(expr, name) abort
  let meta = s:meta(a:expr)
  if !meta.has(a:name)
    throw s:Exception.critical(printf(
          \ 'giit: An required meta value "%s" does not exist on "%s"',
          \ a:name,
          \ bufname(a:expr),
          \))
  endif
  return meta.get(a:name)
endfunction

function! giit#meta#is_modified_at(expr, name, value) abort
  let meta = s:meta(a:expr)
  if !meta.has(a:name)
    return 1
  endif
  return meta.get(a:name) != a:value
endfunction

function! giit#meta#get(...) abort
  return call('giit#meta#get_at', ['%'] + a:000)
endfunction

function! giit#meta#set(...) abort
  return call('giit#meta#set_at', ['%'] + a:000)
endfunction

function! giit#meta#has(...) abort
  return call('giit#meta#has_at', ['%'] + a:000)
endfunction

function! giit#meta#remove(...) abort
  return call('giit#meta#remove_at', ['%'] + a:000)
endfunction

function! giit#meta#clear(...) abort
  return call('giit#meta#clear_at', ['%'] + a:000)
endfunction

function! giit#meta#get_or_fail(...) abort
  return call('giit#meta#get_or_fail_at', ['%'] + a:000)
endfunction

function! giit#meta#is_modified(...) abort
  return call('giit#meta#is_modified_at', ['%'] + a:000)
endfunction


function! s:meta(expr) abort
  let bufnr = bufnr(a:expr)
  if !bufexists(bufnr)
    " Always return a fresh cache instance
    return s:Cache.new()
  endif
  let meta = getbufvar(bufnr, 'giit_meta', {})
  if empty(meta)
    let meta = s:Cache.new()
    call setbufvar(bufnr, 'giit_meta', meta)
  endif
  return meta
endfunction
