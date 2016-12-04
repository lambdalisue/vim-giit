let s:Path = vital#giit#import('System.Filepath')
let s:Argument = vital#giit#import('Argument')
let s:GitProcess = vital#giit#import('Git.Process')

let s:pattern = '^\(..\) \("[^"]\{-}"\|.\{-}\)\%( -> \("[^"]\{-}"\|[^ ]\+\)\)\?$'
let s:params = {
      \ 'amend': 0,
      \ 'untracked-files': 0,
      \ 'ignore-submodules': 0,
      \}


" Public ---------------------------------------------------------------------
function! giit#operator#commit#execute(git, params) abort
  let params = extend(copy(s:params), a:params)
  let args = s:Argument.new()
  call args.set_p(0, 'status')
  call args.set('--amend', params.amend)
  call args.set('--untracked-files', params.untracked_files)
  call args.set('--ignore-submodules', params.ignore_submodules)
  call args.lock()
  return giit#process#execute(a:git, args)
endfunction

function! giit#operator#commit#build_params(args) abort
  let params = {
        \ 'ammend': a:args.get('--ammend'),
        \ 'untracked_files': a:args.get('--untracked-files'),
        \ 'ignore_submodules': a:args.get('--ignore-submodules'),
        \}
  return params
endfunction


function! giit#operator#commit#cleanup_commitmsg(content, mode, ...) abort
  let comment = get(a:000, 0, '#')
  let content = copy(a:content)
  if a:mode =~# '^\%(default\|strip\|whitespace\)$'
    " Strip leading and trailing empty lines
    let content = split(
          \ substitute(join(content, "\n"), '^\n\+\|\n\+$', '', 'g'),
          \ "\n"
          \)
    " Strip trailing whitespace
    call map(content, 'substitute(v:val, ''\s\+$'', '''', '''')')
    " Strip commentary
    if a:mode =~# '^\%(default\|strip\)$'
      call map(content, printf('v:val =~# ''^%s'' ? '''' : v:val', comment))
    endif
    " Collapse consecutive empty lines
    let indices = range(len(content))
    let status = ''
    for index in reverse(indices)
      if empty(content[index]) && status ==# 'consecutive'
        call remove(content, index)
      else
        let status = empty(content[index]) ? 'consecutive' : ''
      endif
    endfor
  endif
  return content
endfunction
