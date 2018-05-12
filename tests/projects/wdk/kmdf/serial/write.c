/*++

Copyright (c) Microsoft Corporation

Module Name:

    write.c

Abstract:

    This module contains the code that is very specific to write
    operations in the serial driver

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "write.tmh"
#endif

EVT_WDF_REQUEST_CANCEL SerialCancelCurrentWrite;
EVT_WDF_REQUEST_CANCEL SerialCancelCurrentXoff;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGiveWriteToIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGiveXoffToIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGrabWriteFromIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGrabXoffFromIsr;


VOID
SerialEvtIoWrite(
    IN WDFQUEUE         Queue,
    IN WDFREQUEST       Request,
    IN size_t            Length
    )

/*++

Routine Description:

    This is the dispatch routine for write.  It validates the parameters
    for the write request and if all is ok then it places the request
    on the work queue.

Arguments:

    Queue - Handle to the framework queue object that is associated
            with the I/O request.
    Request - Pointer to the WDFREQUEST for the current request

    Length - Length of the IO operation
                 The default property of the queue is to not dispatch
                 zero lenght read & write requests to the driver and
                 complete is with status success. So we will never get
                 a zero length request.

Return Value:

--*/

{

    PSERIAL_DEVICE_EXTENSION extension;
    NTSTATUS status;
    WDFDEVICE hDevice;
    WDF_REQUEST_PARAMETERS params;
    PREQUEST_CONTEXT reqContext;
    size_t bufLen;

    hDevice = WdfIoQueueGetDevice(Queue);
    extension = SerialGetDeviceExtension(hDevice);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE,
                    ">SerialEvtIoWrite(%p, 0x%I64x)\n", Request,  Length);

    if (SerialCompleteIfError(extension, Request) != STATUS_SUCCESS) {

        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialEvtIoWrite (2) %d\n", STATUS_CANCELLED);
        return;

    }


    WDF_REQUEST_PARAMETERS_INIT(&params);

    WdfRequestGetParameters(
          Request,
          &params
          );

    //
    // Initialize the scratch area of the request.
    //
    reqContext = SerialGetRequestContext(Request);
    reqContext->MajorFunction = params.Type;
    reqContext->Length = (ULONG) Length;

    status = WdfRequestRetrieveInputBuffer (Request, Length, &reqContext->SystemBuffer, &bufLen);

    if (!NT_SUCCESS (status)) {

        SerialCompleteRequest(Request , status, 0);
        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialEvtIoWrite (4) %X\n", status);
        return;
    }

   SerialStartOrQueue(extension, Request, extension->WriteQueue,
                               &extension->CurrentWriteRequest,
                               SerialStartWrite);

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialEvtIoWrite (5) %X\n", status);

   return ;

}

