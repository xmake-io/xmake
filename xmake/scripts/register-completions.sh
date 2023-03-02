if   [[ "$SHELL" = */zsh ]]; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.zsh"
elif [[ "$SHELL" = */bash ]]; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.bash"
elif [[ "$SHELL" = */fish ]]; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.fish"
fi

