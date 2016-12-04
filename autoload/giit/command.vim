let s:Console = vital#giit#import('Vim.Console')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


" Entry point ----------------------------------------------------------------
function! giit#command#execute(...) abort
  return s:Exception.call(function('s:execute'), a:000)
endfunction

function! giit#command#complete(...) abort
  return s:Exception.call(function('s:complete'), a:000)
endfunction


" Public ---------------------------------------------------------------------
function! giit#command#complete_opener(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#util#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \])
  endif
  return []
endfunction

function! giit#command#complete_selection(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#util#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \])
  endif
  return []
endfunction

" Private --------------------------------------------------------------------
function! s:execute(bang, range, qargs) abort
  let args = s:Argument.new(a:qargs)
  let scheme = args.get_p(0, '')
  if a:bang !=# '!' && !empty(scheme)
    try
      return call(
            \ printf('giit#command#%s#execute', scheme),
            \ [a:range, a:qargs]
            \)
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:Console.debug(v:exception)
      call s:Console.debug(v:throwpoint)
    endtry
  endif
  return giit#command#core#execute(a:range, a:qargs)
endfunction

function! s:complete(arglead, cmdline, cursorpos) abort
  call s:Exception.register(function('s:complete_exception_handler'))
  let cmdline = matchstr(a:cmdline, '^\w\+ \zs.*\ze .*$')
  let args    = s:Argument.new(cmdline)
  let scheme  = args.get_p(0, '')
  if a:cmdline !~# '^\w\+!' && !empty(scheme)
    try
      return call(
            \ printf('giit#command#%s#complete', scheme),
            \ [a:arglead, a:cmdline, a:cursorpos]
            \)
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:Console.debug(v:exception)
      call s:Console.debug(v:throwpoint)
    endtry
  endif
  return giit#command#core#complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:complete_exception_handler(exception) abort
  call s:Console.debug(v:exception)
  call s:Console.debug(v:throwpoint)
  return 1
endfunction
