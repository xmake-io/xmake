/*++

Copyright (c) 1991, 1992, 1993 Microsoft Corporation

Module Name:

    flush.c

Abstract:

    This module contains the code that is very specific to flush
    operations in the serial driver

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "flush.tmh"
#endif

#ifdef ALLOC_PRAGMA
#pragma alloc_text(PAGE, SerialFlush)
#endif

#pragma warning(push)
#pragma warning(disable:28118) // this callback will run at IRQL=PASSIVE_LEVEL
_Use_decl_annotations_
NTSTATUS
SerialFlush(
    WDFDEVICE Device,
    PIRP Irp
    )

/*++

Routine Description:

    This is the dispatch routine for flush.  Flushing works by placing
    this request in the write queue.  When this request reaches the
    front of the write queue we simply complete it since this implies
    that all previous writes have completed.

Arguments:

    DeviceObject - Pointer to the device object for this device

    Irp - Pointer to the IRP for the current request

Return Value:

    Could return status success, cancelled, or pending.

--*/

{

    PSERIAL_DEVICE_EXTENSION extension;

    extension = SerialGetDeviceExtension(Device);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, ">SerialFlush(%p, %p)\n", Device, Irp);

    PAGED_CODE();

    WdfIoQueueStopSynchronously(extension->WriteQueue);
    //
    // Flush is done - restart the queue
    //
    WdfIoQueueStart(extension->WriteQueue);

    Irp->IoStatus.Information = 0L;
    Irp->IoStatus.Status = STATUS_SUCCESS;
    IoCompleteRequest(Irp, IO_NO_INCREMENT);


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialFlush\n");

    return STATUS_SUCCESS;
 }
#pragma warning(pop) // enable 28118 again

