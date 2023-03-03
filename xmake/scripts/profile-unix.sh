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
# @homepage    profile-unix.sh
#

# enable bash compatibility for fish
set -U fish_compatibility shell

# register completions
if   [[ "$SHELL" = */zsh ]]; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.zsh"
elif [[ "$SHELL" = */bash ]]; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.bash"
elif [[ "$SHELL" = */fish ]]; then
  . "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.fish"
fi

# register virtualenvs
if [[ "$SHELL" = */fish ]]; then
# TODO
#  . "$XMAKE_PROGRAM_DIR/scripts/virtualenvs/register-virtualenvs.fish"
else
  . "$XMAKE_PROGRAM_DIR/scripts/virtualenvs/register-virtualenvs.sh"
fi

