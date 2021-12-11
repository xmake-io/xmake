
/*++

Copyright (C) 2004  Microsoft Corporation

Module Name:

    trace.h

Abstract:

    Header file included by the Microsoft Device Specific Module (DSM).

    This file contains Windows tracing related defines.

Environment:

    kernel mode only

Notes:

--*/

//
// Set component ID for DbgPrintEx calls
//
#define DEBUG_COMP_ID   DPFLTR_MSDSM_ID

//
// Include header file and setup GUID for tracing
//
#include <storswtr.h>
#define WPP_GUID_MSDSM      (DEDADFF5, F99F, 4600, B8C9, 2D4D9B806B5B)
#define WPP_CONTROL_GUIDS   WPP_CONTROL_GUIDS_NORMAL_FLAGS(WPP_GUID_MSDSM)

