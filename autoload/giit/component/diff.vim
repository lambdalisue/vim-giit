let s:Buffer = vital#giit#import('Vim.Buffer')
let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')
let s:BufferDoom = vital#giit#import('Vim.Buffer.Doom')
let s:WORKTREE = '@@'


function! giit#component#diff#open(git, options) abort
  let options = giit#operation#diff#correct(a:git, a:options)

  if get(options, 'split')
    call s:open2(a:git, options)
  else
    call s:open1(a:git, options)
  endif
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  let result = giit#operation#diff#execute(
        \ giit#core#get_or_fail(),
        \ giit#meta#require('options')
        \)
  if result.status
    call giit#operation#inform(result)
  endif
  call s:Buffer.edit_content(result.content)
  call giit#util#doautocmd('BufRead')
  " Force override filetype
  if empty(giit#meta#get('filename'))
    setlocal filetype=git
  else
    setlocal filetype=diff
  endif
endfunction

function! s:on_BufWriteCmd() abort
  let git = giit#core#get_or_fail()
  let result = giit#operation#patch#execute(git, {
        \ 'filename': giit#meta#get('filename'),
        \ 'diff_content': getline(1, '$'),
        \})
  if result.status
    call giit#operation#inform(result)
  endif
  setlocal nomodified
endfunction


" private --------------------------------------------------------------------
function! s:initialize_buffer(static_options) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  " Register autocmd
  augroup giit-internal-component-diff
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:on_BufReadCmd()
  augroup END

  if a:static_options.patch
    augroup giit-internal-component-diff
      autocmd BufWriteCmd <buffer> call s:on_BufWriteCmd()
    augroup END
    setlocal buftype=acwrite
    setlocal modifiable
  else
    setlocal buftype=nowrite
    setlocal nomodifiable
  endif
endfunction

function! s:open1(git, options) abort
  let window = get(a:options, 'window', '')
  let opener = get(a:options, 'opener', 'edit')
  let selection = get(a:options, 'selection', [])

  call s:BufferAnchor.focus_if_available(opener)
  let bufname = giit#util#buffer#bufname(a:git, 'diff')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ get(a:options, 'patch') ? ':patch' : '',
        \ a:options.object,
        \)
  let ret = giit#util#buffer#open(bufname, {
        \ 'window': window,
        \ 'opener': opener,
        \ 'selection': selection,
        \})
  call s:initialize_buffer({
        \ 'patch': get(a:options, 'patch'),
        \})

  " Check if redraw is required or not
  let is_redraw_required = giit#meta#modified('options', a:options)

  " Assign options
  call giit#meta#set('options', a:options)
  call giit#meta#set('commit', a:options.commit)
  call giit#meta#set('filename', a:options.filename)

  " Redraw the buffer when necessary
  if is_redraw_required
    call s:on_BufReadCmd()
  endif

  return giit#util#buffer#finalize(ret)
endfunction

function! s:open2(git, options) abort
  let options = extend({
        \ 'patch': 0,
        \ 'cached': 0,
        \ 'reverse': 0,
        \ 'opener': '',
        \ 'selection': [],
        \}, a:options)
  let filename = empty(options.filename)
        \ ? giit#util#normalize#relpath(a:git, giit#expand('%'))
        \ : options.filename
  let [lhs, rhs] = giit#operation#diff#split_commit(a:git, a:options)
  let vertical = matchstr(&diffopt, 'vertical')
  let loptions = {
        \ 'patch': !options.reverse && options.patch,
        \ 'commit': lhs,
        \ 'filename': filename,
        \ 'worktree': lhs ==# s:WORKTREE,
        \}
  let roptions = {
        \ 'silent': 1,
        \ 'patch': options.reverse && options.patch,
        \ 'commit': rhs,
        \ 'filename': filename,
        \ 'worktree': rhs ==# s:WORKTREE,
        \}

  call s:BufferAnchor.focus_if_available(options.opener)
  let ret1 = giit#component#show#open(a:git,
        \ extend(options.reverse ? loptions : roptions, {
        \  'opener': options.opener,
        \  'window': 'diff2_rhs',
        \  'selection': options.selection,
        \ }
        \))
  diffthis

  let ret2 = giit#component#show#open(a:git,
        \ extend(options.reverse ? roptions : loptions, {
        \  'opener': vertical ==# 'vertical'
        \    ? 'leftabove vertical split'
        \    : 'leftabove split',
        \  'window': 'diff2_lhs',
        \  'selection': options.selection,
        \ }
        \))
  diffthis
  diffupdate

  let doom = s:BufferDoom.new()
  let sign = xor(ret1.loaded, ret2.loaded)
  call doom.involve(ret1.bufnum, { 'keep': !ret1.loaded && sign })
  call doom.involve(ret2.bufnum, { 'keep': !ret2.loaded && sign })
endfunction
