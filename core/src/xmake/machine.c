/*!A cross-platform build utility based on Lua
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 * 
 * Copyright (C) 2015 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        machine.c
 *
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME                "machine"
#define TB_TRACE_MODULE_DEBUG               (1)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "xmake.h"
#if defined(TB_CONFIG_OS_WINDOWS)
#   include <windows.h>
#   include <io.h>
#   include <fcntl.h>
#elif defined(TB_CONFIG_OS_MACOSX)
#   include <mach-o/dyld.h>
#elif defined(TB_CONFIG_OS_LINUX)
#   include <unistd.h>
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the machine type
typedef struct __xm_machine_t
{
    // the lua 
    lua_State*              lua;

}xm_machine_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * declaration
 */

// the os functions
tb_int_t xm_os_argv(lua_State* lua);
tb_int_t xm_os_find(lua_State* lua);
tb_int_t xm_os_link(lua_State* lua);
tb_int_t xm_os_isdir(lua_State* lua);
tb_int_t xm_os_rmdir(lua_State* lua);
tb_int_t xm_os_mkdir(lua_State* lua);
tb_int_t xm_os_cpdir(lua_State* lua);
tb_int_t xm_os_chdir(lua_State* lua);
tb_int_t xm_os_mtime(lua_State* lua);
tb_int_t xm_os_sleep(lua_State* lua);
tb_int_t xm_os_mclock(lua_State* lua);
tb_int_t xm_os_curdir(lua_State* lua);
tb_int_t xm_os_tmpdir(lua_State* lua);
tb_int_t xm_os_islink(lua_State* lua);
tb_int_t xm_os_isfile(lua_State* lua);
tb_int_t xm_os_rmfile(lua_State* lua);
tb_int_t xm_os_cpfile(lua_State* lua);
tb_int_t xm_os_rename(lua_State* lua);
tb_int_t xm_os_exists(lua_State* lua);
tb_int_t xm_os_setenv(lua_State* lua);
tb_int_t xm_os_getenv(lua_State* lua);
tb_int_t xm_os_getenvs(lua_State* lua);
tb_int_t xm_os_cpuinfo(lua_State* lua);
tb_int_t xm_os_readlink(lua_State* lua);
tb_int_t xm_os_filesize(lua_State* lua);
tb_int_t xm_os_emptydir(lua_State* lua);
tb_int_t xm_os_strerror(lua_State* lua);
tb_int_t xm_os_getwinsize(lua_State* lua);
#ifndef TB_CONFIG_OS_WINDOWS
tb_int_t xm_os_uid(lua_State* lua);
tb_int_t xm_os_gid(lua_State* lua);
tb_int_t xm_os_getown(lua_State* lua);
#endif

// the io/file functions
tb_int_t xm_io_stdfile(lua_State* lua);
tb_int_t xm_io_file_open(lua_State* lua);
tb_int_t xm_io_file_read(lua_State* lua);
tb_int_t xm_io_file_seek(lua_State* lua);
tb_int_t xm_io_file_size(lua_State* lua);
tb_int_t xm_io_file_rawfd(lua_State* lua);
tb_int_t xm_io_file_write(lua_State* lua);
tb_int_t xm_io_file_flush(lua_State* lua);
tb_int_t xm_io_file_close(lua_State* lua);
tb_int_t xm_io_file_isatty(lua_State* lua);

// the io/filelock functions
tb_int_t xm_io_filelock_open(lua_State* lua);
tb_int_t xm_io_filelock_lock(lua_State* lua);
tb_int_t xm_io_filelock_unlock(lua_State* lua);
tb_int_t xm_io_filelock_trylock(lua_State* lua);
tb_int_t xm_io_filelock_close(lua_State* lua);

// the path functions
tb_int_t xm_path_relative(lua_State* lua);
tb_int_t xm_path_absolute(lua_State* lua);
tb_int_t xm_path_translate(lua_State* lua);
tb_int_t xm_path_is_absolute(lua_State* lua);

// the hash functions
tb_int_t xm_hash_uuid(lua_State* lua);
tb_int_t xm_hash_sha256(lua_State* lua);

