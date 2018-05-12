/*++

Copyright (c) Microsoft Corporation

Module Name:

    purge.c

Abstract:

    This module contains the code that is very specific to purge
    operations in the serial driver

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "purge.tmh"
#endif


VOID
SerialStartPurge(
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    Depending on the mask in the current request, purge the interrupt
    buffer, the read queue, or the write queue, or all of the above.

Arguments:

    Extension - Pointer to the device extension.

Return Value:

    Will return STATUS_SUCCESS always.  This is reasonable
    since the DPC completion code that calls this routine doesn't
    care and the purge request always goes through to completion
    once it's started.

--*/

{

    WDFREQUEST NewRequest;
    PREQUEST_CONTEXT reqContext;

    do {

        ULONG Mask;
        reqContext = SerialGetRequestContext(Extension->CurrentPurgeRequest);
        Mask = *((ULONG *) (reqContext->SystemBuffer));

        if (Mask & SERIAL_PURGE_TXABORT) {

            SerialFlushRequests(
                Extension->WriteQueue,
                &Extension->CurrentWriteRequest
                );

            SerialFlushRequests(
                Extension->WriteQueue,
                &Extension->CurrentXoffRequest
                );

        }

        if (Mask & SERIAL_PURGE_RXABORT) {

            SerialFlushRequests(
                Extension->ReadQueue,
                &Extension->CurrentReadRequest
                );

        }

        if (Mask & SERIAL_PURGE_RXCLEAR) {

            //
            // Clean out the interrupt buffer.
            //
            // Note that we do this under protection of the
            // the drivers control lock so that we don't hose
            // the pointers if there is currently a read that
            // is reading out of the buffer.
            //


            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialPurgeInterruptBuff,
                Extension
                );

        }

        reqContext->Status = STATUS_SUCCESS;
        reqContext->Information = 0;

        SerialGetNextRequest(
            &Extension->CurrentPurgeRequest,
            Extension->PurgeQueue,
            &NewRequest,
            TRUE,
            Extension
            );

    } while (NewRequest);

    return;

}

BOOLEAN
SerialPurgeInterruptBuff(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine simply resets the interrupt (typeahead) buffer.

    NOTE: This routine is being called from WdfInterruptSynchronize.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    Always false.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    //
    // The typeahead buffer is by definition empty if there
    // currently is a read owned by the isr.
    //


    if (Extension->ReadBufferBase == Extension->InterruptReadBuffer) {

        Extension->CurrentCharSlot = Extension->InterruptReadBuffer;
        Extension->FirstReadableChar = Extension->InterruptReadBuffer;
        Extension->LastCharSlot = Extension->InterruptReadBuffer +
                                      (Extension->BufferSize - 1);
        Extension->CharsInInterruptBuffer = 0;

        SerialHandleReducedIntBuffer(Extension);

    }

    return FALSE;

}


