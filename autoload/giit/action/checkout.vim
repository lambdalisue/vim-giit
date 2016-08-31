function! giit#action#checkout#define(binder) abort
  call a:binder.define('checkout', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': {},
        \})
  call a:binder.define('checkout:force', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'force': 1 },
        \})
  call a:binder.define('checkout:ours', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'ours': 1 },
        \})
  call a:binder.define('checkout:theirs', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'is_conflicted'],
        \ 'options': { 'theirs': 1 },
        \})
  call a:binder.define('checkout:HEAD', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents from HEAD',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path', 'is_conflicted'],
        \ 'options': { 'commit': 'HEAD' },
        \})
  call a:binder.define('checkout:HEAD:force', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents from HEAD (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'commit': 'HEAD', 'force': 1 },
        \})
  call a:binder.define('checkout:origin/HEAD', function('s:on_checkout'), {
        \ 'description': 'Checkout a contents from origin/HEAD',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'commit': 'origin/HEAD' },
        \})
  call a:binder.define('checkout:origin/HEAD:force', function('s:on_checkout'), {
        \ 'hidden': 1,
        \ 'description': 'Checkout a contents from origin/HEAD (force)',
        \ 'mapping_mode': 'nv',
        \ 'requirements': ['path'],
        \ 'options': { 'commit': 'origin/HEAD', 'force': 1 },
        \})
endfunction

function! s:on_checkout(candidates, options) abort
  let git = giit#core#get_or_fail()
  let options = extend({
        \ 'force': 0,
        \ 'ours': 0,
        \ 'theirs': 0,
        \ 'commit': '',
        \}, a:options)
  let args = [
        \ 'checkout',
        \ options.force ? '--force' : '',
        \ options.ours ? '--ours' : '',
        \ options.theirs ? '--theirs' : '',
        \ giit#util#normalize#commit(git, options.commit),
        \ '--',
        \]
  let args += map(
        \ copy(a:candidates),
        \ 'giit#util#normalize#relpath(git, v:val.path)',
        \)
  let args = filter(args, '!empty(v:val)')
  let result = git.execute(args)
  if result.status
    call giit#operation#inform(result, options)
  endif
  call giit#trigger_modified()
endfunction
