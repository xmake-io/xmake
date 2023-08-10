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
# @homepage    register-completions.zsh
#

# zsh parameter completion for xmake
_xmake_zsh_complete()
{
  local words
  read -Ac words
  local completions=("$(XMAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.utils.complete 0 nospace "$words")")
  reply=( "${(ps:\n:)completions}" )
}
compctl -f -S "" -K _xmake_zsh_complete xmake

# zsh parameter completion for xrepo
_xrepo_zsh_complete()
{
  local words
  read -Ac words
  local completions=("$(XMAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.xrepo.complete 0 nospace "$words")")
  reply=( "${(ps:\n:)completions}" )
}
compctl -f -S "" -K _xrepo_zsh_complete xrepo

