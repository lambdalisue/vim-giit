let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Exception = vital#giit#import('Vim.Exception')
let s:placeholder = '{}'


function! giit#scheme#fname(scheme, template) abort
  if a:template !~# s:placeholder
    throw s:Exception.critical(printf(
          \ 'A template "%s" does not contain "%s".',
          \ a:template,
          \ s:placeholder,
          \))
  endif
  let scheme = substitute(a:scheme, '-', '_', 'g')
  let template = 'giit#' . a:template
  if empty(scheme)
    return substitute(template, '#' . s:placeholder, '', 'g')
  else
    return substitute(template, s:placeholder, scheme, 'g')
  endif
endfunction

function! giit#scheme#call(scheme, template, arglist) abort
  let fname = giit#scheme#fname(a:scheme, a:template)
  try
    return call(fname, a:arglist)
  catch /^Vim\%((\a\+)\)\=:E117/
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    let fname  = giit#scheme#fname('', a:template)
    return call(fname, a:arglist)
  endtry
endfunction
