/*
 * Copyright 1993-2013 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

//
// Template math library for common 3D functionality
//
// This code is in part deriver from glh, a cross platform glut helper library.
// The copyright for glh follows this notice.
//
// Copyright (c) NVIDIA Corporation. All rights reserved.
////////////////////////////////////////////////////////////////////////////////

/*
    Copyright (c) 2000 Cass Everitt
    Copyright (c) 2000 NVIDIA Corporation
    All rights reserved.

    Redistribution and use in source and binary forms, with or
    without modification, are permitted provided that the following
    conditions are met:

     * Redistributions of source code must retain the above
       copyright notice, this list of conditions and the following
       disclaimer.

     * Redistributions in binary form must reproduce the above
       copyright notice, this list of conditions and the following
       disclaimer in the documentation and/or other materials
       provided with the distribution.

     * The names of contributors to this software may not be used
       to endorse or promote products derived from this software
       without specific prior written permission.

       THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
       ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
       LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
       FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
       REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
       INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
       BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
       LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
       CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
       LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
       ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
       POSSIBILITY OF SUCH DAMAGE.


    Cass Everitt - cass@r3.nu
*/

#ifndef NV_MATH_H
#define NV_MATH_H

#include <math.h>

#include <nvVector.h>
#include <nvMatrix.h>
#include <nvQuaternion.h>

#define NV_PI   float(3.1415926535897932384626433832795)

namespace nv
{

    typedef vec2<float> vec2f;
    typedef vec3<float> vec3f;
    typedef vec3<int> vec3i;
    typedef vec3<unsigned int> vec3ui;
    typedef vec4<float> vec4f;
    typedef matrix4<float> matrix4f;
    typedef quaternion<float> quaternionf;


    inline void applyRotation(const quaternionf &r)
    {
        float angle;
        vec3f axis;
        r.get_value(axis, angle);
        glRotatef(angle/3.1415926f * 180.0f, axis[0], axis[1], axis[2]);
    }



};

#endif
