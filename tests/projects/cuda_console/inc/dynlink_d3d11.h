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

//--------------------------------------------------------------------------------------
// File: dynlink_d3d11.h
//
// Shortcut macros and functions for using DX objects
//
// Copyright (c) Microsoft Corporation. All rights reserved
//--------------------------------------------------------------------------------------

#ifndef _DYNLINK_D3D11_H_
#define _DYNLINK_D3D11_H_

// Standard Windows includes
#include <windows.h>
#include <initguid.h>
#include <assert.h>
#include <wchar.h>
#include <mmsystem.h>
#include <commctrl.h> // for InitCommonControls() 
#include <shellapi.h> // for ExtractIcon()
#include <new.h>      // for placement new
#include <shlobj.h>
#include <math.h>
#include <limits.h>
#include <stdio.h>

// CRT's memory leak detection
#if defined(DEBUG) || defined(_DEBUG)
#include <crtdbg.h>
#endif

// Direct3D9 includes
//#include <d3d9.h>
//#include <d3dx9.h>

// Direct3D10 includes
#include <dxgi.h>
#include <d3d11.h>
#include <d3dx11.h>
// #include <..\Samples\C++\Effects11\Inc\d3dx11effect.h>

// XInput includes
#include <xinput.h>

// HRESULT translation for Direct3D10 and other APIs
#include <dxerr.h>

// strsafe.h deprecates old unsecure string functions.  If you
// really do not want to it to (not recommended), then uncomment the next line
//#define STRSAFE_NO_DEPRECATE

#ifndef STRSAFE_NO_DEPRECATE
#pragma deprecated("strncpy")
#pragma deprecated("wcsncpy")
#pragma deprecated("_tcsncpy")
#pragma deprecated("wcsncat")
#pragma deprecated("strncat")
#pragma deprecated("_tcsncat")
#endif

#pragma warning( disable : 4996 ) // disable deprecated warning 
#include <strsafe.h>
#pragma warning( default : 4996 )

typedef HRESULT(WINAPI *LPCREATEDXGIFACTORY)(REFIID, void **);
typedef HRESULT(WINAPI *LPD3D11CREATEDEVICEANDSWAPCHAIN)(__in_opt IDXGIAdapter *pAdapter, D3D_DRIVER_TYPE DriverType, HMODULE Software, UINT Flags, __in_ecount_opt(FeatureLevels) CONST D3D_FEATURE_LEVEL *pFeatureLevels, UINT FeatureLevels, UINT SDKVersion, __in_opt CONST DXGI_SWAP_CHAIN_DESC *pSwapChainDesc, __out_opt IDXGISwapChain **ppSwapChain, __out_opt ID3D11Device **ppDevice, __out_opt D3D_FEATURE_LEVEL *pFeatureLevel, __out_opt ID3D11DeviceContext **ppImmediateContext);
typedef HRESULT(WINAPI *LPD3D11CREATEDEVICE)(IDXGIAdapter *, D3D_DRIVER_TYPE, HMODULE, UINT32, D3D_FEATURE_LEVEL *, UINT, UINT32, ID3D11Device **, D3D_FEATURE_LEVEL *, ID3D11DeviceContext **);
typedef void (WINAPI *LPD3DX11COMPILEFROMMEMORY)(LPCSTR pSrcData, SIZE_T SrcDataLen, LPCSTR pFileName, CONST D3D10_SHADER_MACRO *pDefines, LPD3D10INCLUDE pInclude,
                                                 LPCSTR pFunctionName, LPCSTR pProfile, UINT Flags1, UINT Flags2, ID3DX11ThreadPump *pPump, ID3D10Blob **ppShader, ID3D10Blob **ppErrorMsgs, HRESULT *pHResult);

