let s:formatters = []


function! giit#util#url#formatter#format(url, rev, path, params) abort
  for formatter in s:formatters
    let baseurl = formatter.baseurl
    for pattern in formatter.patterns
      if a:url =~# pattern
        let baseurl = formatter.baseurl
        let baseurl = substitute(a:url, pattern, baseurl, 'g')
        return formatter.format(baseurl, a:rev, a:path, a:params)
      endif
    endfor
  endfor
  return ''
endfunction

function! giit#util#url#formatter#register(formatter) abort
  call add(s:formatters, a:formatter)
endfunction
