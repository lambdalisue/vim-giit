let s:Argument = vital#giit#import('Argument')


" Entry point ----------------------------------------------------------------
function! giit#command#status#execute(range, qargs) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:qargs)
  let bufname = giit#component#build_bufname(git, 'status')
  return giit#component#open(args, bufname, {
        \ 'group': 'selector',
        \ 'opener': args.pop('-o|--opener', 'botright 15split'),
        \ 'selection': args.pop('-s|--selection', '')
        \})
endfunction

function! giit#command#status#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#common#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^\%(-u\|--untracked-files=\)'
    return s:complete_untracked_files(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^\%(--ignore-submodules=\)'
    return s:complete_ignore_submodules(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#util#list#filter(a:arglead, [
          \ '-o', '--opener=',
          \ '-s', '--selection=',
          \ '--ignored',
          \ '-u', '--untracked-files=',
          \ '--ignore-submodules=',
          \])
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:complete_untracked_files(arglead, cmdline, cursorpos) abort
  if a:arglead !~# '^\%(-u\|--untracked-files=\)'
    return []
  endif
  let candidates = [
        \ 'no',
        \ 'normal',
        \ 'all',
        \]
  let prefix = a:arglead =~# '^-u' ? '-u' : '--untracked-files='
  return giit#util#list#filter(a:arglead, map(candidates, 'prefix . v:val'))
endfunction

function! s:complete_ignore_submodules(arglead, cmdline, cursorpos) abort
  if a:arglead !~# '^\%(--ignore-submodules=\)'
    return []
  endif
  let candidates = [
        \ 'none',
        \ 'untracked',
        \ 'dirty',
        \ 'all',
        \]
  let prefix = '--ignore-submodules='
  return giit#util#list#filter(a:arglead, map(candidates, 'prefix . v:val'))
endfunction
