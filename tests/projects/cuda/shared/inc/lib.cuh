#pragma once

#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#ifdef __cplusplus
extern "C"
{
#endif

#if defined(_WIN32)
#define __export __declspec(dllexport)
#elif defined(__GNUC__) && ((__GNUC__ >= 4) || (__GNUC__ == 3 && __GNUC_MINOR__ >= 3))
#define __export __attribute__((visibility("default")))
#else
#define __export
#endif

    __export cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);

#ifdef __cplusplus
}
#endif
