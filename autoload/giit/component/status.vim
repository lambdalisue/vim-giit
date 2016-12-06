let s:String = vital#giit#import('Data.String')
let s:Buffer = vital#giit#import('Vim.Buffer')
let s:Anchor = vital#giit#import('Vim.Buffer.Anchor')
let s:Observer = vital#giit#import('Vim.Buffer.Observer')
let s:Action = vital#giit#import('Action')
let s:Exception = vital#giit#import('Vim.Exception')


" Entry point ----------------------------------------------------------------
function! giit#component#status#BufReadCmd() abort
  call s:Exception.register(function('s:exception_handler'))
  let git = giit#core#get_or_fail()
  let args = giit#meta#get_or_fail('args')
  let result = giit#operator#status#execute(git, args)
  if result.status
    throw giit#process#error(result)
  endif

  call s:init(args)
  call s:assign_candidates(git, result)
  call giit#util#vim#doautocmd('BufRead')
  setlocal filetype=giit-status
endfunction


" Private --------------------------------------------------------------------
function! s:init(args) abort
  if exists('b:giit_initialized')
    return
  endif
  let b:giit_initialized = 1

  " Attach modules
  let action = s:Action.attach('giit', {
        \ 'get_candidates': function('s:get_candidates'),
        \})
  call action.init()
  call s:Anchor.attach()
  call s:Observer.attach()

  setlocal buftype=nofile
  setlocal bufhidden=delete
  setlocal nomodifiable
endfunction

function! s:exception_handler(exception) abort
  setlocal buftype&
  setlocal filetype&
  setlocal nomodifiable&
  silent 0file!
  call giit#meta#clear()
  return 0
endfunction

function! s:get_candidates(sline, eline) abort
  let candidate_map = giit#meta#get_or_fail('candidate_map')
  let candidates = map(
        \ getline(a:sline, a:eline),
        \ 'get(candidate_map, v:val)'
        \)
  return candidates
endfunction

function! s:assign_candidates(git, result) abort
  let candidates = giit#operator#status#parse_content(a:git, a:result.content)
  let candidate_map = {}
  let buffer_content = []
  for candidate in candidates
    let candidate_map[candidate.word] = candidate
    call add(buffer_content, candidate.word)
  endfor
  call giit#meta#set('candidate_map', candidate_map)
  call s:Buffer.edit_content(buffer_content)
endfunction

function! s:on_stdout(job, data, event) abort
  let bufnum = self.bufnum
  if !bufexists(bufnum)
    return
  endif
  let git = giit#core#get(bufnum)
  let candidates = giit#meta#get_at(bufnum, 'candidates', [])
  let new_candidates = giit#operator#status#parse_content(git, a:data)
  call extend(candidates, new_candidates)
  let candidate_map = {}
  let buffer_content = []
  for candidate in candidates
    let candidate_map[candidate.word] = candidate
    call add(buffer_content, candidate.word)
  endfor
  call giit#meta#set('candidate_map', candidate_map)
endfunction
