let s:Path = vital#giit#import('System.Filepath')
let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:DictOption = vital#giit#import('Data.Dict.Option')
let s:GitProcess = vital#giit#import('Git.Process')


function! giit#operation#log#correct(git, options) abort
  if get(a:options, '__corrected__')
    return a:options
  endif
  let a:options.__corrected__ = 1
  return a:options
endfunction

function! giit#operation#log#execute(git, options) abort
  let args = s:build_args(a:git, a:options)
  let result = a:git.execute(args, {
        \ 'encode_output': 0,
        \})
  return result
endfunction

function! giit#operation#log#command(bang, range, args) abort
  let parser  = s:get_parser()
  let options = parser.parse(a:bang, a:range, a:args)
  if empty(options)
    return
  endif
  let git = giit#core#get_or_fail()
  call giit#component#log#open(git, options)
endfunction

function! giit#operation#log#complete(arglead, cmdline, cursorpos) abort
  let parser = s:get_parser()
  return parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:build_args(git, options) abort
  let options = giit#operation#log#correct(a:git, a:options)
  let args = s:DictOption.translate(options, {
        \})
  let args = ['log', '--no-color', '--oneline', '--graph', '--decorate'] + args
  return filter(args, '!empty(v:val)')
endfunction

function! s:get_parser() abort
  if !exists('s:parser')
    let s:parser = s:ArgumentParser.new({
          \ 'name': 'Giit log',
          \ 'description': 'Show and manipulate a log of the repository',
          \ 'complete_threshold': g:giit#complete_threshold,
          \})
    call s:parser.add_argument(
          \ '--opener', '-o',
          \ 'a way to open a new buffer such as "edit", "split", etc.', {
          \   'type': s:ArgumentParser.types.value,
          \})
  endif
  return s:parser
endfunction


" Parse ----------------------------------------------------------------------
function! giit#operation#log#parse(git, content) abort
  return map(copy(a:content), 's:parse_record(v:val)')
endfunction

function! s:parse_record(record) abort
  return { 'word': a:record }
endfunction
