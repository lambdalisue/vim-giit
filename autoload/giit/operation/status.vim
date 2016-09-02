let s:Path = vital#giit#import('System.Filepath')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:t_number = type(0)


" SYNOPSIS
" Giit status [options]
function! giit#operation#status#command(args) abort
  let git = giit#core#get_or_fail()
  let args = s:adjust(git, a:args)
  let bufname = giit#component#bufname(git, 'status', 1)

  call s:Anchor.focus_if_available(args.options.opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, {
          \ 'group': 'selector',
          \ 'opener': args.options.opener,
          \})
  finally
    call guard.restore()
  endtry
  call giit#meta#set('args', args)
  edit
  call context.end()
endfunction

function! giit#operation#status#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! giit#operation#status#execute(git, args) abort
  let args = giit#util#collapse([
        \ 'status',
        \ a:args.raw,
        \])
  return a:git.execute(args, {
        \ 'encode_output': 0,
        \})
endfunction


function! s:adjust(git, args) abort
  let args = a:args.clone()

  " Add requirements
  call args.set('--porcelain', 1)
  call args.set('--no-column', 1)
  " Remove unsupported options
  call args.pop('-s|--short')
  call args.pop('-b|--branch')
  call args.pop('--long')
  call args.pop('-z')
  call args.pop('--column')

  let args.options = {}
  let args.options.opener = args.pop('-o|--opener', 'botright 15split')
  return args.lock()
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
