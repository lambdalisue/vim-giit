#!/bin/bash
set -ex
export PATH="$HOME/.local/bin:$HOME/neovim/bin:$HOME/vim/bin:/tmp/vim-themis/bin:$PATH"
export THEMIS_HOME="/tmp/vim-themis"
if [[ "$VERSION" == "nvim" ]]; then
    alias vim='nvim'
    export THEMIS_ARGS="-e -s --headless"
fi

uname -a
which -a vim
which -a vint
which -a themis

vim --version
vim --cmd "try | helptags doc/ | catch | cquit | endtry" --cmd quit

vint --version
vint autoload

themis --version
themis --reporter dot --runtimepath /tmp/vital
