/*++

Copyright (c) Microsoft Corporation

Module Name:

    read.c

Abstract:

    This module contains the code that is very specific to read
    operations in the serial driver

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "read.tmh"
#endif

EVT_WDF_REQUEST_CANCEL SerialCancelCurrentRead;

EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGrabReadFromIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialUpdateReadByIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialUpdateInterruptBuffer;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialUpdateAndSwitchToUser;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialUpdateAndSwitchToNew;

ULONG
SerialGetCharsFromIntBuffer(
    PSERIAL_DEVICE_EXTENSION Extension
    );


NTSTATUS
SerialResizeBuffer(
    IN PSERIAL_DEVICE_EXTENSION Extension
    );

ULONG
SerialMoveToNewIntBuffer(
    PSERIAL_DEVICE_EXTENSION Extension,
    PUCHAR NewBuffer
    );

VOID
SerialEvtIoRead(
    IN WDFQUEUE         Queue,
    IN WDFREQUEST       Request,
    IN size_t            Length
    )

/*++

Routine Description:

    This is the dispatch routine for reading.  It validates the parameters
    for the read request and if all is ok then it places the request
    on the work queue.

Arguments:

    Queue - Queue handle
    Request - Handle to the read request
    Lenght - Length of the data buffer associated with the request.
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

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ,
                    ">SerialEvtIoRead(%p, 0x%I64x)\n", Request, Length);

    if (SerialCompleteIfError(extension, Request) != STATUS_SUCCESS) {

       SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, "<SerialEvtIoRead (2) %d\n", STATUS_CANCELLED);
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
    reqContext->Length  = (ULONG) Length;

    status = WdfRequestRetrieveOutputBuffer (Request, Length, &reqContext->SystemBuffer, &bufLen);

    if (!NT_SUCCESS (status)) {

        SerialCompleteRequest(Request , status, 0);
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_READ, "<SerialEvtIoRead (5) %X\n", status);
        return;
    }

    ASSERT(bufLen == reqContext->Length);

    //
    // Well it looks like we actually have to do some
    // work.  Put the read on the queue so that we can
    // process it when our previous reads are done.
    //
    SerialStartOrQueue(extension, Request, extension->ReadQueue,
                                   &extension->CurrentReadRequest, SerialStartRead);


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, "<SerialEvtIoRead (3) %X\n", status);

    return;

}

VOID
SerialStartRead(
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine is used to start off any read.  It initializes
    the Iostatus fields of the request.  It will set up any timers
    that are used to control the read.  It will attempt to complete
    the read from data already in the interrupt buffer.  If the
    read can be completed quickly it will start off another if
    necessary.

Arguments:

    Extension - Simply a pointer to the serial device extension.

Return Value:

    This routine will return the status of the first read
    request.  This is useful in that if we have a read that can
    complete right away (AND there had been nothing in the
    queue before it) the read could return SUCCESS and the
    application won't have to do a wait.

--*/

