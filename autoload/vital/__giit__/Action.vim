function! s:get() abort
  if exists('b:_vital_action_binder')
    return b:_vital_action_binder
  endif
  throw printf(
        \ 'vital: Action: An action binder is not attached to %s',
        \ expand('%')
        \)
endfunction

function! s:attach(name, ...) abort
  let binder = extend({
        \ 'name': a:name,
        \ 'include_path': a:name . '#action',
        \ 'get_candidates': function('s:_default_get_candidates'),
        \ 'actions': {},
        \ 'aliases': {},
        \}, get(a:000, 0, {})
        \)
  let binder = extend(copy(s:binder), binder)

  call binder.define('builtin:echo', function('s:_action_echo'), {
        \ 'hidden': 1,
        \ 'alias': 'echo',
        \ 'description': 'Echo the candidates',
        \})
  call binder.define('builtin:help', function('s:_action_help'), {
        \ 'alias': 'help',
        \ 'description': 'Show help of actions',
        \ 'mapping_mode': 'n',
        \})
  call binder.define('builtin:help:all', function('s:_action_help'), {
        \ 'alias': 'help:all',
        \ 'description': 'Show help of actions including hidden actions',
        \ 'mapping_mode': 'n',
        \ 'options': { 'all': 1 },
        \})
  call binder.define('builtin:choice', function('s:_action_choice'), {
        \ 'hidden': 1,
        \ 'alias': 'choice',
        \ 'description': 'Select action to perform',
        \ 'mapping_mode': 'inv',
        \})
  let b:_vital_action_binder = binder
  return binder
endfunction


" Instance -------------------------------------------------------------------
let s:binder = {}

function! s:binder.init() abort
  nmap <buffer><nowait> ?     <Plug>(giit-builtin-help)
  nmap <buffer><nowait> <Tab> <Plug>(giit-builtin-choice)
  vmap <buffer><nowait> <Tab> <Plug>(giit-builtin-choice)gv
  imap <buffer><nowait> <Tab> <Plug>(giit-builtin-choice)
endfunction

function! s:binder.get_alias(name) abort
  let aliases = filter(keys(self.aliases), 'v:val =~# ''^'' . a:name')

endfunction

function! s:binder.get_action(name) abort
  if has_key(self.actions, a:name)
    return self.actions[a:name]
  elseif has_key(self.aliases, a:name)
    return self.actions[self.aliases[a:name]]
  endif
  let aliases = filter(keys(self.aliases), 'v:val =~# ''^'' . a:name')
  let actions = extend(
        \ filter(keys(self.actions), 'v:val =~# ''^'' . a:name'),
        \ map(aliases, 'self.aliases[v:val]')
        \)
  if empty(actions)
    echohl WarningMsg
    echo printf('No action %s is found.', a:name)
    echohl None
    return {}
  endif
  let actions = sort(
        \ map(actions, 'self.actions[v:val]'),
        \ 's:_compare_action_priority'
        \)
  return get(actions, 0)
endfunction

function! s:binder.define(name, callback, ...) abort
  let action = extend({
        \ 'callback': a:callback,
        \ 'name': a:name,
        \ 'alias': a:name,
        \ 'description': '',
        \ 'mapping': '',
        \ 'mapping_mode': '',
        \ 'requirements': [],
        \ 'options': {},
        \ 'default': 0,
        \ 'hidden': 0,
        \ 'priority': 0,
        \}, get(a:000, 0, {}),
        \)
  if empty(action.mapping)
    let action.mapping = printf(
          \ '<Plug>(%s-%s)',
          \ substitute(self.name, ':', '-', 'g'),
          \ substitute(action.name, ':', '-', 'g'),
          \)
  endif

  for mode in split(action.mapping_mode, '\zs')
    execute printf(
          \ '%snoremap <buffer><silent> %s %s:%scall <SID>_call_for_mapping("%s")<CR>',
          \ mode,
          \ action.mapping,
          \ mode =~# '[i]' ? '<Esc>' : '',
          \ mode =~# '[ni]' ? '<C-u>' : '',
          \ a:name,
          \)
  endfor
  let self.actions[action.name] = action
  let self.aliases[action.alias] = action.name
endfunction

function! s:binder.call(name_or_alias, candidates) abort range
  let action = self.get_action(a:name_or_alias)
  if empty(action)
    return
  endif
  let candidates = copy(a:candidates)
  if !empty(action.requirements)
    let candidates = filter(
          \ candidates,
          \ 's:_is_satisfied(v:val, action.requirements)',
          \)
    if empty(candidates)
      return
    endif
  endif
  call call(action.callback, [candidates, action.options], self)
endfunction

function! s:binder.smart_map(mode, lhs, rhs, ...) abort
  let lhs = get(a:000, 0, a:lhs)
  for mode in split(a:mode, '\zs')
    execute printf(
          \ '%smap <buffer><expr> %s <SID>_smart_map(''%s'', ''%s'')',
          \ mode, a:lhs, lhs, a:rhs,
          \)
  endfor
endfunction

