let s:Path = vital#giit#import('System.Filepath')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:t_string = type('')


function! giit#operation#commit#command(args) abort
  let git = giit#core#get_or_fail()
  let opener = a:args.pop('-o|--opener', 'botright 15split')
  let bufname = giit#component#bufname(git, 'commit', 1)

  call s:Anchor.focus_if_available(opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, {
          \ 'group': 'selector',
          \ 'opener': opener,
          \})
  finally
    call guard.restore()
  endtry
  let is_expired = !context.bufloaded || giit#meta#modified('args', a:args)
  call giit#meta#set('args', a:args)
  if is_expired
    edit!
  endif
  call context.end()
endfunction

function! giit#operation#commit#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! giit#operation#commit#execute(git, args) abort
  let args = a:args.clone()
  let message = args.pop('-m|--message', '')
  if type(message) == s:t_string && !empty(message)
    call add(args.raw, '--message ' . message)
  endif
  return a:git.execute(['commit'] + args.raw, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#commit#cleanup(content, mode, ...) abort
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
