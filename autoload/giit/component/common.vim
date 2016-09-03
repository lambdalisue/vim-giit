let s:List = vital#giit#import('Data.List')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#component#common#open(git, args, range) abort
  let args = a:args.clone()
  let bufname = giit#component#bufname(a:git, args)
  let options = giit#component#options(a:git, args, a:range)
  call args.lock()

  call s:Anchor.focus_if_available(options.opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(bufname, {
          \ 'group':  options.group,
          \ 'opener': options.opener,
          \})
  finally
    call guard.restore()
  endtry
  let is_expired = s:List.or([
        \ !context.bufloaded,
        \ giit#meta#modified('args', args),
        \])
  call giit#meta#set('args', args)
  if is_expired
    " the content might be expired so re-assign the content
    edit
  endif
  call context.end()
endfunction

function! giit#component#common#bufname(git, args) abort
  let scheme  = substitute(a:args.get_p(0, ''), '-', '_', 'g')
  let refname = fnamemodify(a:git.worktree, ':t')
  return join(['giit', refname, scheme], ':')
endfunction

function! giit#component#common#options(git, args, range) abort
  let options = {}
  let options.group     = ''
  let options.opener    = a:args.pop('-o|--opener', '')
  let options.selection = []
  return options
endfunction
