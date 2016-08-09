let s:File = vital#giit#import('System.File')
let s:Path = vital#giit#import('System.Filepath')
let s:Prompt = vital#giit#import('Vim.Prompt')


function! giit#action#discard#define(binder) abort
  call a:binder.define('discard', function('s:on_discard'), {
        \ 'description': 'Discard changes on the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('discard:force', function('s:on_discard'), {
        \ 'hidden': 1,
        \ 'description': 'Discard changes on the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'force': 1 },
        \})
endfunction


function! s:on_discard(candidates, options) abort dict
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  let delete_candidates = []
  let checkout_candidates = []
  for candidate in a:candidates
    if candidate.sign =~# '\%(DD\|AU\|UD\|UA\|DU\|AA\|UU\)$'
      call s:Prompt.warn(printf(
            \ 'A conflicted file "%s" cannot be discarded. Resolve conflict first.',
            \ s:Path.relpath(candidate.path),
            \))
      continue
    elseif candidate.sign =~# '^\%(??\|!!\)$'
      call add(delete_candidates, candidate)
    else
      call add(checkout_candidates, candidate)
    endif
  endfor
  if !options.force
    call s:Prompt.warn(
          \ 'A discard action will discard all local changes on the working tree',
          \ 'and the operation is irreversible, mean that you have no chance to',
          \ 'revert the operation.',
          \)
    echo 'This operation will be performed to the following candidates:'
    for candidate in extend(copy(delete_candidates), checkout_candidates)
      echo '- ' . s:Path.relpath(candidate.path)
    endfor
    if !s:Prompt.confirm('Are you sure to discard the changes?')
      call giit#throw('Cancel: The operation has canceled by user')
    endif
  endif
  " delete untracked files
  for candidate in delete_candidates
    if isdirectory(candidate.path)
      call s:File.rmdir(candidate.path, 'r')
    elseif filewritable(candidate.path)
      call delete(candidate.path)
    endif
  endfor
  " checkout tracked files from HEAD
  noautocmd call self.call('checkout:HEAD:force', checkout_candidates)
  call giit#trigger_modified()
endfunction
