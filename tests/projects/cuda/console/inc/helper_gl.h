/**
 * Copyright 2014 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

// These are helper functions for the SDK samples (OpenGL)
#ifndef HELPER_GL_H
#define HELPER_GL_H

#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
    #include <GL/glew.h>
#endif

#if defined(__APPLE__) || defined(MACOSX)
    #include <OpenGL/gl.h>
#else
    #include <GL/gl.h>
    #ifdef __linux__
    #include <GL/glx.h>
    #endif /* __linux__ */
#endif

#include <iostream>
#include <string>
#include <sstream>
#include <algorithm>
#include <iterator>
#include <vector>
#include <assert.h>


/* Prototypes */
namespace __HelperGL {
    static int isGLVersionSupported(unsigned reqMajor, unsigned reqMinor);
    static int areGLExtensionsSupported(const std::string &);
#ifdef __linux__

    #ifndef HELPERGL_EXTERN_GL_FUNC_IMPLEMENTATION
    #define USE_GL_FUNC(name, proto) proto name = (proto) glXGetProcAddress ((const GLubyte *)#name)
    #else
    #define USE_GL_FUNC(name, proto) extern proto name
    #endif

    USE_GL_FUNC(glBindBuffer, PFNGLBINDBUFFERPROC);
    USE_GL_FUNC(glDeleteBuffers, PFNGLDELETEBUFFERSPROC);
    USE_GL_FUNC(glBufferData, PFNGLBUFFERDATAPROC);
    USE_GL_FUNC(glBufferSubData, PFNGLBUFFERSUBDATAPROC);
    USE_GL_FUNC(glGenBuffers, PFNGLGENBUFFERSPROC);
    USE_GL_FUNC(glCreateProgram, PFNGLCREATEPROGRAMPROC);
    USE_GL_FUNC(glBindProgramARB, PFNGLBINDPROGRAMARBPROC);
    USE_GL_FUNC(glGenProgramsARB, PFNGLGENPROGRAMSARBPROC);
    USE_GL_FUNC(glDeleteProgramsARB, PFNGLDELETEPROGRAMSARBPROC);
    USE_GL_FUNC(glDeleteProgram, PFNGLDELETEPROGRAMPROC);
    USE_GL_FUNC(glGetProgramInfoLog, PFNGLGETPROGRAMINFOLOGPROC);
    USE_GL_FUNC(glGetProgramiv, PFNGLGETPROGRAMIVPROC);
    USE_GL_FUNC(glProgramParameteriEXT, PFNGLPROGRAMPARAMETERIEXTPROC);
    USE_GL_FUNC(glProgramStringARB, PFNGLPROGRAMSTRINGARBPROC);
    USE_GL_FUNC(glUnmapBuffer, PFNGLUNMAPBUFFERPROC);
    USE_GL_FUNC(glMapBuffer, PFNGLMAPBUFFERPROC);
    USE_GL_FUNC(glGetBufferParameteriv, PFNGLGETBUFFERPARAMETERIVPROC);
    USE_GL_FUNC(glLinkProgram, PFNGLLINKPROGRAMPROC);
    USE_GL_FUNC(glUseProgram, PFNGLUSEPROGRAMPROC);
    USE_GL_FUNC(glAttachShader, PFNGLATTACHSHADERPROC);
    USE_GL_FUNC(glCreateShader, PFNGLCREATESHADERPROC);
    USE_GL_FUNC(glShaderSource, PFNGLSHADERSOURCEPROC);
    USE_GL_FUNC(glCompileShader, PFNGLCOMPILESHADERPROC);
    USE_GL_FUNC(glDeleteShader, PFNGLDELETESHADERPROC);
    USE_GL_FUNC(glGetShaderInfoLog, PFNGLGETSHADERINFOLOGPROC);
    USE_GL_FUNC(glGetShaderiv, PFNGLGETSHADERIVPROC);
    USE_GL_FUNC(glUniform1i, PFNGLUNIFORM1IPROC);
    USE_GL_FUNC(glUniform1f, PFNGLUNIFORM1FPROC);
    USE_GL_FUNC(glUniform2f, PFNGLUNIFORM2FPROC);
    USE_GL_FUNC(glUniform3f, PFNGLUNIFORM3FPROC);
    USE_GL_FUNC(glUniform4f, PFNGLUNIFORM4FPROC);
    USE_GL_FUNC(glUniform1fv, PFNGLUNIFORM1FVPROC);
    USE_GL_FUNC(glUniform2fv, PFNGLUNIFORM2FVPROC);
    USE_GL_FUNC(glUniform3fv, PFNGLUNIFORM3FVPROC);
    USE_GL_FUNC(glUniform4fv, PFNGLUNIFORM4FVPROC);
    USE_GL_FUNC(glUniformMatrix4fv, PFNGLUNIFORMMATRIX4FVPROC);
    USE_GL_FUNC(glSecondaryColor3fv, PFNGLSECONDARYCOLOR3FVPROC);
    USE_GL_FUNC(glGetUniformLocation, PFNGLGETUNIFORMLOCATIONPROC);
    USE_GL_FUNC(glGenFramebuffersEXT, PFNGLGENFRAMEBUFFERSEXTPROC);
    USE_GL_FUNC(glBindFramebufferEXT, PFNGLBINDFRAMEBUFFEREXTPROC);
    USE_GL_FUNC(glDeleteFramebuffersEXT, PFNGLDELETEFRAMEBUFFERSEXTPROC);
    USE_GL_FUNC(glCheckFramebufferStatusEXT, PFNGLCHECKFRAMEBUFFERSTATUSEXTPROC);
    USE_GL_FUNC(glGetFramebufferAttachmentParameterivEXT, PFNGLGETFRAMEBUFFERATTACHMENTPARAMETERIVEXTPROC);
    USE_GL_FUNC(glFramebufferTexture1DEXT, PFNGLFRAMEBUFFERTEXTURE1DEXTPROC);
    USE_GL_FUNC(glFramebufferTexture2DEXT, PFNGLFRAMEBUFFERTEXTURE2DEXTPROC);
    USE_GL_FUNC(glFramebufferTexture3DEXT, PFNGLFRAMEBUFFERTEXTURE3DEXTPROC);
    USE_GL_FUNC(glGenerateMipmapEXT, PFNGLGENERATEMIPMAPEXTPROC);
    USE_GL_FUNC(glGenRenderbuffersEXT, PFNGLGENRENDERBUFFERSEXTPROC);
    USE_GL_FUNC(glDeleteRenderbuffersEXT, PFNGLDELETERENDERBUFFERSEXTPROC);
    USE_GL_FUNC(glBindRenderbufferEXT, PFNGLBINDRENDERBUFFEREXTPROC);
    USE_GL_FUNC(glRenderbufferStorageEXT, PFNGLRENDERBUFFERSTORAGEEXTPROC);
    USE_GL_FUNC(glFramebufferRenderbufferEXT, PFNGLFRAMEBUFFERRENDERBUFFEREXTPROC);
    USE_GL_FUNC(glClampColorARB, PFNGLCLAMPCOLORARBPROC);
    USE_GL_FUNC(glBindFragDataLocationEXT, PFNGLBINDFRAGDATALOCATIONEXTPROC);

#if !defined(GLX_EXTENSION_NAME) || !defined(GL_VERSION_1_3)
    USE_GL_FUNC(glActiveTexture, PFNGLACTIVETEXTUREPROC);
    USE_GL_FUNC(glClientActiveTexture, PFNGLACTIVETEXTUREPROC);
#endif

