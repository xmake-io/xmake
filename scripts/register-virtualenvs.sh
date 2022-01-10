
# virtual environments for *nix shell

if test "${XMAKE_ROOTDIR}"; then
    export XMAKE_EXE=${XMAKE_ROOTDIR}/xmake
else
    export XMAKE_EXE=xmake
fi

function xrepo {
    if [ $# -ge 2 ] && [ "$1" = "env" ]; then
        local cmd="${2-x}"
        case "$cmd" in
            shell)
                if test "${XMAKE_PROMPT_BACKUP}"; then
                    PS1="${XMAKE_PROMPT_BACKUP}"
                    source "${XMAKE_ENV_BACKUP}" || return 1
                    unset XMAKE_PROMPT_BACKUP
                    unset XMAKE_ENV_BACKUP
                fi
                "$XMAKE_EXE" lua private.xrepo.action.env.info config || return 1
                local prompt="$("$XMAKE_EXE" lua --quiet private.xrepo.action.env.info prompt)" || return 1
                if [ -z "${prompt+x}" ]; then
                    return 1
                fi
                local activateCommand="$("$XMAKE_EXE" lua private.xrepo.action.env.info script.bash)" || return 1
                export XMAKE_ENV_BACKUP="$("$XMAKE_EXE" lua private.xrepo.action.env.info envfile)"
                export XMAKE_PROMPT_BACKUP="${PS1}"
                "$XMAKE_EXE" lua private.xrepo.action.env.info backup.bash 1>"$XMAKE_ENV_BACKUP"
                eval "$activateCommand"
                PS1="${prompt} $PS1"
                ;;
            quit)
                if test "${XMAKE_PROMPT_BACKUP}"; then
                    PS1="${XMAKE_PROMPT_BACKUP}"
                    source "${XMAKE_ENV_BACKUP}" || return 1
                    unset XMAKE_PROMPT_BACKUP
                    unset XMAKE_ENV_BACKUP
                fi
                ;;
            -b|--bind)
                if [ "$4" = "shell" ]; then
                    local bnd="${3-x}"
                    if test "${XMAKE_PROMPT_BACKUP}"; then
                        PS1="${XMAKE_PROMPT_BACKUP}"
                        source "${XMAKE_ENV_BACKUP}" || return 1
                        unset XMAKE_PROMPT_BACKUP
                        unset XMAKE_ENV_BACKUP
                    fi
                    "$XMAKE_EXE" lua private.xrepo.action.env.info config $bnd || return 1
                    local prompt="$("$XMAKE_EXE" lua --quiet private.xrepo.action.env.info prompt $bnd)" || return 1
                    if [ -z "${prompt+x}" ]; then
                        return 1
                    fi
                    local activateCommand="$("$XMAKE_EXE" lua --quiet private.xrepo.action.env.info script.bash $bnd)" || return 1
                    export XMAKE_ENV_BACKUP="$("$XMAKE_EXE" lua private.xrepo.action.env.info envfile $bnd)"
                    export XMAKE_PROMPT_BACKUP="${PS1}"
                    "$XMAKE_EXE" lua --quiet private.xrepo.action.env.info backup.bash $bnd 1>"$XMAKE_ENV_BACKUP"
                    eval "$activateCommand"
                    PS1="${prompt} $PS1"
                else
                    "$XMAKE_EXE" lua private.xrepo "$@"
                fi
                ;;
            *)
                "$XMAKE_EXE" lua private.xrepo "$@"
                ;;
        esac
    else
        "$XMAKE_EXE" lua private.xrepo "$@"
    fi
}
