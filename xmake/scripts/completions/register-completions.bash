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
# @author      ruki
# @homepage    register-completions.bash
#

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