// the windows functions
#ifdef TB_CONFIG_OS_WINDOWS
tb_int_t xm_winos_cp_info(lua_State* lua);
tb_int_t xm_winos_console_cp(lua_State* lua);
tb_int_t xm_winos_console_output_cp(lua_State* lua);
tb_int_t xm_winos_ansi_cp(lua_State* lua);
tb_int_t xm_winos_oem_cp(lua_State* lua);
tb_int_t xm_winos_logical_drives(lua_State* lua);
tb_int_t xm_winos_registry_query(lua_State* lua);
#endif

// the string functions
tb_int_t xm_string_trim(lua_State* lua);
tb_int_t xm_string_convert(lua_State* lua);
tb_int_t xm_string_endswith(lua_State* lua);
tb_int_t xm_string_startswith(lua_State* lua);

// the process functions
tb_int_t xm_process_open(lua_State* lua);
tb_int_t xm_process_openv(lua_State* lua);
tb_int_t xm_process_waitlist(lua_State* lua);
tb_int_t xm_process_wait(lua_State* lua);
tb_int_t xm_process_close(lua_State* lua);

// the sandbox functions
tb_int_t xm_sandbox_interactive(lua_State* lua);

#ifdef XM_CONFIG_API_HAVE_READLINE
// the readline functions
tb_int_t xm_readline_readline(lua_State* lua);
tb_int_t xm_readline_history_list(lua_State* lua);
tb_int_t xm_readline_add_history(lua_State* lua);
tb_int_t xm_readline_clear_history(lua_State* lua);
#endif

// the semver functions
tb_int_t xm_semver_parse(lua_State* lua);
tb_int_t xm_semver_compare(lua_State* lua);
tb_int_t xm_semver_satisfies(lua_State* lua);
tb_int_t xm_semver_select(lua_State* lua);

#ifdef XM_CONFIG_API_HAVE_CURSES
// register curses
tb_int_t xm_curses_register(lua_State* lua);
#endif

/* //////////////////////////////////////////////////////////////////////////////////////
 * globals
 */

// the os functions
static luaL_Reg const g_os_functions[] = 
{
    { "argv",           xm_os_argv      }
,   { "find",           xm_os_find      }
,   { "link",           xm_os_link      }
,   { "isdir",          xm_os_isdir     }
,   { "rmdir",          xm_os_rmdir     }
,   { "mkdir",          xm_os_mkdir     }
,   { "cpdir",          xm_os_cpdir     }
,   { "chdir",          xm_os_chdir     }
,   { "mtime",          xm_os_mtime     }
,   { "sleep",          xm_os_sleep     }
,   { "mclock",         xm_os_mclock    }
,   { "curdir",         xm_os_curdir    }
,   { "tmpdir",         xm_os_tmpdir    }
,   { "islink",         xm_os_islink    }
,   { "isfile",         xm_os_isfile    }
,   { "rmfile",         xm_os_rmfile    }
,   { "cpfile",         xm_os_cpfile    }
,   { "rename",         xm_os_rename    }
,   { "exists",         xm_os_exists    }
,   { "setenv",         xm_os_setenv    }
,   { "getenv",         xm_os_getenv    }
,   { "getenvs",        xm_os_getenvs   }
,   { "cpuinfo",        xm_os_cpuinfo   }
,   { "readlink",       xm_os_readlink  }
,   { "emptydir",       xm_os_emptydir  }
,   { "strerror",       xm_os_strerror  }
,   { "filesize",       xm_os_filesize  }
,   { "getwinsize",     xm_os_getwinsize}
#ifndef TB_CONFIG_OS_WINDOWS
,   { "uid",            xm_os_uid       }
,   { "gid",            xm_os_gid       }
,   { "getown",         xm_os_getown    }
#endif
,   { tb_null,          tb_null         }
};

// the windows functions
#ifdef TB_CONFIG_OS_WINDOWS
static luaL_Reg const g_winos_functions[] = 
{
    { "cp_info",             xm_winos_cp_info           }
,   { "console_cp",          xm_winos_console_cp        }
,   { "console_output_cp",   xm_winos_console_output_cp }
,   { "oem_cp",              xm_winos_oem_cp            }
,   { "ansi_cp",             xm_winos_ansi_cp           }
,   { "logical_drives",      xm_winos_logical_drives    }
,   { "registry_query",      xm_winos_registry_query    }
,   { tb_null,               tb_null                    }
};
#endif

