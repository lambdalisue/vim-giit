let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')


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
  let git = giit#core#get_or_fail()
  let options = extend({
        \ 'commit': '',
        \ 'opener': '',
        \ 'selection': [],
        \ 'split': 0,
        \}, a:options)
  let candidate = get(a:candidates, 0)
  if empty(candidate)
    return
  endif
  let opener = empty(options.opener) ? 'edit' : options.opener
  let selection = get(candidate, 'selection', options.selection)
  let commit = get(candidate, 'commit', '')
  let cached = empty(commit) && candidate.sign =~# '^. $'
  call s:BufferAnchor.focus_if_available(opener)
  call giit#component#diff#open(git, {
        \ 'window': '',
        \ 'opener': opener,
        \ 'selection': selection,
        \ 'commit': commit,
        \ 'filename': candidate.path,
        \ 'cached': cached,
        \ 'split': options.split,
        \})
endfunction
