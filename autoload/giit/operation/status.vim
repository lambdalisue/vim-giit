let s:Path = vital#giit#import('System.Filepath')
let s:Argument = vital#giit#import('Argument')
let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:DictOption = vital#giit#import('Data.Dict.Option')


function! giit#operation#status#execute(git, args) abort
  call a:args.set('-v|--verbose', 1)
  call a:args.set('--porcelain', 1)
  call a:args.set('--no-column', 1)
  return a:git.execute(a:args.raw, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#status#command(bang, range, cmdline) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.parse(a:cmdline)
  let args.options = {}
  let args.options.bang = a:bang ==# '!'
  let args.options.range = a:range
  let args.options.opener = args.pop('-o|--opener', '')
  let args.options.window = args.pop('-w|--window', '')
  let args.options.selection = args.pop('-s|--selection', '')
  call giit#component#status#open(git, args)
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
