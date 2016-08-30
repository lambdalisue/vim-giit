function! s:_vital_loaded(V) abort
  let s:String = a:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return ['Data.String']
endfunction


" Public ---------------------------------------------------------------------
function! s:new(...) abort
  let args = copy(s:instance)
  let args.raw = get(a:000, 0, [])
  return args
endfunction

function! s:parse(str) abort
  return s:new(s:_split_args(a:str))
endfunction


" Private --------------------------------------------------------------------
function! s:_split_args(str) abort
  let single_quote = '''\zs[^'']\+\ze'''
  let double_quote = '"\zs[^"]\+\ze"'
  let bare_strings = '\%(\\\s\|[^ \t''"]\)\+'
  let atoms = [single_quote, double_quote, bare_strings]
  let pattern = '\%(' . join(atoms, '\|') . '\)'
  return split(a:str, pattern . '*\zs\%(\s\+\|$\)\ze')
endfunction

function! s:_strip_quotes(str) abort
  return a:str =~# '^\%(".*"\|''.*''\)$' ? a:str[1:-2] : a:str
endfunction

function! s:_build_pattern(expr) abort
  let patterns = map(
        \ map(split(a:expr, '|'), 's:String.escape_pattern(v:val)'),
        \ 'v:val =~# ''^--'' ? v:val . ''\>'' : v:val'
        \)
  return printf('^\%%(%s\)', join(patterns, '\|'))
endfunction

function! s:_split_option(option) abort
  if a:option =~# '^\%(-\w\|--\w\+\)$'
    return [a:option, 1]
  else
    let m = matchlist(a:option, '^\(-\w\|--\w\+=\)\(.*\)')
    return [substitute(m[1], '=$', '', ''), s:_strip_quotes(m[2])]
  endif
endfunction

function! s:_count_positional(raw) abort
  return len(filter(copy(a:raw), 'v:val !~# ''^--\?\w\+'''))
endfunction


" Instance -------------------------------------------------------------------
let s:instance = {}

function! s:instance.search(expr_or_n, ...) abort
  let start = get(a:000, 0, 0)
  if type(a:expr_or_n) == type(0)
    return call(
          \ 's:_search_positional',
          \ [a:expr_or_n, start],
          \ self,
          \)
  else
    return call(
          \ 's:_search_optional',
          \ [a:expr_or_n, start],
          \ self,
          \)
  endif
endfunction

function! s:instance.get(expr_or_n, ...) abort
  let default = get(a:000, 0, 0)
  let start = get(a:000, 1, 0)
  let index = self.search(a:expr_or_n, start)
  if index == -1
    return default
  endif
  let value = self.raw[index]
  return s:_strip_quotes(
        \type(a:expr_or_n) == type(0) ? value : s:_split_option(value)[1]
        \)
endfunction

function! s:instance.set(expr_or_n, value, ...) abort
  let start = get(a:000, 0, 0)
  if type(a:expr_or_n) == type(0)
    return call(
          \ 's:_set_positional',
          \ [a:expr_or_n, a:value, start],
          \ self,
          \)
  else
    return call(
          \ 's:_set_optional',
          \ [a:expr_or_n, a:value, start],
          \ self,
          \)
  endif
endfunction

function! s:instance.pop(expr_or_n, ...) abort
  let start = get(a:000, 0, 0)
  let index = self.search(a:expr_or_n, start)
  if index == -1
    return get(a:000, 0, 0)
  endif
  let value = remove(self.raw, index)
  return s:_strip_quotes(
        \type(a:expr_or_n) == type(0) ? value : s:_split_option(value)[1]
        \)
endfunction

function! s:instance.apply(expr_or_n, fn, ...) abort
  let start = get(a:000, 0, 0)
  let index = self.search(a:expr_or_n, start)
  if index == -1
    return
  endif
  let self.raw[index] = a:fn(self.raw[index])
  return self.raw[index]
endfunction

function! s:_search_optional(expr, start) abort dict
  let pattern = s:_build_pattern(a:expr)
  let indices = range(a:start, len(self.raw)-1)
  for index in indices
    if self.raw[index] =~# pattern
      return index
    endif
  endfor
  return -1
endfunction

function! s:_search_positional(n, start) abort dict
  let counter = -1
  let indices = range(a:start, len(self.raw)-1)
  for index in indices
    let counter += self.raw[index] !~# '^--\?\w\+'
    if counter == a:n
      return index
    endif
  endfor
  return -1
endfunction

function! s:_set_optional(expr, value, start) abort dict
  let index = call('s:_search_optional', [a:expr, a:start], self)
  if type(a:value) == type(0) && a:value == 0
    if index > -1
      let value = remove(self.raw, index)
    endif
  else
    if index > -1
      let name = s:_split_option(self.raw[index])[0]
      let repl = (type(a:value) == type('') && name =~# '^--\w\+') ? '%s=%s' : '%s%s'
      let value = printf(repl, name, a:value)
      let self.raw[index] = printf(repl, name, a:value)
    else
      let name = split(a:expr, '|')[-1]
      let repl = (type(a:value) == type('') && name =~# '^--\w\+') ? '%s=%s' : '%s%s'
      let value = printf(repl, name, a:value)
      call add(self.raw, value)
    endif
  endif
  return value
endfunction

function! s:_set_positional(n, value, start) abort dict
  let index = call('s:_search_positional', [a:n, a:start], self)
  if type(a:value) == type(0) && a:value == 0
    if index > -1
      call remove(self.raw, index)
    endif
  else
    if index > -1
      let self.raw[index] = a:value
    else
      let delta = a:n - s:_count_positional(self.raw) + 1
      let self.raw += repeat([''], delta)
      let self.raw[-1] = a:value
    endif
  endif
  return a:value
endfunction
