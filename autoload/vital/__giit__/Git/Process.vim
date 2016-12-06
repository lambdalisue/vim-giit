function! s:_vital_loaded(V) abort
  let s:Dict = a:V.import('Data.Dict')
  let s:String = a:V.import('Data.String')
  let s:Process = a:V.import('System.Process')
  let s:Job = a:V.import('System.Job')
  let s:config = {
        \ 'executable': 'git',
        \ 'arguments': [
        \   '--no-pager',
        \   '-c', 'color.ui=false',
        \   '-c', 'core.editor=false',
        \ ],
        \}
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Data.Dict',
        \ 'Data.String',
        \ 'System.Process',
        \]
endfunction


" Public ---------------------------------------------------------------------
function! s:get_config() abort
  return copy(s:config)
endfunction

function! s:set_config(config) abort
  call extend(s:config, s:Dict.pick(a:config, [
        \ 'executable',
        \]))
endfunction

function! s:get_execute_args(git, args) abort
  let args = [s:config.executable] + s:config.arguments
  if !empty(a:git) && !empty(a:git.worktree)
    let args += ['-C', a:git.worktree]
  endif
  return args + a:args
endfunction

function! s:execute(git, args, ...) abort
  let options = get(a:000, 0, {})
  let args = s:get_execute_args(a:git, a:args)
  return s:Process.execute(args, options)
endfunction

function! s:shell(git, args, ...) abort
  let options = extend({
        \ 'stdout': 0,
        \ 'stderr': 0,
        \}, get(a:000, 0, {}))
  let args = s:get_execute_args(a:git, a:args)
  let args = map(args, 'shellescape(v:val)')
  let stdout = ''
  if options.stdout
    let stdout = tempname()
    let args += ['1>', fnameescape(stdout)]
  endif
  let stderr = ''
  if options.stderr
    let stderr = tempname()
    let args += ['2>', fnameescape(stderr)]
  else
    let args += ['2>&1']
  endif
  silent execute '!' . join(args)
  let result = {
        \ 'args': args,
        \ 'status': v:shell_error,
        \ 'options': options,
        \}
  let result.content = empty(stdout) ? [] : readfile(stdout)
  let result.output = s:String.join_posix_lines(result.content)
  let result.error = empty(stderr) ? '' : s:String.join_posix_lines(readfile(stderr))
  let result.success = result.status ? 0 : 1
  return result
endfunction

function! s:jobstart(git, args, ...) abort
  let options = get(a:000, 0, {})
  let args = s:get_execute_args(a:git, a:args)
  return s:Job.start(args, options)
endfunction
