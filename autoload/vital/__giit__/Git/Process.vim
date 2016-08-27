function! s:_vital_loaded(V) abort
  let s:Dict = a:V.import('Data.Dict')
  let s:Process = a:V.import('System.Process')
  let s:config = {
        \ 'executable': 'git',
        \}
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Data.Dict',
        \ 'System.Process',
        \]
endfunction


" Bind instance --------------------------------------------------------------
function! s:bind(git) abort
  let methods = [
        \ 'arguments',
        \ 'execute',
        \ 'shell',
        \]
  for method in methods
    if !has_key(a:git, method)
      let a:git[method] = function('s:' . method, [a:git])
      lockvar a:git[method]
    endif
  endfor
  return a:git
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

function! s:arguments(git) abort
  let args = [
        \ s:config.executable,
        \ '--no-pager',
        \ '-c', 'color.ui=false',
        \ '-c', 'core.editor=false',
        \]
  if !empty(a:git) && !empty(a:git.worktree)
    let args += ['-C', a:git.worktree]
  endif
  return args
endfunction

function! s:execute(git, args, ...) abort
  let options = get(a:000, 0, {})
  let args = s:arguments(a:git) + a:args
  return s:Process.execute(args, options)
endfunction

function! s:shell(git, args, ...) abort
  let options = extend({
        \ 'stdout': 0,
        \ 'stderr': 0,
        \}, get(a:000, 0, {}))
  let args = s:arguments(a:git) + a:args
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
  endif
  execute '!' . join(args)
  return {
        \ 'args': args,
        \ 'status': v:shell_error,
        \ 'stdout': empty(stdout) ? [] : readfile(stdout),
        \ 'stderr': empty(stderr) ? [] : readfile(stderr),
        \}
endfunction
