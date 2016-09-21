let s:String = vital#giit#import('Data.String')
let s:Aligner = vital#giit#import('Data.String.Aligner')

let s:record_separator = '#GIITSEP#'
let s:record_columns = ['%h', '%ar', '%an', '%s', '%d']

function! giit#component#log#util#parse_content(git, content) abort
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

