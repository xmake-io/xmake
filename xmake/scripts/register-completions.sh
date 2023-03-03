string_contains() {
    case "${1}" in
        *${2}*) return 0;;
        *) return 1;;
    esac
    return 1
}

if string_contains "$SHELL" "zsh"; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.zsh"
elif string_contains "$SHELL" "bash"; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.bash"
elif string_contains "$SHELL" "fish"; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.fish"
fi

