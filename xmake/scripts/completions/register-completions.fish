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
# @author      ruki, Dragon1573
# @homepage    register-completions.fish
#

# fish parameter completion for xmake
function _xmake_fish_complete
    # Read the current command line
    set -l raw_cmd (commandline)
    set -l words (commandline -o)
    # Get the current token
    set -l token (commandline -ot)

    # Call XMake built-in completion to get available results
    set -l result (MAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.utils.complete 0 nospace "$raw_cmd")
    if test (count $result) -lt 1
        # When there are no available completions, the function ends immediately
        # Otherwise, the subsequent `contains` command will trigger an error
        return 1
    end

    # Are there multiple selectable results?
    # When there are multiple options, the user's current token is definitely incomplete
    test (count $result) -gt 1
    set -l is_multiple_choice $status
    # Is the only selectable option identical to the current token under the cursor (which may be empty)?
    # Identical means the user has already completed the process
    # Repeated option outputs are not completions at the current cursor position
    contains -- $token $result
    set -l is_token_incomplete $status
    # Is the only selectable option identical to the last visible token of the command line array?
    # When completing without a prefix in every token position, the current token is an empty string
    # The last item of the command line tokenized array is the token before the cursor
    # This is mainly used to handle completions triggered after a space without a prefix
    contains -- $words[-1] $result
    set -l not_token_completed $status

    test \( $is_token_incomplete -eq 1 \) -a \( $not_token_completed -eq 1 \)
    test \( $is_multiple_choice -eq 0 \) -o \( $status -eq 0 \)
    if test $status -eq 0
        # When the completion list has more than one item, or the current token is different from the unique token in the completion list
        # The user must not have completed the token and needs to be provided with completion options
        for item in $result
            # Each result takes up a separate line, and for the "-a" parameter, it needs to be echoed separately
            # Although the result itself has a newline, "-a" still treats it as a whole,
            # Without tokenizing it as multiple parameters
            if not string match -- '*error*' "$item" > /dev/null
                echo $item
            end
        end
    end
end

complete -c xmake -f -a "(_xmake_fish_complete)"