{

    SERIAL_UPDATE_CHAR updateChar;

    WDFREQUEST newRequest;

    BOOLEAN returnWithWhatsPresent;
    BOOLEAN os2ssreturn;
    BOOLEAN crunchDownToOne;
    BOOLEAN useTotalTimer;
    BOOLEAN useIntervalTimer;

    ULONG multiplierVal = 0;
    ULONG constantVal   = 0;

    LARGE_INTEGER totalTime = {0};

    SERIAL_TIMEOUTS timeoutsForIrp;

    PREQUEST_CONTEXT reqContext;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ,
                     ">SerialStartRead(%p)\n", Extension);

    updateChar.Extension = Extension;


    do {

        reqContext = SerialGetRequestContext(Extension->CurrentReadRequest);

        //
        // Check to see if this is a resize request.  If it is
        // then go to a routine that specializes in that.
        //

        if (reqContext->MajorFunction != IRP_MJ_READ) {

            NTSTATUS localStatus = SerialResizeBuffer(Extension);
            UNREFERENCED_PARAMETER(localStatus);
            ASSERT(NT_SUCCESS(localStatus));

        } else {

            Extension->NumberNeededForRead = reqContext->Length;

            //
            // Calculate the timeout value needed for the
            // request.  Note that the values stored in the
            // timeout record are in milliseconds.
            //

            useTotalTimer = FALSE;
            returnWithWhatsPresent = FALSE;
            os2ssreturn = FALSE;
            crunchDownToOne = FALSE;
            useIntervalTimer = FALSE;

            //
            //
            // CIMEXCIMEX -- this is a lie
            //
            // Always initialize the timer objects so that the
            // completion code can tell when it attempts to
            // cancel the timers whether the timers had ever
            // been Set.
            //
            // CIMEXCIMEX -- this is the truth
            //
            // What we want to do is just make sure the timers are
            // cancelled to the best of our ability and move on with
            // life.
            //

            SerialCancelTimer(Extension->ReadRequestTotalTimer, Extension);
            SerialCancelTimer(Extension->ReadRequestIntervalTimer, Extension);

            //
            // We get the *current* timeout values to use for timing
            // this read.
            //


            timeoutsForIrp = Extension->Timeouts;

            //
            // Calculate the interval timeout for the read.
            //

            if (timeoutsForIrp.ReadIntervalTimeout &&
                (timeoutsForIrp.ReadIntervalTimeout !=
                 MAXULONG)) {

                useIntervalTimer = TRUE;

                Extension->IntervalTime.QuadPart =
                    UInt32x32To64(
                        timeoutsForIrp.ReadIntervalTimeout,
                        10000
                        );


                if (Extension->IntervalTime.QuadPart >=
                    Extension->CutOverAmount.QuadPart) {

                    Extension->IntervalTimeToUse =
                        &Extension->LongIntervalAmount;

                } else {

                    Extension->IntervalTimeToUse =
                        &Extension->ShortIntervalAmount;

                }

            }

            if (timeoutsForIrp.ReadIntervalTimeout == MAXULONG) {

                //
                // We need to do special return quickly stuff here.
                //
                // 1) If both constant and multiplier are
                //    0 then we return immediately with whatever
                //    we've got, even if it was zero.
                //
                // 2) If constant and multiplier are not MAXULONG
                //    then return immediately if any characters
                //    are present, but if nothing is there, then
                //    use the timeouts as specified.
                //
                // 3) If multiplier is MAXULONG then do as in
                //    "2" but return when the first character
                //    arrives.
                //

                if (!timeoutsForIrp.ReadTotalTimeoutConstant &&
                    !timeoutsForIrp.ReadTotalTimeoutMultiplier) {

                    returnWithWhatsPresent = TRUE;

                } else if ((timeoutsForIrp.ReadTotalTimeoutConstant != MAXULONG)
                            &&
                           (timeoutsForIrp.ReadTotalTimeoutMultiplier
                            != MAXULONG)) {

                    useTotalTimer = TRUE;
                    os2ssreturn = TRUE;
                    multiplierVal = timeoutsForIrp.ReadTotalTimeoutMultiplier;
                    constantVal = timeoutsForIrp.ReadTotalTimeoutConstant;

                } else if ((timeoutsForIrp.ReadTotalTimeoutConstant != MAXULONG)
                            &&
                           (timeoutsForIrp.ReadTotalTimeoutMultiplier
                            == MAXULONG)) {

                    useTotalTimer = TRUE;
                    os2ssreturn = TRUE;
                    crunchDownToOne = TRUE;
                    multiplierVal = 0;
                    constantVal = timeoutsForIrp.ReadTotalTimeoutConstant;

                }

            } else {

                //
                // If both the multiplier and the constant are
                // zero then don't do any total timeout processing.
                //

                if (timeoutsForIrp.ReadTotalTimeoutMultiplier ||
                    timeoutsForIrp.ReadTotalTimeoutConstant) {

                    //
                    // We have some timer values to calculate.
                    //

                    useTotalTimer = TRUE;
                    multiplierVal = timeoutsForIrp.ReadTotalTimeoutMultiplier;
                    constantVal = timeoutsForIrp.ReadTotalTimeoutConstant;

                }

            }

            if (useTotalTimer) {

                totalTime.QuadPart = ((LONGLONG)(UInt32x32To64(
                                          Extension->NumberNeededForRead,
                                          multiplierVal
                                          )
                                          + constantVal))
                                      * -10000;

            }


            //
            // We do this copy in the hope of getting most (if not
            // all) of the characters out of the interrupt buffer.
            //
            // Note that we need to protect this operation with a
            // spinlock since we don't want a purge to hose us.
            //

            updateChar.CharsCopied = SerialGetCharsFromIntBuffer(Extension);

            //
            // See if we have any cause to return immediately.
            //

            if (returnWithWhatsPresent || (!Extension->NumberNeededForRead) ||
                (os2ssreturn &&
                 reqContext->Information)) {

                //
                // We got all we needed for this read.
                // Update the number of characters in the
                // interrupt read buffer.
                //

                WdfInterruptSynchronize(
                    Extension->WdfInterrupt,
                    SerialUpdateInterruptBuffer,
                    &updateChar
                    );

                reqContext->Status =  STATUS_SUCCESS;

            } else {

                //
                // The request might go under control of the isr.  It
                // won't hurt to initialize the reference count
                // right now.
                //

                SERIAL_INIT_REFERENCE(reqContext);

                //
                // If we are supposed to crunch the read down to
                // one character, then update the read length
                // in the request and truncate the number needed for
                // read down to one. Note that if we are doing
                // this crunching, then the information must be
                // zero (or we would have completed above) and
                // the number needed for the read must still be
                // equal to the read length.
                //

                if (crunchDownToOne) {

                    ASSERT(
                        (!reqContext->Information)
                        &&
                        (Extension->NumberNeededForRead == reqContext->Length)
                        );

                    Extension->NumberNeededForRead = 1;
                    reqContext->Length = 1;

                }

                //
                // We still need to get more characters for this read.
                // synchronize with the isr so that we can update the
                // number of characters and if necessary it will have the
                // isr switch to copying into the users buffer.
                //

                WdfInterruptSynchronize(
                    Extension->WdfInterrupt,
                    SerialUpdateAndSwitchToUser,
                    &updateChar
                    );

                if (!updateChar.Completed) {

                     SerialSetCancelRoutine(Extension->CurrentReadRequest,
                                                     SerialCancelCurrentRead);

                    //
                    // The request still isn't complete.  The
                    // completion routines will end up reinvoking
                    // this routine.  So we simply leave.
                    //
                    // First thought we should start off the total
                    // timer for the read and increment the reference
                    // count that the total timer has on the current
                    // request.  Note that this is safe, because even if
                    // the io has been satisfied by the isr it can't
                    // complete yet because we still own the cancel
                    // spinlock.
                    //

                    if (useTotalTimer) {
                        BOOLEAN result;

                        result = SerialSetTimer(
                            Extension->ReadRequestTotalTimer,
                            totalTime
                            );

                        if(result == FALSE) {
                            SERIAL_SET_REFERENCE(
                                reqContext,
                                SERIAL_REF_TOTAL_TIMER
                                );
                        }

                    }

                    if (useIntervalTimer) {

                        BOOLEAN result;

                        KeQuerySystemTime(
                            &Extension->LastReadTime

                            );
                        result = SerialSetTimer(
                            Extension->ReadRequestIntervalTimer,
                            *Extension->IntervalTimeToUse
                            );

                        if(result == FALSE) {
                            SERIAL_SET_REFERENCE(
                                reqContext,
                                SERIAL_REF_INT_TIMER
                                );
                        }

                    }

                    break;

                } else {

                    reqContext->Status = STATUS_SUCCESS;
                }

            }

        }

        //
        // Well the operation is complete.
        //

        SerialGetNextRequest(&Extension->CurrentReadRequest,
                             Extension->ReadQueue,
                             &newRequest, TRUE, Extension);

    } while (newRequest);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ,  "<SerialStartRead \n");

    return;

}


