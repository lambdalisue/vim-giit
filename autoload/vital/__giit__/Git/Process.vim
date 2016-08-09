function! s:_vital_loaded(V) abort
  let s:Dict = a:V.import('Data.Dict')
  let s:Process = a:V.import('System.Process')
  let s:config = {
        \ 'executable': 'git',
        \ 'arguments': ['-c', 'color.ui=false', '-c', 'core.editor=false', '--no-pager'],
        \}
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Data.Dict',
        \ 'System.Process',
        \]
endfunction

function! s:get_config() abort
  return copy(s:config)
endfunction

function! s:set_config(config) abort
  call extend(s:config, s:Dict.pick(a:config, [
        \ 'executable',
        \ 'arguments',
        \]))
endfunction

function! s:throw(msg_or_result) abort
  if type(a:msg_or_result) == type({})
    let msg = printf("%s: %s\n%s",
          \ a:msg_or_result.success ? 'OK' : 'Fail',
          \ join(a:msg_or_result.args),
          \ a:msg_or_result.output,
          \)
  else
    let msg = a:msg_or_result
  endif
  throw 'vital: Git.Process: ' . msg
endfunction

function! s:args(git) abort
  let args = [s:config.executable]
  let args += s:config.arguments
  if !empty(a:git) && !empty(a:git.worktree)
    let args += ['-C', a:git.worktree]
  endif
  return args
endfunction

function! s:execute(git, args, ...) abort
  let options = get(a:000, 0, {})
  let args = s:args(a:git) + a:args
  return s:Process.execute(args, options)
endfunction

function! s:shell(git, args, ...) abort
  let options = extend({
        \ 'prefix_args': [],
        \ 'suffix_args': [],
        \}, get(a:000, 0, {}))
  let args = s:args(a:git) + a:args
  let args = map(args, 'shellescape(v:val)')
  let args = options.prefix_args + args + options.suffix_args
  execute '!' . join(args)
endfunction

if has('nvim')
  function! s:jobstart(git, args, ...) abort
    let options = get(a:000, 0, {})
    let args = s:args(a:git) + a:args
    return jobstart(join(args), options)
  endfunction

  function! s:jobstop(job, ...) abort
    let signal = get(a:000, 0, 'term')
    if signal ==# 'term'
      return jobstop(a:job)
    else
      return jobsend(a:job, signal)
    endif
  endfunction

  function! s:jobwait(job, ...) abort
    let timeout = get(a:000, 0, 1000)
    return jobwait([a:job], timeout)
  endfunction
else
  function! s:jobstart(git, args, ...) abort
    let options = get(a:000, 0, {})
    let job_options = {
          \ 'out_mode': 'raw',
          \ 'err_mode': 'raw',
          \}
    if has_key(options, 'on_stdout')
      let job_options.out_cb = function('s:_on_out_cb', [options])
      let job_options.exit_cb = function('s:_on_exit_cb', [options])
    endif
    if has_key(options, 'on_stderr')
      let job_options.err_cb = function('s:_on_err_cb', [options])
    endif
    if has_key(options, 'on_exit')
      let job_options.exit_cb = function('s:_on_exit_cb', [options])
    endif
    let args = s:args(a:git) + a:args
    return job_start(args, job_options)
  endfunction

  function! s:jobstop(job, ...) abort
    let signal = get(a:000, 0, 'term')
    if job_status(a:job) ==# 'run'
      return job_stop(a:job, signal)
    endif
  endfunction

  function! s:jobwait(job, ...) abort
    let timeout = get(a:000, 0, 1000)
    let stime = reltime()
    while job_status(a:job) ==# 'run'
      if reltimefloat(reltime(stime)) * 1000 > timeout
        return -1
      endif
      sleep 100m
    endwhile
  endfunction

  function! s:_on_out_cb(options, channel, msg) abort
    let content = split(a:msg, '\r\?\n', 1)
    call call(a:options.on_stdout, [a:channel, content], a:options)
  endfunction

  function! s:_on_err_cb(options, channel, msg) abort
    let content = split(a:msg, '\r\?\n', 1)
    call call(a:options.on_stderr, [a:channel, content], a:options)
  endfunction

  function! s:_on_exit_cb(options, job, exit_status) abort
    let channel = job_getchannel(a:job)
    let msg = ch_read(channel)
    if !empty(msg) && has_key(a:options, 'on_stdout')
      let content = split(msg, '\r\?\n', 1)
      call call(a:options.on_stdout, [channel, content], a:options)
    endif
    if has_key(a:options, 'on_exit')
      call call(a:options.on_exit, [channel, a:exit_status], a:options)
    endif
  endfunction
endif
