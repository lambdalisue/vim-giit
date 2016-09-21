function! giit#action#show#define(binder) abort
  call a:binder.define('show', function('s:on_show'), {
        \ 'description': 'Show an exact content',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('show:right', function('s:on_show'), {
        \ 'description': 'Show an exact content right',
        \ 'mapping_mode': 'n',
        \ 'requirements': ['path'],
        \ 'options': { 'opener': 'rightbelow vnew' },
        \})
endfunction


function! s:on_show(candidates, options) abort
  let git = giit#core#require()
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
  let object = printf('%s:%s',
        \ get(candidate, 'commit', ''),
        \ git.relpath(candidate.path),
        \)
  execute printf(
        \ 'Giit show --opener=%s %s',
        \ shellescape(opener),
        \ shellescape(object),
        \)
endfunction

