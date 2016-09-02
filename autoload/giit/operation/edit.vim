let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')


" SYNOPSIS
" Giit edit [options] [<filename>]
function! giit#operation#edit#command(args) abort
  let git = giit#core#get()
  let args = s:adjust(git, a:args)

  call s:Anchor.focus_if_available(args.options.opener)
  let context = s:Opener.open(args.options.filename, {
        \ 'opener': args.options.opener,
        \})
  call context.end()
endfunction

function! giit#operation#edit#complete(arglead, cmdline, cursorpos) abort
  if a:arglead =~# '^\%(-o\|--opener=\)'
    return giit#complete#opener(a:arglead, a:cmdline, a:cursorpos)
  elseif a:arglead =~# '^--\?'
    return giit#complete#filter(a:arglead, [
          \ '-o', '--opener=',
          \])
  else
    return giit#complete#filename#any(a:arglead, a:cmdline, a:cursorpos)
  endif
endfunction


function! s:adjust(git, args) abort
  let args = a:args.clone()
  let filename = args.pop_p(0, '%')

  let args.options = {}
  let args.options.opener = args.pop('-o|--opener', '')
  let args.options.filename = a:git.abspath(giit#expand(filename))
  return args.lock()
endfunction
