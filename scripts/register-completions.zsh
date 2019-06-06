# zsh parameter completion for xmake

_xmake_zsh_complete() 
{
  local completions=("$(xmake lua private.utils.complete 0 "$words")")

  reply=( "${(ps:\n:)completions}" )
}

compctl -K _xmake_zsh_complete xmake
