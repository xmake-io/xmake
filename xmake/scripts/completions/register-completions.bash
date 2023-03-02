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
