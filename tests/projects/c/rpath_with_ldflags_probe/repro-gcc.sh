#!/usr/bin/env bash
set -euo pipefail

real_gcc="${REAL_GCC:-gcc}"
compile_only=0
allow_link=0

for arg in "$@"; do
    case "$arg" in
        -c|-S|-E)
            compile_only=1
            ;;
        -shared|-Wl,--hash-style=gnu)
            allow_link=1
            ;;
    esac
done

if [[ "$compile_only" -eq 1 || "$allow_link" -eq 1 ]]; then
    exec "$real_gcc" "$@"
fi

echo "repro-gcc: synthetic link failure for bare flag probes" >&2
exit 1