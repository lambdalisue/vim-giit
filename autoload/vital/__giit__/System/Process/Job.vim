function! s:_vital_loaded(V) abort
  let s:Job = a:V.import('System.Job')
endfunction

function! s:_vital_depends() abort
  return ['System.Job']
endfunction

function! s:is_available() abort
  if has('nvim')
    return 1
  elseif exists('*job_start')
    return 1
  endif
  return 0
endfunction

function! s:is_supported(options) abort
  return 1
endfunction

function! s:execute(args, options) abort
  if a:options.debug > 0
    echomsg printf(
          \ 'vital: System.Process.Job: %s',
          \ join(a:args)
          \)
  endif
  let sync = deepcopy(s:sync)
  let job = s:Job.start(a:args, sync)
  let status = job.wait()
  return {
        \ 'status': status,
        \ 'output': join(sync.stdout, "\n"),
        \}
endfunction


let s:sync = {
      \ 'stdout': [],
      \ 'stderr': [],
      \}

function! s:sync.on_stdout(job, msg, event) abort
  call extend(self.stdout, a:msg)
endfunction

function! s:sync.on_stderr(job, msg, event) abort
  call extend(self.stderr, a:msg)
endfunction
