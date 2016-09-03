function! giit#complete#commit#any(arglead, cmdline, cursorpos) abort
  let candidates = []
  let candidates += giit#complete#commit#branch(a:arglead, a:cmdline, a:cursorpos)
  let candidates += giit#complete#commit#hashref(a:arglead, a:cmdline, a:cursorpos)
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#branch(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#complete#get_slug_expr())
  let git = giit#core#require()
  let candidates = git.core.get_cached_content(slug, 'config', [])
  if empty(candidates)
    let candidates = s:get_available_branches(git, ['--all'])
    call git.core.set_cached_content(slug, 'config', candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#local_branch(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#complete#get_slug_expr())
  let git = giit#core#require()
  let candidates = git.core.get_cached_content(slug, 'config', [])
  if empty(candidates)
    let candidates = s:get_available_branches(git, [])
    call git.core.set_cached_content(slug, 'config', candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#remote_branch(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#complete#get_slug_expr())
  let git = giit#core#require()
  let candidates = git.core.get_cached_content(slug, 'config', [])
  if empty(candidates)
    let candidates = s:get_available_branches(git, ['--remotes'])
    call git.core.set_cached_content(slug, 'config', candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#hashref(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#complete#get_slug_expr())
  let git = giit#core#require()
  let candidates = git.core.get_cached_content(slug, 'index', [])
  if empty(candidates)
    let candidates = s:get_available_commits(git, [])
    call git.core.set_cached_content(slug, 'index', candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction


function! s:filter(arglead, candidates) abort
  return giit#complete#filter(a:arglead, a:candidates)
endfunction

function! s:get_available_commits(git, args) abort
  let args = ['log', '--pretty=%h'] + a:args
  let result = a:git.execute(args)
  if result.status
    return []
  endif
  return result.content
endfunction

function! s:get_available_branches(git, args) abort
  let args = ['branch', '--no-color', '--list'] + a:args
  let result = a:git.execute(args)
  if result.status
    return []
  endif
  let candidates = filter(result.content, 'v:val !~# ''^.* -> .*$''')
  call map(candidates, 'matchstr(v:val, ''^..\zs.*$'')')
  call map(candidates, 'substitute(v:val, ''^remotes/'', '''', '''')')
  return ['HEAD'] + filter(candidates, '!empty(v:val)')
endfunction
