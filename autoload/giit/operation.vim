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
function! s:command(bang, range, cmdline) abort
  let args = s:Argument.parse(a:cmdline)
  let args.options = {}
  let args.options.bang = a:bang ==# '!'
  let args.options.range = a:range
  let args.options.quiet = args.pop('-q|--quiet')
  let args.options.opener = args.pop('-o|--opener', '')
  let args.options.window = args.pop('-w|--window', '')
  let args.options.selection = args.pop('-s|--selection', '')

  let name = args.p.get(0, '')
  if !empty(name) && !args.options.bang
    try
      let fname = printf(
            \ 'giit#operation#%s#command',
            \ substitute(name, '-', '_', 'g')
            \)
      return call(fname, [a:bang, a:range, a:cmdline])
    catch /^Vim\%((\a\+)\)\=:E117/
      " fail silently
    endtry
  endif

  let git = giit#core#get()
  let args.raw = map(args.raw, 'v:val ==# ''%'' ? giit#expand(v:val) : v:val')
  let result = s:GitProcess.shell(git, args.raw, {
        \ 'stdout': 1,
        \})
  if !args.options.quiet
    call giit#operation#inform(result)
  endif
  return result
endfunction

function! s:complete(arglead, cmdline, cursorpos) abort
  let cmdline = substitute(a:cmdline, '^\S\+\?\s', '', '')
  let cmdline = substitute(cmdline, '\S\+$', '', '')
  let args = s:Argument.parse(cmdline)
  let args.options = {}
  let args.options.arglead = a:arglead
  let args.options.cmdline = a:cmdline
  let args.options.cursorpos = a:cursorpos
  let args.options.bang = a:cmdline =~# '\S\+!'
  let args.options.range = [0, 0]
  let args.options.quiet = args.pop('-q|--quiet')
  let args.options.opener = args.pop('-o|--opener', '')
  let args.options.window = args.pop('-w|--window', '')
  let args.options.selection = args.pop('-s|--selection', '')

  let name = args.p.pop(0, '')
  if !empty(name) && !args.options.bang
    try
      let fname = printf(
            \ 'giit#operation#%s#complete',
            \ substitute(name, '-', '_', 'g'),
            \)
      return call(fname, [args])
    catch /^Vim\%((\a\+)\)\=:E117/
      " fail silently
    endtry
    " complete filename
    return giit#util#complete#filename(a:arglead, cmdline, a:cursorpos)
  endif
  let candidates = filter([
      \ 'add',
      \ 'apply',
      \ 'blame',
      \ 'branch',
      \ 'browse',
      \ 'cd',
      \ 'chaperone',
      \ 'checkout',
      \ 'commit',
      \ 'diff',
      \ 'diff-ls',
      \ 'grep',
      \ 'lcd',
      \ 'ls-files',
      \ 'ls-tree',
      \ 'merge',
      \ 'patch',
      \ 'rebase',
      \ 'reset',
      \ 'rm',
      \ 'show',
      \ 'status',
      \ 'init',
      \ 'pull',
      \ 'push',
      \ 'stash',
      \ 'remote',
      \ 'tag',
      \ 'log',
      \], 'v:val =~# ''^'' . a:arglead')
  return candidates
endfunction