VOID
SerialStartWrite(
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine is used to start off any write.  It initializes
    the Iostatus fields of the request.  It will set up any timers
    that are used to control the write.

Arguments:

    Extension - Points to the serial device extension

Return Value:

--*/

{

    LARGE_INTEGER    TotalTime;
    BOOLEAN          UseATimer;
    SERIAL_TIMEOUTS  Timeouts;
    PREQUEST_CONTEXT reqContext;
    PREQUEST_CONTEXT reqContextXoff;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE,
                     ">SerialStartWrite(%p)\n", Extension);

    TotalTime.QuadPart = 0;

    do {

        reqContext = SerialGetRequestContext(Extension->CurrentWriteRequest);

        //
        // If there is an xoff counter then complete it.
        //

        //
        // We see if there is a actually an Xoff counter request.
        //
        // If there is, we put the write request back on the head
        // of the write list.  We then complete the xoff counter.
        // The xoff counter completing code will actually make the
        // xoff counter back into the current write request, and
        // in the course of completing the xoff (which is now
        // the current write) we will restart this request.
        //

        if (Extension->CurrentXoffRequest) {

            reqContextXoff =
                SerialGetRequestContext(Extension->CurrentXoffRequest);

            if (SERIAL_REFERENCE_COUNT(reqContextXoff)) {

                //
                // The reference count is non-zero.  This implies that
                // the xoff request has not made it through the completion
                // path yet.  We will increment the reference count
                // and attempt to complete it ourseleves.
                //

                SERIAL_SET_REFERENCE(
                    reqContextXoff,
                    SERIAL_REF_XOFF_REF
                    );

                reqContextXoff->Information = 0;

                //
                // The following call will actually release the
                // cancel spin lock.
                //

                SerialTryToCompleteCurrent(
                    Extension,
                    SerialGrabXoffFromIsr,
                    STATUS_SERIAL_MORE_WRITES,
                    &Extension->CurrentXoffRequest,
                    NULL,
                    NULL,
                    Extension->XoffCountTimer,
                    NULL,
                    NULL,
                    SERIAL_REF_XOFF_REF
                    );

            } else {

                //
                // The request is well on its way to being finished.
                // We can let the regular completion code do the
                // work.  Just release the spin lock.
                //

            }

        }

        UseATimer = FALSE;

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
            // Take care, we might have an xoff counter masquerading
            // as a write.
            //

            TotalTime.QuadPart =
                ((LONGLONG)((UInt32x32To64(
                                 (reqContext->MajorFunction == IRP_MJ_WRITE)?
                                     (reqContext->Length) : (1),
                                 Timeouts.WriteTotalTimeoutMultiplier
                                 )
                                 + Timeouts.WriteTotalTimeoutConstant)))
                * -10000;

        }

        //
        // The request may be going to the isr shortly.  Now
        // is a good time to initialize its reference counts.
        //

        SERIAL_INIT_REFERENCE(reqContext);

         //
         // We give the request to to the isr to write out.
         // We set a cancel routine that knows how to
         // grab the current write away from the isr.
         //
         SerialSetCancelRoutine(Extension->CurrentWriteRequest,
                                         SerialCancelCurrentWrite);

        if (UseATimer) {
            BOOLEAN result;

            result = SerialSetTimer(
                Extension->WriteRequestTotalTimer,
                TotalTime
                );
            if(result == FALSE) {
                //
                // This timer now has a reference to the request.
                //

                SERIAL_SET_REFERENCE( reqContext, SERIAL_REF_TOTAL_TIMER );
            }
        }

        WdfInterruptSynchronize(
            Extension->WdfInterrupt,
            SerialGiveWriteToIsr,
            Extension
            );

    } WHILE (FALSE);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialStartWrite \n");

    return;
}


