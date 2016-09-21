let s:List = vital#giit#import('Data.List')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#util#buffer#bufname(git, args) abort
  let scheme = substitute(a:args.get_p(0, ''), '-', '_', 'g')
  let refname = fnamemodify(a:git.worktree, ':t')
  return join(['giit', refname, scheme], ':')
endfunction

function! giit#util#buffer#open(args, bufname, ...) abort
  let options = extend({
        \ 'group': '',
        \ 'opener': a:args.pop('-o|--opener', ''),
        \ 'selection': [],
        \}, get(a:000, 0, {}),
        \)

  call s:Anchor.focus_if_available(options.opener)
  let guard = s:Guard.store(['&eventignore'])
  try
    set eventignore+=BufReadCmd
    let context = s:Opener.open(a:bufname, {
          \ 'group':  options.group,
          \ 'opener': options.opener,
          \})
  finally
    call guard.restore()
  endtry
  let is_expired = s:List.or([
        \ !context.bufloaded,
        \ giit#meta#modified('args', a:args),
        \])
  call giit#meta#set('args', a:args)
  " the content might be expired so re-assign the content if expired
  if is_expired
    edit
  endif
  call context.end()
endfunction
