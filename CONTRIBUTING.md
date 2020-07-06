# Contributing

If you discover issues, have ideas for improvements or new features, or
want to contribute a new module, please report them to the
[issue tracker][1] of the repository or submit a pull request. Please,
try to follow these guidelines when you do so.

## Issue reporting

* Check that the issue has not already been reported.
* Check that the issue has not already been fixed in the latest code
  (a.k.a. `master`).
* Be clear, concise and precise in your description of the problem.
* Open an issue with a descriptive title and a summary in grammatically correct,
  complete sentences.
* Include any relevant code to the issue summary.

## Pull requests

* Use a topic branch to easily amend a pull request later, if necessary.
* Write good commit messages.
* Use the same coding conventions as the rest of the project.
* Ensure your edited codes with four spaces instead of TAB.
* Please commit code to `dev` branch and we will merge into `master` branch in future.

### Some suggestions for developing code for this project

#### Speed up build

* Use `ccache`.
* Pre-build by `make build -j`. Then if you do no modification on files in dir `core`, just use `scripts/get.sh __local__ __install_only__` to quickly install.
* Use a real xmake executable file with environment variable `XMAKE_PROGRAM_DIR` set to dir `xmake` in repo path so that no installation is needed.

#### Understand API layouts

* Action scripts, plugin scripts and user's `xmake.lua` run in a sandbox. The sandbox API is in `xmake/core/sandbox`.
* Utility scripts run in a base lua environment. Base API is in `xmake/core/base`
* Native API, which includes the lua API and the xmake ext API, is written in C in `core/src/xmake`

For example, to copy a directory in sandbox, the calling procedure is: `sandbox_os.cp()` -> `os.cp()` -> `xm_os_cpdir()` -> `tb_directory_copy()`

## Financial contributions

We also welcome financial contributions in full transparency on our [sponsor](https://xmake.io/#/about/sponsor).
Anyone can file an expense. If the expense makes sense for the development of the community, it will be "merged" in the ledger of our open collective by the core contributors and the person who filed the expense will be reimbursed.

# 贡献代码

如果你发现一些问题，或者想新增或者改进某些新特性，或者想贡献一个新的模块
那么你可以在[issues][1]上提交反馈，或者发起一个提交代码的请求(pull request).

## 问题反馈

* 确认这个问题没有被反馈过
* 确认这个问题最近还没有被修复，请先检查下 `master` 的最新提交
* 请清晰详细地描述你的问题
* 如果发现某些代码存在问题，请在issue上引用相关代码

## 提交代码

* 请先更新你的本地分支到最新，再进行提交代码请求，确保没有合并冲突
* 编写友好可读的提交信息
* 请使用与工程代码相同的代码规范
* 确保提交的代码缩进是四个空格，而不是tab
* 请提交代码到`dev`分支，如果通过，我们会在特定时间合并到`master`分支上
* 为了规范化提交日志的格式，commit消息，不要用中文，请用英文描述

[1]: https://github.com/xmake-io/xmake/issues

