/*++
Copyright (c) Microsoft Corporation

Module Name:

    error.c

Abstract:

    This module contains the code that is very specific to error
    operations in the serial driver

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "error.tmh"
#endif


VOID
SerialCommError(
    IN WDFDPC Dpc
    )
/*++

Routine Description:

    This routine is invoked at dpc level to in response to
    a comm error.  All comm errors complete all read and writes

Arguments:


Return Value:

    None.

--*/
{
    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfDpcGetParentObject(Dpc));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT,
                     ">SerialCommError(%p)\n", Extension);

    SerialFlushRequests(
        Extension->WriteQueue,
        &Extension->CurrentWriteRequest
        );

    SerialFlushRequests(
        Extension->ReadQueue,
        &Extension->CurrentReadRequest
        );

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT,
                     "<SerialCommError\n");
}


