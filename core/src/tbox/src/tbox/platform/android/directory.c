/*!The Treasure Box Library
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
 * Copyright (C) 2009 - 2019, TBOOX Open Source Group.
 *
 * @author      ruki
 * @file        directory.c
 * @ingroup     platform
 */

/* //////////////////////////////////////////////////////////////////////////////////////
 * trace
 */
#define TB_TRACE_MODULE_NAME            "android_directory"
#define TB_TRACE_MODULE_DEBUG           (0)

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"
#include "android.h"
#include "../directory.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * implementation
 */
tb_size_t tb_directory_temporary(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn > 4, 0);

    // the jvm
    JavaVM* jvm = tb_android_jvm();
    tb_assert_and_check_return_val(jvm, 0);

    // attempt to get jni environment first
    JNIEnv*     jenv = tb_null; 
    tb_bool_t   jattached = tb_false;
    if ((*jvm)->GetEnv(jvm, (tb_pointer_t*)&jenv, JNI_VERSION_1_4) != JNI_OK) 
    {
        // bind jni environment
        if ((*jvm)->AttachCurrentThread(jvm, &jenv, tb_null) != JNI_OK) return 0;

        // attach ok
        jattached = tb_true;
    }
    tb_assert_and_check_return_val(jenv, 0);

    // enter
    if ((*jenv)->PushLocalFrame(jenv, 10) < 0) return 0;

    // done
    tb_size_t   size = 0;
    jboolean    error = tb_false;
    do
    {
        // get the environment class
        jclass environment = (*jenv)->FindClass(jenv, "android/os/Environment");
        tb_assert_and_check_break(!(error = (*jenv)->ExceptionCheck(jenv)) && environment);

        // get the getDownloadCacheDirectory func
        jmethodID getDownloadCacheDirectory_func = (*jenv)->GetStaticMethodID(jenv, environment, "getDownloadCacheDirectory", "()Ljava/io/File;");
        tb_assert_and_check_break(getDownloadCacheDirectory_func);

        // get the download cache directory 
        jobject directory = (*jenv)->CallStaticObjectMethod(jenv, environment, getDownloadCacheDirectory_func);
        tb_assert_and_check_break(!(error = (*jenv)->ExceptionCheck(jenv)) && directory);

        // get file class
        jclass file_class = (*jenv)->GetObjectClass(jenv, directory);
        tb_assert_and_check_break(!(error = (*jenv)->ExceptionCheck(jenv)) && file_class);

        // get the getPath func
        jmethodID getPath_func = (*jenv)->GetMethodID(jenv, file_class, "getPath", "()Ljava/lang/String;");
        tb_assert_and_check_break(getPath_func);

        // get the directory path
        jstring path_jstr = (jstring)(*jenv)->CallObjectMethod(jenv, directory, getPath_func);
        tb_assert_and_check_break(!(error = (*jenv)->ExceptionCheck(jenv)) && path_jstr);

        // get the path string length
        size = (tb_size_t)(*jenv)->GetStringLength(jenv, path_jstr);
        tb_assert_and_check_break(size);

        // get the path string
        tb_char_t const* path_cstr = (*jenv)->GetStringUTFChars(jenv, path_jstr, tb_null);
        tb_assert_and_check_break(path_cstr);

        // trace
        tb_trace_d("temp: %s", path_cstr);

        // copy it
        tb_size_t need = tb_min(size + 1, maxn);
        tb_strlcpy(path, path_cstr, need);

        // exit the path string
        (*jenv)->ReleaseStringUTFChars(jenv, path_jstr, path_cstr);

    } while (0);

    // exception? clear it
    if (error) (*jenv)->ExceptionClear(jenv);

    // leave
    (*jenv)->PopLocalFrame(jenv, tb_null);

    // detach it?
    if (jattached)
    {
        // detach jni environment
        if ((*jvm)->DetachCurrentThread(jvm) == JNI_OK)
            jattached = tb_false;
    }

    // ok?
    return size;
}
tb_size_t tb_directory_home(tb_char_t* path, tb_size_t maxn)
{
    // check
    tb_assert_and_check_return_val(path && maxn, 0);

    // trace
    tb_trace_noimpl();
    return 0;
}
