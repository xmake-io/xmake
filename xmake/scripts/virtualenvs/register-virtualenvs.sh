# A cross-platform build utility based on Lua
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http:##www.apache.org#licenses#LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Copyright (C) 2022-present, TBOOX Open Source Group.
#
# @author      ruki, xq114
# @homepage    register-virtualenvs.sh
#

if test "${XMAKE_ROOTDIR}"; then
    export XMAKE_EXE=${XMAKE_ROOTDIR}/xmake
else
    export XMAKE_EXE=xmake
fi

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
                "$XMAKE_EXE" lua private.xrepo.action.env.info config || return 1
                local prompt="$("$XMAKE_EXE" lua --quiet private.xrepo.action.env.info prompt)" || return 1
                if [ -z "${prompt+x}" ]; then
                    return 1
                fi
                local activateCommand="$("$XMAKE_EXE" lua private.xrepo.action.env.info script.bash)" || return 1
                export XMAKE_ENV_BACKUP="$("$XMAKE_EXE" lua private.xrepo.action.env.info envfile)"
                export XMAKE_PROMPT_BACKUP="${PS1}"
                "$XMAKE_EXE" lua private.xrepo.action.env.info backup.bash 1>"$XMAKE_ENV_BACKUP"
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
                    "$XMAKE_EXE" lua private.xrepo.action.env.info config $bnd || return 1
                    local prompt="$("$XMAKE_EXE" lua --quiet private.xrepo.action.env.info prompt $bnd)" || return 1
                    if [ -z "${prompt+x}" ]; then
                        return 1
                    fi
                    local activateCommand="$("$XMAKE_EXE" lua --quiet private.xrepo.action.env.info script.bash $bnd)" || return 1
                    export XMAKE_ENV_BACKUP="$("$XMAKE_EXE" lua private.xrepo.action.env.info envfile $bnd)"
                    export XMAKE_PROMPT_BACKUP="${PS1}"
                    "$XMAKE_EXE" lua --quiet private.xrepo.action.env.info backup.bash $bnd 1>"$XMAKE_ENV_BACKUP"
                    eval "$activateCommand"
                    PS1="${prompt} $PS1"
                else
                    "$XMAKE_EXE" lua private.xrepo "$@"
                fi
                ;;
            *)
                "$XMAKE_EXE" lua private.xrepo "$@"
                ;;
        esac
    else
        "$XMAKE_EXE" lua private.xrepo "$@"
    fi
}
