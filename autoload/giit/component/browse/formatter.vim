let s:Formatter = vital#giit#import('Data.String.Formatter')
let s:Config = vital#giit#import('Data.Dict.Config')


function! giit#component#browse#util#format(scheme, remote_url, params) abort
  let format_map = {
        \ 'p': 'path',
        \ 'r': 'remote',
        \ 'r1': 'rev1',
        \ 'r2': 'rev2',
        \ 'c1': 'commit1',
        \ 'c2': 'commit2',
        \ 'h1': 'revision1',
        \ 'h2': 'revision2',
        \ 'ls': 'line_start',
        \ 'le': 'line_end',
        \}
  let patterns = g:giit#component#browse#formatter#translation_patterns
  let patterns = extend(
        \ deepcopy(patterns),
        \ g:giit#component#browse#formatter#extra_translation_patterns
        \)
  let baseurl = s:build_baseurl(a:scheme, a:remote_url, patterns)
  if empty(baseurl)
    return ''
  endif
  return s:Formatter.format(baseurl, format_map, a:params)
endfunction


function! s:build_baseurl(scheme, remote_url, translation_patterns) abort
  for [domain, info] in items(a:translation_patterns)
    for pattern in info[0]
      let pattern = substitute(pattern, '\C' . '%domain', domain, 'g')
      if a:remote_url =~# pattern
        let repl = get(info[1], a:scheme, a:remote_url)
        return substitute(a:remote_url, '\C' . pattern, repl, 'g')
      endif
    endfor
  endfor
  return ''
endfunction


call s:Config.define('giit#component#browse#formatter', {
      \ 'translation_patterns': {
      \   'github.com': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '^':     'https://\1/\2/\3/tree/%r1/',
      \       '_':     'https://\1/\2/\3/blob/%r1/%p%{#L|}ls%{-L|}le',
      \       'blame': 'https://\1/\2/\3/blame/%r1/%p%{#L|}ls%{-L|}le',
      \     },
      \   ],
      \   'bitbucket.org': [
      \     [
      \       '\vhttps?://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit://(%domain)/(.{-})/(.{-})%(\.git)?$',
      \       '\vgit\@(%domain):(.{-})/(.{-})%(\.git)?$',
      \       '\vssh://git\@(%domain)/(.{-})/(.{-})%(\.git)?$',
      \     ], {
      \       '^':     'https://\1/\2/\3/branch/%r1/',
      \       '_':     'https://\1/\2/\3/src/%r1/%p%{#cl-|}ls',
      \       'blame': 'https://\1/\2/\3/annotate/%r1/%p',
      \       'diff':  'https://\1/\2/\3/diff/%p?diff1=%h1&diff2=%h2',
      \     },
      \   ],
      \ },
      \ 'extra_translation_patterns': {},
      \})
