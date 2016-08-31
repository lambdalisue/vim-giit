function! giit#action#index#define(binder) abort
  call a:binder.define('index:add', function('s:on_add'), {
        \ 'hidden': 1,
        \ 'description': 'Add a change to the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('index:add:force', function('s:on_add'), {
        \ 'hidden': 1,
        \ 'description': 'Add a change to the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('index:rm', function('s:on_rm'), {
        \ 'hidden': 1,
        \ 'description': 'Remove files from the working tree and from the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('index:rm:cached', function('s:on_rm'), {
        \ 'hidden': 1,
        \ 'description': 'Remove files from the index but the working tree',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'cached': 1 },
        \})
  call a:binder.define('index:rm:cached', function('s:on_rm'), {
        \ 'hidden': 1,
        \ 'description': 'Remove files from the working tree and from the index (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('index:reset', function('s:on_reset'), {
        \ 'hidden': 1,
        \ 'description': 'Reset changes on the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('index:stage', function('s:on_stage'), {
        \ 'alias': 'stage',
        \ 'description': 'Stage changes to the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('index:stage:force', function('s:on_stage'), {
        \ 'hidden': 1,
        \ 'alias': 'stage:force',
        \ 'description': 'Stage changes to the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('index:unstage', function('s:on_unstage'), {
        \ 'alias': 'unstage',
        \ 'description': 'Unstage changes from the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
  call a:binder.define('index:toggle', function('s:on_toggle'), {
        \ 'alias': 'toggle',
        \ 'description': 'Toggle stage/unstage of changes in the index',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'sign'],
        \ 'options': {},
        \})
endfunction

function! s:on_add(candidates, options) abort
  let git = giit#core#get_or_fail()
  let options = extend({
        \ 'force': 0,
        \}, a:options)
  let args = [
        \ 'add',
        \ '--ignore-errors',
        \ options.force ? '--force' : '',
        \ '--',
        \]
  let args += map(
        \ copy(a:candidates),
        \ 'giit#util#normalize#abspath(git, v:val.path)',
        \)
  let args = filter(args, '!empty(v:val)')
  let result = git.execute(args)
  if result.status
    call giit#operation#inform(result)
  endif
  call giit#trigger_modified()
endfunction

function! s:on_rm(candidates, options) abort
  let git = giit#core#get_or_fail()
  let options = extend({
        \ 'cached': 0,
        \ 'force': 0,
        \}, a:options)
  let args = [
        \ 'rm',
        \ '--ignore-unmatch',
        \ options.cached ? '--cached' : '',
        \ options.force ? '--force' : '',
        \ '--',
        \]
  let args += map(
        \ copy(a:candidates),
        \ 'giit#util#normalize#abspath(git, v:val.path)',
        \)
  let args = filter(args, '!empty(v:val)')
  let result = git.execute(args)
  if result.status
    call giit#operation#inform(result)
  endif
  call giit#trigger_modified()
endfunction

function! s:on_reset(candidates, options) abort
  let git = giit#core#get_or_fail()
  let options = extend({}, a:options)
  let args = [
        \ 'reset',
        \ '--',
        \]
  let args += map(
        \ copy(a:candidates),
        \ 'giit#util#normalize#relpath(git, v:val.path)',
        \)
  let args = filter(args, '!empty(v:val)')
  let result = git.execute(args)
  if result.status
    call giit#operation#inform(result)
  endif
  call giit#trigger_modified()
endfunction

function! s:on_stage(candidates, options) abort dict
  let rm_candidates = []
  let add_candidates = []
  for candidate in a:candidates
    if candidate.sign =~# '^.D$'
      call add(rm_candidates, candidate)
    else
      call add(add_candidates, candidate)
    endif
  endfor
  if get(a:options, 'force')
    noautocmd call self.call('index:add:force', add_candidates)
    noautocmd call self.call('index:rm:force', rm_candidates)
  else
    noautocmd call self.call('index:add', add_candidates)
    noautocmd call self.call('index:rm', rm_candidates)
  endif
  call giit#trigger_modified()
endfunction

function! s:on_unstage(candidates, options) abort dict
  call self.call('index:reset', a:candidates)
endfunction

function! s:on_toggle(candidates, options) abort dict
  let stage_candidates = []
  let unstage_candidates = []
  for candidate in a:candidates
    if candidate.sign =~# '^\%(??\|!!\|.\w\)$'
      call add(stage_candidates, candidate)
    elseif candidate.sign =~# '^\w.$'
      call add(unstage_candidates, candidate)
    endif
  endfor
  noautocmd call self.call('index:stage', stage_candidates)
  noautocmd call self.call('index:unstage', unstage_candidates)
  call giit#trigger_modified()
endfunction
