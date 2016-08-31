let s:Dict = vital#giit#import('Data.Dict')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')
let s:GitProcess = vital#giit#import('Git.Process')


" Pubic ----------------------------------------------------------------------
function! giit#operation#command(...) abort
  return s:Exception.call(function('s:command'), a:000)
endfunction

function! giit#operation#complete(...) abort
  return s:Exception.call(function('s:complete'), a:000)
endfunction

function! giit#operation#inform(result) abort
  let [hl, prefix] = a:result.status
        \ ? ['WarningMsg', 'Fail']
        \ : ['Title', 'OK']
  redraw | echo
  call s:Prompt.echo(hl, prefix . ': ' . join(a:result.args))
  for line in a:result.content
    call s:Prompt.echo('None', line)
  endfor
endfunction

function! giit#operation#throw(result) abort
  call giit#operation#inform(a:result)
  throw s:Exception.error('')
endfunction


" Private --------------------------------------------------------------------
function! s:command(cmdline, bang, range) abort
  let args = s:Argument.new(a:cmdline)
  let name = args.get_p(0)
  if !empty(name) && a:bang !=# '!'
    try
      let fname = printf(
            \ 'giit#operation#%s#command',
            \ substitute(name, '-', '_', 'g')
            \)
      return call(fname, [a:cmdline, a:bang, a:range])
    catch /^Vim\%((\a\+)\)\=:E117/
      " fail silently
    endtry
  endif

  let git = giit#core#get()
  let args.raw = map(args.raw, 'v:val ==# ''%'' ? giit#expand(v:val) : v:val')
  let result = s:GitProcess.shell(git, args.raw, {
        \ 'stdout': 1,
        \})
  if !args.get('-q|--quiet')
    call giit#operation#inform(result)
  endif
  return result
endfunction

function! s:complete(arglead, cmdline, cursorpos) abort
  call s:Exception.register(function('s:complete_exception_handler'))
  let cmdline = matchstr(a:cmdline, '^\w\+ \zs.*\ze .*$')
  let args = s:Argument.new(cmdline)
  let name = args.get_p(0)
  if !empty(name) && a:cmdline !~# '^\w\+!'
    try
      let fname = printf(
            \ 'giit#operation#%s#complete',
            \ substitute(name, '-', '_', 'g')
            \)
      return call(fname, [a:arglead, a:cmdline, a:cursorpos])
    catch /^Vim\%((\a\+)\)\=:E117/
      " fail silently
    endtry
  endif
  let candidates = [
        \ 'show',
        \ 'log',
        \]
  return giit#complete#filter(a:arglead, candidates)
endfunction

function! s:complete_exception_handler(exception) abort
  call s:Prompt.debug(v:exception)
  call s:Prompt.debug(v:throwpoint)
  return 1
endfunction
