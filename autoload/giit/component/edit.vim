let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#component#edit#open(git, args, range) abort
  let args = a:args.clone()
  let bufname = giit#component#bufname(a:git, args)
  let options = giit#component#options(a:git, args, a:range)
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


