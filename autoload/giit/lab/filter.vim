function! s:bind(prototype, prompt) abort
  return extend(deepcopy(a:prototype), {
        \ 'prompt': a:prompt,
        \})
endfunction

" Cursor ---------------------------------------------------------------------
let s:cursor = { 'index': 0 }

function! s:cursor.lshift() abort
  let amount = get(a:000, 0, 1)
  let self.index -= amount
  let self.index = self.index <= 0 ? 0 : self.index
endfunction

function! s:cursor.rshift(...) abort
  let amount = get(a:000, 0, 1)
  let threshold = len(self.prompt.input)
  let self.index += amount
  let self.index = self.index >= threshold ? threshold : self.index
endfunction

function! s:cursor.ltext() abort
  return self.index == 0
        \ ? ''
        \ : self.prompt.input[:self.index-1]
endfunction

function! s:cursor.ctext() abort
  return self.prompt.input[self.index]
endfunction

function! s:cursor.rtext() abort
  return self.prompt.input[self.index+1:]
endfunction


" History --------------------------------------------------------------------
let s:history = { 'index': 0 }

function! s:history.previous() abort
  let threshold = histnr('input') * -1
  let self.index = self.index <= threshold ? threshold : self.index - 1
  let self.prompt.input = histget('input', self.index)
  let self.prompt.cursor.index = len(self.prompt.input)
endfunction

function! s:history.next() abort
  let self.index = self.index >= 0 ? 0 : self.index + 1
  let self.prompt.input = histget('input', self.index)
  let self.prompt.cursor.index = len(self.prompt.input)
endfunction


" Prompt ---------------------------------------------------------------------
let s:prompt = {
      \ 'prefix': '',
      \ 'input': '',
      \}

function! s:prompt.start() abort
  call inputsave()
  let char = ''
  let self.input = get(a:000, 0, '')
  let self.cursor = s:bind(s:cursor, self)
  let self.history = s:bind(s:history, self)
  while (char !=# "\<CR>" && !self.callback(self))
    redraw
    echohl Question | echon self.prefix
    echohl None     | echon self.cursor.ltext()
    echohl Cursor   | echon self.cursor.ctext()
    echohl None     | echon self.cursor.rtext()
    let key = getchar()
    let char = nr2char(key)
    if char ==# "\<Esc>"
      redraw | echo
      return 0
    elseif char ==# "\<C-H>" || key ==# "\<BS>"
      call self.remove()
    elseif char ==# "\<C-D>" || key ==# "\<DEL>"
      call self.delete()
    elseif char ==# "\<C-R>"
      let reg = getchar()
      call self.delete()
    elseif key ==# "\<Left>" || char ==# "\<C-F>"
      call self.cursor.lshift()
    elseif key ==# "\<Right>" || char ==# "\<C-B>"
      call self.cursor.rshift()
    elseif key ==# "\<Up>"
      call self.history.previous()
    elseif key ==# "\<Down>"
      call self.history.next()
    elseif !self.keydown(key, char)
      call self.insert(char)
    endif
  endwhile
  call inputrestore()
  return self.input
endfunction

function! s:prompt.insert(text) abort
  let lhs = self.cursor.ltext()
  let rhs = self.cursor.ctext() . self.cursor.rtext()
  let self.input = lhs . a:text . rhs
  call self.cursor.rshift(len(a:text))
endfunction

function! s:prompt.remove() abort
  let lhs = self.cursor.ltext()
  if empty(lhs)
    return
  endif
  let lhs = lhs[:-2]
  let rhs = self.cursor.ctext() . self.cursor.rtext()
  let self.input = lhs . rhs
  call self.cursor.lshift()
endfunction

function! s:prompt.delete() abort
  let lhs = self.cursor.ltext()
  let rhs = self.cursor.rtext()
  let self.input = lhs . rhs
endfunction

function! s:prompt.keydown(key, char) abort
  return 0
endfunction

function! s:prompt.callback(prompt) abort
  return 0
endfunction


function! s:start() abort
  let prompt = deepcopy(s:prompt)
  return prompt.start()
endfunction

echo s:start()
