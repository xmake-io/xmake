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

#ifndef __cuda_drvapi_dynlink_cuda_h__
#define __cuda_drvapi_dynlink_cuda_h__

#include <stdlib.h>

/**
 * CUDA API versioning support
 */
#define __CUDA_API_VERSION 4000

/**
 * \defgroup CUDA_DRIVER CUDA Driver API
 *
 * This section describes the low-level CUDA driver application programming
 * interface.
 *
 * @{
 */

/**
 * \defgroup CUDA_TYPES Data types used by CUDA driver
 * @{
 */

/**
 * CUDA API version number
 */
#define CUDA_VERSION 3020 /* 3.2 */

#ifdef __cplusplus
extern "C" {
#endif

/**
 * CUDA device pointer
 */
#if __CUDA_API_VERSION >= 3020

#if defined(_WIN64) || defined(__LP64__)
typedef unsigned long long CUdeviceptr;
#else
typedef unsigned int CUdeviceptr;
#endif

#endif /* __CUDA_API_VERSION >= 3020 */

typedef int CUdevice;                                     /**< CUDA device */
typedef struct CUctx_st *CUcontext;                       /**< CUDA context */
typedef struct CUmod_st *CUmodule;                        /**< CUDA module */
typedef struct CUfunc_st *CUfunction;                     /**< CUDA function */
typedef struct CUarray_st *CUarray;                       /**< CUDA array */
typedef struct CUtexref_st *CUtexref;                     /**< CUDA texture reference */
typedef struct CUsurfref_st *CUsurfref;                   /**< CUDA surface reference */
typedef struct CUevent_st *CUevent;                       /**< CUDA event */
typedef struct CUstream_st *CUstream;                     /**< CUDA stream */
typedef struct CUgraphicsResource_st *CUgraphicsResource; /**< CUDA graphics interop resource */

typedef struct CUuuid_st                                  /**< CUDA definition of UUID */
{
    char bytes[16];
} CUuuid;

/**
 * Context creation flags
 */
typedef enum CUctx_flags_enum
{
    CU_CTX_SCHED_AUTO          = 0x00, /**< Automatic scheduling */
    CU_CTX_SCHED_SPIN          = 0x01, /**< Set spin as default scheduling */
    CU_CTX_SCHED_YIELD         = 0x02, /**< Set yield as default scheduling */
    CU_CTX_SCHED_BLOCKING_SYNC = 0x04, /**< Set blocking synchronization as default scheduling */
    CU_CTX_BLOCKING_SYNC       = 0x04, /**< Set blocking synchronization as default scheduling \deprecated */
    CU_CTX_MAP_HOST            = 0x08, /**< Support mapped pinned allocations */
    CU_CTX_LMEM_RESIZE_TO_MAX  = 0x10, /**< Keep local memory allocation after launch */
#if __CUDA_API_VERSION < 4000
    CU_CTX_SCHED_MASK          = 0x03,
    CU_CTX_FLAGS_MASK          = 0x1f
#else
    CU_CTX_SCHED_MASK          = 0x07,
    CU_CTX_PRIMARY             = 0x20, /**< Initialize and return the primary context */
    CU_CTX_FLAGS_MASK          = 0x3f
#endif
} CUctx_flags;

/**
 * Event creation flags
 */
typedef enum CUevent_flags_enum
{
    CU_EVENT_DEFAULT        = 0, /**< Default event flag */
    CU_EVENT_BLOCKING_SYNC  = 1, /**< Event uses blocking synchronization */
    CU_EVENT_DISABLE_TIMING = 2  /**< Event will not record timing data */
} CUevent_flags;

/**
 * Array formats
 */
typedef enum CUarray_format_enum
{
    CU_AD_FORMAT_UNSIGNED_INT8  = 0x01, /**< Unsigned 8-bit integers */
    CU_AD_FORMAT_UNSIGNED_INT16 = 0x02, /**< Unsigned 16-bit integers */
    CU_AD_FORMAT_UNSIGNED_INT32 = 0x03, /**< Unsigned 32-bit integers */
    CU_AD_FORMAT_SIGNED_INT8    = 0x08, /**< Signed 8-bit integers */
    CU_AD_FORMAT_SIGNED_INT16   = 0x09, /**< Signed 16-bit integers */
    CU_AD_FORMAT_SIGNED_INT32   = 0x0a, /**< Signed 32-bit integers */
    CU_AD_FORMAT_HALF           = 0x10, /**< 16-bit floating point */
    CU_AD_FORMAT_FLOAT          = 0x20  /**< 32-bit floating point */
} CUarray_format;

/**
 * Texture reference addressing modes
 */
typedef enum CUaddress_mode_enum
{
    CU_TR_ADDRESS_MODE_WRAP   = 0, /**< Wrapping address mode */
    CU_TR_ADDRESS_MODE_CLAMP  = 1, /**< Clamp to edge address mode */
    CU_TR_ADDRESS_MODE_MIRROR = 2, /**< Mirror address mode */
    CU_TR_ADDRESS_MODE_BORDER = 3  /**< Border address mode */
} CUaddress_mode;

/**
 * Texture reference filtering modes
 */
typedef enum CUfilter_mode_enum
{
    CU_TR_FILTER_MODE_POINT  = 0, /**< Point filter mode */
    CU_TR_FILTER_MODE_LINEAR = 1  /**< Linear filter mode */
} CUfilter_mode;

/**
 * Device properties
 */
typedef enum CUdevice_attribute_enum
{
    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_BLOCK = 1,              /**< Maximum number of threads per block */
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_X = 2,                    /**< Maximum block dimension X */
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Y = 3,                    /**< Maximum block dimension Y */
    CU_DEVICE_ATTRIBUTE_MAX_BLOCK_DIM_Z = 4,                    /**< Maximum block dimension Z */
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_X = 5,                     /**< Maximum grid dimension X */
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Y = 6,                     /**< Maximum grid dimension Y */
    CU_DEVICE_ATTRIBUTE_MAX_GRID_DIM_Z = 7,                     /**< Maximum grid dimension Z */
    CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK = 8,        /**< Maximum shared memory available per block in bytes */
    CU_DEVICE_ATTRIBUTE_SHARED_MEMORY_PER_BLOCK = 8,            /**< Deprecated, use CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK */
    CU_DEVICE_ATTRIBUTE_TOTAL_CONSTANT_MEMORY = 9,              /**< Memory available on device for __constant__ variables in a CUDA C kernel in bytes */
    CU_DEVICE_ATTRIBUTE_WARP_SIZE = 10,                         /**< Warp size in threads */
    CU_DEVICE_ATTRIBUTE_MAX_PITCH = 11,                         /**< Maximum pitch in bytes allowed by memory copies */
    CU_DEVICE_ATTRIBUTE_MAX_REGISTERS_PER_BLOCK = 12,           /**< Maximum number of 32-bit registers available per block */
    CU_DEVICE_ATTRIBUTE_REGISTERS_PER_BLOCK = 12,               /**< Deprecated, use CU_DEVICE_ATTRIBUTE_MAX_REGISTERS_PER_BLOCK */
    CU_DEVICE_ATTRIBUTE_CLOCK_RATE = 13,                        /**< Peak clock frequency in kilohertz */
    CU_DEVICE_ATTRIBUTE_TEXTURE_ALIGNMENT = 14,                 /**< Alignment requirement for textures */
    CU_DEVICE_ATTRIBUTE_GPU_OVERLAP = 15,                       /**< Device can possibly copy memory and execute a kernel concurrently */
    CU_DEVICE_ATTRIBUTE_MULTIPROCESSOR_COUNT = 16,              /**< Number of multiprocessors on device */
    CU_DEVICE_ATTRIBUTE_KERNEL_EXEC_TIMEOUT = 17,               /**< Specifies whether there is a run time limit on kernels */
    CU_DEVICE_ATTRIBUTE_INTEGRATED = 18,                        /**< Device is integrated with host memory */
    CU_DEVICE_ATTRIBUTE_CAN_MAP_HOST_MEMORY = 19,               /**< Device can map host memory into CUDA address space */
    CU_DEVICE_ATTRIBUTE_COMPUTE_MODE = 20,                      /**< Compute mode (See ::CUcomputemode for details) */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_WIDTH = 21,           /**< Maximum 1D texture width */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_WIDTH = 22,           /**< Maximum 2D texture width */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_HEIGHT = 23,          /**< Maximum 2D texture height */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_WIDTH = 24,           /**< Maximum 3D texture width */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_HEIGHT = 25,          /**< Maximum 3D texture height */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE3D_DEPTH = 26,           /**< Maximum 3D texture depth */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_WIDTH = 27,     /**< Maximum texture array width */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_HEIGHT = 28,    /**< Maximum texture array height */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE2D_ARRAY_NUMSLICES = 29, /**< Maximum slices in a texture array */
    CU_DEVICE_ATTRIBUTE_SURFACE_ALIGNMENT = 30,                 /**< Alignment requirement for surfaces */
    CU_DEVICE_ATTRIBUTE_CONCURRENT_KERNELS = 31,                /**< Device can possibly execute multiple kernels concurrently */
    CU_DEVICE_ATTRIBUTE_ECC_ENABLED = 32,                       /**< Device has ECC support enabled */
    CU_DEVICE_ATTRIBUTE_PCI_BUS_ID = 33,                        /**< PCI bus ID of the device */
    CU_DEVICE_ATTRIBUTE_PCI_DEVICE_ID = 34,                     /**< PCI device ID of the device */
    CU_DEVICE_ATTRIBUTE_TCC_DRIVER = 35                         /**< Device is using TCC driver model */

#if __CUDA_API_VERSION >= 4000
                                     ,
    CU_DEVICE_ATTRIBUTE_MEMORY_CLOCK_RATE = 36,                 /**< Peak memory clock frequency in kilohertz */
    CU_DEVICE_ATTRIBUTE_GLOBAL_MEMORY_BUS_WIDTH = 37,           /**< Global memory bus width in bits */
    CU_DEVICE_ATTRIBUTE_L2_CACHE_SIZE = 38,                     /**< Size of L2 cache in bytes */
    CU_DEVICE_ATTRIBUTE_MAX_THREADS_PER_MULTIPROCESSOR = 39,    /**< Maximum resident threads per multiprocessor */
    CU_DEVICE_ATTRIBUTE_ASYNC_ENGINE_COUNT = 40,                /**< Number of asynchronous engines */
    CU_DEVICE_ATTRIBUTE_UNIFIED_ADDRESSING = 41,                /**< Device uses shares a unified address space with the host */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_LAYERED_WIDTH = 42,   /**< Maximum 1D layered texture width */
    CU_DEVICE_ATTRIBUTE_MAXIMUM_TEXTURE1D_LAYERED_LAYERS = 43   /**< Maximum layers in a 1D layered texture */
#endif
} CUdevice_attribute;

/**
 * Legacy device properties
 */
typedef struct CUdevprop_st
{
    int maxThreadsPerBlock;     /**< Maximum number of threads per block */
    int maxThreadsDim[3];       /**< Maximum size of each dimension of a block */
    int maxGridSize[3];         /**< Maximum size of each dimension of a grid */
    int sharedMemPerBlock;      /**< Shared memory available per block in bytes */
    int totalConstantMemory;    /**< Constant memory available on device in bytes */
    int SIMDWidth;              /**< Warp size in threads */
    int memPitch;               /**< Maximum pitch in bytes allowed by memory copies */
    int regsPerBlock;           /**< 32-bit registers available per block */
    int clockRate;              /**< Clock frequency in kilohertz */
    int textureAlign;           /**< Alignment requirement for textures */
} CUdevprop;

/**
 * Function properties
 */
typedef enum CUfunction_attribute_enum
{
    /**
     * The maximum number of threads per block, beyond which a launch of the
     * function would fail. This number depends on both the function and the
     * device on which the function is currently loaded.
     */
    CU_FUNC_ATTRIBUTE_MAX_THREADS_PER_BLOCK = 0,

    /**
     * The size in bytes of statically-allocated shared memory required by
     * this function. This does not include dynamically-allocated shared
     * memory requested by the user at runtime.
     */
    CU_FUNC_ATTRIBUTE_SHARED_SIZE_BYTES = 1,

    /**
     * The size in bytes of user-allocated constant memory required by this
     * function.
     */
    CU_FUNC_ATTRIBUTE_CONST_SIZE_BYTES = 2,

    /**
     * The size in bytes of local memory used by each thread of this function.
     */
    CU_FUNC_ATTRIBUTE_LOCAL_SIZE_BYTES = 3,

    /**
     * The number of registers used by each thread of this function.
     */
    CU_FUNC_ATTRIBUTE_NUM_REGS = 4,

    /**
     * The PTX virtual architecture version for which the function was
     * compiled. This value is the major PTX version * 10 + the minor PTX
     * version, so a PTX version 1.3 function would return the value 13.
     * Note that this may return the undefined value of 0 for cubins
     * compiled prior to CUDA 3.0.
     */
    CU_FUNC_ATTRIBUTE_PTX_VERSION = 5,

    /**
     * The binary architecture version for which the function was compiled.
     * This value is the major binary version * 10 + the minor binary version,
     * so a binary version 1.3 function would return the value 13. Note that
     * this will return a value of 10 for legacy cubins that do not have a
     * properly-encoded binary architecture version.
     */
    CU_FUNC_ATTRIBUTE_BINARY_VERSION = 6,

    CU_FUNC_ATTRIBUTE_MAX
} CUfunction_attribute;

/**
 * Function cache configurations
 */
typedef enum CUfunc_cache_enum
{
    CU_FUNC_CACHE_PREFER_NONE    = 0x00, /**< no preference for shared memory or L1 (default) */
    CU_FUNC_CACHE_PREFER_SHARED  = 0x01, /**< prefer larger shared memory and smaller L1 cache */
    CU_FUNC_CACHE_PREFER_L1      = 0x02  /**< prefer larger L1 cache and smaller shared memory */
} CUfunc_cache;

/**
 * Memory types
 */
typedef enum CUmemorytype_enum
{
    CU_MEMORYTYPE_HOST    = 0x01,    /**< Host memory */
    CU_MEMORYTYPE_DEVICE  = 0x02,    /**< Device memory */
    CU_MEMORYTYPE_ARRAY   = 0x03     /**< Array memory */
#if __CUDA_API_VERSION >= 4000
                            ,
    CU_MEMORYTYPE_UNIFIED = 0x04     /**< Unified device or host memory */
#endif
} CUmemorytype;

/**
 * Compute Modes
 */
typedef enum CUcomputemode_enum
{
    CU_COMPUTEMODE_DEFAULT    = 0,  /**< Default compute mode (Multiple contexts allowed per device) */
    CU_COMPUTEMODE_EXCLUSIVE         = 1, /**< Compute-exclusive-thread mode (Only one context used by a single thread can be present on this device at a time) */
    CU_COMPUTEMODE_PROHIBITED        = 2  /**< Compute-prohibited mode (No contexts can be created on this device at this time) */
#if __CUDA_API_VERSION >= 4000
                                       ,
    CU_COMPUTEMODE_EXCLUSIVE_PROCESS = 3  /**< Compute-exclusive-process mode (Only one context used by a single process can be present on this device at a time) */
#endif
} CUcomputemode;

/**
 * Online compiler options
 */
typedef enum CUjit_option_enum
{
    /**
     * Max number of registers that a thread may use.\n
     * Option type: unsigned int
     */
    CU_JIT_MAX_REGISTERS = 0,

    /**
     * IN: Specifies minimum number of threads per block to target compilation
     * for\n
     * OUT: Returns the number of threads the compiler actually targeted.
     * This restricts the resource utilization fo the compiler (e.g. max
     * registers) such that a block with the given number of threads should be
     * able to launch based on register limitations. Note, this option does not
     * currently take into account any other resource limitations, such as
     * shared memory utilization.\n
     * Option type: unsigned int
     */
    CU_JIT_THREADS_PER_BLOCK,

    /**
     * Returns a float value in the option of the wall clock time, in
     * milliseconds, spent creating the cubin\n
     * Option type: float
     */
    CU_JIT_WALL_TIME,

    /**
     * Pointer to a buffer in which to print any log messsages from PTXAS
     * that are informational in nature (the buffer size is specified via
     * option ::CU_JIT_INFO_LOG_BUFFER_SIZE_BYTES) \n
     * Option type: char*
     */
    CU_JIT_INFO_LOG_BUFFER,

    /**
     * IN: Log buffer size in bytes.  Log messages will be capped at this size
     * (including null terminator)\n
     * OUT: Amount of log buffer filled with messages\n
     * Option type: unsigned int
     */
    CU_JIT_INFO_LOG_BUFFER_SIZE_BYTES,

    /**
     * Pointer to a buffer in which to print any log messages from PTXAS that
     * reflect errors (the buffer size is specified via option
     * ::CU_JIT_ERROR_LOG_BUFFER_SIZE_BYTES)\n
     * Option type: char*
     */
    CU_JIT_ERROR_LOG_BUFFER,

    /**
     * IN: Log buffer size in bytes.  Log messages will be capped at this size
     * (including null terminator)\n
     * OUT: Amount of log buffer filled with messages\n
     * Option type: unsigned int
     */
    CU_JIT_ERROR_LOG_BUFFER_SIZE_BYTES,

    /**
     * Level of optimizations to apply to generated code (0 - 4), with 4
     * being the default and highest level of optimizations.\n
     * Option type: unsigned int
     */
    CU_JIT_OPTIMIZATION_LEVEL,

    /**
     * No option value required. Determines the target based on the current
     * attached context (default)\n
     * Option type: No option value needed
     */
    CU_JIT_TARGET_FROM_CUCONTEXT,

    /**
     * Target is chosen based on supplied ::CUjit_target_enum.\n
     * Option type: unsigned int for enumerated type ::CUjit_target_enum
     */
    CU_JIT_TARGET,

    /**
     * Specifies choice of fallback strategy if matching cubin is not found.
     * Choice is based on supplied ::CUjit_fallback_enum.\n
     * Option type: unsigned int for enumerated type ::CUjit_fallback_enum
     */
    CU_JIT_FALLBACK_STRATEGY

} CUjit_option;

/**
 * Online compilation targets
 */
typedef enum CUjit_target_enum
{
    CU_TARGET_COMPUTE_10 = 0,   /**< Compute device class 1.0 */
    CU_TARGET_COMPUTE_11,       /**< Compute device class 1.1 */
    CU_TARGET_COMPUTE_12,       /**< Compute device class 1.2 */
    CU_TARGET_COMPUTE_13,       /**< Compute device class 1.3 */
    CU_TARGET_COMPUTE_20,       /**< Compute device class 2.0 */
    CU_TARGET_COMPUTE_21        /**< Compute device class 2.1 */
} CUjit_target;

/**
 * Cubin matching fallback strategies
 */
typedef enum CUjit_fallback_enum
{
    CU_PREFER_PTX = 0,  /**< Prefer to compile ptx */

    CU_PREFER_BINARY    /**< Prefer to fall back to compatible binary code */

} CUjit_fallback;

/**
 * Flags to register a graphics resource
 */
typedef enum CUgraphicsRegisterFlags_enum
{
    CU_GRAPHICS_REGISTER_FLAGS_NONE          = 0x00,
    CU_GRAPHICS_REGISTER_FLAGS_READ_ONLY     = 0x01,
    CU_GRAPHICS_REGISTER_FLAGS_WRITE_DISCARD = 0x02,
    CU_GRAPHICS_REGISTER_FLAGS_SURFACE_LDST  = 0x04
} CUgraphicsRegisterFlags;

/**
 * Flags for mapping and unmapping interop resources
 */
typedef enum CUgraphicsMapResourceFlags_enum
{
    CU_GRAPHICS_MAP_RESOURCE_FLAGS_NONE          = 0x00,
    CU_GRAPHICS_MAP_RESOURCE_FLAGS_READ_ONLY     = 0x01,
    CU_GRAPHICS_MAP_RESOURCE_FLAGS_WRITE_DISCARD = 0x02
} CUgraphicsMapResourceFlags;

/**
 * Array indices for cube faces
 */
typedef enum CUarray_cubemap_face_enum
{
    CU_CUBEMAP_FACE_POSITIVE_X  = 0x00, /**< Positive X face of cubemap */
    CU_CUBEMAP_FACE_NEGATIVE_X  = 0x01, /**< Negative X face of cubemap */
    CU_CUBEMAP_FACE_POSITIVE_Y  = 0x02, /**< Positive Y face of cubemap */
    CU_CUBEMAP_FACE_NEGATIVE_Y  = 0x03, /**< Negative Y face of cubemap */
    CU_CUBEMAP_FACE_POSITIVE_Z  = 0x04, /**< Positive Z face of cubemap */
    CU_CUBEMAP_FACE_NEGATIVE_Z  = 0x05  /**< Negative Z face of cubemap */
} CUarray_cubemap_face;

/**
 * Limits
 */
typedef enum CUlimit_enum
{
    CU_LIMIT_STACK_SIZE        = 0x00, /**< GPU thread stack size */
    CU_LIMIT_PRINTF_FIFO_SIZE  = 0x01, /**< GPU printf FIFO size */
    CU_LIMIT_MALLOC_HEAP_SIZE  = 0x02  /**< GPU malloc heap size */
} CUlimit;

/**
 * Error codes
 */
typedef enum cudaError_enum
{
    /**
     * The API call returned with no errors. In the case of query calls, this
     * can also mean that the operation being queried is complete (see
     * ::cuEventQuery() and ::cuStreamQuery()).
     */
    CUDA_SUCCESS                              = 0,

    /**
     * This indicates that one or more of the parameters passed to the API call
     * is not within an acceptable range of values.
     */
    CUDA_ERROR_INVALID_VALUE                  = 1,

    /**
     * The API call failed because it was unable to allocate enough memory to
     * perform the requested operation.
     */
    CUDA_ERROR_OUT_OF_MEMORY                  = 2,

    /**
     * This indicates that the CUDA driver has not been initialized with
     * ::cuInit() or that initialization has failed.
     */
    CUDA_ERROR_NOT_INITIALIZED                = 3,

    /**
     * This indicates that the CUDA driver is in the process of shutting down.
     */
    CUDA_ERROR_DEINITIALIZED                  = 4,

    /**
     * This indicates profiling APIs are called while application is running
     * in visual profiler mode.
    */
    CUDA_ERROR_PROFILER_DISABLED           = 5,
    /**
     * This indicates profiling has not been initialized for this context.
     * Call cuProfilerInitialize() to resolve this.
    */
    CUDA_ERROR_PROFILER_NOT_INITIALIZED       = 6,
    /**
     * This indicates profiler has already been started and probably
     * cuProfilerStart() is incorrectly called.
    */
    CUDA_ERROR_PROFILER_ALREADY_STARTED       = 7,
    /**
     * This indicates profiler has already been stopped and probably
     * cuProfilerStop() is incorrectly called.
    */
    CUDA_ERROR_PROFILER_ALREADY_STOPPED       = 8,
    /**
     * This indicates that no CUDA-capable devices were detected by the installed
     * CUDA driver.
     */
    CUDA_ERROR_NO_DEVICE                      = 100,

    /**
     * This indicates that the device ordinal supplied by the user does not
     * correspond to a valid CUDA device.
     */
    CUDA_ERROR_INVALID_DEVICE                 = 101,


    /**
     * This indicates that the device kernel image is invalid. This can also
     * indicate an invalid CUDA module.
     */
    CUDA_ERROR_INVALID_IMAGE                  = 200,

    /**
     * This most frequently indicates that there is no context bound to the
     * current thread. This can also be returned if the context passed to an
     * API call is not a valid handle (such as a context that has had
     * ::cuCtxDestroy() invoked on it). This can also be returned if a user
     * mixes different API versions (i.e. 3010 context with 3020 API calls).
     * See ::cuCtxGetApiVersion() for more details.
     */
    CUDA_ERROR_INVALID_CONTEXT                = 201,

    /**
     * This indicated that the context being supplied as a parameter to the
     * API call was already the active context.
     * \deprecated
     * This error return is deprecated as of CUDA 3.2. It is no longer an
     * error to attempt to push the active context via ::cuCtxPushCurrent().
     */
    CUDA_ERROR_CONTEXT_ALREADY_CURRENT        = 202,

    /**
     * This indicates that a map or register operation has failed.
     */
    CUDA_ERROR_MAP_FAILED                     = 205,

    /**
     * This indicates that an unmap or unregister operation has failed.
     */
    CUDA_ERROR_UNMAP_FAILED                   = 206,

    /**
     * This indicates that the specified array is currently mapped and thus
     * cannot be destroyed.
     */
    CUDA_ERROR_ARRAY_IS_MAPPED                = 207,

    /**
     * This indicates that the resource is already mapped.
     */
    CUDA_ERROR_ALREADY_MAPPED                 = 208,

    /**
     * This indicates that there is no kernel image available that is suitable
     * for the device. This can occur when a user specifies code generation
     * options for a particular CUDA source file that do not include the
     * corresponding device configuration.
     */
    CUDA_ERROR_NO_BINARY_FOR_GPU              = 209,

    /**
     * This indicates that a resource has already been acquired.
     */
    CUDA_ERROR_ALREADY_ACQUIRED               = 210,

    /**
     * This indicates that a resource is not mapped.
     */
    CUDA_ERROR_NOT_MAPPED                     = 211,

    /**
     * This indicates that a mapped resource is not available for access as an
     * array.
     */
    CUDA_ERROR_NOT_MAPPED_AS_ARRAY            = 212,

    /**
     * This indicates that a mapped resource is not available for access as a
     * pointer.
     */
    CUDA_ERROR_NOT_MAPPED_AS_POINTER          = 213,

    /**
     * This indicates that an uncorrectable ECC error was detected during
     * execution.
     */
    CUDA_ERROR_ECC_UNCORRECTABLE              = 214,

    /**
     * This indicates that the ::CUlimit passed to the API call is not
     * supported by the active device.
     */
    CUDA_ERROR_UNSUPPORTED_LIMIT              = 215,

    /**
     * This indicates that the ::CUcontext passed to the API call can
     * only be bound to a single CPU thread at a time but is already
     * bound to a CPU thread.
     */
    CUDA_ERROR_CONTEXT_ALREADY_IN_USE         = 216,

    /**
     * This indicates that the device kernel source is invalid.
     */
    CUDA_ERROR_INVALID_SOURCE                 = 300,

    /**
     * This indicates that the file specified was not found.
     */
    CUDA_ERROR_FILE_NOT_FOUND                 = 301,

    /**
     * This indicates that a link to a shared object failed to resolve.
     */
    CUDA_ERROR_SHARED_OBJECT_SYMBOL_NOT_FOUND = 302,

    /**
     * This indicates that initialization of a shared object failed.
     */
    CUDA_ERROR_SHARED_OBJECT_INIT_FAILED      = 303,

    /**
     * This indicates that an OS call failed.
     */
    CUDA_ERROR_OPERATING_SYSTEM               = 304,


    /**
     * This indicates that a resource handle passed to the API call was not
     * valid. Resource handles are opaque types like ::CUstream and ::CUevent.
     */
    CUDA_ERROR_INVALID_HANDLE                 = 400,


    /**
     * This indicates that a named symbol was not found. Examples of symbols
     * are global/constant variable names, texture names, and surface names.
     */
    CUDA_ERROR_NOT_FOUND                      = 500,


    /**
     * This indicates that asynchronous operations issued previously have not
     * completed yet. This result is not actually an error, but must be indicated
     * differently than ::CUDA_SUCCESS (which indicates completion). Calls that
     * may return this value include ::cuEventQuery() and ::cuStreamQuery().
     */
    CUDA_ERROR_NOT_READY                      = 600,


    /**
     * An exception occurred on the device while executing a kernel. Common
     * causes include dereferencing an invalid device pointer and accessing
     * out of bounds shared memory. The context cannot be used, so it must
     * be destroyed (and a new one should be created). All existing device
     * memory allocations from this context are invalid and must be
     * reconstructed if the program is to continue using CUDA.
     */
    CUDA_ERROR_LAUNCH_FAILED                  = 700,

    /**
     * This indicates that a launch did not occur because it did not have
     * appropriate resources. This error usually indicates that the user has
     * attempted to pass too many arguments to the device kernel, or the
     * kernel launch specifies too many threads for the kernel's register
     * count. Passing arguments of the wrong size (i.e. a 64-bit pointer
     * when a 32-bit int is expected) is equivalent to passing too many
     * arguments and can also result in this error.
     */
    CUDA_ERROR_LAUNCH_OUT_OF_RESOURCES        = 701,

    /**
     * This indicates that the device kernel took too long to execute. This can
     * only occur if timeouts are enabled - see the device attribute
     * ::CU_DEVICE_ATTRIBUTE_KERNEL_EXEC_TIMEOUT for more information. The
     * context cannot be used (and must be destroyed similar to
     * ::CUDA_ERROR_LAUNCH_FAILED). All existing device memory allocations from
     * this context are invalid and must be reconstructed if the program is to
     * continue using CUDA.
     */
    CUDA_ERROR_LAUNCH_TIMEOUT                 = 702,

    /**
     * This error indicates a kernel launch that uses an incompatible texturing
     * mode.
     */
    CUDA_ERROR_LAUNCH_INCOMPATIBLE_TEXTURING  = 703,

    /**
     * This error indicates that a call to ::cuCtxEnablePeerAccess() is
     * trying to re-enable peer access to a context which has already
     * had peer access to it enabled.
     */
    CUDA_ERROR_PEER_ACCESS_ALREADY_ENABLED = 704,

    /**
     * This error indicates that a call to ::cuMemPeerRegister is trying to
     * register memory from a context which has not had peer access
     * enabled yet via ::cuCtxEnablePeerAccess(), or that
     * ::cuCtxDisablePeerAccess() is trying to disable peer access
     * which has not been enabled yet.
     */
    CUDA_ERROR_PEER_ACCESS_NOT_ENABLED    = 705,

    /**
     * This error indicates that a call to ::cuMemPeerRegister is trying to
     * register already-registered memory.
     */
    CUDA_ERROR_PEER_MEMORY_ALREADY_REGISTERED = 706,

    /**
     * This error indicates that a call to ::cuMemPeerUnregister is trying to
     * unregister memory that has not been registered.
     */
    CUDA_ERROR_PEER_MEMORY_NOT_REGISTERED     = 707,

    /**
     * This error indicates that ::cuCtxCreate was called with the flag
     * ::CU_CTX_PRIMARY on a device which already has initialized its
     * primary context.
     */
    CUDA_ERROR_PRIMARY_CONTEXT_ACTIVE         = 708,

    /**
     * This error indicates that the context current to the calling thread
     * has been destroyed using ::cuCtxDestroy, or is a primary context which
     * has not yet been initialized.
     */
    CUDA_ERROR_CONTEXT_IS_DESTROYED           = 709,

    /**
     * This indicates that an unknown internal error has occurred.
     */
    CUDA_ERROR_UNKNOWN                        = 999
} CUresult;

#if __CUDA_API_VERSION >= 4000
/**
 * If set, host memory is portable between CUDA contexts.
 * Flag for ::cuMemHostAlloc()
 */
#define CU_MEMHOSTALLOC_PORTABLE        0x01

/**
 * If set, host memory is mapped into CUDA address space and
 * ::cuMemHostGetDevicePointer() may be called on the host pointer.
 * Flag for ::cuMemHostAlloc()
 */
#define CU_MEMHOSTALLOC_DEVICEMAP       0x02

/**
 * If set, host memory is allocated as write-combined - fast to write,
 * faster to DMA, slow to read except via SSE4 streaming load instruction
 * (MOVNTDQA).
 * Flag for ::cuMemHostAlloc()
 */
#define CU_MEMHOSTALLOC_WRITECOMBINED   0x04

/**
 * If set, host memory is portable between CUDA contexts.
 * Flag for ::cuMemHostRegister()
 */
#define CU_MEMHOSTREGISTER_PORTABLE     0x01

/**
 * If set, host memory is mapped into CUDA address space and
 * ::cuMemHostGetDevicePointer() may be called on the host pointer.
 * Flag for ::cuMemHostRegister()
 */
#define CU_MEMHOSTREGISTER_DEVICEMAP    0x02

/**
 * If set, peer memory is mapped into CUDA address space and
 * ::cuMemPeerGetDevicePointer() may be called on the host pointer.
 * Flag for ::cuMemPeerRegister()
 */
#define CU_MEMPEERREGISTER_DEVICEMAP    0x02
#endif

#if __CUDA_API_VERSION >= 3020

/**
 * 2D memory copy parameters
 */
typedef struct CUDA_MEMCPY2D_st
{
    size_t srcXInBytes;         /**< Source X in bytes */
    size_t srcY;                /**< Source Y */

    CUmemorytype srcMemoryType; /**< Source memory type (host, device, array) */
    const void *srcHost;        /**< Source host pointer */
    CUdeviceptr srcDevice;      /**< Source device pointer */
    CUarray srcArray;           /**< Source array reference */
    size_t srcPitch;            /**< Source pitch (ignored when src is array) */

    size_t dstXInBytes;         /**< Destination X in bytes */
    size_t dstY;                /**< Destination Y */

    CUmemorytype dstMemoryType; /**< Destination memory type (host, device, array) */
    void *dstHost;              /**< Destination host pointer */
    CUdeviceptr dstDevice;      /**< Destination device pointer */
    CUarray dstArray;           /**< Destination array reference */
    size_t dstPitch;            /**< Destination pitch (ignored when dst is array) */

    size_t WidthInBytes;        /**< Width of 2D memory copy in bytes */
    size_t Height;              /**< Height of 2D memory copy */
} CUDA_MEMCPY2D;

/**
 * 3D memory copy parameters
 */
typedef struct CUDA_MEMCPY3D_st
{
    size_t srcXInBytes;         /**< Source X in bytes */
    size_t srcY;                /**< Source Y */
    size_t srcZ;                /**< Source Z */
    size_t srcLOD;              /**< Source LOD */
    CUmemorytype srcMemoryType; /**< Source memory type (host, device, array) */
    const void *srcHost;        /**< Source host pointer */
    CUdeviceptr srcDevice;      /**< Source device pointer */
    CUarray srcArray;           /**< Source array reference */
    void *reserved0;            /**< Must be NULL */
    size_t srcPitch;            /**< Source pitch (ignored when src is array) */
    size_t srcHeight;           /**< Source height (ignored when src is array; may be 0 if Depth==1) */

    size_t dstXInBytes;         /**< Destination X in bytes */
    size_t dstY;                /**< Destination Y */
    size_t dstZ;                /**< Destination Z */
    size_t dstLOD;              /**< Destination LOD */
    CUmemorytype dstMemoryType; /**< Destination memory type (host, device, array) */
    void *dstHost;              /**< Destination host pointer */
    CUdeviceptr dstDevice;      /**< Destination device pointer */
    CUarray dstArray;           /**< Destination array reference */
    void *reserved1;            /**< Must be NULL */
    size_t dstPitch;            /**< Destination pitch (ignored when dst is array) */
    size_t dstHeight;           /**< Destination height (ignored when dst is array; may be 0 if Depth==1) */

    size_t WidthInBytes;        /**< Width of 3D memory copy in bytes */
    size_t Height;              /**< Height of 3D memory copy */
    size_t Depth;               /**< Depth of 3D memory copy */
} CUDA_MEMCPY3D;

/**
 * 3D memory cross-context copy parameters
 */
typedef struct CUDA_MEMCPY3D_PEER_st
{
    size_t srcXInBytes;         /**< Source X in bytes */
    size_t srcY;                /**< Source Y */
    size_t srcZ;                /**< Source Z */
    size_t srcLOD;              /**< Source LOD */
    CUmemorytype srcMemoryType; /**< Source memory type (host, device, array) */
    const void *srcHost;        /**< Source host pointer */
    CUdeviceptr srcDevice;      /**< Source device pointer */
    CUarray srcArray;           /**< Source array reference */
    CUcontext srcContext;       /**< Source context (ignored with srcMemoryType is ::CU_MEMORYTYPE_ARRAY) */
    size_t srcPitch;            /**< Source pitch (ignored when src is array) */
    size_t srcHeight;           /**< Source height (ignored when src is array; may be 0 if Depth==1) */

    size_t dstXInBytes;         /**< Destination X in bytes */
    size_t dstY;                /**< Destination Y */
    size_t dstZ;                /**< Destination Z */
    size_t dstLOD;              /**< Destination LOD */
    CUmemorytype dstMemoryType; /**< Destination memory type (host, device, array) */
    void *dstHost;              /**< Destination host pointer */
    CUdeviceptr dstDevice;      /**< Destination device pointer */
    CUarray dstArray;           /**< Destination array reference */
    CUcontext dstContext;       /**< Destination context (ignored with dstMemoryType is ::CU_MEMORYTYPE_ARRAY) */
    size_t dstPitch;            /**< Destination pitch (ignored when dst is array) */
    size_t dstHeight;           /**< Destination height (ignored when dst is array; may be 0 if Depth==1) */

    size_t WidthInBytes;        /**< Width of 3D memory copy in bytes */
    size_t Height;              /**< Height of 3D memory copy */
    size_t Depth;               /**< Depth of 3D memory copy */
} CUDA_MEMCPY3D_PEER;

/**
 * Array descriptor
 */
typedef struct CUDA_ARRAY_DESCRIPTOR_st
{
    size_t Width;             /**< Width of array */
    size_t Height;            /**< Height of array */

    CUarray_format Format;    /**< Array format */
    unsigned int NumChannels; /**< Channels per array element */
} CUDA_ARRAY_DESCRIPTOR;

/**
 * 3D array descriptor
 */
typedef struct CUDA_ARRAY3D_DESCRIPTOR_st
{
    size_t Width;             /**< Width of 3D array */
    size_t Height;            /**< Height of 3D array */
    size_t Depth;             /**< Depth of 3D array */

    CUarray_format Format;    /**< Array format */
    unsigned int NumChannels; /**< Channels per array element */
    unsigned int Flags;       /**< Flags */
} CUDA_ARRAY3D_DESCRIPTOR;

#endif /* __CUDA_API_VERSION >= 3020 */

/**
 * If set, the CUDA array is a collection of layers, where each layer is either a 1D
 * or a 2D array and the Depth member of CUDA_ARRAY3D_DESCRIPTOR specifies the number
 * of layers, not the depth of a 3D array.
 */
#define CUDA_ARRAY3D_LAYERED        0x01

/**
 * Deprecated, use CUDA_ARRAY3D_LAYERED
 */
#define CUDA_ARRAY3D_2DARRAY        0x01

/**
 * This flag must be set in order to bind a surface reference
 * to the CUDA array
 */
#define CUDA_ARRAY3D_SURFACE_LDST   0x02

/**
 * Override the texref format with a format inferred from the array.
 * Flag for ::cuTexRefSetArray()
 */
#define CU_TRSA_OVERRIDE_FORMAT 0x01

/**
 * Read the texture as integers rather than promoting the values to floats
 * in the range [0,1].
 * Flag for ::cuTexRefSetFlags()
 */
#define CU_TRSF_READ_AS_INTEGER         0x01

/**
 * Use normalized texture coordinates in the range [0,1) instead of [0,dim).
 * Flag for ::cuTexRefSetFlags()
 */
#define CU_TRSF_NORMALIZED_COORDINATES  0x02

/**
 * Perform sRGB->linear conversion during texture read.
 * Flag for ::cuTexRefSetFlags()
 */
#define CU_TRSF_SRGB  0x10

/**
 * End of array terminator for the \p extra parameter to
 * ::cuLaunchKernel
 */
#define CU_LAUNCH_PARAM_END            ((void*)0x00)

/**
 * Indicator that the next value in the \p extra parameter to
 * ::cuLaunchKernel will be a pointer to a buffer containing all kernel
 * parameters used for launching kernel \p f.  This buffer needs to
 * honor all alignment/padding requirements of the individual parameters.
 * If ::CU_LAUNCH_PARAM_BUFFER_SIZE is not also specified in the
 * \p extra array, then ::CU_LAUNCH_PARAM_BUFFER_POINTER will have no
 * effect.
 */
#define CU_LAUNCH_PARAM_BUFFER_POINTER ((void*)0x01)

/**
 * Indicator that the next value in the \p extra parameter to
 * ::cuLaunchKernel will be a pointer to a size_t which contains the
 * size of the buffer specified with ::CU_LAUNCH_PARAM_BUFFER_POINTER.
 * It is required that ::CU_LAUNCH_PARAM_BUFFER_POINTER also be specified
 * in the \p extra array if the value associated with
 * ::CU_LAUNCH_PARAM_BUFFER_SIZE is not zero.
 */
#define CU_LAUNCH_PARAM_BUFFER_SIZE    ((void*)0x02)

/**
 * For texture references loaded into the module, use default texunit from
 * texture reference.
 */
#define CU_PARAM_TR_DEFAULT -1

/**
 * CUDA API made obselete at API version 3020
 */
#if defined(__CUDA_API_VERSION_INTERNAL)
#define CUdeviceptr                  CUdeviceptr_v1
#define CUDA_MEMCPY2D_st             CUDA_MEMCPY2D_v1_st
#define CUDA_MEMCPY2D                CUDA_MEMCPY2D_v1
#define CUDA_MEMCPY3D_st             CUDA_MEMCPY3D_v1_st
#define CUDA_MEMCPY3D                CUDA_MEMCPY3D_v1
#define CUDA_ARRAY_DESCRIPTOR_st     CUDA_ARRAY_DESCRIPTOR_v1_st
#define CUDA_ARRAY_DESCRIPTOR        CUDA_ARRAY_DESCRIPTOR_v1
#define CUDA_ARRAY3D_DESCRIPTOR_st   CUDA_ARRAY3D_DESCRIPTOR_v1_st
#define CUDA_ARRAY3D_DESCRIPTOR      CUDA_ARRAY3D_DESCRIPTOR_v1
#endif /* CUDA_FORCE_LEGACY32_INTERNAL */

#if defined(__CUDA_API_VERSION_INTERNAL) || __CUDA_API_VERSION < 3020

typedef unsigned int CUdeviceptr;

typedef struct CUDA_MEMCPY2D_st
{
    unsigned int srcXInBytes;   /**< Source X in bytes */
    unsigned int srcY;          /**< Source Y */
    CUmemorytype srcMemoryType; /**< Source memory type (host, device, array) */
    const void *srcHost;        /**< Source host pointer */
    CUdeviceptr srcDevice;      /**< Source device pointer */
    CUarray srcArray;           /**< Source array reference */
    unsigned int srcPitch;      /**< Source pitch (ignored when src is array) */

    unsigned int dstXInBytes;   /**< Destination X in bytes */
    unsigned int dstY;          /**< Destination Y */
    CUmemorytype dstMemoryType; /**< Destination memory type (host, device, array) */
    void *dstHost;              /**< Destination host pointer */
    CUdeviceptr dstDevice;      /**< Destination device pointer */
    CUarray dstArray;           /**< Destination array reference */
    unsigned int dstPitch;      /**< Destination pitch (ignored when dst is array) */

    unsigned int WidthInBytes;  /**< Width of 2D memory copy in bytes */
    unsigned int Height;        /**< Height of 2D memory copy */
} CUDA_MEMCPY2D;

typedef struct CUDA_MEMCPY3D_st
{
    unsigned int srcXInBytes;   /**< Source X in bytes */
    unsigned int srcY;          /**< Source Y */
    unsigned int srcZ;          /**< Source Z */
    unsigned int srcLOD;        /**< Source LOD */
    CUmemorytype srcMemoryType; /**< Source memory type (host, device, array) */
    const void *srcHost;        /**< Source host pointer */
    CUdeviceptr srcDevice;      /**< Source device pointer */
    CUarray srcArray;           /**< Source array reference */
    void *reserved0;            /**< Must be NULL */
    unsigned int srcPitch;      /**< Source pitch (ignored when src is array) */
    unsigned int srcHeight;     /**< Source height (ignored when src is array; may be 0 if Depth==1) */

    unsigned int dstXInBytes;   /**< Destination X in bytes */
    unsigned int dstY;          /**< Destination Y */
    unsigned int dstZ;          /**< Destination Z */
    unsigned int dstLOD;        /**< Destination LOD */
    CUmemorytype dstMemoryType; /**< Destination memory type (host, device, array) */
    void *dstHost;              /**< Destination host pointer */
    CUdeviceptr dstDevice;      /**< Destination device pointer */
    CUarray dstArray;           /**< Destination array reference */
    void *reserved1;            /**< Must be NULL */
    unsigned int dstPitch;      /**< Destination pitch (ignored when dst is array) */
    unsigned int dstHeight;     /**< Destination height (ignored when dst is array; may be 0 if Depth==1) */

    unsigned int WidthInBytes;  /**< Width of 3D memory copy in bytes */
    unsigned int Height;        /**< Height of 3D memory copy */
    unsigned int Depth;         /**< Depth of 3D memory copy */
} CUDA_MEMCPY3D;

typedef struct CUDA_ARRAY_DESCRIPTOR_st
{
    unsigned int Width;         /**< Width of array */
    unsigned int Height;        /**< Height of array */

    CUarray_format Format;      /**< Array format */
    unsigned int NumChannels;   /**< Channels per array element */
} CUDA_ARRAY_DESCRIPTOR;

typedef struct CUDA_ARRAY3D_DESCRIPTOR_st
{
    unsigned int Width;         /**< Width of 3D array */
    unsigned int Height;        /**< Height of 3D array */
    unsigned int Depth;         /**< Depth of 3D array */

    CUarray_format Format;      /**< Array format */
    unsigned int NumChannels;   /**< Channels per array element */
    unsigned int Flags;         /**< Flags */
} CUDA_ARRAY3D_DESCRIPTOR;

#endif /* (__CUDA_API_VERSION_INTERNAL) || __CUDA_API_VERSION < 3020 */

/*
 * If set, the CUDA array contains an array of 2D slices
 * and the Depth member of CUDA_ARRAY3D_DESCRIPTOR specifies
 * the number of slices, not the depth of a 3D array.
 */
#define CUDA_ARRAY3D_2DARRAY        0x01

/**
 * This flag must be set in order to bind a surface reference
 * to the CUDA array
 */
#define CUDA_ARRAY3D_SURFACE_LDST   0x02

/**
 * Override the texref format with a format inferred from the array.
 * Flag for ::cuTexRefSetArray()
 */
#define CU_TRSA_OVERRIDE_FORMAT 0x01

/**
 * Read the texture as integers rather than promoting the values to floats
 * in the range [0,1].
 * Flag for ::cuTexRefSetFlags()
 */
#define CU_TRSF_READ_AS_INTEGER         0x01

/**
 * Use normalized texture coordinates in the range [0,1) instead of [0,dim).
 * Flag for ::cuTexRefSetFlags()
 */
#define CU_TRSF_NORMALIZED_COORDINATES  0x02

/**
 * Perform sRGB->linear conversion during texture read.
 * Flag for ::cuTexRefSetFlags()
 */
#define CU_TRSF_SRGB  0x10

/**
 * For texture references loaded into the module, use default texunit from
 * texture reference.
 */
#define CU_PARAM_TR_DEFAULT -1

/** @} */ /* END CUDA_TYPES */

#if defined(WIN32) || defined(_WIN32) || defined(WIN64) || defined(_WIN64)
#define CUDAAPI __stdcall
#else
#define CUDAAPI
#endif

/**
 * \defgroup CUDA_INITIALIZE Initialization
 *
 * This section describes the initialization functions of the low-level CUDA
 * driver application programming interface.
 *
 * @{
 */

/*********************************
 ** Initialization
 *********************************/
typedef CUresult  CUDAAPI tcuInit(unsigned int Flags);

/*********************************
 ** Driver Version Query
 *********************************/
typedef CUresult  CUDAAPI tcuDriverGetVersion(int *driverVersion);

/************************************
 **
 **    Device management
 **
 ***********************************/

typedef CUresult  CUDAAPI tcuDeviceGet(CUdevice *device, int ordinal);
typedef CUresult  CUDAAPI tcuDeviceGetCount(int *count);
typedef CUresult  CUDAAPI tcuDeviceGetName(char *name, int len, CUdevice dev);
typedef CUresult  CUDAAPI tcuDeviceComputeCapability(int *major, int *minor, CUdevice dev);
#if __CUDA_API_VERSION >= 3020
typedef CUresult  CUDAAPI tcuDeviceTotalMem(size_t *bytes, CUdevice dev);
#else
typedef CUresult  CUDAAPI tcuDeviceTotalMem(unsigned int *bytes, CUdevice dev);
#endif

typedef CUresult  CUDAAPI tcuDeviceGetProperties(CUdevprop *prop, CUdevice dev);
typedef CUresult  CUDAAPI tcuDeviceGetAttribute(int *pi, CUdevice_attribute attrib, CUdevice dev);

/************************************
 **
 **    Context management
 **
 ***********************************/

typedef CUresult  CUDAAPI tcuCtxCreate(CUcontext *pctx, unsigned int flags, CUdevice dev);
typedef CUresult  CUDAAPI tcuCtxDestroy(CUcontext ctx);
typedef CUresult  CUDAAPI tcuCtxAttach(CUcontext *pctx, unsigned int flags);
typedef CUresult  CUDAAPI tcuCtxDetach(CUcontext ctx);
typedef CUresult  CUDAAPI tcuCtxPushCurrent(CUcontext ctx);
typedef CUresult  CUDAAPI tcuCtxPopCurrent(CUcontext *pctx);

typedef CUresult  CUDAAPI tcuCtxSetCurrent(CUcontext ctx);
typedef CUresult  CUDAAPI tcuCtxGetCurrent(CUcontext *pctx);

typedef CUresult  CUDAAPI tcuCtxGetDevice(CUdevice *device);
typedef CUresult  CUDAAPI tcuCtxSynchronize(void);


/************************************
 **
 **    Module management
 **
 ***********************************/

typedef CUresult  CUDAAPI tcuModuleLoad(CUmodule *module, const char *fname);
typedef CUresult  CUDAAPI tcuModuleLoadData(CUmodule *module, const void *image);
typedef CUresult  CUDAAPI tcuModuleLoadDataEx(CUmodule *module, const void *image, unsigned int numOptions, CUjit_option *options, void **optionValues);
typedef CUresult  CUDAAPI tcuModuleLoadFatBinary(CUmodule *module, const void *fatCubin);
typedef CUresult  CUDAAPI tcuModuleUnload(CUmodule hmod);
typedef CUresult  CUDAAPI tcuModuleGetFunction(CUfunction *hfunc, CUmodule hmod, const char *name);

#if __CUDA_API_VERSION >= 3020
typedef CUresult  CUDAAPI tcuModuleGetGlobal(CUdeviceptr *dptr, size_t *bytes, CUmodule hmod, const char *name);
#else
typedef CUresult  CUDAAPI tcuModuleGetGlobal(CUdeviceptr *dptr, unsigned int *bytes, CUmodule hmod, const char *name);
#endif

typedef CUresult  CUDAAPI tcuModuleGetTexRef(CUtexref *pTexRef, CUmodule hmod, const char *name);
typedef CUresult  CUDAAPI tcuModuleGetSurfRef(CUsurfref *pSurfRef, CUmodule hmod, const char *name);

/************************************
 **
 **    Memory management
 **
 ***********************************/
#if __CUDA_API_VERSION >= 3020
typedef CUresult CUDAAPI tcuMemGetInfo(size_t *free, size_t *total);
typedef CUresult CUDAAPI tcuMemAlloc(CUdeviceptr *dptr, size_t bytesize);
typedef CUresult CUDAAPI tcuMemGetAddressRange(CUdeviceptr *pbase, size_t *psize, CUdeviceptr dptr);
typedef CUresult CUDAAPI tcuMemAllocPitch(CUdeviceptr *dptr,
                                          size_t *pPitch,
                                          size_t WidthInBytes,
                                          size_t Height,
                                          // size of biggest r/w to be performed by kernels on this memory
                                          // 4, 8 or 16 bytes
                                          unsigned int ElementSizeBytes
                                         );
#else
typedef CUresult CUDAAPI tcuMemGetInfo(unsigned int *free, unsigned int *total);
typedef CUresult CUDAAPI tcuMemAlloc(CUdeviceptr *dptr, unsigned int bytesize);
typedef CUresult CUDAAPI tcuMemGetAddressRange(CUdeviceptr *pbase, unsigned int *psize, CUdeviceptr dptr);
typedef CUresult CUDAAPI tcuMemAllocPitch(CUdeviceptr *dptr,
                                          unsigned int *pPitch,
                                          unsigned int WidthInBytes,
                                          unsigned int Height,
                                          // size of biggest r/w to be performed by kernels on this memory
                                          // 4, 8 or 16 bytes
                                          unsigned int ElementSizeBytes
                                         );
#endif

typedef CUresult CUDAAPI tcuMemFree(CUdeviceptr dptr);

#if __CUDA_API_VERSION >= 3020
typedef CUresult CUDAAPI tcuMemAllocHost(void **pp, size_t bytesize);
#else
typedef CUresult CUDAAPI tcuMemAllocHost(void **pp, unsigned int bytesize);
#endif

typedef CUresult CUDAAPI tcuMemFreeHost(void *p);
typedef CUresult CUDAAPI tcuMemHostAlloc(void **pp, size_t bytesize, unsigned int Flags);

typedef CUresult CUDAAPI tcuMemHostGetDevicePointer(CUdeviceptr *pdptr, void *p, unsigned int Flags);
typedef CUresult CUDAAPI tcuMemHostGetFlags(unsigned int *pFlags, void *p);

typedef CUresult CUDAAPI tcuMemHostRegister(void *p, size_t bytesize, unsigned int Flags);
typedef CUresult CUDAAPI tcuMemHostUnregister(void *p);;
typedef CUresult CUDAAPI tcuMemcpy(CUdeviceptr dst, CUdeviceptr src, size_t ByteCount);
typedef CUresult CUDAAPI tcuMemcpyPeer(CUdeviceptr dstDevice, CUcontext dstContext, CUdeviceptr srcDevice, CUcontext srcContext, size_t ByteCount);

/************************************
 **
 **    Synchronous Memcpy
 **
 ** Intra-device memcpy's done with these functions may execute in parallel with the CPU,
 ** but if host memory is involved, they wait until the copy is done before returning.
 **
 ***********************************/

// 1D functions
#if __CUDA_API_VERSION >= 3020
// system <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyHtoD(CUdeviceptr dstDevice, const void *srcHost, size_t ByteCount);
typedef CUresult  CUDAAPI tcuMemcpyDtoH(void *dstHost, CUdeviceptr srcDevice, size_t ByteCount);

// device <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyDtoD(CUdeviceptr dstDevice, CUdeviceptr srcDevice, size_t ByteCount);

// device <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyDtoA(CUarray dstArray, size_t dstOffset, CUdeviceptr srcDevice, size_t ByteCount);
typedef CUresult  CUDAAPI tcuMemcpyAtoD(CUdeviceptr dstDevice, CUarray srcArray, size_t srcOffset, size_t ByteCount);

// system <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyHtoA(CUarray dstArray, size_t dstOffset, const void *srcHost, size_t ByteCount);
typedef CUresult  CUDAAPI tcuMemcpyAtoH(void *dstHost, CUarray srcArray, size_t srcOffset, size_t ByteCount);

// array <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyAtoA(CUarray dstArray, size_t dstOffset, CUarray srcArray, size_t srcOffset, size_t ByteCount);
#else
// system <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyHtoD(CUdeviceptr dstDevice, const void *srcHost, unsigned int ByteCount);
typedef CUresult  CUDAAPI tcuMemcpyDtoH(void *dstHost, CUdeviceptr srcDevice, unsigned int ByteCount);

// device <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyDtoD(CUdeviceptr dstDevice, CUdeviceptr srcDevice, unsigned int ByteCount);

// device <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyDtoA(CUarray dstArray, unsigned int dstOffset, CUdeviceptr srcDevice, unsigned int ByteCount);
typedef CUresult  CUDAAPI tcuMemcpyAtoD(CUdeviceptr dstDevice, CUarray srcArray, unsigned int srcOffset, unsigned int ByteCount);

// system <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyHtoA(CUarray dstArray, unsigned int dstOffset, const void *srcHost, unsigned int ByteCount);
typedef CUresult  CUDAAPI tcuMemcpyAtoH(void *dstHost, CUarray srcArray, unsigned int srcOffset, unsigned int ByteCount);

// array <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyAtoA(CUarray dstArray, unsigned int dstOffset, CUarray srcArray, unsigned int srcOffset, unsigned int ByteCount);
#endif

// 2D memcpy

typedef CUresult  CUDAAPI tcuMemcpy2D(const CUDA_MEMCPY2D *pCopy);
typedef CUresult  CUDAAPI tcuMemcpy2DUnaligned(const CUDA_MEMCPY2D *pCopy);

// 3D memcpy

typedef CUresult  CUDAAPI tcuMemcpy3D(const CUDA_MEMCPY3D *pCopy);

/************************************
 **
 **    Asynchronous Memcpy
 **
 ** Any host memory involved must be DMA'able (e.g., allocated with cuMemAllocHost).
 ** memcpy's done with these functions execute in parallel with the CPU and, if
 ** the hardware is available, may execute in parallel with the GPU.
 ** Asynchronous memcpy must be accompanied by appropriate stream synchronization.
 **
 ***********************************/

// 1D functions
#if __CUDA_API_VERSION >= 3020
// system <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyHtoDAsync(CUdeviceptr dstDevice,
                                             const void *srcHost, size_t ByteCount, CUstream hStream);
