let s:Cache = vital#giit#import('System.Cache.Memory')
let s:Exception = vital#giit#import('Vim.Exception')

function! giit#meta#require(name) abort
  return giit#meta#require_at('%', a:name)
endfunction

function! giit#meta#require_at(expr, name) abort
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

function! giit#meta#modified(name, value) abort
  return giit#meta#modified_at('%', a:name, a:value)
endfunction

function! giit#meta#modified_at(expr, name, value) abort
  let meta = s:meta(a:expr)
  if !meta.has(a:name)
    return 1
  endif
  return meta.get(a:name) != a:value
endfunction

function! giit#meta#get(...) abort
  let meta = s:meta('%')
  return call(meta.get, a:000, meta)
endfunction

function! giit#meta#get_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.get, a:000, meta)
endfunction

function! giit#meta#set(...) abort
  let meta = s:meta('%')
  return call(meta.set, a:000, meta)
endfunction

function! giit#meta#set_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.set, a:000, meta)
endfunction

function! giit#meta#has(...) abort
  let meta = s:meta('%')
  return call(meta.has, a:000, meta)
endfunction

function! giit#meta#has_at(expr, ...) abort
  let meta = s:meta(a:expr)
  return call(meta.has, a:000, meta)
endfunction

function! giit#meta#remove(...) abort
  let meta = s:meta('%')
  return call(meta.remove, a:000, meta)
endfunction

function! giit#meta#clear(...) abort
  let meta = s:meta('%')
  return call(meta.clear, a:000, meta)
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
