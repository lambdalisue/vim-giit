if exists('b:current_syntax')
  finish
endif

syntax match GiitStaged /^[ MADRC] .*$/
syntax match GiitUnstaged /^ [MDAU?] .*$/
syntax match GiitPatched /^[MADRC][MDAU?] .*$/
syntax match GiitIgnored /^!! .*$/
syntax match GiitUntracked /^?? .*$/
syntax match GiitConflicted /^\%(DD\|AU\|UD\|UA\|DU\|AA\|UU\) .*$/

highlight default link GiitConflicted Error
highlight default link GiitStaged     Special
highlight default link GiitUnstaged   Comment
highlight default link GiitPatched    Constant
highlight default link GiitUntracked  GiitUnstaged
highlight default link GiitIgnored    Identifier

let b:current_syntax = 'giit-status'