VOID
SerialCompleteRead(
    IN WDFDPC Dpc
    )

/*++

Routine Description:

    This routine is merely used to complete any read that
    ended up being used by the Isr.  It assumes that the
    status and the information fields of the request are already
    correctly filled in.

Arguments:

    Dpc - Not Used.


Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION extension = NULL;

    extension = SerialGetDeviceExtension(WdfDpcGetParentObject(Dpc));


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, ">SerialCompleteRead(%p)\n",
                     extension);

    //
    // We set this to indicate to the interval timer
    // that the read has completed.
    //
    // Recall that the interval timer dpc can be lurking in some
    // DPC queue.
    //

    extension->CountOnLastRead = SERIAL_COMPLETE_READ_COMPLETE;

    SerialTryToCompleteCurrent(
        extension,
        NULL,
        STATUS_SUCCESS,
        &extension->CurrentReadRequest,
        extension->ReadQueue,
        extension->ReadRequestIntervalTimer,
        extension->ReadRequestTotalTimer,
        SerialStartRead,
        SerialGetNextRequest,
        SERIAL_REF_ISR
        );


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, "<SerialCompleteRead\n");
}


VOID
SerialCancelCurrentRead(
    WDFREQUEST  Request
    )
/*++

Routine Description:

    This routine is used to cancel the current read.

Arguments:

    Device - Wdf device handle

    Request - Pointer to the WDFREQUEST to be canceled.

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION extension = NULL;
    WDFDEVICE  device = WdfIoQueueGetDevice(WdfRequestGetIoQueue(Request));

    UNREFERENCED_PARAMETER(Request);

    extension = SerialGetDeviceExtension(device);

    //
    // We set this to indicate to the interval timer
    // that the read has encountered a cancel.
    //
    // Recall that the interval timer dpc can be lurking in some
    // DPC queue.
    //

    extension->CountOnLastRead = SERIAL_COMPLETE_READ_CANCEL;

    SerialTryToCompleteCurrent(
        extension,
        SerialGrabReadFromIsr,
        STATUS_CANCELLED,
        &extension->CurrentReadRequest,
        extension->ReadQueue,
        extension->ReadRequestIntervalTimer,
        extension->ReadRequestTotalTimer,
        SerialStartRead,
        SerialGetNextRequest,
        SERIAL_REF_CANCEL
        );

}


BOOLEAN
SerialGrabReadFromIsr(
    IN WDFINTERRUPT Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to grab (if possible) the request from the
    isr.  If it finds that the isr still owns the request it grabs
    the ipr away (updating the number of characters copied into the
    users buffer).  If it grabs it away it also decrements the
    reference count on the request since it no longer belongs to the
    isr (and the dpc that would complete it).

    NOTE: This routine assumes that if the current buffer that the
          ISR is copying characters into is the interrupt buffer then
          the dpc has already been queued.

    NOTE: This routine is being called from WdfInterruptSynchronize.

    NOTE: This routine assumes that it is called with the cancel spin
          lock held.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    Always false.

--*/

