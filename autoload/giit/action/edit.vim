function! giit#action#edit#define(binder) abort
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
        \ 'options': { 'opener': 'belowright vnew' },
        \})
endfunction


function! s:on_edit(candidates, options) abort
  let git = giit#core#get_or_fail()
  let options = extend({
        \ 'opener': '',
        \}, a:options)
  let candidate = get(a:candidates, 0)
  if empty(candidate)
    return
  endif
  let opener = empty(options.opener) ? 'edit' : options.opener
  execute printf(
        \ 'Giit edit --opener=%s %s',
        \ shellescape(opener),
        \ fnameescape(candidate.path),
        \)
endfunction