    #undef USE_GL_FUNC
#endif /*__linux__ */
}


namespace __HelperGL {
    namespace __Int {
        static std::vector<std::string> split(const std::string &str)
        {
            std::istringstream ss(str);
            std::istream_iterator<std::string> it(ss);
            return std::vector<std::string> (it, std::istream_iterator<std::string>());
        }

        /* Sort the vector passed by reference */
        template<typename T> static inline void sort(std::vector<T> &a)
        {
            std::sort(a.begin(), a.end());
        }

        /* Compare two vectors */
        template<typename T> static int equals(std::vector<T> a, std::vector<T> b)
        {
            if (a.size() != b.size()) return 0;
            sort(a);
            sort(b);

            return std::equal(a.begin(), a.end(), b.begin());
        }

        template<typename T> static std::vector<T> getIntersection(std::vector<T> a, std::vector<T> b)
        {
            sort(a);
            sort(b);

            std::vector<T> rc;
            std::set_intersection(a.begin(), a.end(), b.begin(), b.end(),
                             std::back_inserter<std::vector<std::string> >(rc));
            return rc;
        }

        static std::vector<std::string> getGLExtensions()
        {
            std::string extensionsStr( (const char *)glGetString(GL_EXTENSIONS));
            return split (extensionsStr);
        }
    }

    static int areGLExtensionsSupported(const std::string &extensions)
    {
        std::vector<std::string> all = __Int::getGLExtensions();

        std::vector<std::string> requested = __Int::split(extensions);
        std::vector<std::string> matched = __Int::getIntersection(all, requested);

        return __Int::equals(matched, requested);
    }

    static int isGLVersionSupported(unsigned reqMajor, unsigned reqMinor)
    {
#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
        if (glewInit() != GLEW_OK)
        {
            std::cerr << "glewInit() failed!" << std::endl;
            return 0;
        }
#endif
        std::string version ((const char *) glGetString (GL_VERSION));
        std::stringstream stream (version);
        unsigned major, minor;
        char dot;

        stream >> major >> dot >> minor;

        assert (dot == '.');
        return major > reqMajor || (major == reqMajor && minor >= reqMinor);
    }
} /* of namespace __HelperGL*/

using namespace __HelperGL;

#endif /*HELPER_GL_H*/