function! s:binder.include(names, ...) abort
  let include_path = get(a:000, 0, self.include_path)
  for name in a:names
    let domain = matchstr(name, '^[^:]\+')
    let fname = join([include_path, domain, 'define'], '#')
    try
      call call(fname, [self])
    catch /^Vim\%((\a\+)\)\=:E117/
      call s:_throw(printf(
            \ 'An action "%s" does not exist at "%s".',
            \ name, fname,
            \))
    endtry
  endfor
endfunction


" Actions --------------------------------------------------------------------
function! s:_action_help(candidates, options) abort dict
  let mappings = s:_find_mappings(self)
  let actions = values(self.actions)
  if !get(a:options, 'all')
    call filter(actions, '!v:val.hidden')
  endif
  let rows = []
  let longest1 = 0
  let longest2 = 0
  let longest3 = 0
  for action in actions
    let lhs = ''
    let mapping = get(mappings, action.mapping, {})
    if !empty(action.mapping) && !empty(mapping)
      let lhs = mapping.lhs
    endif
    call add(rows, [
          \ action.name,
          \ lhs,
          \ action.alias,
          \ (action.hidden ? '(-) ' : '') . action.description,
          \])
    let longest1 = len(lhs) > longest1 ? len(lhs) : longest1
    let longest2 = len(action.alias) > longest2 ? len(action.alias) : longest2
  endfor

  let content = []
  let pattern = printf('%%-%ds %%-%ds : %%s', longest1, longest2)
  for [name, lhs, alias, description] in sort(rows, 's:_compare')
    call add(content, printf(pattern, lhs, alias, description))
  endfor
  echo join(content, "\n")
endfunction

function! s:_action_choice(candidates, options) abort dict
  let s:_binder = self
  call inputsave()
  try
    echohl Question
    redraw | echo
    let fname = s:_get_function_name(function('s:_complete_action_aliases'))
    let aname = input(
          \ 'action: ', '',
          \ printf('customlist,%s', fname),
          \)
    redraw | echo
  finally
    echohl None
    call inputrestore()
  endtry
  if empty(aname)
    return
  endif
  call self.call(aname, a:candidates)
endfunction

function! s:_action_echo(candidates, options) abort
  for candidate in a:candidates
    echo string(candidate)
  endfor
endfunction


" Privates -------------------------------------------------------------------
function! s:_throw(...) abort
  throw printf(
        \ 'vital: Action: %s',
        \ join(map(a:000, 'type(v:val) == 1 ? v:val : string(v:val)'))
        \)
endfunction

function! s:_is_satisfied(candidate, requirements) abort
  for requirement in a:requirements
    if !has_key(a:candidate, requirement)
      return 0
    endif
  endfor
  return 1
endfunction

function! s:_compare(i1, i2) abort
  return a:i1[0] == a:i2[0] ? 0 : a:i1[0] > a:i2[0] ? 1 : -1
endfunction

function! s:_compare_action_priority(i1, i2) abort
  if a:i1.priority == a:i2.priority
    return len(a:i1.name) - len(a:i2.name)
  else
    return a:i1.priority > a:i2.priority ? 1 : -1
  endif
endfunction

function! s:_find_mappings(binder) abort
  try
    redir => content
    silent execute 'map'
  finally
    redir END
  endtry
  let rhss = filter(
        \ map(values(a:binder.actions), 'v:val.mapping'),
        \ '!empty(v:val)'
        \)
  let rhsp = printf('\%%(%s\)', join(map(rhss, 'escape(v:val, ''\'')'), '\|'))
  let rows = filter(split(content, '\r\?\n'), 'v:val =~# ''@.*'' . rhsp')
  let pattern = '\(...\)\(\S\+\)'
  let mappings = {}
  for row in rows
    let [mode, lhs] = matchlist(row, pattern)[1 : 2]
    let rhs = matchstr(row, rhsp)
    let mappings[rhs] = {
          \ 'mode': mode,
          \ 'lhs': lhs,
          \ 'rhs': rhs,
          \}
  endfor
  return mappings
endfunction

function! s:_complete_action_aliases(arglead, cmdline, cursorpos) abort
  let actions = values(s:_binder.actions)
  if empty(a:arglead)
    call filter(actions, '!v:val.hidden')
  endif
  call sort(actions, 's:_compare_action_priority')
  return filter(map(actions, 'v:val.alias'), 'v:val =~# ''^'' . a:arglead')
endfunction

function! s:_smart_map(lhs, rhs) abort range
  let binder = s:get()
  try
    let candidates = binder.get_candidates(a:firstline, a:lastline)
    return empty(candidates) ? a:lhs : a:rhs
  catch
    return a:lhs
  endtry
endfunction

function! s:_call_for_mapping(name_or_alias) abort range
  let binder = s:get()
  let candidates = binder.get_candidates(a:firstline, a:lastline)
  return call(binder.call, [a:name_or_alias, candidates], binder)
endfunction

function! s:_default_get_candidates(...) abort
  call s:_throw(
        \ '"get_candidates" is not implemented.',
        \ 'Developer requires to implement',
        \)
endfunction


if has('patch-7.4.1842')
  function! s:_get_function_name(fn) abort
    return get(a:fn, 'name')
  endfunction
else
  function! s:_get_function_name(fn) abort
    return matchstr(string(a:fn), 'function(''\zs.*\ze''')
  endfunction
endif
