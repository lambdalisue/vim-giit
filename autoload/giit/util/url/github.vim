function! giit#util#url#github#define() abort
  return s:formatter
endfunction

let s:formatter = {
      \ 'baseurl': 'https://github.com/\1/\2',
      \ 'patterns': [
      \    '\vhttps?://github\.com/(.{-})/(.{-})%(\.git)?$',
      \    '\vgit://github\.com/(.{-})/(.{-})%(\.git)?$',
      \    '\vgit\@github\.com:(.{-})/(.{-})%(\.git)?$',
      \    '\vssh://git\@github\.com/(.{-})/(.{-})%(\.git)?$',
      \ ],
      \ 'scheme': {},
      \}

function! s:formatter.scheme._(baseurl, rev, path, params) abort
  let sl = empty(a:params.line_start)
        \ ? ''
        \ : '#L' . a:params.line_start
  let el = empty(a:params.line_end)
        \ ? ''
        \ : '-L' . a:params.line_end
  let url = printf('%s/blob/%s/%s%s',
        \ a:baseurl,
        \ a:rev,
        \ a:path,
        \ sl . el,
        \)
  return url
endfunction

function! s:formatter.scheme.root(baseurl, rev, path, params) abort
  let url = printf('%s/tree/%s/',
        \ a:baseurl,
        \ a:rev,
        \)
  return url
endfunction

function! s:formatter.scheme.blame(baseurl, rev, path, params) abort
  let sl = empty(a:params.line_start)
        \ ? ''
        \ : '#L' . a:params.line_start
  let el = empty(a:params.line_end)
        \ ? ''
        \ : '-L' . a:params.line_end
  let url = printf('%s/blame/%s/%s%s',
        \ a:baseurl,
        \ a:rev,
        \ a:path,
        \ sl . el,
        \)
  return url
endfunction
