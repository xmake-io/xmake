/*++

Copyright (c) 1991, 1992, 1993 - 1997 Microsoft Corporation

Module Name:

    immediat.c

Abstract:

    This module contains the code that is very specific to transmit
    immediate character operations in the serial driver

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "immediat.tmh"
#endif


VOID
SerialGetNextImmediate(
    IN WDFREQUEST *CurrentOpRequest,
    IN WDFQUEUE QueueToProcess,
    IN WDFREQUEST *NewRequest,
    IN BOOLEAN CompleteCurrent,
    IN PSERIAL_DEVICE_EXTENSION Extension
    );

EVT_WDF_REQUEST_CANCEL SerialCancelImmediate;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGiveImmediateToIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGrabImmediateFromIsr;


VOID
SerialStartImmediate(
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine will calculate the timeouts needed for the
    write.  It will then hand the request off to the isr.  It
    will need to be careful incase the request has been canceled.

Arguments:

    Extension - A pointer to the serial device extension.

Return Value:

    None.

--*/

{
    LARGE_INTEGER TotalTime = {0};
    BOOLEAN UseATimer;
    SERIAL_TIMEOUTS Timeouts;
    PREQUEST_CONTEXT reqContext;

    reqContext = SerialGetRequestContext(Extension->CurrentImmediateRequest);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, ">SerialStartImmediate(%p)\n",
                     Extension);

    UseATimer = FALSE;
    reqContext->Status = STATUS_PENDING;

    //
    // Calculate the timeout value needed for the
    // request.  Note that the values stored in the
    // timeout record are in milliseconds.  Note that
    // if the timeout values are zero then we won't start
    // the timer.
    //

    Timeouts = Extension->Timeouts;

    if (Timeouts.WriteTotalTimeoutConstant ||
        Timeouts.WriteTotalTimeoutMultiplier) {

        UseATimer = TRUE;

        //
        // We have some timer values to calculate.
        //

        TotalTime.QuadPart
           = (LONGLONG)((ULONG)Timeouts.WriteTotalTimeoutMultiplier);

        TotalTime.QuadPart += Timeouts.WriteTotalTimeoutConstant;

        TotalTime.QuadPart *= -10000;

    }

    //
    // As the request might be going to the isr, this is a good time
    // to initialize the reference count.
    //

    SERIAL_INIT_REFERENCE(reqContext);

     //
     // We give the request to to the isr to write out.
     // We set a cancel routine that knows how to
     // grab the current write away from the isr.
     //
    SerialSetCancelRoutine(Extension->CurrentImmediateRequest,
                                    SerialCancelImmediate);

    if (UseATimer) {
        BOOLEAN result;

        result = SerialSetTimer(
            Extension->ImmediateTotalTimer,
            TotalTime
            );

        if(result == FALSE) {
            //
            // Since the timer knows about the request we increment
            // the reference count.
            //

            SERIAL_SET_REFERENCE(
                reqContext,
                SERIAL_REF_TOTAL_TIMER
                );
        }
    }

    WdfInterruptSynchronize(
        Extension->WdfInterrupt,
        SerialGiveImmediateToIsr,
        Extension
        );


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "<SerialStartImmediate\n");

}

VOID
SerialCompleteImmediate(
    IN WDFDPC Dpc
    )

{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfDpcGetParentObject(Dpc));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, ">SerialCompleteImmediate(%p)\n",
                     Extension);

    SerialTryToCompleteCurrent(
        Extension,
        NULL,
        STATUS_SUCCESS,
        &Extension->CurrentImmediateRequest,
        NULL,
        NULL,
        Extension->ImmediateTotalTimer,
        NULL,
        SerialGetNextImmediate,
        SERIAL_REF_ISR
        );

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, "<SerialCompleteImmediate\n");

}

VOID
SerialTimeoutImmediate(
    IN WDFTIMER Timer
    )
{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfTimerGetParentObject(Timer));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, ">SerialTimeoutImmediate(%p)\n",
                     Extension);

    SerialTryToCompleteCurrent(
        Extension,
        SerialGrabImmediateFromIsr,
        STATUS_TIMEOUT,
        &Extension->CurrentImmediateRequest,
        NULL,
        NULL,
        Extension->ImmediateTotalTimer,
        NULL,
        SerialGetNextImmediate,
        SERIAL_REF_TOTAL_TIMER
        );

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, "<SerialTimeoutImmediate\n");
}

