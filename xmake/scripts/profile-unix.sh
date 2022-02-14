# parameter completions for *nix shell
if [[ "$SHELL" = */zsh ]]; then
  # zsh parameter completion for xmake
  _xmake_zsh_complete() 
  {
    local completions=("$(XMAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.utils.complete 0 nospace "$words")")
    reply=( "${(ps:\n:)completions}" )
  }
  compctl -f -S "" -K _xmake_zsh_complete xmake
elif [[ "$SHELL" = */bash ]]; then
  # bash parameter completion for xmake
  _xmake_bash_complete()
  {
    local word=${COMP_WORDS[COMP_CWORD]}
    local completions
    completions="$(XMAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.utils.complete "${COMP_POINT}" "nospace-nokey" "${COMP_LINE}")"
    if [ $? -ne 0 ]; then
      completions=""
    fi
    COMPREPLY=( $(compgen -W "$completions") )
  }
  complete -o default -o nospace -F _xmake_bash_complete xmake
fi
# virtual environments for *nix shell
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
                xmake lua private.xrepo.action.env.info config || return 1
                local prompt="$(xmake lua --quiet private.xrepo.action.env.info prompt)" || return 1
                if [ -z "${prompt+x}" ]; then
                    return 1
                fi
                local activateCommand="$(xmake lua private.xrepo.action.env.info script.bash)" || return 1
                export XMAKE_ENV_BACKUP="$(xmake lua private.xrepo.action.env.info envfile)"
                export XMAKE_PROMPT_BACKUP="${PS1}"
                xmake lua private.xrepo.action.env.info backup.bash 1>"$XMAKE_ENV_BACKUP"
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
                    xmake lua private.xrepo.action.env.info config $bnd || return 1
                    local prompt="$(xmake lua --quiet private.xrepo.action.env.info prompt $bnd)" || return 1
                    if [ -z "${prompt+x}" ]; then
                        return 1
                    fi
                    local activateCommand="$(xmake lua --quiet private.xrepo.action.env.info script.bash $bnd)" || return 1
                    export XMAKE_ENV_BACKUP="$(xmake lua private.xrepo.action.env.info envfile $bnd)"
                    export XMAKE_PROMPT_BACKUP="${PS1}"
                    xmake lua --quiet private.xrepo.action.env.info backup.bash $bnd 1>"$XMAKE_ENV_BACKUP"
                    eval "$activateCommand"
                    PS1="${prompt} $PS1"
                else
                    xmake lua private.xrepo "$@"
                fi
                ;;
            *)
                xmake lua private.xrepo "$@"
                ;;
        esac
    else
        xmake lua private.xrepo "$@"
    fi
}