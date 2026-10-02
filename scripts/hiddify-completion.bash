# bash completion for hiddify
if ! command -v complete >/dev/null 2>&1; then
    return 0 2>/dev/null || exit 0
fi

_hiddify() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local cmds="install start stop upgrade status restart apply sync-configs admin reset-password"

    COMPREPLY=()
    if [[ $COMP_CWORD -eq 1 ]]; then
        COMPREPLY=($(compgen -W "$cmds" -- "$cur"))
        return 0
    fi

    case "${COMP_WORDS[1]}" in
    upgrade | update)
        COMPREPLY=($(compgen -W "release beta develop --no-gui --no-log" -- "$cur"))
        ;;
    install | start | stop | apply | sync-configs | restart | status | uninstall)
        COMPREPLY=($(compgen -W "--no-gui --no-log" -- "$cur"))
        ;;
    esac
}

complete -F _hiddify hiddify
