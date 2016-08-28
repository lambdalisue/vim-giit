scriptencoding utf-8
let s:root = expand('<sfile>:p:h:h:h')
let s:file = simplify(s:root . '/autoload/vital/__giit__/Data/String/Aligner.vim')

function! s:timeit(name, fn, args) abort
  let outer = 5
  let inner = 10
  let timespans = []
  for n in range(1, outer)
    let start = reltime()
    for i in range(1, inner)
      call call(a:fn, deepcopy(a:args))
    endfor
    call add(timespans, str2float(reltimestr(reltime(start))))
  endfor
  let mean = eval(join(timespans, '+')) / len(timespans)
  echomsg printf('%s: %f s', a:name, mean)
endfunction

function! s:main() abort
  let Local = vital#vital#import('Vim.ScriptLocal')
  let funcs = Local.sfuncs(s:file)
  let matrix = [
        \ ['テスト', 'マテリアル', '色'],
        \ ['9', 'leather', 'brown'],
        \ ['10', 'hemp canvas', 'natural'],
        \ ['11', 'glass', 'transparent'],
        \ ['９', '皮', '茶色'],
        \ ['１０', '麻のキャンバス', '自然'],
        \ ['１１', 'コップ', '透明'],
        \]
  let matrix = eval(join(map(range(100), 'matrix'), '+'))
  call s:timeit('vim', function(funcs._align_vim, [], funcs), [matrix])
  if has_key(funcs, '_align_lua')
    call s:timeit('lua', function(funcs._align_lua, [], funcs), [matrix])
  endif
  if has_key(funcs, '_align_python')
    call s:timeit('py2', function(funcs._align_python, [], funcs), [matrix])
  endif
  if has_key(funcs, '_align_python3')
    call s:timeit('py3', function(funcs._align_python3, [], funcs), [matrix])
  endif
endfunction

call s:main()

" with 'luautf8'
"vim: 0.763517 s
"lua: 0.085620 s
"py2: 0.398021 s
"*** time: 6.308894 ***

" without 'luautf8'
" vim: 0.870638 s
" lua: 0.307280 s
" py2: 0.480853 s
" *** time: 8.885382 ***
