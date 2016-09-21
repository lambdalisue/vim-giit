let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#operator#autocmd(event) abort
  let scheme = matchstr(
        \ expand('<afile>'),
        \ 'giit:\%(//\)\?[^:]\+:\zs[^:/]\+\ze'
        \)
  let scheme = substitute(scheme, '-', '_', 'g')
  return s:Exception.call(
        \ printf('giit#component#%s#buffer#%s', scheme, a:event),
        \ [],
        \)
endfunction

function! giit#operator#command(...) abort
  return s:Exception.call(function('s:command'), a:000)
endfunction

function! giit#operator#complete(...) abort
  return s:Exception.call(function('s:complete'), a:000)
endfunction

function! giit#operator#execute(git, args) abort
  let scheme = substitute(a:args.get_p(0, ''), '-', '_', 'g')
  try
    return call(
          \ printf('giit#component#%s#process#execute', scheme),
          \ [a:git, a:args]
          \)
  catch /^Vim\%((\a\+)\)\=:E117/
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
  endtry
  return giit#process#execute(a:git, a:args)
endfunction


" Private --------------------------------------------------------------------
function! s:command(bang, range, qargs) abort
  let args = s:Argument.new(a:qargs)
  let scheme = args.get_p(0, '')
  if a:bang !=# '!' && !empty(scheme)
    try
      return call(
            \ printf('giit#component#%s#command#command', scheme),
            \ [a:range, a:qargs]
            \)
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:Prompt.debug(v:exception)
      call s:Prompt.debug(v:throwpoint)
    endtry
  endif

  let git = giit#core#get()
  let options = {
        \ 'quiet': args.pop('-q|--quiet'),
        \}
  let result = giit#operator#execute(git, args)
  if !options.quiet
    call giit#process#inform(result)
  endif
  call giit#trigger_modified()
  return result
endfunction

function! s:complete(arglead, cmdline, cursorpos) abort
  call s:Exception.register(function('s:complete_exception_handler'))
  let cmdline = matchstr(a:cmdline, '^\w\+ \zs.*\ze .*$')
  let args    = s:Argument.new(cmdline)
  let scheme  = args.get_p(0, '')
  if a:cmdline !~# '^\w\+!' && !empty(scheme)
    try
      return call(
            \ printf('giit#component#%s#command#complete', scheme),
            \ [a:arglead, a:cmdline, a:cursorpos]
            \)
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:Prompt.debug(v:exception)
      call s:Prompt.debug(v:throwpoint)
    endtry
  endif
  return []
endfunction

function! s:complete_exception_handler(exception) abort
  call s:Prompt.debug(v:exception)
  call s:Prompt.debug(v:throwpoint)
  return 1
endfunction
