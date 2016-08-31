let s:t_number = type(0)
let s:t_string = type('')

function! s:_vital_loaded(V) abort
  let s:String = a:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return ['Data.String']
endfunction

function! s:_vital_created(module) abort
  " build pattern for parsing arguments
  let single_quote = '''\zs[^'']\+\ze'''
  let double_quote = '"\zs[^"]\+\ze"'
  let bare_strings = '\%(\\\s\|[^ \t''"]\)\+'
  let s:pattern = printf(
        \ '\%%(%s\)*\zs\%%(\s\+\|$\)\ze',
        \ join([single_quote, double_quote, bare_strings], '\|')
        \)
endfunction


function! s:new(...) abort
  if a:0 > 0
    let init = type(a:1) == s:t_string ? s:parse(a:1) : a:1
  else
    let init = []
  endif
  let args = copy(s:args)
  let args.raw = init
  return args
endfunction

function! s:parse(cmdline) abort
  let terms = split(a:cmdline, s:pattern)
  let terms = map(terms, 's:strip_quotes(v:val)')
  for index in range(len(terms))
    let [key, value] = s:parse_term(terms[index])
    let value = type(value) == s:t_string
          \ ? s:strip_quotes(value)
          \ : value
    let terms[index] = s:build_term(key, value)
  endfor
  return terms
endfunction

function! s:build_pattern(query) abort
  let patterns = split(a:query, '|')
  call map(patterns, 's:String.escape_pattern(v:val)')
  call map(patterns, 'v:val =~# ''^--\w\+'' ? v:val . ''\>'' : v:val')
  return printf('^\%%(%s\)', join(patterns, '\|'))
endfunction

function! s:strip_quotes(str) abort
  return a:str =~# '^\%(".*"\|''.*''\)$' ? a:str[1:-2] : a:str
endfunction

function! s:parse_term(term) abort
  let m = matchlist(a:term, '^\(-\w\|--\w\+=\)\(.\+\)')
  if empty(m)
    return a:term =~# '^--\?\w\+' ? [a:term, 1] : ['', a:term]
  else
    let [key, value] = m[1:2]
    return [substitute(key, '=$', '', ''), value]
  endif
endfunction

function! s:build_term(key, value) abort
  if type(a:value) == s:t_number
    return a:value == 0 ? '' : a:key
  elseif empty(a:key) || a:key =~# '^-\w$'
    return a:key . a:value
  else
    return a:key . '=' . a:value
  endif
endfunction

let s:args = {}

function! s:args.list() abort
  return filter(copy(self.raw), 'v:val =~# ''^--\?\w\+''')
endfunction

function! s:args.search(query, ...) abort
  let pattern = s:build_pattern(a:query)
  let indices = range(get(a:000, 0, 0), len(self.raw)-1)
  for index in indices
    if self.raw[index] =~# pattern
      return index
    endif
  endfor
  return -1
endfunction

function! s:args.get(query, ...) abort
  let index = self.search(a:query, get(a:000, 1, 0))
  if index == -1
    return get(a:000, 0, 0)
  endif
  return s:parse_term(self.raw[index])[1]
endfunction

function! s:args.set(query, value, ...) abort
  if type(a:value) == s:t_number && a:value == 0
    call self.pop(a:query, 0, get(a:000, 0, 0))
    return self
  endif
  let index = self.search(a:query, get(a:000, 0, 0))
  if index == -1
    call add(self.raw, s:build_term(split(a:query, '|')[-1], a:value))
    return self
  endif
  while index != -1
    let self.raw[index] = s:build_term(
          \ s:parse_term(self.raw[index])[0],
          \ a:value
          \)
    let index = self.search(a:query, index + 1)
  endwhile
  return self
endfunction

function! s:args.pop(query, ...) abort
  let index = self.search(a:query, get(a:000, 1, 0))
  if index == -1
    return get(a:000, 0, 0)
  endif
  let value = s:parse_term(self.raw[index])[1]
  while index != -1
    call remove(self.raw, index)
    " NOTE: A term has removed so search from 'index' instead of 'index+1'
    let index = self.search(a:query, index)
  endwhile
  return value
endfunction

function! s:args.map(expr) abort
  let indices = filter(
        \ range(0, len(self.raw)-1),
        \ 'self.raw[v:val] =~# ''^--\?\w\+'''
        \)
  let candidates = map(copy(indices), 's:parse_term(self.raw[v:val])')
  call map(candidates, a:expr)
  for i in range(len(candidates))
    let index = indices[i]
    let self.raw[index] = call('s:build_term', candidates[i])
  endfor
  return self
endfunction

function! s:args.apply(query, expr, ...) abort
  let index = self.search(a:query, get(a:000, 1, 0))
  if index == -1
    return get(a:000, 0, 0)
  endif
  let terms = [s:parse_term(self.raw[index])]
  call map(terms, a:expr)
  let self.raw[index] = call('s:build_term', terms[0])
  let value = self.raw[index]
  let index = self.search(a:query, index+1)
  while index != -1
    let terms = [s:parse_term(self.raw[index])]
    call map(terms, a:expr)
    let self.raw[index] = call('s:build_term', terms[0])
    let index = self.search(a:query, index+1)
  endwhile
  return s:parse_term(value)[1]
endfunction

function! s:args.list_p() abort
  return filter(copy(self.raw), 'v:val !~# ''^--\?\w\+''')
endfunction

function! s:args.search_p(nth, ...) abort
  let counter = -1
  let indices = range(get(a:000, 0, 0), len(self.raw)-1)
  for index in indices
    let counter += self.raw[index] !~# '^--\?\w\+'
    if counter == a:nth
      return index
    endif
  endfor
  return -1
endfunction

function! s:args.get_p(nth, ...) abort
  let index = self.search_p(a:nth, get(a:000, 1, 0))
  if index == -1
    return get(a:000, 0, '')
  endif
  return self.raw[index]
endfunction

function! s:args.set_p(nth, value, ...) abort
  if type(a:value) == s:t_number && a:value == 0
    call self.pop_p(a:nth, '', get(a:000, 0, 0))
    return self
  endif
  let index = self.search_p(a:nth, get(a:000, 0, 0))
  if index == -1
    let n = len(filter(copy(self.raw), 'v:val !~# ''^--\?\w\+'''))
    let self.raw += repeat([''], a:nth - n + 1)
    let self.raw[-1] = a:value
  else
    let self.raw[index] = a:value
  endif
  return self
endfunction

function! s:args.pop_p(nth, ...) abort
  let index = self.search_p(a:nth, get(a:000, 1, 0))
  if index == -1
    return get(a:000, 0, '')
  endif
  let value = self.raw[index]
  call remove(self.raw, index)
  return value
endfunction

function! s:args.map_p(expr) abort
  let indices = filter(
        \ range(0, len(self.raw)-1),
        \ 'self.raw[v:val] !~# ''^--\?\w\+'''
        \)
  let candidates = map(copy(indices), 'self.raw[v:val]')
  call map(candidates, a:expr)
  for i in range(len(candidates))
    let index = indices[i]
    let self.raw[index] = candidates[i]
  endfor
  return self
endfunction

function! s:args.apply_p(nth, expr, ...) abort
  let index = self.search_p(a:nth, get(a:000, 1, 0))
  if index == -1
    return get(a:000, 0, '')
  endif
  let terms = [self.raw[index]]
  call map(terms, a:expr)
  let self.raw[index] = terms[0]
  return terms[0]
endfunction
