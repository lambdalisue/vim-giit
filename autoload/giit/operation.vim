let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:Dict = vital#giit#import('Data.Dict')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:DictOption = vital#giit#import('Data.Dict.Option')
let s:GitProcess = vital#giit#import('Git.Process')
let s:Exception = vital#giit#import('Vim.Exception')


" Pubic ----------------------------------------------------------------------
function! giit#operation#command(...) abort
  return s:Exception.call(function('s:command'), a:000)
endfunction

function! giit#operation#complete(arglead, cmdline, cursorpos) abort
  return s:Exception.call(function('s:complete'), a:000)
endfunction

function! giit#operation#inform(result, options) abort
  if get(a:options, 'quiet')
    return
  endif
  let [hl, prefix] = a:result.status
        \ ? ['WarningMsg', 'Fail']
        \ : ['Title', 'OK']
  redraw | echo
  call s:Prompt.echo(hl, prefix . ': ' . join(a:result.args))
  for line in a:result.content
    call s:Prompt.echo('None', line)
  endfor
endfunction

function! giit#operation#throw(result, options) abort
  call giit#operation#inform(a:result, a:options)
  throw s:Exception.error('')
endfunction


" Private --------------------------------------------------------------------
function! s:command(bang, range, args) abort
  let parser  = s:get_parser()
  let options = parser.parse(a:bang, a:range, a:args)
  if empty(options)
    return
  endif

  let name = get(options, 'command', '')
  if !empty(name) && a:bang !=# '!'
    try
      let fname = printf(
            \ 'giit#operation#%s#command',
            \ substitute(name, '-', '_', 'g')
            \)
      return call(fname, [a:bang, a:range, join(options.__unknown__)])
    catch /^Vim\%((\a\+)\)\=:E117/
      " fail silently
    endtry
  endif

  let git = giit#core#get()
  let args = map(s:DictOption.split_args(a:args), 'giit#expand(v:val)')
  let result = s:GitProcess.shell(git, args, {
        \ 'stdout': 1,
        \})
  if a:args !~# '\%(^\|\s\)\%(-q\|--quiet\)\>'
    call giit#operation#inform(result, {})
  endif
  return result
endfunction

function! s:complete(arglead, cmdline, cursorpos) abort
  let bang    = a:cmdline =~# '^[^ ]\+!' ? '!' : ''
  let cmdline = substitute(a:cmdline, '^[^ ]\+!\?\s', '', '')
  let cmdline = substitute(cmdline, '[^ ]\+$', '', '')

  let parser  = s:get_parser()
  let options = parser.parse(bang, [0, 0], cmdline)
  if !empty(options)
    let name = get(options, 'command', '')
    if bang !=# '!'
      try
        let fname = printf(
              \ 'giit#operation#%s#complete',
              \ substitute(name, '-', '_', 'g'),
              \)
        return call(fname, [a:arglead, cmdline, a:cursorpos])
      catch /^Vim\%((\a\+)\)\=:E117/
        " fail silently
      endtry
    endif
    " complete filename
    return giit#util#complete#filename(a:arglead, cmdline, a:cursorpos)
  endif
  return parser.complete(a:arglead, a:cmdline, a:cursorpos)
endfunction

function! s:complete_command(arglead, cmdline, cursorpos, ...) abort
  let candidates = filter([
      \ 'add',
      \ 'apply',
      \ 'blame',
      \ 'branch',
      \ 'browse',
      \ 'cd',
      \ 'chaperone',
      \ 'checkout',
      \ 'commit',
      \ 'diff',
      \ 'diff-ls',
      \ 'grep',
      \ 'lcd',
      \ 'ls-files',
      \ 'ls-tree',
      \ 'merge',
      \ 'patch',
      \ 'rebase',
      \ 'reset',
      \ 'rm',
      \ 'show',
      \ 'status',
      \ 'init',
      \ 'pull',
      \ 'push',
      \ 'stash',
      \ 'remote',
      \ 'tag',
      \ 'log',
      \], 'v:val =~# ''^'' . a:arglead')
  return candidates
endfunction

function! s:get_parser() abort
  if !exists('s:parser')
    let s:parser = s:ArgumentParser.new({
          \ 'name': 'Giit[!]',
          \ 'description': [
          \   'A git manipulation command. It executes a specified giit''s command or a specified git command if command is not found.',
          \   'Additionally, if the command called with a bang (!), it execute a git command instead of gita''s command.',
          \ ],
          \})
    call s:parser.add_argument(
          \ 'command', [
          \   'A name of a gita command (followings). If a non giit command is specified, git command will be called directly.',
          \   '',
          \   'add       : Add file contents to the index',
          \   'blame     : Show what revision and author last modified each line of a file',
          \   'branch    : List, create, or delete branches',
          \   'browse    : Browse a URL of the remote content',
          \   'cd        : Change a current directory to the working tree top',
          \   'chaperone : Compare differences and help to solve conflictions',
          \   'checkout  : Switch branches or restore working tree files',
          \   'commit    : Record changes to the repository',
          \   'diff      : Show changes between commits, commit and working tree, etc',
          \   'diff-ls   : Show a list of changed files between commits',
          \   'grep      : Print lines matching patterns',
          \   'ls-files  : Show information about files in the index and the working tree',
          \   'lcd       : Change a current directory to the working tree top (lcd)',
          \   'ls-tree   : List the contents of a tree object',
          \   'merge     : Join two or more development histories together',
          \   'patch     : Partially add/reset changes to/from index',
          \   'rebase    : Forward-port local commits to the update upstream head',
          \   'reset     : Reset current HEAD to the specified state',
          \   'rm        : Remove files from the working tree and from the index',
          \   'show      : Show a content of a commit or a file',
          \   'status    : Show and manipulate s status of the repository',
          \   '',
          \   'Note that each sub-commands also have -h/--help option',
          \ ], {
          \   'required': 1,
          \   'terminal': 1,
          \   'complete': function('s:complete_command'),
          \})
  endif
  return s:parser
endfunction
