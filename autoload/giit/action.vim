let s:Action = vital#giit#import('Action')


function! giit#action#define(...) abort
  let binder = s:Action.get()
  return call(binder.define, a:000, binder)
endfunction

function! giit#action#call(...) abort
  let binder = s:Action.get()
  return call(binder.call, a:000, binder)
endfunction

function! giit#action#include(...) abort
  let binder = s:Action.get()
  return call(binder.include, a:000, binder)
endfunction

function! giit#action#smart_map(...) abort
  let binder = s:Action.get()
  return call(binder.smart_map, a:000, binder)
endfunction