VOID
SerialGetNextImmediate(
    IN WDFREQUEST *CurrentOpRequest,
    IN WDFQUEUE QueueToProcess,
    IN WDFREQUEST *NewRequest,
    IN BOOLEAN CompleteCurrent,
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine is used to complete the current immediate
    request.  Even though the current immediate will always
    be completed and there is no queue associated with it,
    we use this routine so that we can try to satisfy
    a wait for transmit queue empty event.

Arguments:

    CurrentOpRequest - Pointer to the pointer that points to the
                   current write request.  This should point
                   to CurrentImmediateRequest.

    QueueToProcess - Always NULL.

    NewRequest - Always NULL on exit to this routine.

    CompleteCurrent - Should always be true for this routine.


Return Value:

    None.

--*/

{
    WDFREQUEST oldRequest = *CurrentOpRequest;
    PREQUEST_CONTEXT reqContext = SerialGetRequestContext(oldRequest);

    UNREFERENCED_PARAMETER(QueueToProcess);
    UNREFERENCED_PARAMETER(CompleteCurrent);


    ASSERT(Extension->TotalCharsQueued >= 1);
    Extension->TotalCharsQueued--;

    *CurrentOpRequest = NULL;
    *NewRequest = NULL;
     WdfInterruptSynchronize(
        Extension->WdfInterrupt,
        SerialProcessEmptyTransmit,
        Extension
        );

    SerialCompleteRequest(oldRequest, reqContext->Status, reqContext->Information);
}

VOID
SerialCancelImmediate(
    IN WDFREQUEST Request
    )

/*++

Routine Description:

    This routine is used to cancel a request that is waiting on
    a comm event.

Arguments:

    Request - Pointer to the WDFREQUEST for the current request

Return Value:

    None.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = NULL;
    WDFDEVICE  device = WdfIoQueueGetDevice(WdfRequestGetIoQueue(Request));

    UNREFERENCED_PARAMETER(Request);

    Extension = SerialGetDeviceExtension(device);

    SerialTryToCompleteCurrent(
        Extension,
        SerialGrabImmediateFromIsr,
        STATUS_CANCELLED,
        &Extension->CurrentImmediateRequest,
        NULL,
        NULL,
        Extension->ImmediateTotalTimer,
        NULL,
        SerialGetNextImmediate,
        SERIAL_REF_CANCEL
        );

}

BOOLEAN
SerialGiveImmediateToIsr(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )
/*++

Routine Description:

    Try to start off the write by slipping it in behind
    a transmit immediate char, or if that isn't available
    and the transmit holding register is empty, "tickle"
    the UART into interrupting with a transmit buffer
    empty.

    NOTE: This routine is called by WdfInterruptSynchronize.

    NOTE: This routine assumes that it is called with the
          cancel spin lock held.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/
{
    PSERIAL_DEVICE_EXTENSION Extension = Context;
    PREQUEST_CONTEXT         reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentImmediateRequest);

    Extension->TransmitImmediate = TRUE;
    Extension->ImmediateChar =  *((UCHAR *) (reqContext->SystemBuffer));

    //
    // The isr now has a reference to the request.
    //

    SERIAL_SET_REFERENCE(
        reqContext,
        SERIAL_REF_ISR
        );

    //
    // Check first to see if a write is going on.  If
    // there is then we'll just slip in during the write.
    //

    if (!Extension->WriteLength) {

        //
        // If there is no normal write transmitting then we
        // will "re-enable" the transmit holding register empty
        // interrupt.  The 8250 family of devices will always
        // signal a transmit holding register empty interrupt
        // *ANY* time this bit is set to one.  By doing things
        // this way we can simply use the normal interrupt code
        // to start off this write.
        //
        // We've been keeping track of whether the transmit holding
        // register is empty so it we only need to do this
        // if the register is empty.
        //

        if (Extension->HoldingEmpty) {
            DISABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
            ENABLE_ALL_INTERRUPTS(Extension, Extension->Controller);

        }

    }

    return FALSE;

}

BOOLEAN
SerialGrabImmediateFromIsr(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:


    This routine is used to grab the current request, which could be timing
    out or canceling, from the ISR

    NOTE: This routine is being called from WdfInterruptSynchronize.

    NOTE: This routine assumes that the cancel spin lock is held
          when this routine is called.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    Always false.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = Context;
    PREQUEST_CONTEXT         reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentImmediateRequest);

    if (Extension->TransmitImmediate) {

        Extension->TransmitImmediate = FALSE;

        //
        // Since the isr no longer references this request, we can
        // decrement it's reference count.
        //

        SERIAL_CLEAR_REFERENCE(
            reqContext,
            SERIAL_REF_ISR
            );

    }

    return FALSE;

}


