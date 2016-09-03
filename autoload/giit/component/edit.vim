let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#component#edit#open(git, args) abort
  let args = a:args.clone()
  let bufname = giit#component#edit#bufname(a:git, args)
  let options = giit#component#common#options(a:git, args)
  call args.lock()

  call s:Anchor.focus_if_available(options.opener)
  let context = s:Opener.open(bufname, {
        \ 'group':  options.group,
        \ 'opener': options.opener,
        \})
  call context.end()
endfunction

function! giit#component#edit#bufname(git, args) abort
  return a:git.abspath(giit#expand(a:args.get_p(1, '%')))
endfunction