{

    PSERIAL_DEVICE_EXTENSION extension = Context;
    PREQUEST_CONTEXT reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(extension->CurrentReadRequest);

    if (extension->ReadBufferBase !=
        extension->InterruptReadBuffer) {

        //
        // We need to set the information to the number of characters
        // that the read wanted minus the number of characters that
        // didn't get read into the interrupt buffer.
        //

        reqContext->Information = reqContext->Length -
            ((extension->LastCharSlot - extension->CurrentCharSlot) + 1);

        //
        // Switch back to the interrupt buffer.
        //

        extension->ReadBufferBase = extension->InterruptReadBuffer;
        extension->CurrentCharSlot = extension->InterruptReadBuffer;
        extension->FirstReadableChar = extension->InterruptReadBuffer;
        extension->LastCharSlot = extension->InterruptReadBuffer +
                                      (extension->BufferSize - 1);
        extension->CharsInInterruptBuffer = 0;

        SERIAL_CLEAR_REFERENCE(
            reqContext,
            SERIAL_REF_ISR
            );

    }

    return FALSE;

}

VOID
SerialReadTimeout(
    IN WDFTIMER Timer
    )

/*++

Routine Description:

    This routine is used to complete a read because its total
    timer has expired.

Arguments:


Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION extension = NULL;

    extension = SerialGetDeviceExtension(WdfTimerGetParentObject(Timer));


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, ">SerialReadTimeout(%p)\n",
                     extension);

    //
    // We set this to indicate to the interval timer
    // that the read has completed due to total timeout.
    //
    // Recall that the interval timer dpc can be lurking in some
    // DPC queue.
    //

    extension->CountOnLastRead = SERIAL_COMPLETE_READ_TOTAL;

    SerialTryToCompleteCurrent(
        extension,
        SerialGrabReadFromIsr,
        STATUS_TIMEOUT,
        &extension->CurrentReadRequest,
        extension->ReadQueue,
        extension->ReadRequestIntervalTimer,
        extension->ReadRequestTotalTimer,
        SerialStartRead,
        SerialGetNextRequest,
        SERIAL_REF_TOTAL_TIMER
        );


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, "<SerialReadTimeout\n");
}


BOOLEAN
SerialUpdateReadByIsr(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to update the count of characters read
    by the isr since the last interval timer experation.

    NOTE: This routine is being called from WdfInterruptSynchronize.

    NOTE: This routine assumes that it is called with the cancel spin
          lock held.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    Always false.

--*/

{

    PSERIAL_DEVICE_EXTENSION extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    extension->CountOnLastRead = extension->ReadByIsr;
    extension->ReadByIsr = 0;

    return FALSE;

}


VOID
SerialIntervalReadTimeout(
    IN WDFTIMER Timer
    )

/*++

Routine Description:

    This routine is used timeout the request if the time between
    characters exceed the interval time.  A global is kept in
    the device extension that records the count of characters read
    the last the last time this routine was invoked (This dpc
    will resubmit the timer if the count has changed).  If the
    count has not changed then this routine will attempt to complete
    the request.  Note the special case of the last count being zero.
    The timer isn't really in effect until the first character is
    read.

Arguments:


Return Value:

    None.

--*/

