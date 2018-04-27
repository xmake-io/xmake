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

#pragma once

#ifndef _RENDERCHECK_D3D10_H_
#define _RENDERCHECK_D3D10_H_

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <d3d10.h>
#include <d3dx10.h>

class CheckRenderD3D10
{
    public:

        CheckRenderD3D10() {}

        static HRESULT ActiveRenderTargetToPPM(ID3D10Device  *pDevice, const char *zFileName);
        static HRESULT ResourceToPPM(ID3D10Device *pDevice, ID3D10Resource *pResource, const char *zFileName);

        static bool PPMvsPPM(const char *src_file, const char *ref_file, const char *exec_path,
                             const float epsilon, const float threshold = 0.0f);
};

#endif