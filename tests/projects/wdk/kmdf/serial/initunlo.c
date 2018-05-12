/*++

Copyright (c) Microsoft Corporation

Module Name:

    initunlo.c

Abstract:

    This module contains the code that is very specific to initialization
    and unload operations in the serial driver

    WDF Version of serial sample doesn't support:
    1) Multiport Serial devices.
    2) Enumeration of Non PNP serial devices that are not detected by BIOS
                    (IO address range 0x2F0-0x2F7 using IRQ 9)
Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "initunlo.tmh"
#endif

static const PHYSICAL_ADDRESS SerialPhysicalZero = {0};

//
// We use this to query into the registry as to whether we
// should break at driver entry.
//

SERIAL_FIRMWARE_DATA    driverDefaults;

//
// This is exported from the kernel.  It is used to point
// to the address that the kernel debugger is using.
//
extern PUCHAR *KdComPortInUse;
//
// INIT - only needed during init and then can be disposed
// PAGESRP0 - always paged / never locked
// PAGESER - must be locked when a device is open, else paged
//
//
// INIT is used for DriverEntry() specific code
//
// PAGESRP0 is used for code that is not often called and has nothing
// to do with I/O performance.  An example, passive-level PNP
// support functions
//
// PAGESER is used for code that needs to be locked after an open for both
// performance and IRQL reasons.
//

ULONG DebugLevel = TRACE_LEVEL_INFORMATION;
ULONG DebugFlag = 0xf;//0x46;//0x4FF; //0x00000006;

#ifdef ALLOC_PRAGMA
#pragma alloc_text(INIT, DriverEntry)
#pragma alloc_text(PAGE, SerialEvtDriverContextCleanup)
#endif



NTSTATUS
DriverEntry(
    IN PDRIVER_OBJECT DriverObject,
    IN PUNICODE_STRING RegistryPath
    )
/*++

Routine Description:

    The entry point that the system point calls to initialize
    any driver.

Arguments:

    DriverObject - Just what it says,  really of little use
    to the driver itself, it is something that the IO system
    cares more about.

    PathToRegistry - points to the entry for this driver
    in the current control set of the registry.

Return Value:

    Always STATUS_SUCCESS

--*/

{
    WDF_DRIVER_CONFIG config;
    WDFDRIVER hDriver;
    NTSTATUS status;
    WDF_OBJECT_ATTRIBUTES attributes;

    //
    // Initialize WPP Tracing
    //
    WPP_INIT_TRACING( DriverObject, RegistryPath );

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT,
                    "Serial Sample (WDF Version)\n");
    //
    // Register a cleanup callback so that we can call WPP_CLEANUP when
    // the framework driver object is deleted during driver unload.
    //
    WDF_OBJECT_ATTRIBUTES_INIT(&attributes);
    attributes.EvtCleanupCallback = SerialEvtDriverContextCleanup;

    WDF_DRIVER_CONFIG_INIT(&config, SerialEvtDeviceAdd);

    status = WdfDriverCreate(DriverObject,
                           RegistryPath,
                           &attributes,
                           &config,
                           &hDriver);
    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_INIT,
                         "WdfDriverCreate failed with status 0x%x\n",
                         status);
        //
        // Cleanup tracing here because DriverContextCleanup will not be called
        // as we have failed to create WDFDRIVER object itself.
        // Please note that if your return failure from DriverEntry after the
        // WDFDRIVER object is created successfully, you don't have to
        // call WPP cleanup because in those cases DriverContextCleanup
        // will be executed when the framework deletes the DriverObject.
        //
        WPP_CLEANUP(DriverObject);
        return status;
    }

    //
    // Call to find out default values to use for all the devices that the
    // driver controls, including whether or not to break on entry.
    //

    SerialGetConfigDefaults(&driverDefaults, hDriver);

    //
    // Break on entry if requested via registry
    //
    if (driverDefaults.ShouldBreakOnEntry) {
        DbgBreakPoint();
    }


    return status;
}


_Use_decl_annotations_
VOID
SerialEvtDriverContextCleanup(
    WDFOBJECT Driver
    )
/*++
Routine Description:

    Free all the resources allocated in DriverEntry.

Arguments:

    Driver - handle to a WDF Driver object.

Return Value:

    VOID.

--*/
{
    UNREFERENCED_PARAMETER(Driver);

    PAGED_CODE ();

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT,
                     "--> SerialEvtDriverContextCleanup\n");

    //
    // Stop WPP Tracing
    //
    WPP_CLEANUP( WdfDriverWdmGetDriverObject(Driver) );

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT,
                     "<-- SerialEvtDriverContextCleanup\n");

}



