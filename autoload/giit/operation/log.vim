let s:Path = vital#giit#import('System.Filepath')
let s:String = vital#giit#import('Data.String')
let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:DictOption = vital#giit#import('Data.Dict.Option')
let s:GitProcess = vital#giit#import('Git.Process')
let s:Aligner = vital#giit#import('Data.String.Aligner')


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
  let args = [
        \ 'log',
        \ '--no-color',
        \ '--graph',
        \ '--oneline',
        \ '--pretty=format:' . s:record_separator . join(s:record_columns, s:record_separator),
        \] + args
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
let s:record_separator = '#GIITSEP#'
let s:record_columns = ['%h', '%ar', '%an', '%s', '%d']

function! giit#operation#log#parse(git, content) abort
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
