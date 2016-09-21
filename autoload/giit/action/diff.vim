function! giit#action#diff#define(binder) abort
  call a:binder.define('diff', function('s:on_diff'), {
        \ 'description': 'Show a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})

  call a:binder.define('diff:split', function('s:on_diff'), {
        \ 'description': 'Show a diff content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'split': 1 },
        \})
endfunction


function! s:on_diff(candidates, options) abort
  let git = giit#core#require()
  let options = extend({
        \ 'commit': '',
        \ 'opener': '',
        \ 'split': 0,
        \}, a:options)
  let candidate = get(a:candidates, 0)
  if empty(candidate)
    return
  endif
  let opener = empty(options.opener) ? 'edit' : options.opener
  let commit = get(candidate, 'commit', '')
  let cached = empty(commit) && candidate.sign =~# '^. $'
  execute printf(
        \ 'Giit diff %s --opener=%s %s %s',
        \ cached ? '--cached' : '',
        \ shellescape(opener),
        \ empty(commit) ? '' : shellescape(commit),
        \ shellescape(candidate.path),
        \)
endfunction
