let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#operation#edit#command(args) abort
  let git = giit#core#get()
  let opener = a:args.pop('-o|--opener', '')
  let bufname = giit#util#normalize#abspath(git, a:args.pop_p(0, '%'))

  call s:Anchor.focus_if_available(opener)
  let context = s:Opener.open(bufname, {
        \ 'opener': opener,
        \})
  call context.end()
endfunction

function! giit#operation#edit#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \ '--window=',
          \ '--selection=',
          \ '-p', '--patch',
          \])
  else
    return giit#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
  endif
endfunction