typedef CUresult  CUDAAPI tcuMemcpyDtoHAsync(void *dstHost,
                                             CUdeviceptr srcDevice, size_t ByteCount, CUstream hStream);

// device <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyDtoDAsync(CUdeviceptr dstDevice,
                                             CUdeviceptr srcDevice, size_t ByteCount, CUstream hStream);

// system <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyHtoAAsync(CUarray dstArray, size_t dstOffset,
                                             const void *srcHost, size_t ByteCount, CUstream hStream);
typedef CUresult  CUDAAPI tcuMemcpyAtoHAsync(void *dstHost, CUarray srcArray, size_t srcOffset,
                                             size_t ByteCount, CUstream hStream);

#else
// system <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyHtoDAsync(CUdeviceptr dstDevice,
                                             const void *srcHost, unsigned int ByteCount, CUstream hStream);
typedef CUresult  CUDAAPI tcuMemcpyDtoHAsync(void *dstHost,
                                             CUdeviceptr srcDevice, unsigned int ByteCount, CUstream hStream);

// device <-> device memory
typedef CUresult  CUDAAPI tcuMemcpyDtoDAsync(CUdeviceptr dstDevice,
                                             CUdeviceptr srcDevice, unsigned int ByteCount, CUstream hStream);

// system <-> array memory
typedef CUresult  CUDAAPI tcuMemcpyHtoAAsync(CUarray dstArray, unsigned int dstOffset,
                                             const void *srcHost, unsigned int ByteCount, CUstream hStream);
