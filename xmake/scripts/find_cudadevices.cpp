#include <cuda_runtime.h>
#include <stdio.h>
#include <stdlib.h>

#ifndef PRINT_SUFFIX
#define PRINT_SUFFIX "<find_cudadevices>"
#endif

#define MY_CUDA_VER (__CUDACC_VER_MAJOR__ * 100 + __CUDACC_VER_MINOR__)

inline void check(cudaError_t result)
{
    if (result)
    {
        fprintf(stderr, PRINT_SUFFIX "%s (%s)", cudaGetErrorName(result), cudaGetErrorString(result));
        cudaDeviceReset();
        // Make sure we call CUDA Device Reset before exiting
        exit(0);
    }
}

inline void print_value(unsigned long long value)
{
    printf("%llu", value);
}

inline void print_value(unsigned long value)
{
    printf("%lu", value);
}

inline void print_value(unsigned int value)
{
    printf("%u", value);
}

inline void print_value(bool value)
{
    printf(value ? "true" : "false");
}

inline void print_value(int value)
{
    printf("%d", value);
}

template <typename T, size_t len>
inline void print_value(const T (&value)[len])
{
    printf("(");
    for (size_t i = 0; i < len - 1; i++)
    {
        print_value(value[i]);
        printf(", ");
    }
    print_value(value[len - 1]);
    printf(")");
}

inline void print_value(const void *value)
{
    printf("\"%s\"", (const char *)value);
}

template <size_t len>
inline void print_value(const char (&value)[len])
{
    printf("\"");
    for (size_t i = 0; i < len; i++)
        printf("%02hhx", value[i]);
    printf("\"");
}

template <>
inline void print_value<16>(const char (&value)[16])
{
    // speicalized for uuid
    printf("\"%02hhx%02hhx%02hhx%02hhx-%02hhx%02hhx-%02hhx%02hhx-%02hhx%02hhx-%02hhx%02hhx%02hhx%02hhx%02hhx%02hhx\"",
           value[0], value[1], value[2], value[3],
           value[4], value[5], value[6], value[7],
           value[8], value[9], value[10], value[11],
           value[12], value[13], value[14], value[15]);
}

#if MY_CUDA_VER >= 1000
inline void print_value(const cudaUUID_t &value)
{
    print_value(value.bytes);
}
#endif

template <typename T>
inline void print_property(const char *name, const T &value)
{
    printf(PRINT_SUFFIX "    %s = ", name);
    print_value(value);
    printf("\n");
}

