/*++

Copyright (c) 1990-2000  Microsoft Corporation

Module Name:

    device.h

Abstract:

    This is a C version of a very simple sample driver that illustrates
    how to use the driver framework and demonstrates best practices.

--*/

#include "public.h"

//
// The device context performs the same job as
// a WDM device extension in the driver frameworks
//
typedef struct _DEVICE_CONTEXT
{
    ULONG PrivateDeviceData;  // just a placeholder

} DEVICE_CONTEXT, *PDEVICE_CONTEXT;

//
// This macro will generate an inline function called WdfObjectGet_DEVICE_CONTEXT
// which will be used to get a pointer to the device context memory
// in a type safe manner.
//
WDF_DECLARE_CONTEXT_TYPE(DEVICE_CONTEXT)

//
// Function to initialize the device and its callbacks
//
NTSTATUS
EchoDeviceCreate(
    PWDFDEVICE_INIT DeviceInit
    );

//
// Device events
//
EVT_WDF_DEVICE_SELF_MANAGED_IO_INIT EchoEvtDeviceSelfManagedIoStart;
EVT_WDF_DEVICE_SELF_MANAGED_IO_SUSPEND EchoEvtDeviceSelfManagedIoSuspend;

