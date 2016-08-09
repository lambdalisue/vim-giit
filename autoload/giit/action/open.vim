let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#action#open#define(binder) abort
  call a:binder.define('edit', function('s:on_edit'), {
        \ 'description': 'Open and edit a content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('edit:right', function('s:on_edit'), {
        \ 'alias': 'right',
        \ 'description': 'Open and edit a content right',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'rightbelow vnew' },
        \})

  call a:binder.define('show', function('s:on_show'), {
        \ 'description': 'Show an exact content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'commit'],
        \ 'options': {},
        \})
  call a:binder.define('show:right', function('s:on_show'), {
        \ 'description': 'Show an exact content right',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path', 'commit'],
        \ 'options': { 'opener': 'rightbelow vnew' },
        \})
endfunction


function! s:on_edit(candidates, options) abort
  let git = giit#core#get_or_fail()
  let options = extend({
        \ 'opener': '',
        \ 'selection': [],
        \}, a:options)
  let candidate = get(a:candidates, 0)
  if empty(candidate)
    return
  endif
  let opener = empty(options.opener) ? 'edit' : options.opener
  let selection = get(candidate, 'selection', options.selection)
  call s:BufferAnchor.focus_if_available(opener)
  call giit#component#show#open(git, {
        \ 'window': '',
        \ 'opener': opener,
        \ 'selection': selection,
        \ 'worktree': 1,
        \ 'filename': candidate.path,
        \})
endfunction

function! s:on_show(candidates, options) abort
  let git = giit#core#get_or_fail()
  let options = extend({
        \ 'commit': '',
        \ 'opener': '',
        \ 'selection': [],
        \}, a:options)
  let candidate = get(a:candidates, 0)
  if empty(candidate)
    return
  endif
  let opener = empty(options.opener) ? 'edit' : options.opener
  let selection = get(candidate, 'selection', options.selection)
  call s:BufferAnchor.focus_if_available(opener)
  call giit#component#show#open(git, {
        \ 'window': '',
        \ 'opener': opener,
        \ 'selection': selection,
        \ 'commit': candidate.commit,
        \ 'filename': candidate.path,
        \})
endfunction
