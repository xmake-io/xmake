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

* Please update your local branch to the latest before submitting a pull request to ensure no merge conflicts.
* Use a topic branch to easily amend a pull request later, if necessary.
* Write good commit messages.
* Please use English for commit messages to standardize the log format.
* Use the same coding conventions as the rest of the project.
* Ensure your edited codes with four spaces instead of TAB.
* Please commit code to `dev` branch and we will merge into `master` branch in future.
* If it involves public API changes, please create a corresponding feature request in issues first, then describe the design of the new API in detail. It needs to be approved before you can start creating a PR to add and implement them, rather than directly opening a PR to add or modify new APIs at will.

## Development Guide

### Compiling Source Code

1. Download source code

```bash
git clone --recursive https://github.com/xmake-io/xmake.git
cd xmake
```

2. Compile

* Linux/macOS

```bash
./configure
make
```

* Windows

```bash
cd core
xmake
```

### Local Debugging

If you want to debug the local xmake source code, you can run the following command to load the local environment.

* Linux/macOS

```bash
source scripts/srcenv.profile
xmake --version
```

* Windows

Run `scripts\srcenv.bat` directly.

After loading the environment, we can directly modify the Lua script in the source code directory, and then run `xmake` to verify the modification effect in real time, without reinstalling.

### Environment Variables for Debugging

* `XMAKE_PROGRAM_DIR`: This environment variable specifies the directory containing Xmake's Lua scripts. By setting this to your local `xmake` source directory (e.g., `path/to/xmake/xmake`), you can force Xmake to use your local scripts. This allows you to test changes to Lua scripts immediately without re-compiling or re-installing.
* `XMAKE_PROGRAM_FILE`: This environment variable specifies the path to the `xmake` executable. It ensures that the correct binary is used, which is useful when you have multiple Xmake versions or want to test a locally compiled binary.

The `source scripts/srcenv.profile` (or `srcenv.bat`) command automatically sets these variables for you.

### Run Tests

Run the tests using the following command (Please ensure the local environment is loaded):

```bash
xmake l tests/run.lua [testname]
```

### Source Code Structure

The xmake source code is mainly divided into two parts: the C core and the Lua scripts.

* `core/`: The C core implementation, including the Lua runtime, cross-platform abstraction layer, and native API implementation.
* `xmake/`: The Lua script implementation, containing the core logic, modules, actions, and platforms.

#### Architecture Design

Xmake adopts a separation of concern design, where the performance-critical parts are implemented in C, and the build logic is implemented in Lua.

* **Sandbox**: User's `xmake.lua` and plugin scripts run in a sandbox environment to ensure safety and isolation. The sandbox API is defined in `xmake/core/sandbox`.
* **Core Modules**: The core Lua modules are located in `xmake/core`.
* **Actions**: Built-in actions (like `build`, `run`, `install`) are in `xmake/actions`.
* **Modules**: Extension modules are in `xmake/modules`.
* **Base API**: Utility scripts run in a base lua environment. Base API is in `xmake/core/base`.
* **Native API**: The Lua API and Xmake extension API, written in C, are located in `core/src/xmake`.

For example, when you call `os.cp()` in `xmake.lua`:
`sandbox_os.cp()` (Sandbox) -> `os.cp()` (Base) -> `xm_os_cpdir()` (Native C) -> `tb_directory_copy()` (Tbox)

## Financial contributions

