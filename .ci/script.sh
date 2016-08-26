#!/bin/bash
set -ex
export PATH="$HOME/.local/bin:$HOME/neovim/bin:$HOME/vim/bin:/tmp/vim-themis/bin:$PATH"
export THEMIS_HOME="/tmp/vim-themis"

if [[ "$VERSION" == "nvim" ]]; then
    export THEMIS_VIM="nvim"
    export THEMIS_ARGS="-e -s --headless"
else
    export THEMIS_VIM="vim"
fi

uname -a
which -a $THEMIS_VIM
which -a python
which -a vint
which -a themis

$THEMIS_VIM --version
$THEMIS_VIM --cmd "try | helptags doc/ | catch | cquit | endtry" --cmd quit

python --version
vint --version
vint autoload

themis --version
themis --reporter dot --runtimepath /tmp/vital
