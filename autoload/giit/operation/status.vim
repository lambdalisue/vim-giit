let s:Path = vital#giit#import('System.Filepath')
let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:DictOption = vital#giit#import('Data.Dict.Option')


function! giit#operation#status#correct(git, options) abort
  if get(a:options, '__corrected__')
    return a:options
  endif
  let a:options.__corrected__ = 1
  return a:options
endfunction

function! giit#operation#status#execute(git, options) abort
  let args = s:build_args(a:git, a:options)
  return a:git.execute(args, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#status#command(bang, range, args) abort
  let parser  = s:get_parser()
  let options = parser.parse(a:bang, a:range, a:args)
  if empty(options)
    return
  endif
  let git = giit#core#get_or_fail()
  call giit#component#status#open(git, options)
endfunction

function! giit#operation#status#complete(arglead, cmdline, cursorpos) abort
  let parser = s:get_parser()
  return parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:build_args(git, options) abort
  let options = giit#operation#status#correct(a:git, a:options)
  let args = s:DictOption.translate(options, {
        \ 'ignored': 1,
        \ 'ignore-submodules': 1,
        \ 'untracked-files': 1,
        \})
  let args = ['status', '--verbose', '--porcelain', '--no-column'] + args
  return filter(args, '!empty(v:val)')
endfunction

function! s:get_parser() abort
  if !exists('s:parser')
    let s:parser = s:ArgumentParser.new({
          \ 'name': 'Giit status',
          \ 'description': 'Show and manipulate a status of the repository',
          \ 'complete_threshold': g:giit#complete_threshold,
          \})
    call s:parser.add_argument(
          \ '--ignored',
          \ 'show ignored files as well'
          \)
    call s:parser.add_argument(
          \ '--ignore-submodules',
          \ 'ignore changes to submodules when looking for changes', {
          \   'choices': ['none', 'untracked', 'dirty', 'all'],
          \   'on_default': 'all',
          \})
    call s:parser.add_argument(
          \ '--untracked-files', '-u',
          \ 'show untracked files, optional modes: all, normal, no', {
          \   'choices': ['all', 'normal', 'no'],
          \   'on_default': 'all',
          \})
    call s:parser.add_argument(
          \ '--opener', '-o',
          \ 'a way to open a new buffer such as "edit", "split", etc.', {
          \   'type': s:ArgumentParser.types.value,
          \})
  endif
  return s:parser
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