static HMODULE                              s_hModDXGI = NULL;
static LPCREATEDXGIFACTORY                  sFnPtr_CreateDXGIFactory = NULL;
static HMODULE                              s_hModD3D11 = NULL;
static HMODULE                              s_hModD3DX11 = NULL;
static LPD3D11CREATEDEVICE                  sFnPtr_D3D11CreateDevice = NULL;
static LPD3D11CREATEDEVICEANDSWAPCHAIN      sFnPtr_D3D11CreateDeviceAndSwapChain = NULL;
static LPD3DX11COMPILEFROMMEMORY            sFnPtr_D3DX11CompileFromMemory = NULL;

// unload the D3D10 DLLs
static bool dynlinkUnloadD3D11API(void)
{
    if (s_hModDXGI)
    {
        FreeLibrary(s_hModDXGI);
        s_hModDXGI = NULL;
    }

    if (s_hModD3D11)
    {
        FreeLibrary(s_hModD3D11);
        s_hModD3D11 = NULL;
    }

    if (s_hModD3DX11)
    {
        FreeLibrary(s_hModD3DX11);
        s_hModD3DX11 = NULL;
    }

    return true;
}

// Dynamically load the D3D11 DLLs loaded and map the function pointers
static bool dynlinkLoadD3D11API(void)
{
    // If both modules are non-NULL, this function has already been called.  Note
    // that this doesn't guarantee that all ProcAddresses were found.
    if (s_hModD3D11 != NULL && s_hModD3DX11 != NULL && s_hModDXGI != NULL)
    {
        return true;
    }

#if 1
    // This may fail if Direct3D 11 isn't installed
    s_hModD3D11 = LoadLibrary("d3d11.dll");

    if (s_hModD3D11 != NULL)
    {
        sFnPtr_D3D11CreateDevice = (LPD3D11CREATEDEVICE)GetProcAddress(s_hModD3D11, "D3D11CreateDevice");
        sFnPtr_D3D11CreateDeviceAndSwapChain = (LPD3D11CREATEDEVICEANDSWAPCHAIN)GetProcAddress(s_hModD3D11, "D3D11CreateDeviceAndSwapChain");
    }

    // first try to load D3DX11CompileFromMemory from DirectX 2010 June
    s_hModD3DX11 = LoadLibrary("D3DX11d_43.dll");

    if (s_hModD3DX11 != NULL)
    {
        sFnPtr_D3DX11CompileFromMemory = (LPD3DX11COMPILEFROMMEMORY)     GetProcAddress(s_hModD3DX11, "D3DX11CompileFromMemory");
    }
    else    // if absent try to take it from DirectX 2010 Feb
    {
        s_hModD3DX11 = LoadLibrary("D3DX11d_42.dll");

        if (s_hModD3DX11 != NULL)
        {
            sFnPtr_D3DX11CompileFromMemory = (LPD3DX11COMPILEFROMMEMORY)     GetProcAddress(s_hModD3DX11, "D3DX11CompileFromMemory");
        }
    }

    if (!sFnPtr_CreateDXGIFactory)
    {
        s_hModDXGI = LoadLibrary("dxgi.dll");

        if (s_hModDXGI)
        {
            sFnPtr_CreateDXGIFactory = (LPCREATEDXGIFACTORY)GetProcAddress(s_hModDXGI, "CreateDXGIFactory1");
        }

        return (s_hModDXGI != NULL) && (s_hModD3D11 != NULL);
    }

    return (s_hModD3D11 != NULL);
#else
    sFnPtr_D3D11CreateDevice = (LPD3D11CREATEDEVICE)D3D11CreateDeviceAndSwapChain;
    sFnPtr_D3D11CreateDeviceAndSwapChain = (LPD3D11CREATEDEVICEANDSWAPCHAIN)D3D11CreateDeviceAndSwapChain;
    //sFnPtr_D3DX11CreateEffectFromMemory  = ( LPD3DX11CREATEEFFECTFROMMEMORY )D3DX11CreateEffectFromMemory;
    sFnPtr_D3DX11CompileFromMemory = (LPD3DX11COMPILEFROMMEMORY)D3DX11CompileFromMemory;
    sFnPtr_CreateDXGIFactory = (LPCREATEDXGIFACTORY)CreateDXGIFactory;
    return true;
#endif
    return true;
}

#endif