typedef CUresult  CUDAAPI tcuMemcpyAtoHAsync(void *dstHost, CUarray srcArray, unsigned int srcOffset,
                                             unsigned int ByteCount, CUstream hStream);
#endif

// 2D memcpy
typedef CUresult  CUDAAPI tcuMemcpy2DAsync(const CUDA_MEMCPY2D *pCopy, CUstream hStream);

// 3D memcpy
typedef CUresult  CUDAAPI tcuMemcpy3DAsync(const CUDA_MEMCPY3D *pCopy, CUstream hStream);

/************************************
 **
 **    Memset
 **
 ***********************************/
typedef CUresult  CUDAAPI tcuMemsetD8(CUdeviceptr dstDevice, unsigned char uc, unsigned int N);
typedef CUresult  CUDAAPI tcuMemsetD16(CUdeviceptr dstDevice, unsigned short us, unsigned int N);
typedef CUresult  CUDAAPI tcuMemsetD32(CUdeviceptr dstDevice, unsigned int ui, unsigned int N);

#if __CUDA_API_VERSION >= 3020
typedef CUresult  CUDAAPI tcuMemsetD2D8(CUdeviceptr dstDevice, unsigned int dstPitch, unsigned char uc, size_t Width, size_t Height);
typedef CUresult  CUDAAPI tcuMemsetD2D16(CUdeviceptr dstDevice, unsigned int dstPitch, unsigned short us, size_t Width, size_t Height);
typedef CUresult  CUDAAPI tcuMemsetD2D32(CUdeviceptr dstDevice, unsigned int dstPitch, unsigned int ui, size_t Width, size_t Height);
#else
typedef CUresult  CUDAAPI tcuMemsetD2D8(CUdeviceptr dstDevice, unsigned int dstPitch, unsigned char uc, unsigned int Width, unsigned int Height);
typedef CUresult  CUDAAPI tcuMemsetD2D16(CUdeviceptr dstDevice, unsigned int dstPitch, unsigned short us, unsigned int Width, unsigned int Height);
typedef CUresult  CUDAAPI tcuMemsetD2D32(CUdeviceptr dstDevice, unsigned int dstPitch, unsigned int ui, unsigned int Width, unsigned int Height);
#endif

