let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')
let s:Action = vital#giit#import('Action')
let s:Selector = vital#giit#import('Selector')
let s:Chunker = vital#giit#import('Data.List.Chunker')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


function! giit#component#status#autocmd(event) abort
  return call('s:on_' . a:event, [])
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = giit#meta#get('args', s:Argument.new())
  call args.set_p(0, 'status')
  call args.set('--porcelain', 1)
  call args.pop('-s|--short')
  call args.pop('-b|--branch')
  call args.pop('--long')
  call args.pop('-z')
  call args.pop('--column')
  let result = giit#operation#status#execute(git, args)
  if result.status
    call giit#operation#throw(result)
  endif
  call giit#meta#set('args', args)
  call s:init()

  let chunker = s:Chunker.new(1000, result.content)
  let chunker.git = git
  let chunker.selector = s:Selector.get()
  call chunker.selector.assign_candidates([])
  if exists('s:timer_id')
    call timer_stop(s:timer_id)
  endif
  let s:timer_id = timer_start(0, function('s:extend_candidates', [chunker]))
endfunction


" private --------------------------------------------------------------------
function! s:init() abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  " Attach modules
  call s:Anchor.attach()
  call s:Observer.attach()

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

  setlocal buftype=nofile nobuflisted
  setlocal filetype=giit-status
endfunction

function! s:exception_handler(exception) abort
  setlocal buftype&
  setlocal filetype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction

function! s:extend_candidates(chunker, timer_id) abort
  let chunk = a:chunker.next()
  if empty(chunk)
    return
  endif
  let candidates = giit#operation#status#parse(a:chunker.git, chunk)
  call a:chunker.selector.extend_candidates(candidates)
  let s:timer_id = timer_start(10, function('s:extend_candidates', [a:chunker]))
endfunction
