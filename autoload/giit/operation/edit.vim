let s:Argument = vital#giit#import('Argument')
let s:BufferAnchor = vital#giit#import('Vim.Buffer.Anchor')


function! giit#operation#edit#command(bang, range, cmdline) abort
  let git = giit#core#get_or_fail()
  let args = s:Argument.new(a:cmdline)

  let filename = giit#expand(args.pop_p(0, '%'))
  let opener = args.pop('-o|--opener', 'edit')
  let window = args.pop('--window', '')

  if args.has('--selection')
    let selection = giit#selection#parse(args.pop('--selection'))
  elseif filename ==# giit#expand('%')
    let selection = a:range
  else
    let selection = []
  endif

  call s:BufferAnchor.focus_if_available(opener)
  let ret = giit#util#buffer#open(filename, {
        \ 'window': window,
        \ 'opener': opener,
        \ 'selection': selection,
        \})
endfunction
