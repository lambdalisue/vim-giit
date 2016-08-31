let s:Path = vital#giit#import('System.Filepath')
let s:String = vital#giit#import('Data.String')


function! giit#complete#filename#any(arglead, cmdline, cursorpos) abort
  let git = giit#core#get_or_fail()
  let candidates = s:get_available_filenames(git, [
        \ '--cached', '--others', '--', a:arglead . '*',
        \])
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#tracked(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#util#slug())
  let git = giit#core#get_or_fail()
  let candidates = git.core.get_cached_content(slug, 'index', [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, [])
    call git.core.set_cached_content(slug, 'index', candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#cached(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#util#slug())
  let git = giit#core#get_or_fail()
  let candidates = git.core.get_cached_content(slug, 'index', [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--cached'])
    call git.core.set_cached_content(slug, 'index', candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#deleted(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#util#slug())
  let git = giit#core#get_or_fail()
  let candidates = git.core.get_cached_content(slug, 'index', [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--deleted'])
    call git.core.set_cached_content(slug, 'index', candidates)
  endif
  return s:filter(a:arglead, candidates)
endfunction

function! giit#complete#filename#modified(arglead, cmdline, cursorpos) abort
  let slug = eval(giit#util#slug())
  let git = giit#core#get_or_fail()
  let candidates = git.core.get_cached_content(slug, 'index', [])
  if empty(candidates)
    let candidates = s:get_available_filenames(git, ['--modified'])
    call git.core.set_cached_content(slug, 'index', candidates)
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


function! s:filter(arglead, candidates) abort
  let pattern = s:String.escape_pattern(a:arglead)
  let separator = s:Path.separator()
  let candidates = giit#complete#filter(a:arglead, a:candidates, '^\.')
  call map(
        \ candidates,
        \ printf('matchstr(v:val, ''^%s[^%s]*\ze'')', pattern, separator),
        \)
  return uniq(candidates)
endfunction

function! s:get_available_filenames(git, args) abort
  let args = ['ls-files', '--full-name'] + a:args
  let result = a:git.execute(args)
  if result.status
    return []
  endif
  return map(result.content, 'fnamemodify(v:val, '':~:.'')')
endfunction
