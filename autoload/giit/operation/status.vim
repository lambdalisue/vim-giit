let s:Path = vital#giit#import('System.Filepath')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#operation#status#command(args) abort
  let git = giit#core#get_or_fail()
  let opener = a:args.pop('-o|--opener', 'botright 15split')
  let bufname = giit#component#bufname(git, 'status', 1)

  call s:Anchor.focus_if_available(opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, {
          \ 'group': 'selector',
          \ 'opener': opener,
          \})
  finally
    call guard.restore()
  endtry
  let is_expired = !context.bufloaded || giit#meta#modified('args', a:args)
  call giit#meta#set('args', a:args)
  if is_expired
    edit!
  endif
  call context.end()
endfunction

function! giit#operation#status#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! giit#operation#status#execute(git, args) abort
  return a:git.execute(['status'] + a:args.raw, {
        \ 'encode_output': 0,
        \})
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
