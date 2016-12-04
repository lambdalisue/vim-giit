let s:Path = vital#giit#import('System.Filepath')
let s:Argument = vital#giit#import('Argument')
let s:GitProcess = vital#giit#import('Git.Process')

let s:pattern = '^\(..\) \("[^"]\{-}"\|.\{-}\)\%( -> \("[^"]\{-}"\|[^ ]\+\)\)\?$'


" Public ---------------------------------------------------------------------
function! giit#operator#status#execute(git, args) abort
  let args = a:args.clone()
  call args.set_p(0, 'status')
  call args.set('--porcelain', 1)
  call args.set('--no-column', 1)
  call args.pop('-o|--opener')
  call args.pop('-s|--selection')
  call args.lock()
  return giit#process#execute(a:git, args)
endfunction

function! giit#operator#status#parse_content(git, content) abort
  let prefix = a:git.worktree . s:Path.separator()
  let candidates = map(copy(a:content), 's:parse_record(prefix, v:val)')
  call filter(candidates, '!empty(v:val)')
  call sort(candidates, function('s:compare_candidate'))
  return candidates
endfunction


" Private --------------------------------------------------------------------
function! s:parse_record(prefix, record) abort
  let m = matchlist(a:record, s:pattern)
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