// the io functions
static luaL_Reg const g_io_functions[] = 
{
    { "stdfile",            xm_io_stdfile          }
,   { "file_open",          xm_io_file_open        }
,   { "file_read",          xm_io_file_read        }
,   { "file_seek",          xm_io_file_seek        }
,   { "file_size",          xm_io_file_size        }
,   { "file_write",         xm_io_file_write       }
,   { "file_flush",         xm_io_file_flush       }
,   { "file_isatty",        xm_io_file_isatty      }
,   { "file_close",         xm_io_file_close       }
,   { "file_rawfd",         xm_io_file_rawfd       }
,   { "filelock_open",      xm_io_filelock_open    }
,   { "filelock_lock",      xm_io_filelock_lock    }
,   { "filelock_trylock",   xm_io_filelock_trylock }
,   { "filelock_unlock",    xm_io_filelock_unlock  }
,   { "filelock_close",     xm_io_filelock_close   }
,   { tb_null,              tb_null                }
};

// the path functions
static luaL_Reg const g_path_functions[] = 
{
    { "relative",       xm_path_relative    }
,   { "absolute",       xm_path_absolute    }
,   { "translate",      xm_path_translate   }
,   { "is_absolute",    xm_path_is_absolute }
,   { tb_null,          tb_null             }
};

// the hash functions
static luaL_Reg const g_hash_functions[] = 
{
    { "uuid",           xm_hash_uuid   }
,   { "sha256",         xm_hash_sha256 }
,   { tb_null,          tb_null        }
};

// the string functions
static luaL_Reg const g_string_functions[] = 
{
    { "trim",           xm_string_trim          }
,   { "convert",        xm_string_convert       }
,   { "endswith",       xm_string_endswith      }
,   { "startswith",     xm_string_startswith    }
,   { tb_null,          tb_null                 }
};

// the process functions
static luaL_Reg const g_process_functions[] = 
{
    { "open",           xm_process_open     }
,   { "openv",          xm_process_openv    }
,   { "waitlist",       xm_process_waitlist }
,   { "wait",           xm_process_wait     }
,   { "close",          xm_process_close    }
,   { tb_null,          tb_null             }
};

// the sandbox functions
static luaL_Reg const g_sandbox_functions[] = 
{
    { "interactive",    xm_sandbox_interactive }
,   { tb_null,          tb_null                }
};

#ifdef XM_CONFIG_API_HAVE_READLINE
// the readline functions
static luaL_Reg const g_readline_functions[] =
{
    { "readline",       xm_readline_readline     }
,   { "history_list",   xm_readline_history_list }
,   { "add_history",    xm_readline_add_history  }
,   { "clear_history",  xm_readline_clear_history}
,   { tb_null,          tb_null                  }
};
#endif

// the semver functions
static luaL_Reg const g_semver_functions[] =
{
    { "parse",          xm_semver_parse     }
,   { "compare",        xm_semver_compare   }
,   { "satisfies",      xm_semver_satisfies }
,   { "select",         xm_semver_select    }
,   { tb_null,          tb_null             }
};

/* //////////////////////////////////////////////////////////////////////////////////////
 * private implementation
 */
