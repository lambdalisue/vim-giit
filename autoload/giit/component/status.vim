let s:String = vital#giit#import('Data.String')
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
  let candidates = giit#operation#status#parse(git, result.content)
  let selector = s:Selector.get()
  call selector.assign_candidates(candidates)
  call selector.define_syntax()
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
  let selector.define_highlight = function('s:define_highlight')
  let selector.define_syntax = function('s:define_syntax')
  call selector.define_highlight()
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

function! s:define_highlight() abort dict
  highlight default link GiitSelectorInput    Constant
  highlight default link GiitSelectorPrefix   Text
  highlight default link GiitSelectorSelected Statement
  highlight default link GiitSelectorMatch    Title
  highlight default link GiitSelectorNotMatch Comment

  highlight default link GiitConflicted       Error
  highlight default link GiitStaged           Special
  highlight default link GiitUnstaged         Comment
  highlight default link GiitPatched          Constant
  highlight default link GiitUntracked        GiitUnstaged
  highlight default link GiitIgnored          Identifier
endfunction

function! s:define_syntax() abort dict
  syntax clear
  syntax sync maxlines=0
  syntax match GiitNotMatch   /.*/
        \ contains=GiitSelectorMatch,GiitStaged,GiitUnstaged,GiitPatched,GiitIgnored,GiitUntracked,GiitConflicted
  syntax match GiitStaged     /^. [ MADRC] .*$/hs=s+2
        \ contained contains=GiitSelectorMatch
  syntax match GiitUnstaged   /^.  [MDAU?] .*$/hs=s+2
        \ contained contains=GiitSelectorMatch
  syntax match GiitPatched    /^. [MADRC][MDAU?] .*$/hs=s+2
        \ contained contains=GiitSelectorMatch
  syntax match GiitIgnored    /^. !! .*$/
        \ contained contains=GiitSelectorMatch
  syntax match GiitUntracked  /^. ?? .*$/
        \ contained contains=GiitSelectorMatch
  syntax match GiitConflicted /^. \%(DD\|AU\|UD\|UA\|DU\|AA\|UU\) .*$/
        \ contained contains=GiitSelectorMatch
  syntax match GiitSelectorSelected /^\*.*$/
        \ contains=GiitSelectorMatch
  syntax match GiitSelectorInput /\%^.*$/
        \ contains=GiitSelectorPrefix
  execute printf(
        \ 'syntax match GiitSelectorPrefix /^%s/ contained',
        \ escape(s:String.escape_pattern(self.prefix), '/'),
        \)
  let patterns = self.get_patterns()
  if !empty(patterns)
    let patterns = map(
          \ patterns,
          \ 's:String.escape_pattern(v:val)',
          \)
    let pattern = printf('%s\%%(%s\)',
          \ join(patterns, '\|'),
          \ &ignorecase ? '\c' : '\C',
          \)
    execute printf(
          \ 'syntax match GiitSelectorMatch /%s/ contained',
          \ escape(pattern, '/'),
          \)
  endif
endfunction
