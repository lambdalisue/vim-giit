function! giit#component#lcd#process#execute(git, args) abort
  let path = a:args.get('-r|--repository')
        \ ? a:git.repository
        \ : a:git.worktree
  let args = [
        \ 'lcd',
        \ fnameescape(path),
        \]
  execute join(args)
  let output = 'cwd: ' . fnamemodify(getcwd(), ':~')
  return {
        \ 'status': 0,
        \ 'success': 1,
        \ 'args': args,
        \ 'output': output,
        \ 'content': [output],
        \}
endfunction

