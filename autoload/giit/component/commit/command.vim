let s:Argument = vital#giit#import('Argument')

function! giit#component#commit#command#command(range, qargs) abort
  let git = giit#core#require()
  let args = s:Argument.new(a:qargs)
  let bufname = giit#util#buffer#bufname(git, args)
  let bufname = bufname . (args.get('--amend') ? ':amend' : '')
  return giit#util#buffer#open(args, bufname, {
        \ 'group': 'selector',
        \ 'opener': args.pop('-o|--opener', 'botright 15split'),
        \ 'selection': [],
        \})
endfunction
