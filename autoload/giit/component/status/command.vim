let s:Argument = vital#giit#import('Argument')

function! giit#component#status#command#command(range, qargs) abort
  let git = giit#core#require()
  let args = s:Argument.new(a:qargs)

  let bufname = giit#util#buffer#bufname(git, args)
  return giit#util#buffer#open(args, bufname, {
        \ 'group': 'selector',
        \ 'opener': args.pop('-o|--opener', 'botright 15split'),
        \ 'selection': [],
        \})
endfunction
