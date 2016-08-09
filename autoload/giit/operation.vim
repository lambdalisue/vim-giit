let s:ArgumentParser = vital#giit#import('ArgumentParser')
let s:Dict = vital#giit#import('Data.Dict')
let s:Prompt = vital#giit#import('Vim.Prompt')
let s:DictOption = vital#giit#import('Data.Dict.Option')
let s:GitProcess = vital#giit#import('Git.Process')


function! giit#operation#command(bang, range, args) abort
  let parser  = s:get_parser()
  let options = parser.parse(a:bang, a:range, a:args)
  if !empty(options)
    let args  = join(options.__unknown__)
    let name  = get(options, 'command', '')
    let git = giit#core#get()
    try
      if a:bang ==# '!'
        call s:GitProcess.shell(git, map(
              \ s:DictOption.split_args(a:args),
              \ 'giit#core#expand(v:val)'
              \))
      else
        try
          let funcname = printf(
                \ 'giit#operation#%s#command',
                \ substitute(name, '-', '_', 'g'),
                \)
          call call(funcname, [a:bang, a:range, args])
        catch /^Vim\%((\a\+)\)\=:E117/
          " fail silently and execute git command
          call s:GitProcess.execute(git, map(
                \ s:DictOption.split_args(a:args),
                \ 'giit#core#expand(v:val)',
                \))
        endtry
      endif
    catch /^\%(vital: Git[:.]\|giit:\)/
      call giit#handle_exception()
    endtry
  endif
endfunction

function! giit#operation#complete(arglead, cmdline, cursorpos) abort
  let bang    = a:cmdline =~# '^[^ ]\+!' ? '!' : ''
  let cmdline = substitute(a:cmdline, '^[^ ]\+!\?\s', '', '')
  let cmdline = substitute(cmdline, '[^ ]\+$', '', '')

  let parser  = s:get_parser()
  let options = parser.parse(bang, [0, 0], cmdline)
  if !empty(options)
    let name = get(options, 'command', '')
    try
      if bang !=# '!'
        try
          let funcname = printf(
                \ 'giit#operation#%s#complete',
                \ substitute(name, '-', '_', 'g'),
                \)
          return call(funcname, [a:arglead, cmdline, a:cursorpos])
        catch /^Vim\%((\a\+)\)\=:E117/
          " fail silently
        endtry
      endif
      " complete filename
      return giit#util#complete#filename(a:arglead, cmdline, a:cursorpos)
    catch /^\%(vital: Git[:.]\|giit:\)/
      " fail silently
      call s:Prompt.debug(v:exception)
      call s:Prompt.debug(v:throwpoint)
      return []
    endtry
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
