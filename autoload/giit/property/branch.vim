let s:GitCache = vital#giit#import('Git.Cache')
let s:GitProperty = vital#giit#import('Git.Property')


" Public ---------------------------------------------------------------------
function! giit#property#branch#local(git) abort
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['HEAD', 'refs/heads']
  let content = s:GitCache.get_cached_content(a:git, slug, deps, {})
  if !empty(content)
    return content
  endif
  let content = s:GitProperty.get_local_branch(a:git)
  call s:GitCache.set_cached_content(a:git, slug, deps, content)
  return content
endfunction

function! giit#property#branch#remote(git) abort
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['HEAD', 'config', 'refs/remotes']
  let content = s:GitCache.get_cached_content(a:git, slug, deps, {})
  if !empty(content)
    return content
  endif
  let content = s:GitProperty.get_remote_branch(a:git)
  call s:GitCache.set_cached_content(a:git, slug, deps, content)
  return content
endfunction
