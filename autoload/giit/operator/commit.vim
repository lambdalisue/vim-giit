function! giit#operator#commit#execute(git, args) abort
  let args = a:args.clone()

  " Remove unsupported options
  call args.pop('-z|--null')
  call args.lock()

  return giit#operator#common#execute(a:git, args)
endfunction
