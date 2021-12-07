/*++

Copyright (c) Microsoft Corporation.  All rights reserved.

    THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
    KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
    PURPOSE.

Module Name:

    kcs.h

Abstract:

    This module contains sample code to demonstrate how to provide
    counter data from a kernel driver.

Environment:

    Kernel mode only.

--*/

typedef struct _GEOMETRIC_WAVE_VALUES {
    ULONG Square;
    ULONG Triangle;
} GEOMETRIC_WAVE_VALUES, *PGEOMETRIC_WAVE_VALUES;

typedef struct _TRIGNOMETRIC_WAVE_VALUES {
    ULONG Constant;
    ULONG Cosine;
    ULONG Sine;
} TRIGNOMETRIC_WAVE_VALUES, *PTRIGNOMETRIC_WAVE_VALUES;