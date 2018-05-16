/*++

Copyright (C) Microsoft Corporation, All Rights Reserved

Module Name:

    Internal.h

Abstract:

    This module contains the local type definitions for the UMDF Skeleton
    driver sample.

Environment:

    Windows User-Mode Driver Framework (WUDF)

--*/

#pragma once

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))
#endif

//
// Include the WUDF DDI 
//

#include "wudfddi.h"

//
// Use specstrings for in/out annotation of function parameters.
//

#include "specstrings.h"

//
// Forward definitions of classes in the other header files.
//

typedef class CMyDriver *PCMyDriver;
typedef class CMyDevice *PCMyDevice;

//
// Define the tracing flags.
//
// TODO: Choose a different trace control GUID
//

#define WPP_CONTROL_GUIDS                                                   \
    WPP_DEFINE_CONTROL_GUID(                                                \
        MyDriverTraceControl, (e7541cdd,30e8,4b50,aeb0,51927330ae64),       \
                                                                            \
        WPP_DEFINE_BIT(MYDRIVER_ALL_INFO)                                   \
        )

#define WPP_FLAG_LEVEL_LOGGER(flag, level)                                  \
    WPP_LEVEL_LOGGER(flag)

#define WPP_FLAG_LEVEL_ENABLED(flag, level)                                 \
    (WPP_LEVEL_ENABLED(flag) &&                                             \
     WPP_CONTROL(WPP_BIT_ ## flag).Level >= level)

//
// This comment block is scanned by the trace preprocessor to define our
// Trace function.
//
// begin_wpp config
// FUNC Trace{FLAG=MYDRIVER_ALL_INFO}(LEVEL, MSG, ...);
// end_wpp
//

//
// Driver specific #defines
//
// TODO: Change these values to be appropriate for your driver.
//

#define MYDRIVER_TRACING_ID L"Microsoft\\UMDF\\Skeleton"
#define MYDRIVER_CLASS_ID   { 0xd4112073, 0xd09b, 0x458f, { 0xa5, 0xaa, 0x35, 0xef, 0x21, 0xee, 0xf5, 0xde } }


//
// Include the type specific headers.
//

#include "comsup.h"
#include "driver.h"
#include "device.h"
