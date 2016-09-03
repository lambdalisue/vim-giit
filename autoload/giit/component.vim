let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Exception = vital#giit#import('Vim.Exception')


" Entry points ---------------------------------------------------------------
function! giit#component#open(git, args) abort
  let scheme = substitute(a:args.get_p(0, ''), '-', '_', 'g')
  try
    return call(
          \ printf('giit#component#%s#open', scheme),
          \ [a:git, a:args]
          \)
  catch /^Vim\%((\a\+)\)\=:E117/
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
  endtry
  return giit#component#common#open(a:git, a:args)
endfunction

function! giit#component#bufname(git, args) abort
  let scheme = substitute(a:args.get_p(0, ''), '-', '_', 'g')
  try
    return call(
          \ printf('giit#component#%s#bufname', scheme),
          \ [a:git, a:args]
          \)
  catch /^Vim\%((\a\+)\)\=:E117/
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
  endtry
  return giit#component#common#bufname(a:git, a:args)
endfunction

function! giit#component#options(git, args) abort
  let scheme = substitute(a:args.get_p(0, ''), '-', '_', 'g')
  try
    return call(
          \ printf('giit#component#%s#options', scheme),
          \ [a:git, a:args]
          \)
  catch /^Vim\%((\a\+)\)\=:E117/
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
  endtry
  return giit#component#common#options(a:git, a:args)
endfunction

function! giit#component#autocmd(event) abort
  let scheme = matchstr(
        \ expand('<afile>'),
        \ 'giit:\%(//\)\?[^:]\+:\zs[^:/]\+\ze'
        \)
  let scheme = substitute(scheme, '-', '_', 'g')
  return s:Exception.call(
        \ printf('giit#component#%s#autocmd', scheme),
        \ [a:event],
        \)
endfunction


" Utility --------------------------------------------------------------------
function! giit#component#split_object(object) abort
  let m = matchlist(a:object, '^\(:\?[^:]*\):\(.\+\)$')
  if empty(m)
    return [a:object, '']
  endif
  return m[1:2]
endfunction

function! giit#component#build_object(commit, filename) abort
  return empty(a:filename)
        \ ? a:commit
        \ : a:commit . ':' . a:filename
endfunction
