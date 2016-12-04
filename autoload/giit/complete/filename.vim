let s:Path = vital#giit#import('System.Filepath')
let s:String = vital#giit#import('Data.String')
let s:Argument = vital#giit#import('Argument')
let s:GitCache = vital#giit#import('Git.Cache')


" Public ---------------------------------------------------------------------
function! giit#complete#filename#any(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let candidates = s:get_available_filenames(git, [
        \ '--cached', '--others', '--', a:arglead . '*',
        \])
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#tracked(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['index']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, [])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#cached(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['index']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--cached'])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#deleted(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['index']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--deleted'])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#modified(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['index']
  let candidates = s:GitCache.get_cached_content(git, slug, deps, [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--modified'])
    call s:GitCache.set_cached_content(git, slug, deps, candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#others(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let candidates = s:get_available_filenames(git, [
        \ '--others', '--', a:arglead . '*',
        \])
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#unstaged(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let candidates = s:get_available_filenames(git, [
        \ '--others', '--modified', '--', a:arglead . '*',
        \])
  return s:filter(a:arglead, candidates)
endfunction


" Private --------------------------------------------------------------------
function! s:filter(arglead, candidates) abort
  let pattern = s:String.escape_pattern(a:arglead)
  let separator = s:Path.separator()
  let candidates = giit#util#list#filter(a:arglead, a:candidates, '^\.')
  call map(
        \ candidates,
        \ printf('matchstr(v:val, ''^%s[^%s]*\ze'')', pattern, separator),
        \)
  return uniq(candidates)
endfunction

function! s:get_available_filenames(git, args) abort
  let args = s:Argument.new(['ls-files', '--full-name'] + a:args)
  let result = giit#operator#core#execute(a:git, args)
  if result.status
    return []
  endif
  return map(result.content, 'fnamemodify(v:val, '':~:.'')')
endfunction
