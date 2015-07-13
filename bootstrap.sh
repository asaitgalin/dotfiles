#!/usr/bin/env bash

set -e

cd "$(dirname "$0")"
REPO_ROOT=$(pwd)

error() {
    printf "\e[0;31mERROR:\e[0m %s\n" "$1"
    exit 1
}

info() {
    printf "\e[0;32mINFO:\e[0m %s\n" "$1"
}

warning() {
    printf "\e[0;33mWARNING:\e[0m %s\n" "$1"
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
    info "Starting zsh bootstrap"
    make_backup "$HOME/.zshrc"
    rm -rf "$HOME/.zshrc"
    make_backup "$HOME/.zsh"
    rm -rf "$HOME/.zsh"

    for file in $(find "$REPO_ROOT/zsh" -maxdepth 1 -name "*.link"); do
        make_link "$file" "$HOME/.$(basename "${file%.*}")"
    done

    info "Bootstrap zsh finished"
}

info "Checking out and updating submodules"
git submodule update --init

bootstrap_zsh
info "Bootstrap script finished"
