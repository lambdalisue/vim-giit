let s:Git = vital#giit#import('Git')
let s:List = vital#giit#import('Data.List')
let s:Guard = vital#giit#import('Vim.Guard')
let s:Opener = vital#giit#import('Vim.Buffer.Opener')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Exception = vital#giit#import('Vim.Exception')

let s:t_string = type('')


" Public ---------------------------------------------------------------------
function! giit#component#open(args, bufname, ...) abort
  let options = extend({
        \ 'group': '',
        \ 'opener': '',
        \ 'selection': [],
        \}, get(a:000, 0, {}),
        \)
  " Use current selection if a buffer is a corresponding buffer of the current
  " buffer and no selection has specified
  if empty(options.selection) && giit#expand('%') ==# giit#expand(a:bufname)
    let options.selection = giit#selection#get_current_selection()
  endif
  " Move focus to an anchor buffer if necessary
  if !s:Anchor.is_suitable(winnr())
    call s:Anchor.focus_if_available(options.opener)
  endif
  " Open a buffer without BufReadCmd
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
  " Assign 'args' and call BufReadCmd
  call giit#meta#set('args', a:args)
  call giit#util#vim#doautocmd('BufReadCmd')
  " Move cursor if necessary
  if !empty(options.selection)
    call giit#selection#set_current_selection(options.selection)
  endif
  " Finalize
  call context.end()
endfunction

function! giit#component#parse_bufname(bufname) abort
  if a:bufname !~# '^giit:'
    return {}
  endif
  let refname = matchstr(a:bufname, '^giit:\%(//\)\?\zs[^:\\/]\+')
  let commit = matchstr(a:bufname, '^giit:\%(//\)\?[^\\/]\+[\\/]\zs[^:]*')
  let path = matchstr(a:bufname, '^giit:\%(//\)\?[^\\/]\+[\\/][^:]*:\zs.*')
  return {
        \ 'refname': refname,
        \ 'commit': commit,
        \ 'path': simplify(path),
        \}
endfunction

function! giit#component#build_bufname(git, scheme, ...) abort
  let options = extend({
        \ 'file': 0,
        \ 'object': '',
        \ 'extras': [],
        \}, get(a:000, 0, {})
        \)
  let bufmeta = join(giit#util#list#cleanup([
        \ a:git.refname,
        \ a:scheme,
        \ join(options.extras, ':'),
        \]), ':')
  let bufname = printf('giit:%s%s',
        \ options.file ? '//' : '',
        \ join(giit#util#list#cleanup([bufmeta, options.object]), '/')
        \)
  return substitute(bufname, ':\+$', '', '')
endfunction


" Entry point ----------------------------------------------------------------
function! giit#component#autocmd(event) abort
  let scheme = matchstr(
        \ expand('<afile>'),
        \ 'giit:\%(//\)\?[^:]\+:\zs[^:/]\+\ze'
        \)
  let scheme = substitute(scheme, '-', '_', 'g')
  return s:Exception.call(
        \ printf('giit#component#%s#%s', scheme, a:event),
        \ [],
        \)
endfunction