/************************************
 **
 **    Function management
 **
 ***********************************/


typedef CUresult CUDAAPI tcuFuncSetBlockShape(CUfunction hfunc, int x, int y, int z);
typedef CUresult CUDAAPI tcuFuncSetSharedSize(CUfunction hfunc, unsigned int bytes);
typedef CUresult CUDAAPI tcuFuncGetAttribute(int *pi, CUfunction_attribute attrib, CUfunction hfunc);
typedef CUresult CUDAAPI tcuFuncSetCacheConfig(CUfunction hfunc, CUfunc_cache config);
typedef CUresult CUDAAPI tcuLaunchKernel(CUfunction f,
                                         unsigned int gridDimX,  unsigned int gridDimY,  unsigned int gridDimZ,
                                         unsigned int blockDimX, unsigned int blockDimY, unsigned int blockDimZ,
                                         unsigned int sharedMemBytes,
                                         CUstream hStream, void **kernelParams, void **extra);

/************************************
 **
 **    Array management
 **
 ***********************************/

typedef CUresult  CUDAAPI tcuArrayCreate(CUarray *pHandle, const CUDA_ARRAY_DESCRIPTOR *pAllocateArray);
typedef CUresult  CUDAAPI tcuArrayGetDescriptor(CUDA_ARRAY_DESCRIPTOR *pArrayDescriptor, CUarray hArray);
typedef CUresult  CUDAAPI tcuArrayDestroy(CUarray hArray);

