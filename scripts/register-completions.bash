# bash parameter completion for xmake

_xmake_bash_complete()
{
  local word=${COMP_WORDS[COMP_CWORD]}

  local completions
  completions="$(XMAKE_SKIP_HISTORY=1 xmake lua private.utils.complete "${COMP_POINT}" "${COMP_LINE}" 2>/dev/null)"
  if [ $? -ne 0 ]; then
    completions=""
  fi

  COMPREPLY=( $(compgen -W "$completions" -- "$word") )
}

complete -o default -o nospace -F _xmake_bash_complete xmake
