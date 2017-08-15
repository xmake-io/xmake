<div align="center">
  <h1>tbox</h1>

  <div>
    <a href="https://travis-ci.org/tboox/tbox">
      <img src="https://img.shields.io/travis/tboox/tbox/master.svg?style=flat-square" alt="travis-ci" />
    </a>
    <a href="https://ci.appveyor.com/project/waruqi/tbox/branch/master">
      <img src="https://img.shields.io/appveyor/ci/waruqi/tbox/master.svg?style=flat-square" alt="appveyor-ci" />
    </a>
    <a href="https://codecov.io/gh/tboox/tbox">
      <img src="https://img.shields.io/codecov/c/github/tboox/tbox/master.svg?style=flat-square" alt="Coverage" />
    </a>
    <a href="https://github.com/tboox/tbox/releases">
      <img src="https://img.shields.io/github/release/tboox/tbox.svg?style=flat-square" alt="Github All Releases" />
    </a>
    <a href="https://github.com/tboox/tbox/releases">
      <img src="https://img.shields.io/github/downloads/tboox/tbox/total.svg?style=flat-square" alt="Downloads" />
    </a>
  </div>
  <div>
    <a href="https://github.com/tboox/tbox/blob/master/LICENSE.md">
      <img src="https://img.shields.io/github/license/tboox/tbox.svg?colorB=f48041&style=flat-square" alt="license" />
    </a>
    <a href="https://gitter.im/tboox/tboox?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge">
      <img src="https://img.shields.io/gitter/room/tboox/tboox.svg?style=flat-square&colorB=96c312" alt="Gitter" />
    </a>
    <a href="http://tboox.org/donation/">
      <img src="https://img.shields.io/badge/donate-us-orange.svg?style=flat-square" alt="Donate" />
    </a>
  </div>

  <p>A glib-like cross-platform C library</p>
</div>

## Introduction ([中文](/README_zh.md))

TBOX is a glib-like cross-platform C library that is simple to use yet powerful in nature.

The project focuses on making C development easier and provides many modules (.e.g stream, asio, regex, container, algorithm ...), 
so that any developer can quickly pick it up and enjoy the productivity boost when developing in C language.

It supports the following platforms:

- Windows
- Macosx
- Linux
- Android
- iOS

