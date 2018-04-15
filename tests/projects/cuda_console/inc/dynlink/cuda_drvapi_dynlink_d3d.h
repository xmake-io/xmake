/**
 * Copyright 1993-2013 NVIDIA Corporation.  All rights reserved.
 *
 * Please refer to the NVIDIA end user license agreement (EULA) associated
 * with this source code for terms and conditions that govern your use of
 * this software. Any use, reproduction, disclosure, or distribution of
 * this software and related documentation outside the terms of the EULA
 * is strictly prohibited.
 *
 */

#ifndef __cuda_drvapi_dynlink_d3d_h__
#define __cuda_drvapi_dynlink_d3d_h__

#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
#pragma warning(disable: 4312)

#if defined (CUDA_INIT_D3D9) || defined(CUDA_INIT_D3D10) || defined(CUDA_INIT_D3D11)
#include <Windows.h>
#include <mmsystem.h>
#endif

#ifdef CUDA_INIT_D3D9
#include <d3dx9.h>
#pragma warning( disable : 4996 ) // disable deprecated warning 
#include <strsafe.h>
#pragma warning( default : 4996 )

/**
 * CUDA 2.x compatibility - Flags to register a D3D9 graphics resource
 */
typedef enum CUd3d9register_flags_enum
{
    CU_D3D9_REGISTER_FLAGS_NONE  = 0x00,
    CU_D3D9_REGISTER_FLAGS_ARRAY = 0x01,
} CUd3d9register_flags;

/**
 * CUDA 2.x compatibility - Flags for D3D9 mapping and unmapping interop resources
 */
typedef enum CUd3d9map_flags_enum
{
    CU_D3D9_MAPRESOURCE_FLAGS_NONE         = 0x00,
    CU_D3D9_MAPRESOURCE_FLAGS_READONLY     = 0x01,
    CU_D3D9_MAPRESOURCE_FLAGS_WRITEDISCARD = 0x02,
} CUd3d9map_flags;

// D3D9/CUDA interop (CUDA 1.x compatible API). These functions are deprecated, please use the ones below
typedef CUresult CUDAAPI tcuD3D9Begin(IDirect3DDevice9 *pDevice);
typedef CUresult CUDAAPI tcuD3D9End(void);
typedef CUresult CUDAAPI tcuD3D9RegisterVertexBuffer(IDirect3DVertexBuffer9 *pVB);
typedef CUresult CUDAAPI tcuD3D9MapVertexBuffer(CUdeviceptr *pDevPtr, unsigned int *pSize, IDirect3DVertexBuffer9 *pVB);
typedef CUresult CUDAAPI tcuD3D9UnmapVertexBuffer(IDirect3DVertexBuffer9 *pVB);
typedef CUresult CUDAAPI tcuD3D9UnregisterVertexBuffer(IDirect3DVertexBuffer9 *pVB);

// D3D9/CUDA interop (CUDA 2.x compatible)
typedef CUresult CUDAAPI tcuD3D9GetDirect3DDevice(IDirect3DDevice9 **ppD3DDevice);
typedef CUresult CUDAAPI tcuD3D9RegisterResource(IDirect3DResource9 *pResource, unsigned int Flags);
typedef CUresult CUDAAPI tcuD3D9UnregisterResource(IDirect3DResource9 *pResource);

typedef CUresult CUDAAPI tcuD3D9MapResources(unsigned int count, IDirect3DResource9 **ppResource);
typedef CUresult CUDAAPI tcuD3D9UnmapResources(unsigned int count, IDirect3DResource9 **ppResource);
typedef CUresult CUDAAPI tcuD3D9ResourceSetMapFlags(IDirect3DResource9 *pResource, unsigned int Flags);

typedef CUresult CUDAAPI tcuD3D9ResourceGetSurfaceDimensions(unsigned int *pWidth, unsigned int *pHeight, unsigned int *pDepth, IDirect3DResource9 *pResource, unsigned int Face, unsigned int Level);
typedef CUresult CUDAAPI tcuD3D9ResourceGetMappedArray(CUarray *pArray, IDirect3DResource9 *pResource, unsigned int Face, unsigned int Level);
typedef CUresult CUDAAPI tcuD3D9ResourceGetMappedPointer(CUdeviceptr *pDevPtr, IDirect3DResource9 *pResource, unsigned int Face, unsigned int Level);
typedef CUresult CUDAAPI tcuD3D9ResourceGetMappedSize(unsigned int *pSize, IDirect3DResource9 *pResource, unsigned int Face, unsigned int Level);
typedef CUresult CUDAAPI tcuD3D9ResourceGetMappedPitch(unsigned int *pPitch, unsigned int *pPitchSlice, IDirect3DResource9 *pResource, unsigned int Face, unsigned int Level);

// D3D9/CUDA interop (CUDA 2.0+)
typedef CUresult CUDAAPI tcuD3D9GetDevice(CUdevice *pCudaDevice, const char *pszAdapterName);
typedef CUresult CUDAAPI tcuD3D9CtxCreate(CUcontext *pCtx, CUdevice *pCudaDevice, unsigned int Flags, IDirect3DDevice9 *pD3DDevice);
typedef CUresult CUDAAPI tcuGraphicsD3D9RegisterResource(CUgraphicsResource *pCudaResource, IDirect3DResource9 *pD3DResource, unsigned int Flags);
#endif

#ifdef CUDA_INIT_D3D10
#include <dxgi.h>
#include <d3d10_1.h>
#include <d3d10.h>
#include <d3dx10.h>

#pragma warning( disable : 4996 ) // disable deprecated warning 
#include <strsafe.h>
#pragma warning( default : 4996 )

// D3D11/CUDA interop (CUDA 3.0)
typedef CUresult CUDAAPI tcuD3D10GetDevice(CUdevice *pCudaDevice, IDXGIAdapter *pAdapter);
typedef CUresult CUDAAPI tcuD3D10CtxCreate(CUcontext *pCtx, CUdevice *pCudaDevice, unsigned int Flags, ID3D10Device *pD3DDevice);
typedef CUresult CUDAAPI tcuGraphicsD3D10RegisterResource(CUgraphicsResource *pCudaResource, ID3D10Resource *pD3DResource, unsigned int Flags);
#endif // CUDA_INIT_D3D10

#ifdef CUDA_INIT_D3D11
#include <dxgi.h>
#include <d3d11.h>
#include <d3dx11.h>

#pragma warning( disable : 4996 ) // disable deprecated warning 
#include <strsafe.h>
#pragma warning( default : 4996 )

// D3D11/CUDA interop (CUDA 3.0)
typedef CUresult CUDAAPI tcuD3D11GetDevice(CUdevice *pCudaDevice, IDXGIAdapter *pAdapter);
typedef CUresult CUDAAPI tcuD3D11CtxCreate(CUcontext *pCtx, CUdevice *pCudaDevice, unsigned int Flags, ID3D11Device *pD3DDevice);
typedef CUresult CUDAAPI tcuGraphicsD3D11RegisterResource(CUgraphicsResource *pCudaResource, ID3D11Resource *pD3DResource, unsigned int Flags);
#endif // CUDA_INIT_D3D11

#endif // WIN32

#endif // __cuda_drvapi_dynlink_cuda_d3d_h__
