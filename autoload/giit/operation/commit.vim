let s:Path = vital#giit#import('System.Filepath')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Argument = vital#giit#import('Argument')


function! giit#operation#commit#execute(git, args) abort
  return a:git.execute(a:args.raw, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#commit#command(cmdline, bang, range) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:cmdline)
  "let bufname = giit#component#bufname(git, 'commit', 1)
  let bufname = s:Path.join(git.repository, 'COMMIT_EDITMSG')
  let opener = args.pop('-o|--opener', 'botright 15split')

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
  call giit#meta#set('args', args)
  call giit#util#doautocmd('BufReadCmd')
  call context.end()
endfunction

function! giit#operation#commit#complete(arglead, cmdline, cursorpos) abort
  return []
endfunction
