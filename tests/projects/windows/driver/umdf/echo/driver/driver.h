/*++

Copyright (c) 1990-2000  Microsoft Corporation

Module Name:

    driver.h

Abstract:

    This is a C version of a very simple sample driver that illustrates
    how to use the driver framework and demonstrates best practices.

--*/

#define INITGUID

#include <windows.h>
#include <wdf.h>
#include "device.h"
#include "queue.h"

#ifndef ASSERT
#if DBG
#define ASSERT( exp ) \
    ((!(exp)) ? \
        (KdPrint(( "\n*** Assertion failed: " #exp "\n\n")), \
         DebugBreak(), \
         FALSE) : \
        TRUE)
#else
#define ASSERT( exp )
#endif // DBG
#endif // ASSERT

//
// WDFDRIVER Events
//

DRIVER_INITIALIZE DriverEntry;
EVT_WDF_DRIVER_DEVICE_ADD EchoEvtDeviceAdd;

NTSTATUS
EchoPrintDriverVersion(
    );

