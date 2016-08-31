let s:Guard = vital#giit#import('Vim.Guard')
let s:Argument = vital#giit#import('Argument')
let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#operation#show#execute(git, args) abort
  let raw_args = filter(copy(a:args.raw), '!empty(v:val)')
  return a:git.execute(raw_args, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#show#command(cmdline, bang, range) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:cmdline)
  let object = args.get_p(1)
  let bufname = giit#util#buffer#bufname(git, 'show')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ empty(args.pop('-p|--patch')) ? '' : ':patch',
        \ object,
        \)

  let opener = args.pop('-o|--opener', '')
  let window = args.pop('--window', '')

  call s:BufferAnchor.focus_if_available(opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let ret = giit#util#buffer#open(bufname, {
          \ 'window': window,
          \ 'opener': opener,
          \})
  finally
    call guard.restore()
  endtry
  call giit#meta#set('args', args)
  call giit#util#doautocmd('BufReadCmd')
  call giit#util#buffer#finalize(ret)
endfunction

function! giit#operation#show#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \ '--window=',
          \ '--selection=',
          \ '-p', '--patch',
          \])
  elseif a:arglead =~# '^[^:]*:'
    let m = matchlist(a:arglead, '^\([^:]*:\)\(.*\)$')
    let [prefix, arglead] = m[1:2]
    let candidates = giit#complete#filename#tracked(arglead, a:cmdline, a:cursorpos)
    return map(candidates, 'prefix . v:val')
  else
    return giit#complete#commit#any(a:arglead, a:cmdline, a:cursorpos)
  endif
endfunction
