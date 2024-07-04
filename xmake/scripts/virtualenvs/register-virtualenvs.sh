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
    export XMAKE_PROGRAM_FILE=${XMAKE_ROOTDIR}/xmake
else
    local -i XMAKE_ROOTDIR=~/.local/bin
    export XMAKE_PROGRAM_FILE=xmake
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
                "$XMAKE_PROGRAM_FILE" lua private.xrepo.action.env.info config || return 1
                local currentTest="$("$XMAKE_PROGRAM_FILE" lua --quiet private.xrepo.action.env)" || return 1
                if [ ! -z "$currentTest" ]; then
                    echo "error: corrupt xmake.lua detected in the current directory!"
                    return 1
                fi
                local prompt="$("$XMAKE_PROGRAM_FILE" lua --quiet private.xrepo.action.env.info prompt)" || return 1
                if [ -z "${prompt+x}" ]; then
                    return 1
                fi
                local activateCommand="$("$XMAKE_PROGRAM_FILE" lua private.xrepo.action.env.info script.bash)" || return 1
                export XMAKE_ENV_BACKUP="$("$XMAKE_PROGRAM_FILE" lua private.xrepo.action.env.info envfile)"
                export XMAKE_PROMPT_BACKUP="${PS1}"
                "$XMAKE_PROGRAM_FILE" lua private.xrepo.action.env.info backup.bash 1>"$XMAKE_ENV_BACKUP"
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
                    pushd ${XMAKE_ROOTDIR} 1>/dev/null
                    "$XMAKE_PROGRAM_FILE" lua private.xrepo.action.env.info config $bnd || popd 1>/dev/null && return 1
                    local prompt="$("$XMAKE_PROGRAM_FILE" lua --quiet private.xrepo.action.env.info prompt $bnd)" || popd 1>/dev/null && return 1
                    if [ -z "${prompt+x}" ]; then
                        popd 1>/dev/null
                        echo "error: invalid environment!"
                        return 1
                    fi
                    local activateCommand="$("$XMAKE_PROGRAM_FILE" lua --quiet private.xrepo.action.env.info script.bash $bnd)" || popd 1>/dev/null && return 1
                    export XMAKE_ENV_BACKUP="$("$XMAKE_PROGRAM_FILE" lua private.xrepo.action.env.info envfile $bnd)"
                    export XMAKE_PROMPT_BACKUP="${PS1}"
                    "$XMAKE_PROGRAM_FILE" lua --quiet private.xrepo.action.env.info backup.bash $bnd 1>"$XMAKE_ENV_BACKUP"
                    eval "$activateCommand"
                    popd 1>/dev/null
                    PS1="${prompt} $PS1"
                else
                    "$XMAKE_PROGRAM_FILE" lua private.xrepo "$@"
                fi
                ;;
            *)
                "$XMAKE_PROGRAM_FILE" lua private.xrepo "$@"
                ;;
        esac
    else
        "$XMAKE_PROGRAM_FILE" lua private.xrepo "$@"
    fi
}
