let s:Dict = vital#giit#import('Data.Dict')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')
let s:GitProcess = vital#giit#import('Git.Process')


" Pubic ----------------------------------------------------------------------
function! giit#operation#command(...) abort
  return s:Exception.call(function('s:command'), a:000)
endfunction

function! giit#operation#execute(...) abort
  return s:Exception.call(function('s:execute'), a:000)
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
function! s:command(qbang, range, qargs) abort
  let args   = s:Argument.new(a:qargs)
  let scheme = args.get_p(0, '')
  if a:qbang !=# '!' && !empty(scheme)
    let fname  = giit#util#fname('operation', scheme, 'command')
    try
      call call(fname, [a:range, a:qargs])
      return
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:Prompt.debug(v:exception)
      call s:Prompt.debug(v:throwpoint)
    endtry
  endif
  let result = giit#operation#execute(args.lock())
  if !args.get('-q|--quiet')
    call giit#operation#inform(result)
  endif
  return
endfunction

function! s:execute(git, args) abort
  let scheme = a:args.get_p(0, '')
  let fname  = giit#util#fname('operation', scheme, 'execute')
  try
    return call(fname, [a:git, a:args])
  catch /^Vim\%((\a\+)\)\=:E117/
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
  endtry
  let args   = a:args.clone()
  let args   = args.map_p({ v -> v ==# '%' ? giit#expand(v) : v })
  let method = s:is_interactive(args) ? 'shell' : 'execute'

  return s:GitProcess[method](a:git, args.raw, { 'stdout': 1 })
endfunction

function! s:complete(arglead, cmdline, cursorpos) abort
  call s:Exception.register(function('s:complete_exception_handler'))
  let cmdline = matchstr(a:cmdline, '^\w\+ \zs.*\ze .*$')
  let args    = s:Argument.new(cmdline)
  let scheme  = args.get_p(0, '')
  if a:cmdline !~# '^\w\+!' && !empty(scheme)
    let fname   = giit#util#fname('operation', scheme, 'complete')
    try
      return call(fname, [a:arglead, a:cmdline, a:cursorpos])
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:Prompt.debug(v:exception)
      call s:Prompt.debug(v:throwpoint)
    endtry
  endif
  let candidates = [
        \ 'edit',
        \ 'show',
        \ 'status',
        \ 'commit',
        \ 'log',
        \]
  return giit#complete#filter(a:arglead, candidates)
endfunction

function! s:complete_exception_handler(exception) abort
  call s:Prompt.debug(v:exception)
  call s:Prompt.debug(v:throwpoint)
  return 1
endfunction

function! s:is_interactive(args) abort
  if a:args.pop('--interactive')
    return 1
  elseif a:args.get_p(0, '') =~# '^\%(clone\|fetch\|push\|pull\|checkout\)$'
    " Command which access to a remote may fail and ask users to fill them
    " password so these command should be performed with :! instead.
    return 1
  endif
  return 0
endfunction
