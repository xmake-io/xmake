# zsh parameter completion for xmake

_xmake_zsh_complete() 
{
  local completions=("$(xmake lua private.utils.complete 0 nospace "$words")")

  reply=( "${(ps:\n:)completions}" )
}

compctl -f -S "" -K _xmake_zsh_complete xmake
