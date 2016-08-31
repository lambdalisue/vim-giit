let s:Guard = vital#giit#import('Vim.Guard')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Argument = vital#giit#import('Argument')


function! giit#operation#show#command(cmdline, bang, range) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:cmdline)
  let object = args.apply_p(1, function('s:expand_object', [git]))
  let bufname = giit#util#buffer#bufname(git, 'show')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ empty(args.pop('-p|--patch')) ? '' : ':patch',
        \ object,
        \)
  let opener = args.pop('-o|--opener', '')
  let window = args.pop('--window', '')

  call s:Anchor.focus_if_available(opener)
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

function! giit#operation#show#execute(git, args) abort
  let args = a:args.clone()
  call args.apply_p(1, function('s:normalize_object', [a:git]))
  call filter(args.raw, '!empty(v:val)')
  return a:git.execute(args.raw, {
        \ 'encode_output': 0,
        \})
endfunction


function! s:expand_object(git, _, object) abort
  let m = matchlist(a:object, '^\([^:]*:\?\)\(.*\)$')
  if empty(m)
    return ''
  endif
  let relpath = a:git.relpath(giit#expand(m[2]))
  return m[1] . relpath
endfunction

function! s:normalize_object(git, _, object) abort
  let m = matchlist(a:object, '^\([^:]*\)\%(:\(.*\)\)\?$')
  if empty(m)
    return ''
  endif
  let commit  = giit#util#normalize#commit(a:git, m[1])
  let relpath = a:git.relpath(giit#expand(m[2]))
  return empty(relpath) ? commit : commit . ':' . relpath
endfunction