typedef CUresult  CUDAAPI tcuArray3DCreate(CUarray *pHandle, const CUDA_ARRAY3D_DESCRIPTOR *pAllocateArray);
typedef CUresult  CUDAAPI tcuArray3DGetDescriptor(CUDA_ARRAY3D_DESCRIPTOR *pArrayDescriptor, CUarray hArray);


/************************************
 **
 **    Texture reference management
 **
 ***********************************/
typedef CUresult  CUDAAPI tcuTexRefCreate(CUtexref *pTexRef);
typedef CUresult  CUDAAPI tcuTexRefDestroy(CUtexref hTexRef);

typedef CUresult  CUDAAPI tcuTexRefSetArray(CUtexref hTexRef, CUarray hArray, unsigned int Flags);

#if __CUDA_API_VERSION >= 3020
typedef CUresult  CUDAAPI tcuTexRefSetAddress(size_t *ByteOffset, CUtexref hTexRef, CUdeviceptr dptr, size_t bytes);
typedef CUresult  CUDAAPI tcuTexRefSetAddress2D(CUtexref hTexRef, const CUDA_ARRAY_DESCRIPTOR *desc, CUdeviceptr dptr, size_t Pitch);
#else
typedef CUresult  CUDAAPI tcuTexRefSetAddress(unsigned int *ByteOffset, CUtexref hTexRef, CUdeviceptr dptr, unsigned int bytes);
typedef CUresult  CUDAAPI tcuTexRefSetAddress2D(CUtexref hTexRef, const CUDA_ARRAY_DESCRIPTOR *desc, CUdeviceptr dptr, unsigned int Pitch);
#endif

