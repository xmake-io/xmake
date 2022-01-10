/*++

Copyright (c) 1991, 1992, 1993 - 1997 Microsoft Corporation

Module Name:

    qsfile.c

Abstract:

    This module contains the code that is very specific to query/set file
    operations in the serial driver.

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "qsfile.tmh"
#endif

#ifdef ALLOC_PRAGMA
#pragma alloc_text(PAGESRP0,SerialQueryInformationFile)
#pragma alloc_text(PAGESRP0,SerialSetInformationFile)
#endif


NTSTATUS
SerialQueryInformationFile(
    IN WDFDEVICE Device,
    IN PIRP Irp
    )

/*++

Routine Description:

    This routine is used to query the end of file information on
    the opened serial port.  Any other file information request
    is retured with an invalid parameter.

    This routine always returns an end of file of 0.

Arguments:

    DeviceObject - Pointer to the device object for this device

    Irp - Pointer to the IRP for the current request

Return Value:

    The function value is the final status of the call

--*/

{
    NTSTATUS Status;
    PIO_STACK_LOCATION IrpSp;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, ">SerialQueryInformationFile(%p, %p)\n", Device, Irp);

    PAGED_CODE();


    IrpSp = IoGetCurrentIrpStackLocation(Irp);
    Irp->IoStatus.Information = 0L;
    Status = STATUS_SUCCESS;

    if (IrpSp->Parameters.QueryFile.FileInformationClass ==
        FileStandardInformation) {

        if (IrpSp->Parameters.DeviceIoControl.OutputBufferLength <
                sizeof(FILE_STANDARD_INFORMATION))
        {
                Status = STATUS_BUFFER_TOO_SMALL;
        }
        else
        {
            PFILE_STANDARD_INFORMATION Buf = Irp->AssociatedIrp.SystemBuffer;

            Buf->AllocationSize.QuadPart = 0;
            Buf->EndOfFile = Buf->AllocationSize;
            Buf->NumberOfLinks = 0;
            Buf->DeletePending = FALSE;
            Buf->Directory = FALSE;
            Irp->IoStatus.Information = sizeof(FILE_STANDARD_INFORMATION);
        }

    } else if (IrpSp->Parameters.QueryFile.FileInformationClass ==
               FilePositionInformation) {

        if (IrpSp->Parameters.DeviceIoControl.OutputBufferLength <
                sizeof(FILE_POSITION_INFORMATION))
        {
                Status = STATUS_BUFFER_TOO_SMALL;
        }
        else
        {

            ((PFILE_POSITION_INFORMATION)Irp->AssociatedIrp.SystemBuffer)->
                CurrentByteOffset.QuadPart = 0;
            Irp->IoStatus.Information = sizeof(FILE_POSITION_INFORMATION);
        }

    } else {
        Status = STATUS_INVALID_PARAMETER;
    }

    Irp->IoStatus.Status = Status;

    IoCompleteRequest(Irp, IO_NO_INCREMENT);

    return Status;

}

NTSTATUS
SerialSetInformationFile(
    IN WDFDEVICE Device,
    IN PIRP Irp
    )

/*++

Routine Description:

    This routine is used to set the end of file information on
    the opened parallel port.  Any other file information request
    is retured with an invalid parameter.

    This routine always ignores the actual end of file since
    the query information code always returns an end of file of 0.

Arguments:

    DeviceObject - Pointer to the device object for this device

    Irp - Pointer to the IRP for the current request

Return Value:

The function value is the final status of the call

--*/

{
    NTSTATUS Status;

    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, ">SerialSetInformationFile(%p, %p)\n", Device, Irp);

    Irp->IoStatus.Information = 0L;
    if ((IoGetCurrentIrpStackLocation(Irp)->
            Parameters.SetFile.FileInformationClass ==
         FileEndOfFileInformation) ||
        (IoGetCurrentIrpStackLocation(Irp)->
            Parameters.SetFile.FileInformationClass ==
         FileAllocationInformation)) {

        Status = STATUS_SUCCESS;

    } else {

        Status = STATUS_INVALID_PARAMETER;

    }

    Irp->IoStatus.Status = Status;

    IoCompleteRequest(Irp, IO_NO_INCREMENT);

    return Status;

}