inline void print_device(int id)
{
    cudaDeviceProp deviceProp;
    check(cudaGetDeviceProperties(&deviceProp, id));

#define PRINT_PROPERTY(name) print_property(#name, deviceProp.name)
#define PRINT_BOOL_PROPERTY(name) print_property(#name, static_cast<bool>(deviceProp.name))
#define PRINT_STR_PROPERTY(name) print_property(#name, static_cast<const void *>(deviceProp.name))
    // cuda 8.0
    PRINT_STR_PROPERTY(name);
    PRINT_PROPERTY(totalGlobalMem);
    PRINT_PROPERTY(sharedMemPerBlock);
    PRINT_PROPERTY(regsPerBlock);
    PRINT_PROPERTY(warpSize);
    PRINT_PROPERTY(memPitch);
    PRINT_PROPERTY(maxThreadsPerBlock);
    PRINT_PROPERTY(maxThreadsDim);
    PRINT_PROPERTY(maxGridSize);
    PRINT_PROPERTY(clockRate);
    PRINT_PROPERTY(totalConstMem);
    PRINT_PROPERTY(major);
    PRINT_PROPERTY(minor);
    PRINT_PROPERTY(textureAlignment);
    PRINT_PROPERTY(texturePitchAlignment);
    PRINT_BOOL_PROPERTY(deviceOverlap);
    PRINT_PROPERTY(multiProcessorCount);
    PRINT_BOOL_PROPERTY(kernelExecTimeoutEnabled);
    PRINT_BOOL_PROPERTY(integrated);
    PRINT_BOOL_PROPERTY(canMapHostMemory);
    PRINT_PROPERTY(computeMode);
    PRINT_PROPERTY(maxTexture1D);
    PRINT_PROPERTY(maxTexture1DMipmap);
    PRINT_PROPERTY(maxTexture1DLinear);
    PRINT_PROPERTY(maxTexture2D);
    PRINT_PROPERTY(maxTexture2DMipmap);
    PRINT_PROPERTY(maxTexture2DLinear);
    PRINT_PROPERTY(maxTexture2DGather);
    PRINT_PROPERTY(maxTexture3D);
    PRINT_PROPERTY(maxTexture3DAlt);
    PRINT_PROPERTY(maxTextureCubemap);
    PRINT_PROPERTY(maxTexture1DLayered);
    PRINT_PROPERTY(maxTexture2DLayered);
    PRINT_PROPERTY(maxTextureCubemapLayered);
    PRINT_PROPERTY(maxSurface1D);
    PRINT_PROPERTY(maxSurface2D);
    PRINT_PROPERTY(maxSurface3D);
    PRINT_PROPERTY(maxSurface1DLayered);
    PRINT_PROPERTY(maxSurface2DLayered);
    PRINT_PROPERTY(maxSurfaceCubemap);
    PRINT_PROPERTY(maxSurfaceCubemapLayered);
    PRINT_PROPERTY(surfaceAlignment);
    PRINT_BOOL_PROPERTY(concurrentKernels);
    PRINT_BOOL_PROPERTY(ECCEnabled);
    PRINT_PROPERTY(pciBusID);
    PRINT_PROPERTY(pciDeviceID);
    PRINT_PROPERTY(pciDomainID);
    PRINT_BOOL_PROPERTY(tccDriver);
    PRINT_PROPERTY(asyncEngineCount);
    PRINT_BOOL_PROPERTY(unifiedAddressing);
    PRINT_PROPERTY(memoryClockRate);
    PRINT_PROPERTY(memoryBusWidth);
    PRINT_PROPERTY(l2CacheSize);
    PRINT_PROPERTY(maxThreadsPerMultiProcessor);
    PRINT_BOOL_PROPERTY(streamPrioritiesSupported);
    PRINT_BOOL_PROPERTY(globalL1CacheSupported);
    PRINT_BOOL_PROPERTY(localL1CacheSupported);
    PRINT_PROPERTY(sharedMemPerMultiprocessor);
    PRINT_PROPERTY(regsPerMultiprocessor);
    PRINT_BOOL_PROPERTY(isMultiGpuBoard);
    PRINT_PROPERTY(multiGpuBoardGroupID);
    PRINT_PROPERTY(singleToDoublePrecisionPerfRatio);
    PRINT_BOOL_PROPERTY(pageableMemoryAccess);
    PRINT_BOOL_PROPERTY(concurrentManagedAccess);
    PRINT_BOOL_PROPERTY(managedMemory);

#if MY_CUDA_VER >= 900
    // Added in cuda 9.0
    PRINT_BOOL_PROPERTY(computePreemptionSupported);
    PRINT_BOOL_PROPERTY(canUseHostPointerForRegisteredMem);
    PRINT_BOOL_PROPERTY(cooperativeLaunch);
    PRINT_BOOL_PROPERTY(cooperativeMultiDeviceLaunch);
    PRINT_PROPERTY(sharedMemPerBlockOptin);
#endif

#if MY_CUDA_VER >= 902
    // Added in cuda 9.2
    PRINT_BOOL_PROPERTY(pageableMemoryAccessUsesHostPageTables);
    PRINT_BOOL_PROPERTY(directManagedMemAccessFromHost);
#endif

#if MY_CUDA_VER >= 1000
    // Added in cuda 10.0
    PRINT_PROPERTY(uuid);
    PRINT_PROPERTY(luid);
    PRINT_PROPERTY(luidDeviceNodeMask);
#endif
}

int main(int argc, char *argv[])
{
    printf("\n");
    fprintf(stderr, "\n");

    int count = 0;
    check(cudaGetDeviceCount(&count));
    for (int i = 0; i < count; i++)
    {
        printf(PRINT_SUFFIX "DEVICE #%d\n", i);
        print_device(i);
    }
    return 0;
}
