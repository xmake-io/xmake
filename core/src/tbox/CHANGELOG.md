# Changelog  ([中文](#中文))

## master (unreleased)

### New features

* Add ping demo for network

### Changes

* Modify license to Apache License 2.0
* Rename `--smallest=y|n` option to `--small=y|n`
* Support stat64
* Improve copy speed and fix permissions for `tb_file_copy`
* Improve path operation for posix platform
* Improve socket interfaces and support icmp

### Bugs fixed

* Fix create file mode to 0644
* Fix file and directory path bug
* Fix remove directory with dead symbol link failed
* Fix remove readonly file failed
* [#34](https://github.com/tboox/tbox/issues/34): Fix cache time and coroutine sleep bug
* [#35](https://github.com/tboox/tbox/issues/35): Fix epoll bug with the edge trigger mode

## v1.6.1

### New features

* Support coroutine context switch for mips
* Add `__tb_thread_local__` keyword macro
* Add `--micro=y|n` option to compiling micro library (~64K) for the embed system
* Add `tb_addrinfo_addr` and `tb_addrinfo_name` interfaces
* Add stackless coroutine
* Add semaphone and lock for the stackless coroutine

### Changes

* Optimize io scheduler for coroutine, cache events for poller
* Add c11 `_Static_assert`
* Remove some deprecated interfaces for hash and platform

## v1.6.0

### New features

* Support make command and compile directly without xmake
* Add switch context interfaces into platform module
* Add coroutine module (supports i386, x86_64, arm, arm64, mips ..)
* Add simple http server demo using coroutine
* Add simple spider using coroutine
* Add io poller interfaces(with epoll, poll, kqueue, select)
* Support mbedtls ssl library
* All io modules(stream, socket, http, ..) support coroutine mode
* Provide lock, semaphone and channel for coroutine

### Changes

* Optimize and rewrite thread local store module
* Modify thread interfaces 
* Mark the asio module as deprecated
* Optimize exception interfaces

### Bugs fixed

* Fix some warning and errors for compiler
* Fix some thread bugs
* Fix parse bplist uid type

## v1.5.3

### New features

* Add wait multi-processes interface
* Add uuid generator
* Add hash library module
* Add `__tb_deprecated__` keyword and option

### Changes

* Move some utils interfaces to the hash module
* Rewrite random generator

### Bugs fixed

* Fix stdout compatibility issue for vs2015
* Fix process arguments length limit

## v1.5.2

### New features

* Add smallest configure option
* Add process operation interfaces

### Changes

* Improve envirnoment interfaces
* Modify xmake.lua for supporting xmake v2.x

### Bugs fixed

* Fix ltimer bug
* Fix asio memory leaks bug
* Fix asio httpd response bug on linux
* Fix path bug for windows

## v1.5.1

### New features

* Add automaticlly check libc interfaces
* Support custom allocator 
* Add trace for allocator in the debug mode
* Add `static_pool` module
* Add stream interfaces for reading all data to string
* Add adler32 hash algorithm
* Add `tb_memmem` interface
* Add regex module with pcre, pcre2 or posix regex 

### Changes

* Optimize stream and support read/write character device file
* Modify `tb_init` api and support allocator arguments
* Improve memory manager and use the allocator mode
* Redefine `assert` and will abort for debug mode 

### Bugs fixed

* Fix some bugs for android
* Fix seek bug for stream

<h1 id="中文"></h1>

# 更新日志

## master (开发中)

### 新特性

* 增加ping测试程序

### 改进

* 修改license，使用更加宽松的Apache License 2.0
* 重命名`--smallest=y|n`选项到`--small=y|n`
* 使用`stat64`支持大文件信息获取
* 改进`tb_file_copy`，更加快速的文件copy，并且修复copy后文件权限丢失问题
* 改进posix平台下的路径操作
* 改进socket初始化接口，支持icmp协议

### Bugs修复

* 修复创建文件权限不对问题
* 修复文件和目录路径问题
* 修复无法移除带有无效软链的目录问题
* 修复无法移除只读文件问题
* [#34](https://github.com/tboox/tbox/issues/34): 修复缓存时间和协程sleep不准问题
* [#35](https://github.com/tboox/tbox/issues/35): 修复epoll边缘触发模式下，centos上检测连接关闭失效问题

## v1.6.1

### 新特性

* 针对协程上下文切换，支持mips架构
* 添加`__tb_thread_local__`关键字宏
* 添加 `--micro=y|n` 选项，实现极小编译，针对嵌入式平台，编译tbox微内核(~64K) 
* 添加 `tb_addrinfo_addr` and `tb_addrinfo_name` 接口
* 添加stackless协程，更加轻量的协程支持，每个协程只占用几十个bytes，同时支持io调度
* 针对stackless协程，增加lock和semaphone支持

### 改进

* 为协程优化io调度器，缓存poller轮询等待，减少频繁重复调用epoll_ctl, kevent等系统接口
* 添加对c11关键字`_Static_assert`的支持
* 针对hash和platform模块，移除一些废弃的接口

## v1.6.0

### 新特性

* 支持make进行直接编译（会去自动下载xmake进行构建）
* 在平台库中，添加切换context上下文接口（参考boost.context实现原理进行重写，并对部分架构进行优化）
* 新增跨平台协程模块（支持i386, x86_64, arm, arm64, mips），提供更加易用的高性能并发编程模式
* 新增基于协程的各种服务器开发实例（包括：简单轻量的http服务器，爬虫。。）
* 新增poller轮询器接口，实现对epoll, poll, kqueue, select的封装，逐步取代老的aiop接口
* 新增mbedtls ssl库接口支持，目前已支持：openssl, polarssl, mbedtls
* tbox所有stream, socket, http, dns, ssl 等io相关操作，原生支持协程模式，并且可以在线程和协程间随意切换
* 为协程提供lock, semaphone, channel模块

### 改进

* 优化和重构线程局部存储TLS模块
* 修改部分线程接口
* asio模块被标记为废弃接口，下个版本将会被移除，逐步使用协程模式来实现异步io开发
* 优化异常捕获接口

### Bugs修复

* 修复一些编译警告和错误
* 修复一些线相关bug
* 修复bplist中解析uid类型失败问题

## v1.5.3

### 新特性

* 增加同时等待多个进程接口
* 增加uuid生成器
* 增加hash库模块
* 添加`__tb_deprecated__`关键字以及配置选项

### 改进

* 移动部分utils接口到hash模块
* 重写random生成器

### Bugs修复

* 修复stdout在vs2015以上版本的兼容性问题
* 修复进程参数长度限制

## v1.5.2

### 新特性

* 增加smallest参数配置选项，实现一键配置最小化编译，禁用所有扩展模块和依赖库
* 增加进程创建和控制接口

### 改进

* 增强环境变量设置接口
* 修改xmake.lua支持最新版xmake v2.x, 简化编译配置

### Bugs修复

* 修复ltimer定时器不准问题
* 修复asio部分内存泄露问题
* 修复asio/httpd在linux下keepalive模式，响应很慢问题
* 修复windows下路径处理的一些bug

## v1.5.1

### 新特性

* 自动检测所有系统libc接口，优先使用系统版本
* 支持自定义内存分配器，并且能够在debug模式下，获取每次分配的代码位置信息，用于自定义追踪
* 增加轻量级`static_pool`来维护整块buffer的内存分配，适合局部管理部分内存，pool虽然也能维护，但是底层基于`large_pool`，比较重量级，适合全局管理内存
* 增加stream快速读取全部数据到string的接口
* 增加adler32 hash算法
* 增加`tb_memmem`接口
* 采用pcre/pcre2/posix regex实现正则表达式库

### 改进

* 优化stream，支持对字符设备文件的读写
* 修改`tb_init`接口，增加allocator自定义内存分配器参数，实现用户的侵入式内存管理
* 重构内存管理，完全采用分配器allocator模式，可以灵活切换内存管理，支持原生系统内存、静态buffer内存、内存池等各种分配方式
* 重定义assert，debug模式遇到assert直接abort执行

### Bugs修复

* 修复android下的一些bug
* 修复stream的seek问题

## v1.5.0

### 新特性

* 增加跨平台环境变量操作接口

### 改进

* 重建整个编译架构，采用xmake跨平台自动构建工具进行构建。。
* 优化.pkg的依赖包机制，支持依赖库和接口的自动检测，针对libc、libm优先使用自动检测到的系统库接口实现，如果当前平台没有实现则使用tbox的自己实现版本，使得最大化性能和跨平台性。。
* 完善和优化路径操作，增加相对路径、绝对路径的相互转换

### Bugs修复

* 修复strlcpy等一些libc接口的实现bug

## v1.4.8

### 新特性

* 新增路径操作接口，支持相对路径、绝对路径相互转换

### 改进

* 重建整个makefile架构，采用`*.pkg`依赖包模式模块化对第三方库的依赖，降低耦合
* 默认编译配置可以自动探测当前平台支持的依赖包，注：所有依赖包都是可选的，如果要最小化编译，可以完全禁用
* 编译生成的所有库和头文件，也都安装成独立`*.pkg`格式，方便集成到其他开发平台，也方便copy
* 增强object路径解析接口，支持json, xml宏路径解析，并增加实用json解析工具：jcat
* 实现通用ipaddr结构，统一接口，全面支持ipv6/ipv4，stream/http的url也完全支持ipv6格式解析
* 重命名hash为`hash_map`，并新增`hash_set`容器

## v1.4.7

### 改进

* 增强fixed16定点类型的接口，优化部分接口性能，调试模式下增加更多的溢出检测
* 优化整数平方根的实现，增加对64位整数平方根的快速计算

### Bugs修复

* 修复string空字符串bug
* 修复windows下asio的一些bug
* 修复一些编译问题

## v1.4.7_rc1

### 新特性

* 增加asio模块，支持各种异步socket/file操作，支持异步dns、ssl（依赖polarssl/openssl）、http
* 增加http cookie支持，完善http客户端协议
* 增加sql数据库模块，依赖sqlite3/mysql
* 增加object模块
* 新增min/max heap容器，新增`list_entry`、`single_list_entry`等外置轻量链表实现，和`list`、`single_list`不同的是，不需要维护内部内存，而且更加灵活，新增bloom_filter
* 新增remove、walk、count、for等常用算法支持
* 新增线程池、定时器、信号量、自旋锁、atomic64等常用系统操作
* 新增http服务器、http爬虫、http下载器等实用性demo

### 改进

* 重构stream模块，并新增`async_stream`、`async_transfer`、`transfer_pool`等新特性。
* 优化和完善libc、libm的接口
* 重构整个内存管理架构，完善内存检测的支持，优化内存使用和效率

### Bugs修复

* 修复和优化xml解析模块
