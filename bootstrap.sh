#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
REPO_ROOT=$(pwd)

error() {
    printf "\e[0;31m[ERROR]\e[0m %s\n" "$1"
    exit 1
}

info() {
    printf "\e[0;32m[INFO]\e[0m %s\n" "$1"
}

warning() {
    printf "\e[0;33m[WARNING]\e[0m %s\n" "$1"
}

input() {
    printf "\e[0;34m[INPUT]\e[0m "
    read -p "$1 " -e $2
}

info "Bootstrap script started (user: $(whoami)) "

MAKE_BACKUP=1

while [[ $# > 0 ]]; do
    key=$1
    case $key in
        --no-backup)
            MAKE_BACKUP=0
            ;;
        *)
            error "Unknown command line option $key"
            ;;
    esac

    shift
done

make_backup() {
    if [[ $MAKE_BACKUP -eq 0 || -h "$1" ]]; then
        return
    fi
    if [[ -f "$1" || -d "$1" ]]; then
        info "Backup $1 -> $1.backup"
        cp -r "$1" "$1.backup" && rm -rf "$1"
    fi
}

make_link() {
    info "Making symbolic link $2 -> $1"
    ln -s "$1" "$2"
}

bootstrap_zsh() {
    info "Bootstrapping zsh"
    make_backup "$HOME/.zshrc"
    rm -rf "$HOME/.zshrc"
    make_backup "$HOME/.zsh"
    rm -rf "$HOME/.zsh"

    for file in $(find "$REPO_ROOT/zsh" -maxdepth 1 -name "*.link"); do
        make_link "$file" "$HOME/.$(basename "${file%.*}")"
    done
}

bootstrap_ls_colors() {
    info "Bootstrapping ls colors"
    make_backup "$HOME/.dir_colors"
    rm -rf "$HOME/.dir_colors"
    make_link "$REPO_ROOT/dir_colors.link" "$HOME/.dir_colors"
}

bootstrap_tmux() {
    info "Bootstrapping tmux"
    make_backup "$HOME/.tmux.conf"
    rm -rf "$HOME/.tmux.conf"
    make_link "$REPO_ROOT/tmux.link" "$HOME/.tmux.conf"
}

bootstrap_git() {
    info "Bootstrapping git"
    make_backup "$HOME/.gitconfig"
    rm -rf "$HOME/.gitconfig"
    make_backup "$HOME/.githooks"
    rm -rf "$HOME/.githooks"

    input "Enter your git name:" git_name
    input "Enter your git email:" git_email

    sed -e "s/USERNAME/$git_name/g" \
        -e "s/USERMAIL/$git_email/g" \
        $REPO_ROOT/git/gitconfig.link.sample > $REPO_ROOT/git/gitconfig.link

    for file in $(find "$REPO_ROOT/git" -maxdepth 1 -name "*.link"); do
        make_link "$file" "$HOME/.$(basename "${file%.*}")"
    done
}

bootstrap_vim() {
   info "Bootstrapping vim"
   make_backup "$HOME/.vimrc"
   rm -rf "$HOME/.vimrc"
   make_backup "$HOME/.vim"
   rm -rf "$HOME/.vim"

   mkdir -p "$HOME/.vim/bundle"

   make_link "$REPO_ROOT/vim/vimrc.link" "$HOME/.vimrc"
   make_link "$REPO_ROOT/vim/vim.link/bundle/Vundle.vim" "$HOME/.vim/bundle/Vundle.vim"

   info "NOTE: Do not forget to run :PluginInstall in Vim to install all plugins with Vundle."
   info "NOTE: After plugins installation call \"$HOME/.vim/bundle/YouCompleteMe/install.py --clang-completer\""
   info "  to build all necessary stuff for YouCompleteMe."
}

info "Checking out and updating submodules"
git submodule update --init --recursive

bootstrap_zsh
bootstrap_ls_colors
bootstrap_tmux
bootstrap_git
bootstrap_vim
