function! s:_vital_loaded(V) abort
  let s:String = a:V.import('Data.String')
endfunction

function! s:_vital_depends() abort
  return ['Data.String']
endfunction


" Public ---------------------------------------------------------------------
function! s:new(...) abort
  let args = copy(s:option)
  let args.raw = get(a:000, 0, [])
  let args.p = copy(s:parameter)
  let args.p.raw = args.raw
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


" Common ---------------------------------------------------------------------
let s:common = {}

function! s:common.len() abort
  return len(self.iter())
endfunction

function! s:common.get(expr_or_n, ...) abort
  let index = self.search(a:expr_or_n)
  if index == -1
    return get(a:000, 0, 0)
  endif
  return self.elaborate(self.raw[index])
endfunction

function! s:common.pop(expr_or_n, ...) abort
  let index = self.search(a:expr_or_n)
  if index == -1
    return get(a:000, 0, 0)
  endif
  return self.elaborate(remove(self.raw, index))
endfunction

function! s:common.apply(expr_or_n, fn) abort
  let index = self.search(a:expr_or_n)
  if index == -1
    return
  endif
  let self.raw[index] = a:fn(self.raw[index])
  return self.raw[index]
endfunction

function! s:common.elaborate(value) abort
  return s:_strip_quotes(a:value)
endfunction


" Option ---------------------------------------------------------------------
let s:option = copy(s:common)

function! s:_option_validate(expr) abort
  if type(a:expr) == type(0)
    throw printf(
          \ 'vital: Argument: A number %d has passed to {expr}. Did you mean args.p.xxx()?',
          \ a:expr,
          \)
  endif
endfunction

function! s:option.iter() abort
  return filter(copy(self.raw), 'v:val =~# ''^--\?\w\+''')
endfunction

function! s:option.set(expr, value) abort
  call s:_option_validate(a:expr)
  if type(a:value) == type(0) && a:value == 0
    return self.remove(a:expr)
  endif
  let index = self.search(a:expr)
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
  return value
endfunction

function! s:option.search(expr, ...) abort
  call s:_option_validate(a:expr)
  let start = get(a:000, 0, 0)
  let pattern = s:_build_pattern(a:expr)
  let indices = range(start, len(self.raw)-1)
  for index in indices
    if self.raw[index] =~# pattern
      return index
    endif
  endfor
  return -1
endfunction

function! s:option.elaborate(value) abort
  return s:_strip_quotes(s:_split_option(a:value)[1])
endfunction


" Parameter ------------------------------------------------------------------
let s:parameter = copy(s:common)

function! s:_parameter_validate(n) abort
  if type(a:n) == type('')
    throw printf(
          \ 'vital: Argument: A string %s has passed to {n}. Did you mean args.xxx()?',
          \ a:n,
          \)
  endif
endfunction

function! s:parameter.iter() abort
  return filter(copy(self.raw), 'v:val !~# ''^--\?\w\+''')
endfunction

function! s:parameter.set(n, value) abort
  call s:_parameter_validate(a:n)
  if type(a:value) == type(0) && a:value == 0
    return self.remove(a:n)
  endif
  let index = self.search(a:n)
  if index > -1
    let self.raw[index] = a:value
  else
    let delta = a:n - self.len() + 1
    let self.raw += repeat([''], delta)
    let self.raw[-1] = a:value
  endif
  return a:value
endfunction

function! s:parameter.search(n, ...) abort
  call s:_parameter_validate(a:n)
  let start = get(a:000, 0, 0)
  let counter = -1
  let indices = range(start, len(self.raw)-1)
  for index in indices
    let counter += self.raw[index] !~# '^--\?\w\+'
    if counter == a:n
      return index
    endif
  endfor
  return -1
endfunction