VOID
SerialGetNextWrite(
    IN WDFREQUEST *CurrentOpRequest,
    IN WDFQUEUE QueueToProcess,
    IN WDFREQUEST *NewRequest,
    IN BOOLEAN CompleteCurrent,
    PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine completes the old write as well as getting
    a pointer to the next write.

    The reason that we have have pointers to the current write
    queue as well as the current write request is so that this
    routine may be used in the common completion code for
    read and write.

Arguments:

    CurrentOpRequest - Pointer to the pointer that points to the
                   current write request.

    QueueToProcess - Pointer to the write queue.

    NewRequest - A pointer to a pointer to the request that will be the
             current request.  Note that this could end up pointing
             to a null pointer.  This does NOT necessaryly mean
             that there is no current write.  What could occur
             is that while the cancel lock is held the write
             queue ended up being empty, but as soon as we release
             the cancel spin lock a new request came in from
             SerialStartWrite.

    CompleteCurrent - Flag indicates whether the CurrentOpRequest should
                      be completed.

Return Value:

    None.

--*/

{
    PREQUEST_CONTEXT reqContext;

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, ">SerialGetNextWrite\n");


    do {

        reqContext = SerialGetRequestContext(*CurrentOpRequest);

        //
        // We could be completing a flush.
        //

        if (reqContext->MajorFunction == IRP_MJ_WRITE) {

            ASSERT(Extension->TotalCharsQueued >= reqContext->Length);

            Extension->TotalCharsQueued -= reqContext->Length;

        } else if (reqContext->MajorFunction == IRP_MJ_DEVICE_CONTROL) {

            WDFREQUEST request = *CurrentOpRequest;
            PSERIAL_XOFF_COUNTER Xc;

            Xc = reqContext->SystemBuffer;

            //
            // We should never have a xoff counter when we
            // get to this point.
            //

            ASSERT(!Extension->CurrentXoffRequest);

            //
            // This could only be a xoff counter masquerading as
            // a write request.
            //

            Extension->TotalCharsQueued--;

            //
            // Check to see of the xoff request has been set with success.
            // This means that the write completed normally.  If that
            // is the case, and it hasn't been set to cancel in the
            // meanwhile, then go on and make it the CurrentXoffRequest.
            //

            if (reqContext->Status != STATUS_SUCCESS || reqContext->Cancelled) {

                // TODO: I see Xoff request getting abandoned due to loss of
                // Total timer - SERIAL_REF_TOTAL_TIMER
                //
                // Oh well, we can just finish it off.
                //
                NOTHING;

            } else {

                SerialSetCancelRoutine(request, SerialCancelCurrentXoff);

                //
                // We don't want to complete the current request now.  This
                // will now get completed by the Xoff counter code.
                //

                CompleteCurrent = FALSE;

                //
                // Give the counter to the isr.
                //

                Extension->CurrentXoffRequest = request;
                WdfInterruptSynchronize(
                    Extension->WdfInterrupt,
                    SerialGiveXoffToIsr,
                    Extension
                    );

                //
                // Start the timer for the counter and increment
                // the reference count since the timer has a
                // reference to the request.
                //

                if (Xc->Timeout) {

                    LARGE_INTEGER delta;
                    BOOLEAN result;

                    delta.QuadPart = -((LONGLONG)UInt32x32To64(
                                                     1000,
                                                     Xc->Timeout
                                                     ));

                    result = SerialSetTimer(
                        Extension->XoffCountTimer,
                        delta

                        );
                    if(result == FALSE) {
                        SERIAL_SET_REFERENCE(
                            reqContext,
                            SERIAL_REF_TOTAL_TIMER
                            );
                    }
                }

            }


        }

        //
        // Note that the following call will (probably) also cause
        // the current request to be completed.
        //

        SerialGetNextRequest(
            CurrentOpRequest,
            QueueToProcess,
            NewRequest,
            CompleteCurrent,
            Extension
            );

        if (!*NewRequest) {


            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialProcessEmptyTransmit,
                Extension
                );

            break;

        } else if (SerialGetRequestContext(*NewRequest)->MajorFunction
                   == IRP_MJ_FLUSH_BUFFERS) {

            //
            // If we encounter a flush request we just want to get
            // the next request and complete the flush.
            //
            // Note that if NewRequest is non-null then it is also
            // equal to CurrentWriteRequest.
            //


            ASSERT((*NewRequest) == (*CurrentOpRequest));
            SerialGetRequestContext(*NewRequest)->Status = STATUS_SUCCESS;

        } else {

            break;

        }

    } WHILE (TRUE);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialGetNextWrite\n");

}


VOID
SerialCompleteWrite(
    IN WDFDPC Dpc
    )