{
    PSERIAL_DEVICE_EXTENSION extension = NULL;

    extension = SerialGetDeviceExtension(WdfTimerGetParentObject(Timer));


    //SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, ">SerialIntervalReadTimeout(%p)\n",
    //                 extension);

    if (extension->CountOnLastRead == SERIAL_COMPLETE_READ_TOTAL) {

        //
        // This value is only set by the total
        // timer to indicate that it has fired.
        // If so, then we should simply try to complete.
        //
        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT, "in SERIAL_COMPLETE_READ_TOTAL\n");

        SerialTryToCompleteCurrent(
            extension,
            SerialGrabReadFromIsr,
            STATUS_TIMEOUT,
            &extension->CurrentReadRequest,
            extension->ReadQueue,
            extension->ReadRequestIntervalTimer,
            extension->ReadRequestTotalTimer,
            SerialStartRead,
            SerialGetNextRequest,
            SERIAL_REF_INT_TIMER
            );

    } else if (extension->CountOnLastRead == SERIAL_COMPLETE_READ_COMPLETE) {

        //
        // This value is only set by the regular
        // completion routine.
        //
        // If so, then we should simply try to complete.
        //
        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT, "in SERIAL_COMPLETE_READ_COMPLETE\n");

        SerialTryToCompleteCurrent(
            extension,
            SerialGrabReadFromIsr,
            STATUS_SUCCESS,
            &extension->CurrentReadRequest,
            extension->ReadQueue,
            extension->ReadRequestIntervalTimer,
            extension->ReadRequestTotalTimer,
            SerialStartRead,
            SerialGetNextRequest,
            SERIAL_REF_INT_TIMER
            );

    } else if (extension->CountOnLastRead == SERIAL_COMPLETE_READ_CANCEL) {

        //
        // This value is only set by the cancel
        // read routine.
        //
        // If so, then we should simply try to complete.
        //
        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_INIT, "in SERIAL_COMPLETE_READ_CANCEL\n");

        SerialTryToCompleteCurrent(
            extension,
            SerialGrabReadFromIsr,
            STATUS_CANCELLED,
            &extension->CurrentReadRequest,
            extension->ReadQueue,
            extension->ReadRequestIntervalTimer,
            extension->ReadRequestTotalTimer,
            SerialStartRead,
            SerialGetNextRequest,
            SERIAL_REF_INT_TIMER
            );

    } else if (extension->CountOnLastRead || extension->ReadByIsr) {

        //
        // Something has happened since we last came here.  We
        // check to see if the ISR has read in any more characters.
        // If it did then we should update the isr's read count
        // and resubmit the timer.
        //

        if (extension->ReadByIsr) {

            WdfInterruptSynchronize(
                extension->WdfInterrupt,
                SerialUpdateReadByIsr,
                extension
                );

            //
            // Save off the "last" time something was read.
            // As we come back to this routine we will compare
            // the current time to the "last" time.  If the
            // difference is ever larger then the interval
            // requested by the user, then time out the request.
            //

            KeQuerySystemTime(
                &extension->LastReadTime
                );

            SerialSetTimer(
                extension->ReadRequestIntervalTimer,
                *extension->IntervalTimeToUse
                );

        } else {

            //
            // Take the difference between the current time
            // and the last time we had characters and
            // see if it is greater then the interval time.
            // if it is, then time out the request.  Otherwise
            // go away again for a while.
            //

            //
            // No characters read in the interval time.  Kill
            // this read.
            //

            LARGE_INTEGER currentTime;

            KeQuerySystemTime(
                &currentTime
                );

            if ((currentTime.QuadPart - extension->LastReadTime.QuadPart) >=
                extension->IntervalTime.QuadPart) {

                SerialTryToCompleteCurrent(
                    extension,
                    SerialGrabReadFromIsr,
                    STATUS_TIMEOUT,
                    &extension->CurrentReadRequest,
                    extension->ReadQueue,
                    extension->ReadRequestIntervalTimer,
                    extension->ReadRequestTotalTimer,
                    SerialStartRead,
                    SerialGetNextRequest,
                    SERIAL_REF_INT_TIMER
                    );

            } else {

                SerialSetTimer(
                    extension->ReadRequestIntervalTimer,
                    *extension->IntervalTimeToUse
                    );

            }


        }

    } else {

        //
        // Timer doesn't really start until the first character.
        // So we should simply resubmit ourselves.
        //

        SerialSetTimer(
            extension->ReadRequestIntervalTimer,
            *extension->IntervalTimeToUse
            );

    }


    //SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_READ, "<SerialIntervalReadTimeout\n");
}


