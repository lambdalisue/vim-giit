let s:String = vital#giit#import('Data.String')
let s:Path = vital#giit#import('System.Filepath')
let s:Prompt = vital#giit#import('Vim.Prompt')

function! s:get_available_branches(git, args) abort
  let args = ['branch', '--no-color', '--list'] + a:args
  let result = a:git.execute(args)
  if !result.success
    return []
  endif
  let content = filter(result.content, 'v:val !~# ''HEAD''')
  return map(content, 'matchstr(v:val, "^..\\zs.*$")')
endfunction

function! s:get_available_commits(git, args) abort
  let args = ['log', '--pretty=%h'] + a:args
  let result = a:git.execute(args)
  if !result.success
    return []
  endif
  return result.content
endfunction

function! s:get_available_filenames(git, args) abort
  let args = [
        \ 'ls-files', '--full-name',
        \] + a:args
  let result = a:git.execute(args)
  if !result.success
    return []
  endif
  let content = map(result.content, 'fnamemodify(v:val, '':~:.'')')
  return content
endfunction

function! giit#util#complete#branch(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, 'config', [])
    if empty(candidates)
      let candidates = s:get_available_branches(git, ['--all'])
      call s:Git.set_cached_content(git, slug, 'config', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#local_branch(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, 'config', [])
    if empty(candidates)
      let candidates = s:get_available_branches(git, [])
      call s:Git.set_cached_content(git, slug, 'config', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#remote_branch(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, 'config', [])
    if empty(candidates)
      let candidates = s:get_available_branches(git, ['--remotes'])
      call s:Git.set_cached_content(git, slug, 'config', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#commit(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, 'index', [])
    if empty(candidates)
      let candidates = s:get_available_commits(git, [])
      call s:Git.set_cached_content(git, slug, 'index', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#commitish(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, 'index', [])
    if empty(candidates)
      let candidates = s:get_available_branches(git, ['--all'])
      let candidates += s:get_available_commits(git, [])
      call s:Git.set_cached_content(git, slug, 'index', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#cached_filename(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, 'index', [])
    if empty(candidates)
      let candidates = s:get_available_filenames(git, ['--cached'])
      call s:Git.set_cached_content(git, slug, 'index', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#deleted_filename(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, 'index', [])
    if empty(candidates)
      let candidates = s:get_available_filenames(git, ['--deleted'])
      call s:Git.set_cached_content(git, slug, 'index', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#modified_filename(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let slug = matchstr(expand('<sfile>'), '\.\.\zs[^.]*$')
    let candidates = s:Git.get_cached_content(git, slug, '.', '')
    if empty(candidates)
      let candidates = s:get_available_filenames(git, ['--modified'])
      call s:Git.set_cached_content(git, slug, '.', candidates)
    endif
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#others_filename(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let candidates = s:get_available_filenames(git, [
          \ '--others', '--', a:arglead . '*',
          \])
    return candidates
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#unstaged_filename(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let candidates = s:get_available_filenames(git, [
          \ '--others', '--modified', '--', a:arglead . '*',
          \])
    return candidates
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#filename(arglead, cmdline, cursorpos, ...) abort
  try
    let git = giit#core#get_or_fail()
    let candidates = s:get_available_filenames(git, [
          \ '--cached', '--others', '--', a:arglead . '*',
          \])
    return filter(copy(candidates), 'v:val =~# ''^'' . a:arglead')
  catch
    call s:Prompt.debug(v:exception)
    call s:Prompt.debug(v:throwpoint)
    return ''
  endtry
endfunction

function! giit#util#complete#directory(arglead, cmdline, cursorpos, ...) abort
  let git = giit#core#get()
  let root = empty(git.worktree) ? getcwd() : git.worktree
  let root = s:Path.realpath(s:Path.remove_last_separator(root) . s:Path.separator())
  let candidates = split(
        \ glob(s:Path.join(root, a:arglead . '*'), 0),
        \ "\r\\?\n",
        \)
  let candidates = filter(candidates, 'isdirectory(v:val)')
  " substitute 'root'
  call map(candidates, printf(
        \ 'substitute(v:val, ''^%s'', '''', '''')',
        \ s:String.escape_pattern(root),
        \))
  " substitute /home/<user> to ~/ if ~/ is specified
  if a:arglead =~# '^\~'
    call map(candidates, 'fnameescape(v:val, '':~'')')
  endif
  return candidates
endfunction
