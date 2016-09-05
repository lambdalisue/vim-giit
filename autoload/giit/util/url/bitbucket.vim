function! giit#util#url#bitbucket#define() abort
  return s:formatter
endfunction


let s:formatter = {
      \ 'baseurl': 'https://bitbucket.org/\1/\2',
      \ 'patterns': [
      \    '\vhttps?://bitbucket\.org/(.{-})/(.{-})%(\.git)?$',
      \    '\vgit://bitbucket\.org/(.{-})/(.{-})%(\.git)?$',
      \    '\vgit\@bitbucket\.org:(.{-})/(.{-})%(\.git)?$',
      \    '\vssh://git\@bitbucket\.org/(.{-})/(.{-})%(\.git)?$',
      \ ],
      \ 'scheme': {},
      \}

function! s:formatter.scheme._(baseurl, rev, path, params) abort
  let sl = empty(a:params.line_start)
        \ ? ''
        \ : '#cl-' . a:params.line_start
  let url = printf('%s/src/%s/%s%s',
        \ a:baseurl,
        \ a:rev,
        \ a:path,
        \ sl
        \)
  return url
endfunction

function! s:formatter.scheme.root(baseurl, rev, path, params) abort
  let url = printf('%s/branch/%s/',
        \ a:baseurl,
        \ a:rev,
        \)
  return url
endfunction

function! s:formatter.scheme.blame(baseurl, rev, path, params) abort
  let url = printf('%s/annotate/%s/%s',
        \ a:baseurl,
        \ a:rev,
        \ a:path,
        \)
  return url
endfunction

function! s:formatter.scheme.diff(baseurl, rev, path, params) abort
  let url = printf('%s/diff/%s?diff1=%s&diff2=%s',
        \ a:baseurl,
        \ a:path,
        \ a:params.rev1,
        \ a:params.rev2,
        \)
  return url
endfunction
