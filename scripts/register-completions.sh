
# parameter completions for *nix shell

if   [[ "$SHELL" = */zsh ]]; then
  # zsh parameter completion for xmake
  _xmake_zsh_complete() 
  {
    local completions=("$(XMAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.utils.complete 0 nospace "$words")")
    reply=( "${(ps:\n:)completions}" )
  }
  compctl -f -S "" -K _xmake_zsh_complete xmake

  # zsh parameter completion for xrepo
  _xrepo_zsh_complete() 
  {
    local completions=("$(XMAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.xrepo.complete 0 nospace "$words")")
    reply=( "${(ps:\n:)completions}" )
  }
  compctl -f -S "" -K _xrepo_zsh_complete xrepo

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

  # bash parameter completion for xrepo
  _xrepo_bash_complete()
  {
    local word=${COMP_WORDS[COMP_CWORD]}
    local completions
    completions="$(XMAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.xrepo.complete "${COMP_POINT}" "nospace-nokey" "${COMP_LINE}")"
    if [ $? -ne 0 ]; then
      completions=""
    fi
    COMPREPLY=( $(compgen -W "$completions") )
  }
  complete -o default -o nospace -F _xrepo_bash_complete xrepo
fi