typedef CUresult  CUDAAPI tcuTexRefSetFormat(CUtexref hTexRef, CUarray_format fmt, int NumPackedComponents);
typedef CUresult  CUDAAPI tcuTexRefSetAddressMode(CUtexref hTexRef, int dim, CUaddress_mode am);
typedef CUresult  CUDAAPI tcuTexRefSetFilterMode(CUtexref hTexRef, CUfilter_mode fm);
typedef CUresult  CUDAAPI tcuTexRefSetFlags(CUtexref hTexRef, unsigned int Flags);

typedef CUresult  CUDAAPI tcuTexRefGetAddress(CUdeviceptr *pdptr, CUtexref hTexRef);
typedef CUresult  CUDAAPI tcuTexRefGetArray(CUarray *phArray, CUtexref hTexRef);
typedef CUresult  CUDAAPI tcuTexRefGetAddressMode(CUaddress_mode *pam, CUtexref hTexRef, int dim);
typedef CUresult  CUDAAPI tcuTexRefGetFilterMode(CUfilter_mode *pfm, CUtexref hTexRef);
typedef CUresult  CUDAAPI tcuTexRefGetFormat(CUarray_format *pFormat, int *pNumChannels, CUtexref hTexRef);
typedef CUresult  CUDAAPI tcuTexRefGetFlags(unsigned int *pFlags, CUtexref hTexRef);

