function! giit#util#url#formatter#github#define() abort
  return s:formatter
endfunction

let s:formatter = {
      \ 'baseurl': 'https://github.com/\1/\2/',
      \ 'patterns': [
      \    '\vhttps?://github\.com/(.{-})/(.{-})%(\.git)?$',
      \    '\vgit://github\.com/(.{-})/(.{-})%(\.git)?$',
      \    '\vgit\@github\.com:(.{-})/(.{-})%(\.git)?$',
      \    '\vssh://git\@github\.com/(.{-})/(.{-})%(\.git)?$',
      \ ],
      \ 'scheme': {},
      \}

function! s:formatter.scheme._(baseurl, rev, path, params) abort

endfunction
