let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#command#command(...) abort
  return s:Exception.call(function('s:command'), a:000)
endfunction

function! giit#command#complete(...) abort
  return s:Exception.call(function('s:complete'), a:000)
endfunction


" Private --------------------------------------------------------------------
function! s:command(bang, range, qargs) abort
  let args   = s:Argument.new(a:qargs)
  let scheme = args.get_p(0, '')
  if a:bang !=# '!' && !empty(scheme)
    try
      return call(
            \ printf('giit#command#%s#command', scheme),
            \ [a:range, a:qargs]
            \)
    "catch /^Vim\%((\a\+)\)\=:E117/
    catch /E117/
      call s:Prompt.debug(v:exception)
      call s:Prompt.debug(v:throwpoint)
    endtry
  endif
  return giit#command#common#command(a:range, a:qargs)
endfunction

function! s:complete(arglead, cmdline, cursorpos) abort
  call s:Exception.register(function('s:complete_exception_handler'))
  let cmdline = matchstr(a:cmdline, '^\w\+ \zs.*\ze .*$')
  let args    = s:Argument.new(cmdline)
  let scheme  = args.get_p(0, '')
  if a:cmdline !~# '^\w\+!' && !empty(scheme)
    try
      return giit#command#{scheme}#complete(a:arglead, a:cmdline, a:cursorpos)
      return call(
            \ printf('giit#command#%s#complete', scheme),
            \ [a:arglead, a:cmdline, a:cursorpos]
            \)
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:Prompt.debug(v:exception)
      call s:Prompt.debug(v:throwpoint)
    endtry
  endif
  return giit#command#common#complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:complete_exception_handler(exception) abort
  call s:Prompt.debug(v:exception)
  call s:Prompt.debug(v:throwpoint)
  return 1
endfunction