/*++

Routine Description:

    This routine is merely used to complete any write.  It
    assumes that the status and the information fields of
    the request are already correctly filled in.

Arguments:

    Dpc - Not Used.

    DeferredContext - Really points to the device extension.

    SystemContext1 - Not Used.

    SystemContext2 - Not Used.

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfDpcGetParentObject(Dpc));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, ">SerialCompleteWrite(%p)\n",
                     Extension);


    SerialTryToCompleteCurrent(Extension, NULL, STATUS_SUCCESS,
                               &Extension->CurrentWriteRequest,
                               Extension->WriteQueue, NULL,
                               Extension->WriteRequestTotalTimer,
                               SerialStartWrite, SerialGetNextWrite,
                               SERIAL_REF_ISR);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialCompleteWrite\n");

}


BOOLEAN
SerialProcessEmptyTransmit(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to determine if conditions are appropriate
    to satisfy a wait for transmit empty event, and if so to complete
    the request that is waiting for that event.  It also call the code
    that checks to see if we should lower the RTS line if we are
    doing transmit toggling.

    NOTE: This routine is called by WdfInterruptSynchronize.

    NOTE: This routine assumes that it is called with the cancel
          spinlock held.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    if (Extension->IsrWaitMask && (Extension->IsrWaitMask & SERIAL_EV_TXEMPTY) &&
        Extension->EmptiedTransmit && (!Extension->TransmitImmediate) &&
        (!Extension->CurrentWriteRequest) && IsQueueEmpty(Extension->WriteQueue)) {

        Extension->HistoryMask |= SERIAL_EV_TXEMPTY;
        if (Extension->IrpMaskLocation) {

            *Extension->IrpMaskLocation = Extension->HistoryMask;
            Extension->IrpMaskLocation = NULL;
            Extension->HistoryMask = 0;

            SerialGetRequestContext(Extension->CurrentWaitRequest)->Information = sizeof(ULONG);
            SerialInsertQueueDpc(
                Extension->CommWaitDpc
                );

        }

        Extension->CountOfTryingToLowerRTS++;
        SerialPerhapsLowerRTS(Extension->WdfInterrupt, Extension);

    }

    return FALSE;

}


BOOLEAN
SerialGiveWriteToIsr(
    IN WDFINTERRUPT Interrupt,
    IN PVOID Context
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

    //
    // The current stack location.  This contains all of the
    // information we need to process this particular request.
    //
    PREQUEST_CONTEXT reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentWriteRequest);

    //
    // We might have a xoff counter request masquerading as a
    // write.  The length of these requests will always be one
    // and we can get a pointer to the actual character from
    // the data supplied by the user.
    //

    if (reqContext->MajorFunction == IRP_MJ_WRITE) {

        Extension->WriteLength = reqContext->Length;
        Extension->WriteCurrentChar = reqContext->SystemBuffer;

    } else {

        Extension->WriteLength = 1;
        Extension->WriteCurrentChar =
            ((PUCHAR)reqContext->SystemBuffer) +
            FIELD_OFFSET(
                SERIAL_XOFF_COUNTER,
                XoffChar
                );

    }

    //
    // The isr now has a reference to the request.
    //

    SERIAL_SET_REFERENCE(
        reqContext,
        SERIAL_REF_ISR
        );

    //
    // Check first to see if an immediate char is transmitting.
    // If it is then we'll just slip in behind it when its
    // done.
    //

    if (!Extension->TransmitImmediate) {

        //
        // If there is no immediate char transmitting then we
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

    //
    // The rts line may already be up from previous writes,
    // however, it won't take much additional time to turn
    // on the RTS line if we are doing transmit toggling.
    //

    if ((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK) ==
        SERIAL_TRANSMIT_TOGGLE) {

        SerialSetRTS(Extension->WdfInterrupt, Extension);

    }

    return FALSE;

}


VOID
SerialCancelCurrentWrite(
    IN WDFREQUEST Request
    )

/*++

Routine Description:

    This routine is used to cancel the current write.

Arguments:

    Device - Wdf handle for the device

    Request - Pointer to the WDFREQUEST to be canceled.

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension;
    WDFDEVICE  device = WdfIoQueueGetDevice(WdfRequestGetIoQueue(Request));

    UNREFERENCED_PARAMETER(Request);

    Extension = SerialGetDeviceExtension(device);

    SerialTryToCompleteCurrent(
        Extension,
        SerialGrabWriteFromIsr,
        STATUS_CANCELLED,
        &Extension->CurrentWriteRequest,
        Extension->WriteQueue,
        NULL,
        Extension->WriteRequestTotalTimer,
        SerialStartWrite,
        SerialGetNextWrite,
        SERIAL_REF_CANCEL
        );

}


VOID
SerialWriteTimeout(
    IN WDFTIMER Timer
    )

/*++

Routine Description:

    This routine will try to timeout the current write.

Arguments:

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfTimerGetParentObject(Timer));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, ">SerialWriteTimeout(%p)\n",
                     Extension);

    SerialTryToCompleteCurrent(Extension, SerialGrabWriteFromIsr,
                               STATUS_TIMEOUT, &Extension->CurrentWriteRequest,
                               Extension->WriteQueue, NULL,
                               Extension->WriteRequestTotalTimer,
                               SerialStartWrite, SerialGetNextWrite,
                               SERIAL_REF_TOTAL_TIMER);


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialWriteTimeout\n");
}


BOOLEAN
SerialGrabWriteFromIsr(
    IN WDFINTERRUPT Interrupt,
    IN PVOID Context
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

    PREQUEST_CONTEXT reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentWriteRequest);

    //
    // Check if the write length is non-zero.  If it is non-zero
    // then the ISR still owns the request. We calculate the the number
    // of characters written and update the information field of the
    // request with the characters written.  We then clear the write length
    // the isr sees.
    //

    if (Extension->WriteLength) {

        //
        // We could have an xoff counter masquerading as a
        // write request.  If so, don't update the write length.
        //

        if (reqContext->MajorFunction == IRP_MJ_WRITE) {

            reqContext->Information = reqContext->Length -Extension->WriteLength;

        } else {

            reqContext->Information = 0;

        }

        //
        // Since the isr no longer references this request, we can
        // decrement it's reference count.
        //

        SERIAL_CLEAR_REFERENCE(
            reqContext,
            SERIAL_REF_ISR
            );

        Extension->WriteLength = 0;

    }

    return FALSE;

}


BOOLEAN
SerialGrabXoffFromIsr(
    IN WDFINTERRUPT Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to grab an xoff counter request from the
    isr when it is no longer masquerading as a write request.  This
    routine is called by the cancel and timeout code for the
    xoff counter ioctl.


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

    PREQUEST_CONTEXT reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentXoffRequest);

    if (Extension->CountSinceXoff) {

        //
        // This is only non-zero when there actually is a Xoff ioctl
        // counting down.
        //

        Extension->CountSinceXoff = 0;

        //
        // We decrement the count since the isr no longer owns
        // the request.
        //

        SERIAL_CLEAR_REFERENCE(
            reqContext,
            SERIAL_REF_ISR
            );

    }

    return FALSE;

}


VOID
SerialCompleteXoff(
    IN WDFDPC Dpc
    )

/*++

Routine Description:

    This routine is merely used to truely complete an xoff counter request.  It
    assumes that the status and the information fields of the request are
    already correctly filled in.

Arguments:

    Dpc - Not Used.

    DeferredContext - Really points to the device extension.

    SystemContext1 - Not Used.

    SystemContext2 - Not Used.

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfDpcGetParentObject(Dpc));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, ">SerialCompleteXoff(%p)\n",
                     Extension);


    SerialTryToCompleteCurrent(Extension, NULL, STATUS_SUCCESS,
                               &Extension->CurrentXoffRequest, NULL, NULL,
                               Extension->XoffCountTimer, NULL, NULL,
                               SERIAL_REF_ISR);


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialCompleteXoff\n");

}


VOID
SerialTimeoutXoff(
    IN WDFTIMER Timer
    )

/*++

Routine Description:

    This routine is merely used to truely complete an xoff counter request,
    if its timer has run out.

Arguments:


Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfTimerGetParentObject(Timer));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, ">SerialTimeoutXoff(%p)\n", Extension);

    SerialTryToCompleteCurrent(Extension, SerialGrabXoffFromIsr,
                               STATUS_SERIAL_COUNTER_TIMEOUT,
                               &Extension->CurrentXoffRequest, NULL, NULL, NULL,
                               NULL, NULL, SERIAL_REF_TOTAL_TIMER);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_WRITE, "<SerialTimeoutXoff\n");
}


VOID
SerialCancelCurrentXoff(
    IN WDFREQUEST Request
    )

/*++

Routine Description:

    This routine is used to cancel the current write.

Arguments:

    Device - Wdf handle for the device

    Request - Pointer to the WDFREQUEST to be canceled.

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension;
    WDFDEVICE  device = WdfIoQueueGetDevice(WdfRequestGetIoQueue(Request));

    UNREFERENCED_PARAMETER(Request);

    Extension = SerialGetDeviceExtension(device);

    SerialTryToCompleteCurrent(
        Extension,
        SerialGrabXoffFromIsr,
        STATUS_CANCELLED,
        &Extension->CurrentXoffRequest,
        NULL,
        NULL,
        Extension->XoffCountTimer,
        NULL,
        NULL,
        SERIAL_REF_CANCEL
        );

}


BOOLEAN
SerialGiveXoffToIsr(
    IN WDFINTERRUPT Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:


    This routine starts off the xoff counter.  It merely
    has to set the xoff count and increment the reference
    count to denote that the isr has a reference to the request.

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
    PREQUEST_CONTEXT reqContext;
    PSERIAL_XOFF_COUNTER Xc = NULL;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentXoffRequest);
    Xc = reqContext->SystemBuffer;

    //
    // The current stack location.  This contains all of the
    // information we need to process this particular request.
    //

    ASSERT(Extension->CurrentXoffRequest);
    Extension->CountSinceXoff = Xc->Counter;

    //
    // The isr now has a reference to the request.
    //

    SERIAL_SET_REFERENCE(
        reqContext,
        SERIAL_REF_ISR
        );

    return FALSE;

}


