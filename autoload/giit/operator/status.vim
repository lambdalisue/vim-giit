function! giit#operator#status#execute(git, args) abort
  let args = a:args.clone()

  " Remove unsupported options
  call args.pop('-z')
  call args.lock()

  return giit#operator#common#execute(a:git, args)
endfunction
