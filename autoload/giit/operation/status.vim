let s:Path = vital#giit#import('System.Filepath')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Argument = vital#giit#import('Argument')


function! giit#operation#status#execute(git, args) abort
  return a:git.execute(a:args.raw, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#status#command(cmdline, bang, range) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:cmdline)
  let bufname = giit#util#buffer#bufname(git, 'status', 1)
  let opener = args.pop('-o|--opener', 'botright 15split')
  let window = args.pop('--window', 'selector')

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

function! giit#operation#status#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction


" Parse ----------------------------------------------------------------------
let s:record_pattern =
      \ '^\(..\) \("[^"]\{-}"\|.\{-}\)\%( -> \("[^"]\{-}"\|[^ ]\+\)\)\?$'

function! giit#operation#status#parse(git, content) abort
  let prefix = a:git.worktree . s:Path.separator()
  let candidates = map(copy(a:content), 's:parse_record(prefix, v:val)')
  call filter(candidates, '!empty(v:val)')
  call sort(candidates, function('s:compare_candidate'))
  return candidates
endfunction

function! s:parse_record(prefix, record) abort
  let m = matchlist(a:record, s:record_pattern)
  if len(m) && !empty(m[3])
    return {
          \ 'word': a:record,
          \ 'sign': m[1],
          \ 'path': a:prefix . s:strip_quotes(m[3]),
          \ 'path1': a:prefix . s:strip_quotes(m[2]),
          \ 'path2': a:prefix . s:strip_quotes(m[3]),
          \}
  elseif len(m) && !empty(m[2])
    return {
          \ 'word': a:record,
          \ 'sign': m[1],
          \ 'path': a:prefix . s:strip_quotes(m[2]),
          \ 'path1': a:prefix . s:strip_quotes(m[2]),
          \ 'path2': '',
          \}
  else
    return {}
  endif
endfunction

function! s:compare_candidate(a, b) abort
  return a:a.path == a:b.path ? 0 : a:a.path > a:b.path ? 1 : -1
endfunction

function! s:strip_quotes(str) abort
  return a:str =~# '^\%(".*"\|''.*''\)$' ? a:str[1:-2] : a:str
endfunction