/************************************
 **
 **    Surface reference management
 **
 ***********************************/

typedef CUresult  CUDAAPI tcuSurfRefSetArray(CUsurfref hSurfRef, CUarray hArray, unsigned int Flags);
typedef CUresult  CUDAAPI tcuSurfRefGetArray(CUarray *phArray, CUsurfref hSurfRef);

/************************************
 **
 **    Parameter management
 **
 ***********************************/

typedef CUresult  CUDAAPI tcuParamSetSize(CUfunction hfunc, unsigned int numbytes);
typedef CUresult  CUDAAPI tcuParamSeti(CUfunction hfunc, int offset, unsigned int value);
typedef CUresult  CUDAAPI tcuParamSetf(CUfunction hfunc, int offset, float value);
typedef CUresult  CUDAAPI tcuParamSetv(CUfunction hfunc, int offset, void *ptr, unsigned int numbytes);
typedef CUresult  CUDAAPI tcuParamSetTexRef(CUfunction hfunc, int texunit, CUtexref hTexRef);


/************************************
 **
 **    Launch functions
 **
 ***********************************/

typedef CUresult CUDAAPI tcuLaunch(CUfunction f);
typedef CUresult CUDAAPI tcuLaunchGrid(CUfunction f, int grid_width, int grid_height);
typedef CUresult CUDAAPI tcuLaunchGridAsync(CUfunction f, int grid_width, int grid_height, CUstream hStream);

/************************************
 **
 **    Events
 **
 ***********************************/
typedef CUresult CUDAAPI tcuEventCreate(CUevent *phEvent, unsigned int Flags);
typedef CUresult CUDAAPI tcuEventRecord(CUevent hEvent, CUstream hStream);
typedef CUresult CUDAAPI tcuEventQuery(CUevent hEvent);
typedef CUresult CUDAAPI tcuEventSynchronize(CUevent hEvent);
typedef CUresult CUDAAPI tcuEventDestroy(CUevent hEvent);
typedef CUresult CUDAAPI tcuEventElapsedTime(float *pMilliseconds, CUevent hStart, CUevent hEnd);

/************************************
 **
 **    Streams
 **
 ***********************************/
typedef CUresult CUDAAPI  tcuStreamCreate(CUstream *phStream, unsigned int Flags);
typedef CUresult CUDAAPI  tcuStreamQuery(CUstream hStream);
typedef CUresult CUDAAPI  tcuStreamSynchronize(CUstream hStream);
typedef CUresult CUDAAPI  tcuStreamDestroy(CUstream hStream);

/************************************
 **
 **    Graphics interop
 **
 ***********************************/
typedef CUresult CUDAAPI tcuGraphicsUnregisterResource(CUgraphicsResource resource);
typedef CUresult CUDAAPI tcuGraphicsSubResourceGetMappedArray(CUarray *pArray, CUgraphicsResource resource, unsigned int arrayIndex, unsigned int mipLevel);