static tb_bool_t xm_machine_save_arguments(xm_machine_t* machine, tb_int_t argc, tb_char_t** argv)
{
    // check
    tb_assert_and_check_return_val(machine && machine->lua && argc >= 1 && argv, tb_false);

#ifdef TB_CONFIG_OS_WINDOWS
    tb_wchar_t **argvw = CommandLineToArgvW(GetCommandLineW(), &argc);
#endif

    // put a new table into the stack
    lua_createtable(machine->lua, argc, 0);

    // save all arguments to the new table
    tb_int_t i = 0;
    for (i = 1; i < argc; i++)
    {
#ifdef TB_CONFIG_OS_WINDOWS
        tb_char_t argvbuf[4096] = {0};
        tb_wcstombs(argvbuf, argvw[i], tb_arrayn(argvbuf));
        // table_new[table.getn(table_new) + 1] = argv[i]
        lua_pushstring(machine->lua, argvbuf);
#else
        lua_pushstring(machine->lua, argv[i]);
#endif
        lua_rawseti(machine->lua, -2, (int)lua_objlen(machine->lua, -2) + 1);
    }

    // _ARGV = table_new
    lua_setglobal(machine->lua, "_ARGV");

    // ok
    return tb_true;
}
static tb_size_t xm_machine_get_program_file(xm_machine_t* machine, tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(machine && path && maxn, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
#if defined(TB_CONFIG_OS_WINDOWS)
        // get the executale file path as program directory
        tb_wchar_t buf[TB_PATH_MAXN] = {0};
        tb_size_t  size              = (tb_size_t)GetModuleFileNameW(tb_null, buf, (DWORD)TB_PATH_MAXN);
        tb_assert_and_check_break(size < TB_PATH_MAXN);
        // end
        buf[size]  = L'\0';
        size       = tb_wcstombs(path, buf, maxn);
        tb_assert_and_check_break(size < maxn);
        path[size] = '\0';

        // ok
        ok = tb_true;

#elif defined(TB_CONFIG_OS_MACOSX)
        /*
         * _NSGetExecutablePath() copies the path of the main executable into the buffer. The bufsize parameter
         * should initially be the size of the buffer.  The function returns 0 if the path was successfully copied,
         * and *bufsize is left unchanged. It returns -1 if the buffer is not large enough, and *bufsize is set 
         * to the size required. 
         * 
         * Note that _NSGetExecutablePath will return "a path" to the executable not a "real path" to the executable. 
         * That is the path may be a symbolic link and not the real file. With deep directories the total bufsize 
         * needed could be more than MAXPATHLEN.
         */
        tb_uint32_t bufsize = (tb_uint32_t)maxn;
        if (!_NSGetExecutablePath(path, &bufsize))
            ok = tb_true;
#elif defined(TB_CONFIG_OS_LINUX)
        // get the executale file path as program directory
        ssize_t size = readlink("/proc/self/exe", path, (size_t)maxn);
        if (size > 0 && size < maxn)
        {
            // end
            path[size] = '\0';

            // ok
            ok = tb_true;
        }
#endif

    } while (0);

    // ok?
    if (ok)
    {
        // trace
        tb_trace_d("programfile: %s", path);

        // save the directory to the global variable: _PROGRAM_FILE
        lua_pushstring(machine->lua, path);
        lua_setglobal(machine->lua, "_PROGRAM_FILE");
    }

    // ok?
    return ok;
}
static tb_bool_t xm_machine_get_program_directory(xm_machine_t* machine, tb_char_t* path, tb_size_t maxn, tb_char_t const* programfile)
{
    // check
    tb_assert_and_check_return_val(machine && path && maxn, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // get it from the environment variable first
        tb_char_t data[TB_PATH_MAXN] = {0};
        if (tb_environment_first("XMAKE_PROGRAM_DIR", data, sizeof(data)) && tb_path_absolute(data, path, maxn))
        {
            // ok
            ok = tb_true;
            break;
        }

        // get it from program file path
        if (programfile)
        {
            tb_size_t size = tb_strlcpy(data, programfile, sizeof(data));
            if (size < sizeof(data))
            {
                // get the directory
                while (size-- > 0)
                {
                    if (data[size] == '\\' || data[size] == '/')
                    {
                        data[size] = '\0';
                        tb_strlcpy(path, data, maxn);
                        ok = tb_true;
                        break;
                    }
                }
            }
        }

    } while (0);

    // ok?
    if (ok)
    {
        // trace
        tb_trace_d("programdir: %s", path);

        // save the directory to the global variable: _PROGRAM_DIR
        lua_pushstring(machine->lua, path);
        lua_setglobal(machine->lua, "_PROGRAM_DIR");
    }

    // ok?
    return ok;
}
static tb_bool_t xm_machine_get_project_directory(xm_machine_t* machine, tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(machine && path && maxn, tb_false);

    // done
    tb_bool_t ok = tb_false;
    do
    {
        // attempt to get it from the environment variable first
        tb_char_t data[TB_PATH_MAXN] = {0};
        if (    !tb_environment_first("XMAKE_PROJECT_DIR", data, sizeof(data))
            ||  !tb_path_absolute(data, path, maxn))
        {
            // get it from the current directory
            if (!tb_directory_current(path, maxn)) break;
        }

        // trace
        tb_trace_d("project: %s", path);

        // save the directory to the global variable: _PROJECT_DIR
        lua_pushstring(machine->lua, path);
        lua_setglobal(machine->lua, "_PROJECT_DIR");

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok) tb_printf("error: not found the project directory!\n");

    // ok?
    return ok;
}
static tb_void_t xm_machine_init_arch(xm_machine_t* machine)
{
    // check
    tb_assert_and_check_return(machine && machine->lua);

#if defined(TB_CONFIG_OS_WINDOWS)

    // the GetNativeSystemInfo function type
    typedef void (WINAPI *GetNativeSystemInfo_t)(LPSYSTEM_INFO);

    // get system info
    SYSTEM_INFO systeminfo = {0};
    GetNativeSystemInfo_t pGetNativeSystemInfo = tb_null;
    tb_dynamic_ref_t kernel32 = tb_dynamic_init("kernel32.dll");
    if (kernel32) pGetNativeSystemInfo = (GetNativeSystemInfo_t)tb_dynamic_func(kernel32, "GetNativeSystemInfo");
    if (pGetNativeSystemInfo) pGetNativeSystemInfo(&systeminfo);
    else GetSystemInfo(&systeminfo);

    // init architecture
    switch (systeminfo.wProcessorArchitecture)
    {
    case PROCESSOR_ARCHITECTURE_AMD64:
        lua_pushstring(machine->lua, "x64");
        break;
    case PROCESSOR_ARCHITECTURE_ARM:
        lua_pushstring(machine->lua, "arm");
        break;
    case PROCESSOR_ARCHITECTURE_INTEL:
        lua_pushstring(machine->lua, "x86");
        break;
    default:
#   ifdef TB_ARCH_x64
        lua_pushstring(machine->lua, "x64");
#   else
        lua_pushstring(machine->lua, "x86");
#   endif
        break;
    }
#elif defined(TB_ARCH_x64)
    lua_pushstring(machine->lua, "x86_64");
#elif defined(TB_ARCH_x86)
    lua_pushstring(machine->lua, "i386");
#else
    lua_pushstring(machine->lua, TB_ARCH_STRING);
#endif
    lua_setglobal(machine->lua, "_ARCH");
}

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
xm_machine_ref_t xm_machine_init()
{
    // done
    tb_bool_t      ok = tb_false;
    xm_machine_t*  machine = tb_null;
    do
    {
        // init self
        machine = tb_malloc0_type(xm_machine_t);
        tb_assert_and_check_break(machine);

        // init lua 
        machine->lua = lua_open();
        tb_assert_and_check_break(machine->lua);

        // open lua libraries
        luaL_openlibs(machine->lua);

        // bind os functions
        luaL_register(machine->lua, "os", g_os_functions);

        // bind io functions
        luaL_register(machine->lua, "io", g_io_functions);

        // bind path functions
        luaL_register(machine->lua, "path", g_path_functions);

        // bind hash functions
        luaL_register(machine->lua, "hash", g_hash_functions);

        // bind string functions
        luaL_register(machine->lua, "string", g_string_functions);

        // bind process functions
        luaL_register(machine->lua, "process", g_process_functions);

        // bind sandbox functions
        luaL_register(machine->lua, "sandbox", g_sandbox_functions);

        // bind windows functions 
#ifdef TB_CONFIG_OS_WINDOWS
        luaL_register(machine->lua, "winos", g_winos_functions);
#endif

#ifdef XM_CONFIG_API_HAVE_READLINE
        // bind readline functions
        luaL_register(machine->lua, "readline", g_readline_functions);
#endif

        // bind semver functions
        luaL_register(machine->lua, "semver", g_semver_functions);

#ifdef XM_CONFIG_API_HAVE_CURSES
        // bind curses 
        xm_curses_register(machine->lua);
        lua_setglobal(machine->lua, "curses");
#endif

        // init host
#if defined(TB_CONFIG_OS_WINDOWS)
        lua_pushstring(machine->lua, "windows");
#elif defined(TB_CONFIG_OS_MACOSX)
        lua_pushstring(machine->lua, "macosx");
#elif defined(TB_CONFIG_OS_LINUX)
        lua_pushstring(machine->lua, "linux");
#elif defined(TB_CONFIG_OS_IOS)
        lua_pushstring(machine->lua, "ios");
#elif defined(TB_CONFIG_OS_ANDROID)
        lua_pushstring(machine->lua, "android");
#elif defined(TB_CONFIG_OS_LIKE_UNIX)
        lua_pushstring(machine->lua, "unix");
#else
        lua_pushstring(machine->lua, "unknown");
#endif
        lua_setglobal(machine->lua, "_HOST");

        // init architecture
        xm_machine_init_arch(machine);

        // get version
        tb_version_t const* version = xm_version();
        tb_assert_and_check_break(version);

        // init version string
        tb_char_t version_cstr[256] = {0};
        tb_snprintf(version_cstr, sizeof(version_cstr), "%u.%u.%u+%llu", version->major, version->minor, version->alter, version->build);
        lua_pushstring(machine->lua, version_cstr);
        lua_setglobal(machine->lua, "_VERSION");

        // init short version string
        tb_snprintf(version_cstr, sizeof(version_cstr), "%u.%u.%u", version->major, version->minor, version->alter);
        lua_pushstring(machine->lua, version_cstr);
        lua_setglobal(machine->lua, "_VERSION_SHORT");

        // init namespace: xmake
        lua_newtable(machine->lua);
        lua_setglobal(machine->lua, "xmake");

#ifdef TB_CONFIG_OS_WINDOWS
        // enable terminal colors output for windows cmd
        HANDLE output =  GetStdHandle(STD_OUTPUT_HANDLE);
        if (output != INVALID_HANDLE_VALUE)
        {
            DWORD mode;
            if (GetConsoleMode(output, &mode))
            {
                // attempt to enable 0x4: ENABLE_VIRTUAL_TERMINAL_PROCESSING
                if (SetConsoleMode(output, mode | 0x4))
                    tb_environment_set("COLORTERM", "color256");
            }
        }
#endif

        // ok
        ok = tb_true;

    } while (0);

    // failed?
    if (!ok)
    {
        // exit it
        if (machine) xm_machine_exit((xm_machine_ref_t)machine);
        machine = tb_null;
    }

    return (xm_machine_ref_t)machine;
}
tb_void_t xm_machine_exit(xm_machine_ref_t self)
{
    // check
    xm_machine_t* machine = (xm_machine_t*)self;
    tb_assert_and_check_return(machine);

    // exit lua
    if (machine->lua) lua_close(machine->lua);
    machine->lua = tb_null;

    // exit it
    tb_free(machine);
}
tb_int_t xm_machine_main(xm_machine_ref_t self, tb_int_t argc, tb_char_t** argv)
{
    // check
    xm_machine_t* machine = (xm_machine_t*)self;
    tb_assert_and_check_return_val(machine && machine->lua, -1);

#ifdef TB_CONFIG_OS_WINDOWS
    if (_isatty(_fileno(stdin))) _setmode(_fileno(stdin), _O_U16TEXT);
#endif

    // save main arguments to the global variable: _ARGV
    if (!xm_machine_save_arguments(machine, argc, argv)) return -1;

    // get the project directory
    tb_char_t path[TB_PATH_MAXN] = {0};
    if (!xm_machine_get_project_directory(machine, path, sizeof(path))) return -1;

    // get the program file
    if (!xm_machine_get_program_file(machine, path, sizeof(path))) return -1;

    // get the program directory
    if (!xm_machine_get_program_directory(machine, path, sizeof(path), path)) return -1;

    // append the main script path
    tb_strcat(path, "/core/_xmake_main.lua");

    // exists this script?
    if (!tb_file_info(path, tb_null))
    {
        // error
        tb_printf("not found main script: %s\n", path);

        // failed
        return -1;
    }

    // trace
    tb_trace_d("main: %s", path);

    // load and execute the main script
    if (luaL_dofile(machine->lua, path))
    {
        // error
        tb_printf("error: %s\n", lua_tostring(machine->lua, -1));

        // failed
        return -1;
    }

    // set the error function
    lua_getglobal(machine->lua, "debug");
    lua_getfield(machine->lua, -1, "traceback");

    // call the main function
    lua_getglobal(machine->lua, "_xmake_main");
    if (lua_pcall(machine->lua, 0, 1, -2)) 
    {
        // error
        tb_printf("error: %s\n", lua_tostring(machine->lua, -1));

        // failed
        return -1;
    }

    // get the error code
    return (tb_int_t)lua_tonumber(machine->lua, -1);
}
