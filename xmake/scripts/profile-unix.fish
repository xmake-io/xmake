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
# @homepage    profile-unix.fish
#

# register PATH
string match --regex --quiet "(^|:)$XMAKE_ROOTDIR(:|\$)" "$PATH" || \
    export PATH="$XMAKE_ROOTDIR:$PATH"

# register environments
export XMAKE_SHELL=fish

# register completions
. "$XMAKE_PROGRAM_DIR/scripts/completions/register-completions.fish"

