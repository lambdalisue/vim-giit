let s:Buffer = vital#giit#import('Vim.Buffer')
let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#component#show#open(git, options) abort
  let options = giit#operation#show#correct(a:git, a:options)
  let window = get(a:options, 'window', '')
  let opener = get(a:options, 'opener', 'edit')
  let selection = get(a:options, 'selection', [])

  if get(options, 'worktree')
    let bufname = giit#util#normalize#abspath(a:git, options.filename) 
    let ret = giit#util#buffer#open(bufname, {
          \ 'window': window,
          \ 'opener': opener,
          \ 'selection': selection,
          \})
    return giit#util#buffer#finalize(ret)
  endif

  call s:BufferAnchor.focus_if_available(opener)
  let bufname = giit#util#buffer#bufname(a:git, 'show')
  let bufname = printf('%s%s/%s',
        \ bufname,
        \ get(options, 'patch') ? ':patch' : '',
        \ options.object,
        \)
  let ret = giit#util#buffer#open(bufname, {
        \ 'window': window,
        \ 'opener': opener,
        \ 'selection': selection,
        \})
  call s:initialize_buffer({
        \ 'patch': get(options, 'patch'),
        \})

  " Check if redraw is required or not
  let is_redraw_required = giit#meta#modified('options', options)

  " Assign options
  call giit#meta#set('options', options)
  call giit#meta#set('commit', options.commit)
  call giit#meta#set('filename', options.filename)

  " Redraw the buffer when necessary
  if is_redraw_required
    call s:on_BufReadCmd()
  endif

  return giit#util#buffer#finalize(ret)
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  let result = giit#operation#show#execute(
        \ giit#core#get_or_fail(),
        \ giit#meta#require('options')
        \)
  if result.status
    call giit#throw(result)
  endif
  call s:Buffer.edit_content(result.content)
  call giit#util#doautocmd('BufRead')
endfunction

function! s:on_BufWriteCmd() abort
  let git = giit#core#get_or_fail()
  let result = giit#operation#patch#execute(git, {
        \ 'filename': giit#meta#get('filename'),
        \ 'content': getline(1, '$'),
        \})
  if result.status
    call giit#throw(result)
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
  augroup giit-internal-component-show
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:on_BufReadCmd()
  augroup END

  if a:static_options.patch
    augroup giit-internal-component-show
      autocmd BufWriteCmd <buffer> call s:on_BufWriteCmd()
    augroup END
    setlocal buftype=acwrite
    setlocal modifiable
  else
    setlocal buftype=nowrite
    setlocal nomodifiable
  endif
endfunction
