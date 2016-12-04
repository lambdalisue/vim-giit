let s:Argument = vital#giit#import('Argument')
let s:GitCache = vital#giit#import('Git.Cache')
let s:GitProcess = vital#giit#import('Git.Process')
let s:GitProperty = vital#giit#import('Git.Property')


" Public ---------------------------------------------------------------------
function! giit#complete#commit#any(arglead, cmdline, cursorpos) abort
  let candidates = []
  let candidates += giit#complete#commit#branch(a:arglead, a:cmdline, a:cursorpos)
  let candidates += giit#complete#commit#hashref(a:arglead, a:cmdline, a:cursorpos)
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#branch(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['config']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_branches(git, ['--all'])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#local_branch(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['config']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_branches(git, [])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#remote_branch(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['config']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_branches(git, ['--remotes'])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#commit#hashref(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['config']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_commits(git, [])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction


" Public ---------------------------------------------------------------------
function! s:filter(arglead, candidates) abort
  return giit#util#list#filter(a:arglead, a:candidates)
endfunction

function! s:get_available_commits(git, args) abort
  let args = s:Argument.new(['log', '--pretty=%h'] + a:args)
  let result = giit#operator#core#execute(a:git, args)
  if result.status
    return []
  endif
  return result.content
endfunction

function! s:get_available_branches(git, args) abort
  let args = s:Argument.new(['branch', '--no-color', '--list'] + a:args)
  let result = giit#operator#core#execute(a:git, args)
  if result.status
    return []
  endif
  let candidates = filter(result.content, 'v:val !~# ''^.* -> .*$''')
  call map(candidates, 'matchstr(v:val, ''^..\zs.*$'')')
  call map(candidates, 'substitute(v:val, ''^remotes/'', '''', '''')')
  return ['HEAD'] + filter(candidates, '!empty(v:val)')
endfunction
