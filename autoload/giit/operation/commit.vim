let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:t_string = type('')


" SYNOPSIS
" Giit commit [options]
function! giit#operation#commit#command(args) abort
  let git = giit#core#get_or_fail()
  let args = s:adjust(git, a:args)
  let bufname = printf('%s%s%s',
        \ giit#component#bufname(git, 'commit', 1),
        \ args.options.dry ? ':dry' : '',
        \ args.options.amend ? ':amend' : '',
        \)

  call s:Anchor.focus_if_available(args.options.opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, {
          \ 'group': 'selector',
          \ 'opener': args.options.opener,
          \})
  finally
    call guard.restore()
  endtry
  call giit#meta#set('args', args)
  edit
  call context.end()
endfunction

function! giit#operation#commit#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! giit#operation#commit#execute(git, args) abort
  let args = giit#util#collapse([
        \ 'commit',
        \ a:args.raw,
        \ a:args.options.amend ? '--amend' : '',
        \ a:args.options.dry ? '--dry-run' : '',
        \])
  let message = get(a:args.options, 'message', '')
  if !empty(message) && !a:args.options.dry
    call add(args, '--message')
    call add(args, message)
  endif
  return a:git.execute(args, {
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


function! s:adjust(git, args) abort
  let args = a:args.clone()

  " Add requirements
  call args.set('-e|--edit', 1)
  " Remove unsupported options
  call args.pop('--short')
  call args.pop('--branch')
  call args.pop('--porcelain')
  call args.pop('--long')
  call args.pop('-z|--null')
  call args.pop('--no-edit')

  let args.options = {}
  let args.options.opener = args.pop('-o|--opener', 'botright 15split')
  let args.options.dry = args.pop('--dry-run')
  let args.options.amend = args.pop('--amend')
  return args.lock()
endfunction
