let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Exception = vital#giit#import('Vim.Exception')
let s:GitProcess = vital#giit#import('Git.Process')


function! giit#process#execute(git, args) abort
  let args = a:args.clone()
  call args.map_p(function('s:expand_percent'))
  call args.map_r(function('s:expand_percent'))
  let method = s:is_interactive(args) ? 'shell' : 'execute'
  return s:GitProcess[method](
        \ a:git,
        \ filter(args.raw, '!empty(v:val)'),
        \ { 'stdout': 1 }
        \)
endfunction

function! giit#process#inform(result) abort
  redraw | echo
  if a:result.status
    call s:Prompt.echo('WarningMsg', 'Fail: ' . join(a:result.args))
  endif
  for line in a:result.content
    call s:Prompt.echo('None', line)
  endfor
endfunction

function! giit#process#error(result) abort
  return s:Exception.error(printf(
        \ "Fail: %s\n%s",
        \ join(a:result.args),
        \ join(a:result.content, "\n")
        \))
endfunction


" Private --------------------------------------------------------------------
function! s:is_interactive(args) abort
  if a:args.pop('--interactive')
    return 1
  elseif a:args.get_p(0, '') =~# '^\%(clone\|fetch\|push\|pull\|checkout\)$'
    " Command which access to a remote may fail and ask users to fill them
    " password so these command should be performed with :! instead.
    return 1
  endif
  return 0
endfunction

function! s:expand_percent(value) abort
  return a:value ==# '%' ? giit#expand(a:value) : a:value
endfunction
