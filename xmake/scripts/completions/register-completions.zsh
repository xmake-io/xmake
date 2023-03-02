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