If you want to contribute to Xmake but are unable to contribute code due to technical or time constraints, you can also support the further development of the community through [financial contributions](https://xmake.io/about/sponsor).

# 贡献代码

如果你发现一些问题，或者想新增或者改进某些新特性，或者想贡献一个新的模块
那么你可以在[issues][1]上提交反馈，或者发起一个提交代码的请求(pull request).

## 问题反馈

* 确认这个问题没有被反馈过
* 确认这个问题最近还没有被修复，请先检查下 `master` 的最新提交
* 请清晰详细地描述你的问题
* 请使用语法正确、完整的句子，开启一个带有描述性标题和摘要的 issue
* 如果发现某些代码存在问题，请在issue上引用相关代码

## 提交代码

* 请先更新你的本地分支到最新，再进行提交代码请求，确保没有合并冲突
* 如果需要，使用 topic 分支以便稍后轻松修改 pull request
* 编写友好可读的提交信息
* 请使用与工程代码相同的代码规范
* 确保提交的代码缩进是四个空格，而不是tab
* 请提交代码到`dev`分支，如果通过，我们会在特定时间合并到`master`分支上
* 为了规范化提交日志的格式，commit消息，不要用中文，请用英文描述
* 如果涉及公开的 API 改动，请先在 issues 中创建对应的 feature request ，然后详细描述下 新 API 的设计，并且需要经过赞同后，才能开始创建 pr 去添加和实现它们，而不是直接打开 pr 去随意添加修改新的 API

## 开发指南

### 源码编译

1. 下载源码

```bash
git clone --recursive https://github.com/xmake-io/xmake.git
cd xmake
```

2. 编译

* Linux/macOS

```bash
./configure
make
```

* Windows

```bash
cd core
xmake
```

### 本地调试

如果想要调试本地 xmake 源码，可以运行以下命令加载本地环境。

* Linux/macOS

```bash
source scripts/srcenv.profile
xmake --version
```

* Windows

直接运行 `scripts\srcenv.bat`。

加载环境后，我们就可以直接修改源码目录下的 Lua 脚本，然后运行 `xmake` 即可实时验证修改效果，无需重新安装。

### 调试环境变量

* `XMAKE_PROGRAM_DIR`: 指定 Xmake 的 Lua 脚本目录。将其设置为本地源码中的 `xmake` 目录（例如 `path/to/xmake/xmake`），可以让 Xmake 直接加载本地脚本。这样修改 Lua 脚本后无需重新编译安装即可生效，非常适合调试脚本逻辑。
* `XMAKE_PROGRAM_FILE`: 指定 `xmake` 可执行文件的路径。确保使用指定的二进制文件运行，适用于多版本共存或测试本地编译生成的二进制文件。

`source scripts/srcenv.profile` (或 `srcenv.bat`) 脚本会自动为你设置这些环境变量。

### 运行测试

使用以下命令运行测试（请确保本地环境已经加载）：

```bash
xmake l tests/run.lua [testname]
```

### 源码结构

Xmake 的源码主要分为两部分：C 核心和 Lua 脚本。

* `core/`: C 核心实现，包括 Lua 运行时、跨平台抽象层和原生 API 实现。
* `xmake/`: Lua 脚本实现，包含核心逻辑、模块、操作和平台支持。

#### 架构设计

Xmake 采用关注点分离的设计，性能敏感的部分由 C 实现，而构建逻辑由 Lua 实现。

* **沙盒 (Sandbox)**: 用户的 `xmake.lua` 和插件脚本运行在沙盒环境中，以确保安全性和隔离性。沙盒 API 定义在 `xmake/core/sandbox` 中。
* **核心模块 (Core Modules)**: 核心 Lua 模块位于 `xmake/core`。
* **操作 (Actions)**: 内置操作（如 `build`, `run`, `install`）位于 `xmake/actions`。
* **模块 (Modules)**: 扩展模块位于 `xmake/modules`。
* **基础 API (Base API)**: 工具脚本运行在基础 Lua 环境中。基础 API 位于 `xmake/core/base`。
* **原生 API (Native API)**: 包含 Lua API 和 Xmake 扩展 API，用 C 编写，位于 `core/src/xmake`。

例如，当你在 `xmake.lua` 中调用 `os.cp()` 时：
`sandbox_os.cp()` (Sandbox) -> `os.cp()` (Base) -> `xm_os_cpdir()` (Native C) -> `tb_directory_copy()` (Tbox)

## 资金赞助

如果您想要为 Xmake 做贡献，但受限于技术能力或时间无法参与代码开发，也可以通过[资金赞助](https://xmake.io/about/sponsor)来支持社区的进一步发展。

[1]: https://github.com/xmake-io/xmake/issues

