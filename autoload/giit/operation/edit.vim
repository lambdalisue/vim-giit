let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Argument = vital#giit#import('Argument')


function! giit#operation#edit#command(cmdline, bang, range) abort
  let git = giit#core#get()
  let args = s:Argument.new(a:cmdline)
  let bufname = giit#normalize#abspath(git, args.pop_p(1, '%'))
  let opener = args.pop('-o|--opener', '')
  let window = args.pop('--window', '')

  call s:Anchor.focus_if_available(opener)
  let ret = giit#util#buffer#open(bufname, {
        \ 'window': window,
        \ 'opener': opener,
        \})
  call giit#util#buffer#finalize(ret)
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
