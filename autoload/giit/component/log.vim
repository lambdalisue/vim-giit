let s:String = vital#giit#import('Data.String')
let s:Aligner = vital#giit#import('Data.String.Aligner')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')
let s:Chunker = vital#giit#import('Data.List.Chunker')
let s:Action = vital#giit#import('Action')
let s:Selector = vital#giit#import('Selector')
let s:Argument = vital#giit#import('Argument')
let s:Exception = vital#giit#import('Vim.Exception')


" Entry point ----------------------------------------------------------------
function! giit#component#log#autocmd(event) abort
  return call('s:on_' . a:event, [])
endfunction

function! giit#component#log#options(git, args) abort
  let options = {}
  let options.group     = 'selector'
  let options.opener    = a:args.pop('-o|--opener', 'botright 15split')
  let options.selection = []
  return options
endfunction

" autocmd --------------------------------------------------------------------
function! s:on_BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = s:adjust(git, expand('<afile>'))
  let result = giit#operator#execute(git, args)
  if result.status
    throw giit#operator#error(result)
  endif

  call s:init(args)
  let chunker = s:Chunker.new(1000, result.content)
  let chunker.git = git
  let chunker.selector = s:Selector.get()
  call chunker.selector.assign_candidates([])
  if exists('s:timer_id')
    call timer_stop(s:timer_id)
  endif
  let s:timer_id = timer_start(0, function('s:extend_candidates', [chunker]))
endfunction


" Private --------------------------------------------------------------------
function! s:adjust(git, bufname) abort
  let args = giit#meta#get('args', s:Argument.new())
  let args = args.clone()
  call args.set_p(0, 'log')
  call args.set('--no-color', 1)
  call args.set('--graph', 1)
  call args.set('--oneline', 1)
  call args.set('--pretty', printf(
        \ 'format:%s%s',
        \ s:record_separator,
        \ join(s:record_columns, s:record_separator),
        \))
  return args.lock()
endfunction

function! s:init(args) abort
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

  setlocal buftype=nofile nobuflisted
  setlocal filetype=giit-status
endfunction

function! s:extend_candidates(chunker, timer_id) abort
  let chunk = a:chunker.next()
  if empty(chunk)
    return
  endif
  let candidates = s:parse_content(a:chunker.git, chunk)
  call a:chunker.selector.extend_candidates(candidates)
  let s:timer_id = timer_start(10, function('s:extend_candidates', [a:chunker]))
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


" Parse ----------------------------------------------------------------------
let s:record_separator = '#GIITSEP#'
let s:record_columns = ['%h', '%ar', '%an', '%s', '%d']

function! s:parse_content(git, content) abort
  let candidates = map(copy(a:content), 'split(v:val, s:record_separator, 1)')
  let trailings = repeat([''], 5)
  call map(candidates, 'len(v:val) == 1 ? v:val + trailings : v:val')
  call s:Aligner.align(candidates)
  let widths = map(copy(candidates[0]), 'strwidth(v:val)')
  let fixwidth = eval(join(widths, '+'))
  let colwidth = winwidth(0) - fixwidth - 8 + widths[4]
  return map(candidates, 's:parse_record(v:val, colwidth)')
endfunction


function! s:parse_record(columns, colwidth) abort
  let columns = a:columns[:3] + [s:String.truncate(a:columns[4], a:colwidth)] + a:columns[5:]
  if empty(a:columns[1])
    return { 'word': join(columns) }
  else
    return {
          \ 'word': join(columns),
          \ 'hashref': s:strip(a:columns[1]),
          \ 'reldate': s:strip(a:columns[2]),
          \ 'author': s:strip(a:columns[3]),
          \ 'subject': s:strip(a:columns[4]),
          \ 'reflog': s:strip(a:columns[5]),
          \}
  endif
endfunction

function! s:strip(str) abort
  return substitute(a:str, '^\s\+\|\s\+$', '', 'g')
endfunction
