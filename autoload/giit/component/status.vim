let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')
let s:BufferObserver = vital#giit#import('Vim.Buffer.Observer')
let s:ListChunker = vital#giit#import('Data.List.Chunker')
let s:Action = vital#giit#import('Action')
let s:Selector = vital#giit#import('Selector')


function! giit#component#status#open(git, args, ...) abort
  let options = giit#util#assign(get(a:000, 0), {
        \ 'window': 'candidate_window',
        \ 'opener': 'botright 15split',
        \})

  call s:BufferAnchor.focus_if_available(options.opener)
  let bufname = giit#util#buffer#bufname(a:git, 'status')
  let ret = giit#util#buffer#open(bufname, {
        \ 'window': options.window,
        \ 'opener': options.opener,
        \})
  call s:initialize_buffer({})

  " Check if redraw is required or not
  let is_redraw_required = giit#meta#modified('args', a:args)

  call giit#meta#set('args', a:args)

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
        \ giit#meta#require('args')
        \)
  if result.status
    call giit#operation#inform(result)
    return
  endif
  let chunker = s:ListChunker.new(1000, result.content)
  let chunker.git = git
  let chunker.selector = s:Selector.get()
  call chunker.selector.assign_candidates([])
  call timer_start(0, function('s:extend_candidates', [chunker]))
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
  call action.smart_map('n', 'dd', '<Plug>(giit-diff)', '0D')
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

function! s:extend_candidates(chunker, timer_id) abort
  let chunk = a:chunker.next()
  if empty(chunk)
    return
  endif
  let candidates = giit#operation#status#parse(a:chunker.git, chunk)
  call a:chunker.selector.extend_candidates(candidates)
  call timer_start(10, function('s:extend_candidates', [a:chunker]))
endfunction
