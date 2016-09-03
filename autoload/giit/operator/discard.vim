let s:File = vital#giit#import('System.File')
let s:Path = vital#giit#import('System.Filepath')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:Exception = vital#giit#import('Vim.Exception')


" discard [--force] -- <path>...
function! giit#operator#discard#execute(git, args) abort
  let pathlist   = a:args.list_p() + a:args.list_r()
  let candidates = s:retrieve_candidates(a:git, pathlist)
  return giit#operator#discard#perform(a:git, candidates, {
        \ 'force': a:args.get('-f|--force'),
        \})
endfunction

function! giit#operator#discard#perform(git, candidates, options) abort
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
  if !a:options.force
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
      throw s:Exception.info('giit: The operation has canceled by user')
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
  let pathlist = map(
        \ copy(checkout_candidates),
        \ 'shellescape(a:git.relpath(giit#expand(v:val)))',
        \)
  execute printf(
        \ 'Giit checkout --quiet --force HEAD -- %s',
        \ join(pathlist),
        \)
endfunction


function! s:retrieve_candidates(git, pathlist) abort
  let result = a:git.execute(giit#util#collapse([
        \ 'status',
        \ '--porcelain',
        \ '--no-column',
        \ '--',
        \ a:pathlist,
        \]))
  if result.status
    throw giit#operator#error(result)
  endif
  return giit#util#status#parse_content(a:git, result.content)
endfunction
