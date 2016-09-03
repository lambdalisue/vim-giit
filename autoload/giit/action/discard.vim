function! giit#action#discard#define(binder) abort
  call a:binder.define('discard', function('s:on_discard'), {
        \ 'description': 'Discard changes on the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('discard:force', function('s:on_discard'), {
        \ 'hidden': 1,
        \ 'description': 'Discard changes on the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'force': 1 },
        \})
endfunction


function! s:on_discard(candidates, options) abort dict
  let git = giit#core#require()
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  call giit#operator#discard#perform(git, a:candidates, options)
endfunction
