let s:GitCache = vital#giit#import('Git.Cache')
let s:GitProperty = vital#giit#import('Git.Property')


" Public ---------------------------------------------------------------------
function! giit#property#commit#ahead(git) abort
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['HEAD', 'config', 'index']
  let content = s:GitCache.get_cached_content(a:git, slug, deps, v:null)
  if content isnot# v:null
    return content
  endif
  unlet content
  let content = s:GitProperty.count_commits_ahead_of_remote(a:git)
  call s:GitCache.set_cached_content(a:git, slug, deps, content)
  return content
endfunction

function! giit#property#commit#behind(git) abort
  let slug = eval(s:GitCache.get_slug_expr())
  let deps = ['HEAD', 'config', 'index']
  let content = s:GitCache.get_cached_content(a:git, slug, deps, v:null)
  if content isnot# v:null
    return content
  endif
  unlet content
  let content = s:GitProperty.count_commits_behind_remote(a:git)
  call s:GitCache.set_cached_content(a:git, slug, deps, content)
  return content
endfunction
