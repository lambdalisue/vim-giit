let s:Path = vital#giit#import('System.Filepath')
let s:Dict = vital#giit#import('Data.Dict')
let s:Git = vital#giit#import('Git')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')
let s:BufferObserver = vital#giit#import('Vim.Buffer.Observer')


function! giit#component#commit#open(git, options) abort
  let options = giit#operation#commit#correct(a:git, a:options)
  let window = get(options, 'window', '')
  let opener = get(options, 'opener', 'split')
  let selection = get(options, 'selection', [])

  call s:BufferAnchor.focus_if_available(opener)
  call giit#operation#commit#execute(a:git, options)
  let bufname = s:Path.join(a:git.repository, 'COMMIT_EDITMSG')
  let ret = giit#util#buffer#open(bufname, {
        \ 'window': window,
        \ 'opener': opener,
        \ 'selection': selection,
        \})
  call s:initialize_buffer({})

  " Assign options
  call giit#meta#set('options', options)

  return giit#util#buffer#finalize(ret)
endfunction


" autocmd --------------------------------------------------------------------
function! s:on_BufWinLeave() abort
  let expr = expand('<afile>')
  let git = giit#core#get_or_fail(expr)
  let options = giit#meta#require_at(expr, 'options')
  call s:commit(git, options)
endfunction


" private --------------------------------------------------------------------
function! s:initialize_buffer(static_options) abort
  if exists('b:_giit_initialized')
    return
  endif
  let b:_giit_initialized = 1

  " Register autocmd
  augroup giit-internal-component-commit
    autocmd! * <buffer>
    autocmd BufWinLeave <buffer> call s:on_BufWinLeave()
  augroup END

  " Attach modules
  call s:BufferAnchor.attach()
  call s:BufferObserver.attach()

  setlocal nobuflisted
  setlocal bufhidden=wipe
endfunction

function! s:get_candidates(fline, eline) abort

endfunction

function! s:commit(git, options) abort
  let options = s:Dict.omit(a:options, [
        \ 'patch',
        \ 'reuse-message',
        \ 'reedit-message',
        \ 'file',
        \ 'message',
        \ 'edit',
        \ 'no-edit',
        \])
  let options.file = s:Path.join(a:git.repository, 'COMMIT_EDITMSG')
  let options.cleanup = 'strip'
  let result = giit#operation#commit#execute(a:git, options)
  call s:Prompt.echo('Title', result.content)
endfunction
