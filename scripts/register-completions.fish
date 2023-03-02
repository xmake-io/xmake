#!/usr/bin/env fish
# XMake 的 Fish Shell 自动补全

# 补全钩子函数
function _xmake_fish_complete
    # 读取当前命令行
    set -l raw_cmd (commandline)
    set -l words (commandline -o)
    # 获取当前令牌
    set -l token (commandline -ot)

    # 调用 XMake 内置补全来获得可用结果
    set -l result (MAKE_SKIP_HISTORY=1 XMAKE_ROOT=y xmake lua private.utils.complete 0 nospace "$raw_cmd")
    if test (count $result) -lt 1
        # 当没有可用的补全项时，直接结束函数
        # 否则后续 contains 命令会触发错误
        return 1
    end

    # 结果是否有多个可选项？
    # 当有多个可选项时，用户当前令牌必定不完整
    test (count $result) -gt 1
    set -l is_multiple_choice $status
    # 唯一的可选项是否与当前光标下的令牌（可能为空）完全相同？
    # 相同表示用户已经执行了补全过程
    # 可选项输出重复，不是当前光标位置的补全
    contains -- $token $result
    set -l is_token_incomplete $status
    # 唯一的可选项是不是与命令行的最后一个可见令牌完全相同？
    # 在每一个令牌位不带前缀触发补全时，当前令牌为空字符串
    # 命令行令牌化数组的最后一项为光标的上一个令牌
    # 主要应对空格后无前缀触发补全的场景
    contains -- $words[-1] $result
    set -l not_token_completed $status

    test \( $is_token_incomplete -eq 1 \) -a \( $not_token_completed -eq 1 \)
    test \( $is_multiple_choice -eq 0 \) -o \( $status -eq 0 \)
    if test $status -eq 0
        # 当不全列表不只有一项的时候，或者当前令牌与补全列表的唯一令牌不同
        # 用户必然没有写全令牌，需要为用户提供补全
        for item in $result 
            # 每个结果独占一行，对于 "-a" 参数而言需要分别 echo 出去
            # 尽管结果本身带有换行，但 "-a" 仍会将它视为一个整体，
            # 不执行分词视为多个参数
            if not string match -- '*error*' "$item" > /dev/null
                echo $item
            end
        end
    end
end

# 补全代理
complete -c xmake -f -a "(_xmake_fish_complete)"
