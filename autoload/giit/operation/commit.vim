let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:DictOption = vital#giit#import('Data.Dict.Option')


function! giit#operation#commit#correct(git, options) abort
  if get(a:options, '__corrected__')
    return a:options
  endif
  let a:options.__corrected__ = 1
  return a:options
endfunction

function! giit#operation#commit#execute(git, options) abort
  let args = s:build_args(a:git, a:options)
  let mode = s:build_mode(a:git, a:options)
  return a:git.execute(args, {
        \ 'encode_output': 0,
        \})
endfunction

function! giit#operation#commit#command(bang, range, args) abort
  let parser  = s:get_parser()
  let options = parser.parse(a:bang, a:range, a:args)
  if empty(options)
    return
  endif
  let git = giit#core#get_or_fail()
  call giit#component#commit#open(git, options)
endfunction

function! giit#operation#commit#complete(arglead, cmdline, cursorpos) abort
  let parser = s:get_parser()
  return parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction


function! s:build_args(git, options) abort
  let args = s:DictOption.translate(a:options, {
        \ 'all': 1,
        \ 'file': 1,
        \ 'reset-author': 1,
        \ 'author': 1,
        \ 'date': 1,
        \ 'gpg-sign': 1,
        \ 'no-gpg-sign': 1,
        \ 'amend': 1,
        \ 'allow-empty': 1,
        \ 'allow-empty-message': 1,
        \ 'verbose': 1,
        \ 'cleanup': 1,
        \})
  let args = [
        \ 'commit',
        \] + args
  return filter(args, '!empty(v:val)')
endfunction

function! s:build_mode(git, options) abort
  " The following options are directly modify the mode
  if get(a:options, 'edit')
    return 'edit'
  elseif get(a:options, 'no-edit')
    return 'no-edit'
  endif
  " The following options are impling the modes
  let no_edit_implies = ['file', 'messages', 'reuse-messages']
  for imply in no_edit_implies
    if get(a:options, imply)
      return 'no-edit'
    endif
  endfor
  " In this case, probably edit-mode
  return 'edit'
endfunction

function! s:get_parser() abort
  if !exists('s:parser')
    let s:parser = s:ArgumentParser.new({
          \ 'name': 'Giit commit',
          \ 'description': 'Record changes to the repository',
          \ 'complete_threshold': g:giit#complete_threshold,
          \})
    call s:parser.add_argument(
          \ '--all', '-a',
          \ 'reset author for commit',
          \)
    call s:parser.add_argument(
          \ '--reset-author',
          \ 'reset author for commit',
          \)
    call s:parser.add_argument(
          \ '--author',
          \ 'override author for commit', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '--date',
          \ 'override date for commit', {
          \   'type': s:ArgumentParser.types.value,
          \})
    call s:parser.add_argument(
          \ '--gpg-sign', '-S',
          \ 'GPG sign commit', {
          \   'type': s:ArgumentParser.types.any,
          \   'conflicts': ['no-gpg-sign'],
          \})
    call s:parser.add_argument(
          \ '--no-gpg-sign',
          \ 'no GPG sign commit', {
          \   'conflicts': ['gpg-sign'],
          \})
    call s:parser.add_argument(
          \ '--amend',
          \ 'amend previous commit',
          \)
    call s:parser.add_argument(
          \ '--allow-empty',
          \ 'allow an empty commit',
          \)
    call s:parser.add_argument(
          \ '--allow-empty-message',
          \ 'allow an empty commit message',
          \)
    call s:parser.add_argument(
          \ '--untracked-files', '-u',
          \ 'show untracked files, optional modes: all, normal, no', {
          \   'choices': ['all', 'normal', 'no'],
          \   'on_default': 'all',
          \})
    call s:parser.add_argument(
          \ '--verbose', '-v',
          \ 'verbose',
          \)
    call s:parser.add_argument(
          \ '--opener', '-o',
          \ 'a way to open a new buffer such as "edit", "split", etc.', {
          \   'type': s:ArgumentParser.types.value,
          \})
  endif
  return s:parser
endfunction