And it provides many compiling options using [xmake](http://www.xmake.io):

* Release: Disable debug information, assertion, memory checking and enable optimization.
* Debug: Enable debug information, assertion, memory checking and disable optimization.
* Small: Disable all extensional modules and enable space optimization.
* Micro: compiling micro library (~64K) for the embed system.

If you want to know more, please refer to:

* [Documents](https://github.com/waruqi/tbox/wiki/documents)
* [Github](https://github.com/waruqi/tbox)
* [HomePage](http://tboox.org)

## Features

#### The stream library

- Supports file, data, http and socket source
- Supports the stream filter for gzip, charset and...
- Implements stream transfer
- Implements the static buffer stream for parsing data
- Supports coroutine and implements asynchronous operation

#### The coroutine library 

- Provides high-performance coroutine switch(refer to [reports](http://tboox.org/2016/10/28/benchbox-coroutine/))
- Supports arm, arm64, x86, x86_64 ..
- Provides channel interfaces
- Provides semaphore and lock interfaces
- Supports io socket and stream operation in coroutine
- Provides some io servers (http ..) using coroutine
- Provides stackfull and stackless coroutines

#### The database library

- Supports mysql and sqlite3 database and enumerates data using the iterator mode

#### The xml parser library

- Supports DOM and SAX mode and Supports xpath

#### The serialization and deserialization library

- Supports xml, json, bplist, xplist, binary formats

#### The memory library

- Implements some memory pools for optimizing memory
- Supports fast memory error detecting. it can detect the following types of bugs for the debug mode:
  - out-of-bounds accesses to heap and globals
  - use-after-free
  - double-free, invalid free
  - memory leaks

#### The container library

- Implements hash table, single list, double list, vector, stack, queue
  and min/max heap. Supports iterator mode for algorithm

#### The algorithm library

- Uses the iterator mode
- Implements find, binary find and reverse find algorithm
- Implements sort, bubble sort, quick sort, heap sort and insert sort algorithm
- Implements count, walk items, reverse walk items, for_all and rfor_all

#### The network library

- Implements dns(cached)
- Implements ssl(openssl, polarssl, mbedtls)
- Implements http
- Implements cookies
- Supports ipv4, ipv6
- Supports coroutine

#### The platform library

- Implements timer, fast and low precision timer
- Implements atomic and atomic64 operation
- Implements spinlock, mutex, event, semaphore, thread and thread pool 
- Implements file, socket operation
- Implements poller using epoll, poll, select, kqueue ...
- Implements switch context interfaces for coroutine

#### The charset library

- Supports utf8, utf16, gbk, gb2312, uc2 and uc4
- Supports big endian and little endian mode

#### The zip library

- Supports gzip, zlibraw, zlib formats using the zlib library if exists
- Implements lzsw, lz77 and rlc algorithm

#### The utils library

- Implements base32, base64 encoder and decoder
- Implements assert and trace output for the debug mode
- Implements bits operation for parsing u8, u16, u32, u64 data

#### The math library

- Implements random generator
- Implements fast fixed-point calculation, Supports 6-bits, 16-bits, 30-bits fixed-point number

#### The libc library

- Implements lightweight libc library interfaces, the interface name contains `tb_xxx` prefix for avoiding conflict
- Implements strixxx strrxxx wcsixxx wcsrxxx interface extension
- Optimizes some frequently-used interface, .e.g. memset, memcpy, strcpy ... 
- Implements `memset_u16`, `memset_u32`, `memset_u64` extension interfaces

#### The libm library

- Implements lightweight libm library interfaces, the interface name contains `tb_xxx` prefix for avoiding conflict
- Supports float and double type

#### The regex library

- Supports match and replace
- Supports global/multiline/caseless mode
- Uses pcre, pcre2 and posix regex modules

#### The hash library

- Implements crc32, adler32, md5 and sha1 hash algorithm
- Implements some string hash algorithms (.e.g bkdr, fnv32, fnv64, sdbm, djb2, rshash, aphash ...)
- Implements uuid generator

#### The asynchronous io library (deprecated)

- Please uses coroutine to implement asio programming

## Todolist

- Add server module
- Reconstruction xml module
- Add more algorithms and container
- Optimizes more libc interfaces 
- Implements more libm interfaces and not wrap it only

## Projects

Some projects using tbox:

* [gbox](https://github.com/waruqi/gbox)
* [vm86](https://github.com/waruqi/vm86)
* [xmake](http://www.xmake.io)
* [itrace](https://github.com/waruqi/itrace)
* [more](https://github.com/waruqi/tbox/wiki/tbox-projects)

## Build

Please install xmake first: [xmake](https://github.com/waruqi/xmake)

    # build for the host platform
    cd ./tbox
    xmake

    # build for the mingw platform
    cd ./tbox
    xmake f -p mingw --sdk=/home/mingwsdk 
    xmake
    
    # build for the iphoneos platform
    cd ./tbox
    xmake f -p iphoneos 
    xmake
    
    # build for the android platform
    cd ./tbox
    xmake f -p android --ndk=xxxxx
    xmake
    
    # build for the linux cross-platform
    cd ./tbox
    xmake f -p linux --sdk=/home/sdk # --toolchains=/home/sdk/bin
    xmake

    
## Example

    #include "tbox/tbox.h"

    int main(int argc, char** argv)
    {
        // init tbox
        if (!tb_init(tb_null, tb_null)) return 0;

        // trace
        tb_trace_i("hello tbox");

        // init vector
        tb_vector_ref_t vector = tb_vector_init(0, tb_element_cstr(tb_true));
        if (vector)
        {
            // insert item
            tb_vector_insert_tail(vector, "hello");
            tb_vector_insert_tail(vector, "tbox");

            // dump all items
            tb_for_all (tb_char_t const*, cstr, vector)
            {
                // trace
                tb_trace_i("%s", cstr);
            }

            // exit vector
            tb_vector_exit(vector);
        }

        // init stream
        tb_stream_ref_t stream = tb_stream_init_from_url("http://www.xxx.com/file.txt");
        if (stream)
        {
            // open stream
            if (tb_stream_open(stream))
            {
                // read line
                tb_long_t size = 0;
                tb_char_t line[TB_STREAM_BLOCK_MAXN];
                while ((size = tb_stream_bread_line(stream, line, sizeof(line))) >= 0)
                {
                    // trace
                    tb_trace_i("line: %s", line);
                }
            }

            // exit stream
            tb_stream_exit(stream);
        }

        // wait some time
        getchar();

        // exit tbox
        tb_exit();
        return 0;
    }

## Contacts

* Email：[waruqi@gmail.com](mailto:waruqi@gmail.com)
* Homepage：[tboox.org](http://www.tboox.org)
* Community：[tboox@community](https://github.com/tboox/community/issues)