ULONG
SerialGetCharsFromIntBuffer(
    PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine is used to copy any characters out of the interrupt
    buffer into the users buffer.  It will be reading values that
    are updated with the ISR but this is safe since this value is
    only decremented by synchronization routines.  This routine will
    return the number of characters copied so some other routine
    can call a synchronization routine to update what is seen at
    interrupt level.

Arguments:

    Extension - A pointer to the device extension.

Return Value:

    The number of characters that were copied into the user
    buffer.

--*/

{

    //
    // This value will be the number of characters that this
    // routine returns.  It will be the minimum of the number
    // of characters currently in the buffer or the number of
    // characters required for the read.
    //
    ULONG numberOfCharsToGet;

    //
    // This holds the number of characters between the first
    // readable character and - the last character we will read or
    // the real physical end of the buffer (not the last readable
    // character).
    //
    ULONG firstTryNumberToGet;

    PREQUEST_CONTEXT reqContext = SerialGetRequestContext(Extension->CurrentReadRequest);

    //
    // The minimum of the number of characters we need and
    // the number of characters available
    //

    numberOfCharsToGet = Extension->CharsInInterruptBuffer;

    if (numberOfCharsToGet > Extension->NumberNeededForRead) {

        numberOfCharsToGet = Extension->NumberNeededForRead;

    }

    if (numberOfCharsToGet) {

        //
        // This will hold the number of characters between the
        // first available character and the end of the buffer.
        // Note that the buffer could wrap around but for the
        // purposes of the first copy we don't care about that.
        //

        firstTryNumberToGet = (ULONG)(Extension->LastCharSlot -
                               Extension->FirstReadableChar) + 1;

        if (firstTryNumberToGet > numberOfCharsToGet) {

            //
            // The characters don't wrap. Actually they may wrap but
            // we don't care for the purposes of this read since the
            // characters we need are available before the wrap.
            //

            RtlMoveMemory(
                ((PUCHAR)(reqContext->SystemBuffer))
                    + (reqContext->Length - Extension->NumberNeededForRead),
                Extension->FirstReadableChar,
                numberOfCharsToGet
                );

            Extension->NumberNeededForRead -= numberOfCharsToGet;

            //
            // We now will move the pointer to the first character after
            // what we just copied into the users buffer.
            //
            // We need to check if the stream of readable characters
            // is wrapping around to the beginning of the buffer.
            //
            // Note that we may have just taken the last characters
            // at the end of the buffer.
            //

            if ((Extension->FirstReadableChar + (numberOfCharsToGet - 1)) ==
                Extension->LastCharSlot) {

                Extension->FirstReadableChar = Extension->InterruptReadBuffer;

            } else {

                Extension->FirstReadableChar += numberOfCharsToGet;

            }

        } else {

            //
            // The characters do wrap.  Get up until the end of the buffer.
            //

            RtlMoveMemory(
                ((PUCHAR)(reqContext->SystemBuffer))
                    + (reqContext->Length - Extension->NumberNeededForRead),
                Extension->FirstReadableChar,
                firstTryNumberToGet
                );

            Extension->NumberNeededForRead -= firstTryNumberToGet;

            //
            // Now get the rest of the characters from the beginning of the
            // buffer.
            //

            RtlMoveMemory(
                ((PUCHAR)(reqContext->SystemBuffer))
                    + (reqContext->Length  - Extension->NumberNeededForRead),
                Extension->InterruptReadBuffer,
                numberOfCharsToGet - firstTryNumberToGet
                );

            Extension->FirstReadableChar = Extension->InterruptReadBuffer +
                                           (numberOfCharsToGet -
                                            firstTryNumberToGet);

            Extension->NumberNeededForRead -= (numberOfCharsToGet -
                                               firstTryNumberToGet);

        }

    }

    reqContext->Information += numberOfCharsToGet;
    return numberOfCharsToGet;

}


BOOLEAN
SerialUpdateInterruptBuffer(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to update the number of characters that
    remain in the interrupt buffer.  We need to use this routine
    since the count could be updated during the update by execution
    of the ISR.

    NOTE: This is called by WdfInterruptSynchronize.

Arguments:

    Context - Points to a structure that contains a pointer to the
              device extension and count of the number of characters
              that we previously copied into the users buffer.  The
              structure actually has a third field that we don't
              use in this routine.

Return Value:

    Always FALSE.

--*/

{

    PSERIAL_UPDATE_CHAR update = Context;
    PSERIAL_DEVICE_EXTENSION extension = update->Extension;

    UNREFERENCED_PARAMETER(Interrupt);

    ASSERT(extension->CharsInInterruptBuffer >= update->CharsCopied);
    extension->CharsInInterruptBuffer -= update->CharsCopied;

    //
    // Deal with flow control if necessary.
    //

    SerialHandleReducedIntBuffer(extension);


    return FALSE;

}


BOOLEAN
SerialUpdateAndSwitchToUser(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine gets the (hopefully) few characters that
    remain in the interrupt buffer after the first time we tried
    to get them out.  If we still don't have enough characters
    to satisfy the read it will then we set things up so that the
    ISR uses the user buffer copy into.

    This routine is also used to update a count that is maintained
    by the ISR to keep track of the number of characters in its buffer.

    NOTE: This is called by WdfInterruptSynchronize.

Arguments:

    Context - Points to a structure that contains a pointer to the
              device extension, a count of the number of characters
              that we previously copied into the users buffer, and
              a boolean that we will set that defines whether we
              switched the ISR to copy into the users buffer.

Return Value:

    Always FALSE.

--*/

{

    PSERIAL_UPDATE_CHAR      updateChar = Context;
    PSERIAL_DEVICE_EXTENSION extension = updateChar->Extension;
    PREQUEST_CONTEXT         reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(extension->CurrentReadRequest);

    SerialUpdateInterruptBuffer(extension->WdfInterrupt, Context);

    //
    // There are more characters to get to satisfy this read.
    // Copy any characters that have arrived since we got
    // the last batch.
    //

    updateChar->CharsCopied = SerialGetCharsFromIntBuffer(extension);

    SerialUpdateInterruptBuffer(extension->WdfInterrupt, Context);

    //
    // No more new characters will be "received" until we exit
    // this routine.  We again check to make sure that we
    // haven't satisfied this read, and if we haven't we set things
    // up so that the ISR copies into the user buffer.
    //

    if (extension->NumberNeededForRead) {

        //
        // We shouldn't be switching unless there are no
        // characters left.
        //

        ASSERT(!extension->CharsInInterruptBuffer);

        //
        // We use the following to values to do inteval timing.
        //
        // CountOnLastRead is mostly used to simply prevent
        // the interval timer from timing out before any characters
        // are read. (Interval timing should only be effective
        // after the first character is read.)
        //
        // After the first time the interval timer fires and
        // characters have be read we will simply update with
        // the value of ReadByIsr and then set ReadByIsr to zero.
        // (We do that in a synchronization routine.
        //
        // If the interval timer dpc routine ever encounters
        // ReadByIsr == 0 when CountOnLastRead is non-zero it
        // will timeout the read.
        //
        // (Note that we have a special case of CountOnLastRead
        // < 0.  This is done by the read completion routines other
        // than the total timeout dpc to indicate that the total
        // timeout has expired.)
        //

        extension->CountOnLastRead = (LONG)reqContext->Information;

        extension->ReadByIsr = 0;

        //
        // By compareing the read buffer base address to the
        // the base address of the interrupt buffer the ISR
        // can determine whether we are using the interrupt
        // buffer or the user buffer.
        //

        extension->ReadBufferBase = reqContext->SystemBuffer;

        //
        // The current char slot is after the last copied in
        // character.  We know there is always room since we
        // we wouldn't have gotten here if there wasn't.
        //

        extension->CurrentCharSlot = extension->ReadBufferBase +
                                    reqContext->Information;

        //
        // The last position that a character can go is on the
        // last byte of user buffer.  While the actual allocated
        // buffer space may be bigger, we know that there is at
        // least as much as the read length.
        //

        extension->LastCharSlot = extension->ReadBufferBase +
                                      (reqContext->Length - 1);
#if 0 // We set the cancel before calling this routine in StartRead
        //
        // Mark the request as being in a cancelable state.
        //
        IoSetCancelRoutine(
            extension->CurrentReadIrp,
            SerialCancelCurrentRead
            );

       SERIAL_SET_REFERENCE(
            reqContext,
            SERIAL_REF_CANCEL
            );
#endif
        //
        // Increment the reference count twice.
        //
        // Once for the Isr owning the request and once
        // because the cancel routine has a reference
        // to it.
        //

        SERIAL_SET_REFERENCE(
            reqContext,
            SERIAL_REF_ISR
            );

        updateChar->Completed = FALSE;

    } else {

        updateChar->Completed = TRUE;

    }

    return FALSE;

}
//
// We use this structure only to communicate to the synchronization
// routine when we are switching to the resized buffer.
//
typedef struct _SERIAL_RESIZE_PARAMS {
    PSERIAL_DEVICE_EXTENSION Extension;
    PUCHAR OldBuffer;
    PUCHAR NewBuffer;
    ULONG NewBufferSize;
    ULONG NumberMoved;
    } SERIAL_RESIZE_PARAMS,*PSERIAL_RESIZE_PARAMS;


NTSTATUS
SerialResizeBuffer(
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine will process the resize buffer request.
    If size requested for the RX buffer is smaller than
    the current buffer then we will simply return
    STATUS_SUCCESS.  (We don't want to make buffers smaller.
    If we did that then we all of a sudden have "overrun"
    problems to deal with as well as flow control to deal
    with - very painful.)  We ignore the TX buffer size
    request since we don't use a TX buffer.

Arguments:

    Extension - Pointer to the device extension for the port.

Return Value:

    STATUS_SUCCESS if everything worked out ok.
    STATUS_INSUFFICIENT_RESOURCES if we couldn't allocate the
    memory for the buffer.

--*/

{

    PREQUEST_CONTEXT reqContext = SerialGetRequestContext(Extension->CurrentReadRequest);
    PSERIAL_QUEUE_SIZE rs = reqContext->SystemBuffer;

    PVOID newBuffer = reqContext->Type3InputBuffer;


    reqContext->Type3InputBuffer = NULL;
    reqContext->Information = 0L;
    reqContext->Status = STATUS_SUCCESS;

    if (rs->InSize <= Extension->BufferSize) {

        //
        // Nothing to do.  We don't make buffers smaller.  Just
        // agree with the user.  We must deallocate the memory
        // that was already allocated in the ioctl dispatch routine.
        //

        ExFreePool(newBuffer);

    } else {

        SERIAL_RESIZE_PARAMS rp;

        //
        // Hmmm, looks like we actually have to go
        // through with this.  We need to move all the
        // data that is in the current buffer into this
        // new buffer.  We'll do this in two steps.
        //
        // First we go up to dispatch level and try to
        // move as much as we can without stopping the
        // ISR from running.  We go up to dispatch level
        // by acquiring the control lock.  We do it at
        // dispatch using the control lock so that:
        //
        //    1) We can't be context switched in the middle
        //       of the move.  Our pointers into the buffer
        //       could be *VERY* stale by the time we got back.
        //
        //    2) We use the control lock since we don't want
        //       some pesky purge request to come along while
        //       we are trying to move.
        //
        // After the move, but while we still hold the control
        // lock, we synch with the ISR and get those last
        // (hopefully) few characters that have come in since
        // we started the copy.  We switch all of our pointers,
        // counters, and such to point to this new buffer.  NOTE:
        // we need to be careful.  If the buffer we were using
        // was not the default one created when we initialized
        // the device (i.e. it was created via a previous WDFREQUEST of
        // this type), we should deallocate it.
        //

        rp.Extension = Extension;
        rp.OldBuffer = Extension->InterruptReadBuffer;
        rp.NewBuffer = newBuffer;
        rp.NewBufferSize = rs->InSize;

        rp.NumberMoved = SerialMoveToNewIntBuffer(
                             Extension,
                             newBuffer
                             );

        WdfInterruptSynchronize(
            Extension->WdfInterrupt,
            SerialUpdateAndSwitchToNew,
            &rp
            );

        //
        // Free up the memory that the old buffer consumed.
        //

        ExFreePool(rp.OldBuffer);

    }

    return STATUS_SUCCESS;

}


ULONG
SerialMoveToNewIntBuffer(
    PSERIAL_DEVICE_EXTENSION Extension,
    PUCHAR NewBuffer
    )

/*++

Routine Description:

    This routine is used to copy any characters out of the interrupt
    buffer into the "new" buffer.  It will be reading values that
    are updated with the ISR but this is safe since this value is
    only decremented by synchronization routines.  This routine will
    return the number of characters copied so some other routine
    can call a synchronization routine to update what is seen at
    interrupt level.

Arguments:

    Extension - A pointer to the device extension.
    NewBuffer - Where the characters are to be move to.

Return Value:

    The number of characters that were copied into the user
    buffer.

--*/

{

    ULONG numberOfCharsMoved = Extension->CharsInInterruptBuffer;


    if (numberOfCharsMoved) {

        //
        // This holds the number of characters between the first
        // readable character and the last character we will read or
        // the real physical end of the buffer (not the last readable
        // character).
        //
        ULONG firstTryNumberToGet = (ULONG)(Extension->LastCharSlot -
                                     Extension->FirstReadableChar) + 1;

        if (firstTryNumberToGet >= numberOfCharsMoved) {

            //
            // The characters don't wrap.
            //

            RtlMoveMemory(
                NewBuffer,
                Extension->FirstReadableChar,
                numberOfCharsMoved
                );

            if ((Extension->FirstReadableChar+(numberOfCharsMoved-1)) ==
                Extension->LastCharSlot) {

                Extension->FirstReadableChar = Extension->InterruptReadBuffer;

            } else {

                Extension->FirstReadableChar += numberOfCharsMoved;

            }

        } else {

            //
            // The characters do wrap.  Get up until the end of the buffer.
            //

            RtlMoveMemory(
                NewBuffer,
                Extension->FirstReadableChar,
                firstTryNumberToGet
                );

            //
            // Now get the rest of the characters from the beginning of the
            // buffer.
            //

            RtlMoveMemory(
                NewBuffer+firstTryNumberToGet,
                Extension->InterruptReadBuffer,
                numberOfCharsMoved - firstTryNumberToGet
                );

            Extension->FirstReadableChar = Extension->InterruptReadBuffer +
                                   numberOfCharsMoved - firstTryNumberToGet;

        }

    }

    return numberOfCharsMoved;

}


BOOLEAN
SerialUpdateAndSwitchToNew(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine gets the (hopefully) few characters that
    remain in the interrupt buffer after the first time we tried
    to get them out.

    NOTE: This is called by WdfInterruptSynchronize.

Arguments:

    Context - Points to a structure that contains a pointer to the
              device extension, a pointer to the buffer we are moving
              to, and a count of the number of characters
              that we previously copied into the new buffer, and the
              actual size of the new buffer.

Return Value:

    Always FALSE.

--*/

{

    PSERIAL_RESIZE_PARAMS params = Context;
    PSERIAL_DEVICE_EXTENSION extension = params->Extension;
    ULONG tempCharsInInterruptBuffer = extension->CharsInInterruptBuffer;

    UNREFERENCED_PARAMETER(Interrupt);

    ASSERT(extension->CharsInInterruptBuffer >= params->NumberMoved);

    //
    // We temporarily reduce the chars in interrupt buffer to
    // "fool" the move routine.  We will restore it after the
    // move.
    //

    extension->CharsInInterruptBuffer -= params->NumberMoved;

    if (extension->CharsInInterruptBuffer) {

        SerialMoveToNewIntBuffer(
            extension,
            params->NewBuffer + params->NumberMoved
            );

    }

    extension->CharsInInterruptBuffer = tempCharsInInterruptBuffer;


    extension->LastCharSlot = params->NewBuffer + (params->NewBufferSize - 1);
    extension->FirstReadableChar = params->NewBuffer;
    extension->ReadBufferBase = params->NewBuffer;
    extension->InterruptReadBuffer = params->NewBuffer;
    extension->BufferSize = params->NewBufferSize;

    //
    // We *KNOW* that the new interrupt buffer is larger than the
    // old buffer.  We don't need to worry about it being full.
    //

    extension->CurrentCharSlot = extension->InterruptReadBuffer +
                                 extension->CharsInInterruptBuffer;

    //
    // We set up the default xon/xoff limits.
    //

    extension->HandFlow.XoffLimit = extension->BufferSize >> 3;
    extension->HandFlow.XonLimit = extension->BufferSize >> 1;

    extension->WmiCommData.XoffXmitThreshold = extension->HandFlow.XoffLimit;
    extension->WmiCommData.XonXmitThreshold = extension->HandFlow.XonLimit;

    extension->BufferSizePt8 = ((3*(extension->BufferSize>>2))+
                                   (extension->BufferSize>>4));

    //
    // Since we (essentially) reduced the percentage of the interrupt
    // buffer being full, we need to handle any flow control.
    //

    SerialHandleReducedIntBuffer(extension);

    return FALSE;

}


