let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')
let s:BufferObserver = vital#giit#import('Vim.Buffer.Observer')
let s:Action = vital#giit#import('Action')
let s:Selector = vital#giit#import('Selector')


function! giit#component#status#open(git, options) abort
  let options = giit#operation#status#correct(a:git, a:options)
  let window = get(a:options, 'window', 'candidate_window')
  let opener = get(a:options, 'opener', 'botright 15split')
  let selection = get(a:options, 'selection', [])

  call s:BufferAnchor.focus_if_available(opener)
  let bufname = giit#util#buffer#bufname(a:git, 'status')
  let ret = giit#util#buffer#open(bufname, {
        \ 'window': window,
        \ 'opener': opener,
        \ 'selection': selection,
        \})
  call s:initialize_buffer({})

  " Check if redraw is required or not
  let is_redraw_required = giit#meta#modified('options', options)

  " Assign options
  call giit#meta#set('options', options)

  " Redraw the buffer when necessary
  if is_redraw_required
    call s:on_BufReadCmd()
  endif

  return giit#util#buffer#finalize(ret)
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  let git = giit#core#get_or_fail()
  let result = giit#operation#status#execute(
        \ git,
        \ giit#meta#require('options')
        \)
  if result.status
    call giit#throw(result)
  endif
  let candidates = giit#operation#status#parse(
        \ git,
        \ result.content
        \)
  let selector = s:Selector.get()
  call selector.assign_candidates(candidates)
endfunction


" private --------------------------------------------------------------------
function! s:initialize_buffer(static_options) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  " Attach modules
  call s:BufferAnchor.attach()
  call s:BufferObserver.attach()

  let selector = s:Selector.attach('giit')
  call selector.init()

  let action = s:Action.attach('giit', {
        \ 'get_candidates': s:Selector.get_candidates,
        \})
  call action.init()
  call action.include([
        \ 'open', 'diff',
        \ 'index', 'checkout', 'discard',
        \])
  call action.smart_map('n', '<Return>', '<Plug>(giit-edit)')
  call action.smart_map('n', 'ee', '<Plug>(giit-edit)')
  call action.smart_map('n', 'EE', '<Plug>(giit-edit-right)')
  call action.smart_map('n', 'dd', '<Plug>(giit-diff)')
  call action.smart_map('n', 'ds', '<Plug>(giit-diff-split)')
  call action.smart_map('nv', '<<', '<Plug>(giit-index-stage)')
  call action.smart_map('nv', '>>', '<Plug>(giit-index-unstage)')
  call action.smart_map('nv', '--', '<Plug>(giit-index-toggle)')
  call action.smart_map('nv', '==', '<Plug>(giit-index-discard)')

  " Register autocmd
  augroup giit-internal-component-status
    autocmd! * <buffer>
    autocmd BufReadCmd <buffer> call s:on_BufReadCmd()
  augroup END

  setlocal buftype=nofile nobuflisted
  setlocal filetype=gitcommit
  setlocal winfixheight

  nnoremap <buffer><silent> <Plug>(giit-switch-commit) :<C-u>Giit commit<CR>
  nmap <buffer><nowait> <C-^> <Plug>(giit-switch-commit)
endfunction
