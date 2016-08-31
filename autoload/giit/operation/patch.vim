let s:String = vital#giit#import('Data.String')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:is_windows = has('win32') || has('win64')


function! giit#operation#patch#correct(git, options) abort
  if get(a:options, '__corrected__')
    return a:options
  endif

  let filename = get(a:options, 'filename', '')
  let filename = empty(filename)
        \ ? giit#expand('%')
        \ : filename
  let filename = giit#normalize#relpath(a:git, filename)
  let content = get(a:options, 'content', '')
  let content = empty(content)
        \ ? getline(1, '$')
        \ : content

  let diff_content = get(a:options, 'diff_content', '')

  let a:options.filename = filename
  let a:options.content = content
  let a:options.diff_content = diff_content
  let a:options.__corrected__ = 1
  return a:options
endfunction

function! giit#operation#patch#execute(git, options) abort
  let tempfile = tempname()
  try
    let options = giit#operation#patch#correct(a:git, a:options)
    let diff_content = options.diff_content
    if empty(diff_content)
      let diff_content = s:get_diff_content(
            \ a:git,
            \ options.filename,
            \ options.content,
            \)
    endif
    call writefile(diff_content, tempfile)
    return a:git.execute([
          \ 'apply',
          \ '--verbose',
          \ '--cached',
          \ '--whitespace=fix',
          \ '--allow-overlap',
          \ '--recount',
          \ '--',
          \ tempfile
          \])
  finally
    call delete(tempfile)
  endtry
endfunction


function! s:replace_filenames_in_diff(content, filename1, filename2, repl, ...) abort
  let is_windows = get(a:000, 0, s:is_windows)
  " replace tempfile1/tempfile2 in the header to a:filename
  "
  "   diff --git a/<tempfile1> b/<tempfile2>
  "   index XXXXXXX..XXXXXXX XXXXXX
  "   --- a/<tempfile1>
  "   +++ b/<tempfile2>
  "
  let src1 = s:String.escape_pattern(a:filename1)
  let src2 = s:String.escape_pattern(a:filename2)
  if is_windows
    " NOTE:
    " '\' in {content} from 'git diff' are escaped so double escape is required
    " to substitute such path
    " NOTE:
    " escape(src1, '\') cannot be used while other characters such as '.' are
    " already escaped as well
    let src1 = substitute(src1, '\\\\', '\\\\\\\\', 'g')
    let src2 = substitute(src2, '\\\\', '\\\\\\\\', 'g')
  endif
  let repl = (a:filename1 =~# '^/' ? '/' : '') . a:repl
  let content = copy(a:content)
  let content[0] = substitute(content[0], src1, repl, '')
  let content[0] = substitute(content[0], src2, repl, '')
  let content[2] = substitute(content[2], src1, repl, '')
  let content[3] = substitute(content[3], src2, repl, '')
  return content
endfunction

function! s:get_diff_content(git, content, filename) abort
  let tempfile = tempname()
  let tempfile1 = tempfile . '.index'
  let tempfile2 = tempfile . '.buffer'
  try
    " save contents to temporary files
    let result = a:git.execute(['show', ':' . a:filename])
    " NOTE:
    " the file may not exist on cache so use an empty list in that case
    let content = result.success ? result.content : []
    call writefile(content, tempfile1)
    call writefile(a:content, tempfile2)
    " create a diff content between index_content and content
    " NOTE:
    " --no-index force --exit-code option.
    " --exit-code mean that the program exits with 1 if there were differences
    " and 0 means no differences
    let result = a:git.execute([
          \ 'diff',
          \ '--no-index',
          \ '--unified=1',
          \ '--',
          \ tempfile1,
          \ tempfile2
          \])
    let content = result.content
    if len(content) < 4
      " fail or no differences. Assume that there are no differences
      call s:Prompt.debug(content)
      call giit#throw('Attention: No differences are detected')
    endif
    return s:replace_filenames_in_diff(
          \ content,
          \ tempfile1,
          \ tempfile2,
          \ a:filename,
          \)
  finally
    call delete(tempfile1)
    call delete(tempfile2)
  endtry
endfunction
