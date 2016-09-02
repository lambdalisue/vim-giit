let s:List = vital#giit#import('Data.List')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:t_string = type('')


" SYNOPSIS
" Giit commit [options]
function! giit#operation#commit#command(args) abort
  let git = giit#core#get_or_fail()
  let args = s:adjust(git, a:args)
  if !args.options.edit
    call giit#operation#commit#execute(git, args)
    return
  else
    let bufname = printf('%s%s%s',
          \ giit#component#bufname(git, 'commit', 1),
          \ args.options.dry_run ? ':dry-run' : '',
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
    return
  endif
endfunction

function! giit#operation#commit#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction

function! giit#operation#commit#execute(git, args) abort
  let args = giit#util#collapse([
        \ 'commit',
        \ a:args.raw,
        \ a:args.options.edit ? '--edit' : '',
        \ a:args.options.amend ? '--amend' : '',
        \ a:args.options.dry_run ? '--dry-run' : '',
        \])
  if !a:args.options.dry_run
    " -m|--message
    let message = get(a:args.options, 'message', '')
    if !empty(message)
      call add(args, '--message')
      call add(args, message)
    endif
    " --file
    let file = get(a:args.options, 'file', '')
    if !empty(file)
      call add(args, '--file')
      call add(args, file)
    endif
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

" NOTE:
" The command will be executed with 'git -c core.editor=false', mean that
" the command with '-e|--edit' will fail while the editor is invalid.
" However, a corresponding commit message is generated and saved to a
" 'COMMIT_EDITMSG' file in '.git' directory.
function! s:adjust(git, args) abort
  let args = a:args.clone()
  " Remove unsupported options
  call args.pop('--short')
  call args.pop('--branch')
  call args.pop('--porcelain')
  call args.pop('--long')
  call args.pop('-z|--null')
  call args.pop('--no-edit')
  let args.options = {}
  let args.options.opener = args.pop('-o|--opener', 'botright 15split')
  let args.options.amend = args.pop('--amend')
  let args.options.dry_run = args.pop('--dry-run')
  let args.options.edit = args.pop('-e|--edit') || !s:List.or([
        \ args.has('-C|--reuse-message'),
        \ args.has('-F|--file'),
        \ args.has('-m|--message'),
        \ args.pop('--no-edit'),
        \ args.options.dry_run,
        \])
  let args.options.message = args.pop('-m|--message', '')
  return args.lock()
endfunction