#if __CUDA_API_VERSION >= 3020
typedef CUresult CUDAAPI tcuGraphicsResourceGetMappedPointer(CUdeviceptr *pDevPtr, size_t *pSize, CUgraphicsResource resource);
#else
typedef CUresult CUDAAPI tcuGraphicsResourceGetMappedPointer(CUdeviceptr *pDevPtr, unsigned int *pSize, CUgraphicsResource resource);
#endif

typedef CUresult CUDAAPI tcuGraphicsResourceSetMapFlags(CUgraphicsResource resource, unsigned int flags);
typedef CUresult CUDAAPI tcuGraphicsMapResources(unsigned int count, CUgraphicsResource *resources, CUstream hStream);
typedef CUresult CUDAAPI tcuGraphicsUnmapResources(unsigned int count, CUgraphicsResource *resources, CUstream hStream);

/************************************
 **
 **    Export tables
 **
 ***********************************/
typedef CUresult CUDAAPI tcuGetExportTable(const void **ppExportTable, const CUuuid *pExportTableId);

/************************************
 **
 **    Limits
 **
 ***********************************/

typedef CUresult CUDAAPI tcuCtxSetLimit(CUlimit limit, size_t value);
typedef CUresult CUDAAPI tcuCtxGetLimit(size_t *pvalue, CUlimit limit);


/************************************
 ************************************/

extern CUresult CUDAAPI cuInit(unsigned int, int cudaVersion);

extern tcuDriverGetVersion             *cuDriverGetVersion;
extern tcuDeviceGet                    *cuDeviceGet;
extern tcuDeviceGetCount               *cuDeviceGetCount;
extern tcuDeviceGetName                *cuDeviceGetName;
extern tcuDeviceComputeCapability      *cuDeviceComputeCapability;
extern tcuDeviceGetProperties          *cuDeviceGetProperties;
extern tcuDeviceGetAttribute           *cuDeviceGetAttribute;
extern tcuCtxDestroy                   *cuCtxDestroy;
extern tcuCtxAttach                    *cuCtxAttach;
extern tcuCtxDetach                    *cuCtxDetach;
extern tcuCtxPushCurrent               *cuCtxPushCurrent;
extern tcuCtxPopCurrent                *cuCtxPopCurrent;

extern tcuCtxSetCurrent                *cuCtxSetCurrent;
extern tcuCtxGetCurrent                *cuCtxGetCurrent;

extern tcuCtxGetDevice                 *cuCtxGetDevice;
extern tcuCtxSynchronize               *cuCtxSynchronize;
extern tcuModuleLoad                   *cuModuleLoad;
extern tcuModuleLoadData               *cuModuleLoadData;
extern tcuModuleLoadDataEx             *cuModuleLoadDataEx;
extern tcuModuleLoadFatBinary          *cuModuleLoadFatBinary;
extern tcuModuleUnload                 *cuModuleUnload;
extern tcuModuleGetFunction            *cuModuleGetFunction;
extern tcuModuleGetTexRef              *cuModuleGetTexRef;
extern tcuModuleGetSurfRef             *cuModuleGetSurfRef;
extern tcuMemFreeHost                  *cuMemFreeHost;
extern tcuMemHostAlloc                 *cuMemHostAlloc;
extern tcuMemHostGetFlags              *cuMemHostGetFlags;

extern tcuMemHostRegister              *cuMemHostRegister;
extern tcuMemHostUnregister            *cuMemHostUnregister;
extern tcuMemcpy                       *cuMemcpy;
extern tcuMemcpyPeer                   *cuMemcpyPeer;

extern tcuDeviceTotalMem               *cuDeviceTotalMem;
extern tcuCtxCreate                    *cuCtxCreate;
extern tcuModuleGetGlobal              *cuModuleGetGlobal;
extern tcuMemGetInfo                   *cuMemGetInfo;
extern tcuMemAlloc                     *cuMemAlloc;
extern tcuMemAllocPitch                *cuMemAllocPitch;
extern tcuMemFree                      *cuMemFree;
extern tcuMemGetAddressRange           *cuMemGetAddressRange;
extern tcuMemAllocHost                 *cuMemAllocHost;
extern tcuMemHostGetDevicePointer      *cuMemHostGetDevicePointer;
extern tcuFuncSetBlockShape            *cuFuncSetBlockShape;
extern tcuFuncSetSharedSize            *cuFuncSetSharedSize;
extern tcuFuncGetAttribute             *cuFuncGetAttribute;
extern tcuFuncSetCacheConfig           *cuFuncSetCacheConfig;
extern tcuLaunchKernel                 *cuLaunchKernel;
extern tcuArrayDestroy                 *cuArrayDestroy;
extern tcuTexRefCreate                 *cuTexRefCreate;
extern tcuTexRefDestroy                *cuTexRefDestroy;
extern tcuTexRefSetArray               *cuTexRefSetArray;
extern tcuTexRefSetFormat              *cuTexRefSetFormat;
extern tcuTexRefSetAddressMode         *cuTexRefSetAddressMode;
extern tcuTexRefSetFilterMode          *cuTexRefSetFilterMode;
extern tcuTexRefSetFlags               *cuTexRefSetFlags;
extern tcuTexRefGetArray               *cuTexRefGetArray;
extern tcuTexRefGetAddressMode         *cuTexRefGetAddressMode;
extern tcuTexRefGetFilterMode          *cuTexRefGetFilterMode;
extern tcuTexRefGetFormat              *cuTexRefGetFormat;
extern tcuTexRefGetFlags               *cuTexRefGetFlags;
extern tcuSurfRefSetArray              *cuSurfRefSetArray;
extern tcuSurfRefGetArray              *cuSurfRefGetArray;
extern tcuParamSetSize                 *cuParamSetSize;
extern tcuParamSeti                    *cuParamSeti;
extern tcuParamSetf                    *cuParamSetf;
extern tcuParamSetv                    *cuParamSetv;
extern tcuParamSetTexRef               *cuParamSetTexRef;
extern tcuLaunch                       *cuLaunch;
extern tcuLaunchGrid                   *cuLaunchGrid;
extern tcuLaunchGridAsync              *cuLaunchGridAsync;
extern tcuEventCreate                  *cuEventCreate;
extern tcuEventRecord                  *cuEventRecord;
extern tcuEventQuery                   *cuEventQuery;
extern tcuEventSynchronize             *cuEventSynchronize;
extern tcuEventDestroy                 *cuEventDestroy;
extern tcuEventElapsedTime             *cuEventElapsedTime;
extern tcuStreamCreate                 *cuStreamCreate;
extern tcuStreamQuery                  *cuStreamQuery;
extern tcuStreamSynchronize            *cuStreamSynchronize;
extern tcuStreamDestroy                *cuStreamDestroy;
extern tcuGraphicsUnregisterResource         *cuGraphicsUnregisterResource;
extern tcuGraphicsSubResourceGetMappedArray  *cuGraphicsSubResourceGetMappedArray;
extern tcuGraphicsResourceSetMapFlags        *cuGraphicsResourceSetMapFlags;
extern tcuGraphicsMapResources               *cuGraphicsMapResources;
extern tcuGraphicsUnmapResources             *cuGraphicsUnmapResources;
extern tcuGetExportTable                     *cuGetExportTable;
extern tcuCtxSetLimit                        *cuCtxSetLimit;
extern tcuCtxGetLimit                        *cuCtxGetLimit;

// These functions could be using the CUDA 3.2 interface (_v2)
extern tcuMemcpyHtoD                   *cuMemcpyHtoD;
extern tcuMemcpyDtoH                   *cuMemcpyDtoH;
extern tcuMemcpyDtoD                   *cuMemcpyDtoD;
extern tcuMemcpyDtoA                   *cuMemcpyDtoA;
extern tcuMemcpyAtoD                   *cuMemcpyAtoD;
extern tcuMemcpyHtoA                   *cuMemcpyHtoA;
extern tcuMemcpyAtoH                   *cuMemcpyAtoH;
extern tcuMemcpyAtoA                   *cuMemcpyAtoA;
extern tcuMemcpy2D                     *cuMemcpy2D;
extern tcuMemcpy2DUnaligned            *cuMemcpy2DUnaligned;
extern tcuMemcpy3D                     *cuMemcpy3D;
extern tcuMemcpyHtoDAsync              *cuMemcpyHtoDAsync;
extern tcuMemcpyDtoHAsync              *cuMemcpyDtoHAsync;
extern tcuMemcpyDtoDAsync              *cuMemcpyDtoDAsync;
extern tcuMemcpyHtoAAsync              *cuMemcpyHtoAAsync;
extern tcuMemcpyAtoHAsync              *cuMemcpyAtoHAsync;
extern tcuMemcpy2DAsync                *cuMemcpy2DAsync;
extern tcuMemcpy3DAsync                *cuMemcpy3DAsync;
extern tcuMemsetD8                     *cuMemsetD8;
extern tcuMemsetD16                    *cuMemsetD16;
extern tcuMemsetD32                    *cuMemsetD32;
extern tcuMemsetD2D8                   *cuMemsetD2D8;
extern tcuMemsetD2D16                  *cuMemsetD2D16;
extern tcuMemsetD2D32                  *cuMemsetD2D32;
extern tcuArrayCreate                  *cuArrayCreate;
extern tcuArrayGetDescriptor           *cuArrayGetDescriptor;
extern tcuArray3DCreate                *cuArray3DCreate;
extern tcuArray3DGetDescriptor         *cuArray3DGetDescriptor;
extern tcuTexRefSetAddress             *cuTexRefSetAddress;
extern tcuTexRefSetAddress2D           *cuTexRefSetAddress2D;
extern tcuTexRefGetAddress             *cuTexRefGetAddress;
extern tcuGraphicsResourceGetMappedPointer   *cuGraphicsResourceGetMappedPointer;

#ifdef __cplusplus
}
#endif

//#undef __CUDA_API_VERSION

#endif //__cuda_drvapi_dynlink_cuda_h__
