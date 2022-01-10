/*++

Copyright (c) Microsoft Corporation

Module Name:

    waitmask.c

Abstract:

    This module contains the code that is very specific to get/set/wait
    on event mask operations in the serial driver

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "waitmask.tmh"
#endif

EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGrabWaitFromIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGiveWaitToIsr;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialFinishOldWait;


VOID
SerialStartMask(
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine is used to process the set mask and wait
    mask ioctls.  Calls to this routine are serialized by
    placing irps in the list under the protection of the
    cancel spin lock.

Arguments:

    Extension - A pointer to the serial device extension.

Return Value:

    Will return pending for everything put the first
    request that we actually process.  Even in that
    case it will return pending unless it can complete
    it right away.


--*/

{


    WDFREQUEST NewRequest;
    PREQUEST_CONTEXT reqContext;
    WDF_REQUEST_PARAMETERS  params;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "In SerialStartMask\n");

    ASSERT(Extension->CurrentMaskRequest);


    do {

        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                         "STARTMASK - CurrentMaskRequest: %p\n",
                         Extension->CurrentMaskRequest);

        WDF_REQUEST_PARAMETERS_INIT(&params);

        WdfRequestGetParameters(
                 Extension->CurrentMaskRequest,
                 &params
                 );


         reqContext = SerialGetRequestContext(Extension->CurrentMaskRequest);

        ASSERT((params.Parameters.DeviceIoControl.IoControlCode ==
                IOCTL_SERIAL_WAIT_ON_MASK) ||
               (params.Parameters.DeviceIoControl.IoControlCode ==
                IOCTL_SERIAL_SET_WAIT_MASK));

        if (params.Parameters.DeviceIoControl.IoControlCode ==
                                    IOCTL_SERIAL_SET_WAIT_MASK) {

            SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                             "SERIAL - %p is a SETMASK request\n",
                             Extension->CurrentMaskRequest);

            //
            // Complete the old wait if there is one.
            //

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialFinishOldWait,
                Extension
                );

            //
            // Any current waits should be on its way to completion
            // at this point.  There certainly shouldn't be any
            // request mask location.
            //

            ASSERT(!Extension->IrpMaskLocation);

            reqContext->Status = STATUS_SUCCESS;

            //
            // The following call will also cause the current
            // call to be completed.
            //

            SerialGetNextRequest(
                &Extension->CurrentMaskRequest,
                Extension->MaskQueue,
                &NewRequest,
                TRUE,
                Extension
                );
            SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                             "Perhaps another mask request was found in "
                             "the queue\n"
                             "------- %p/%p <- values should be the same\n",
                             Extension->CurrentMaskRequest, NewRequest);


        } else {

            //
            // First make sure that we have a non-zero mask.
            // If the app queues a wait on a zero mask it can't
            // be statisfied so it makes no sense to start it.
            //

            if ((!Extension->IsrWaitMask) || (Extension->CurrentWaitRequest)) {

                SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                                 "WaitIrp is invalid\n"
                                 "------- IsrWaitMask: %x\n"
                                 "------- CurrentWaitRequest: %p\n",
                                 Extension->IsrWaitMask,
                                 Extension->CurrentWaitRequest);

                reqContext->Status = STATUS_INVALID_PARAMETER;

                SerialGetNextRequest(&Extension->CurrentMaskRequest,
                                 Extension->MaskQueue, &NewRequest, TRUE,
                                 Extension);

                SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                                 "Perhaps another mask request was found "
                                 "in the queue\n"
                                 "------- %p/%p <- values should be the same\n",
                                 Extension->CurrentMaskRequest,NewRequest);

            } else {

                //
                // Make the current mask request the current wait request and
                // get a new current mask request.  Note that when we get
                // the new current mask request we DO NOT complete the
                // old current mask request (which is now the current wait
                // request.
                //
                // Then under the protection of the cancel spin lock
                // we check to see if the current wait request needs to
                // be canceled
                //

                SERIAL_INIT_REFERENCE(reqContext);

                SerialSetCancelRoutine(Extension->CurrentMaskRequest,
                                                SerialCancelWait);

                SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                                 "%p will become the current "
                                 "wait request\n",
                                 Extension->CurrentMaskRequest);
                //
                // There should never be a mask location when
                // there isn't a current wait request.  At this point
                // there shouldn't be a current wait request also.
                //

                ASSERT(!Extension->IrpMaskLocation);
                ASSERT(!Extension->CurrentWaitRequest);

                Extension->CurrentWaitRequest = Extension->CurrentMaskRequest;

                WdfInterruptSynchronize(
                    Extension->WdfInterrupt,
                    SerialGiveWaitToIsr,
                    Extension
                    );

                //
                // Since it isn't really the mask request anymore,
                // null out that pointer.
                //
                Extension->CurrentMaskRequest = NULL;

                //
                // This will release the cancel spinlock for us
                //

                SerialGetNextRequest(&Extension->CurrentMaskRequest,
                                       Extension->MaskQueue, &NewRequest,
                                       FALSE, Extension);

                SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                                 "Perhaps another mask request was "
                                 "found in the queue\n"
                                 "------- %p/%p <- values should be the "
                                 "same\n", Extension->CurrentMaskRequest,
                                 NewRequest);
            }

        }

    } while (NewRequest);

    return;

}

BOOLEAN
SerialGrabWaitFromIsr(
    IN WDFINTERRUPT Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine will check to see if the ISR still knows about
    a wait request by checking to see if the IrpMaskLocation is non-null.
    If it is then it will zero the Irpmasklocation (which in effect
    grabs the request away from the isr).  This routine is only called
    buy the cancel code for the wait.

    NOTE: This is called by WdfInterruptSynchronize.

Arguments:

    Context - A pointer to the device extension

Return Value:

    Always FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = Context;

    PREQUEST_CONTEXT reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentWaitRequest);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "In SerialGrabWaitFromIsr\n");

    if (Extension->IrpMaskLocation) {

        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                         "The isr still owns the request %p, mask "
                         "location is %p\n"
                         "------- and system buffer is %p\n",
                         Extension->CurrentWaitRequest,Extension->IrpMaskLocation,
                         reqContext->SystemBuffer);

        //
        // The isr still "owns" the request.
        //

        *Extension->IrpMaskLocation = 0;
        Extension->IrpMaskLocation = NULL;

        reqContext->Information = sizeof(ULONG);

        //
        // Since the isr no longer references the request we need to
        // decrement the reference count.
        //

        SERIAL_CLEAR_REFERENCE(
            reqContext,
            SERIAL_REF_ISR
            );

    }

    return FALSE;
}

BOOLEAN
SerialGiveWaitToIsr(
    IN WDFINTERRUPT Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine simply sets a variable in the device extension
    so that the isr knows that we have a wait request.

    NOTE: This is called by WdfInterruptSynchronize.

    NOTE: This routine assumes that it is called with the
          cancel spinlock held.

Arguments:

    Context - Simply a pointer to the device extension.

Return Value:

    Always FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    PREQUEST_CONTEXT reqContext;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContext = SerialGetRequestContext(Extension->CurrentWaitRequest);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "In SerialGiveWaitToIsr\n");
    //
    // There certainly shouldn't be a current mask location at
    // this point since we have a new current wait request.
    //

    ASSERT(!Extension->IrpMaskLocation);

    //
    // The isr may or may not actually reference this request.  It
    // won't if the wait can be satisfied immediately.  However,
    // since it will then go through the normal completion sequence,
    // we need to have an incremented reference count anyway.
    //

    SERIAL_SET_REFERENCE(
        reqContext,
        SERIAL_REF_ISR
        );

    if (!Extension->HistoryMask) {

        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                         "No events occured prior to the wait call"
                         "\n");

        //
        // Although this wait might not be for empty transmit
        // queue, it doesn't hurt anything to set it to false.
        //

        Extension->EmptiedTransmit = FALSE;

        //
        // Record where the "completion mask" should be set.
        //

        Extension->IrpMaskLocation = reqContext->SystemBuffer;
        SerialDbgPrintEx( TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                          "The isr owns the request %p, mask location is "
                          "%p\n"
                          "------- and system buffer is %p\n",
                          Extension->CurrentWaitRequest,Extension->IrpMaskLocation,
                          reqContext->SystemBuffer);

    } else {

        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                         "%x occurred prior to the wait - starting "
                         "the\n"
                         "------- completion code for %p\n",
                         Extension->HistoryMask,Extension->CurrentWaitRequest);

        *((ULONG *)reqContext->SystemBuffer) =
            Extension->HistoryMask;
        Extension->HistoryMask = 0;
        reqContext->Information = sizeof(ULONG);
        reqContext->Status = STATUS_SUCCESS;

        SerialInsertQueueDpc(Extension->CommWaitDpc);

    }

    return FALSE;
}

BOOLEAN
SerialFinishOldWait(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine will check to see if the ISR still knows about
    a wait request by checking to see if the Irpmasklocation is non-null.
    If it is then it will zero the Irpmasklocation (which in effect
    grabs the request away from the isr).  This routine is only called
    buy the cancel code for the wait.

    NOTE: This is called by WdfInterruptSynchronize.

Arguments:

    Context - A pointer to the device extension

Return Value:

    Always FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = Context;

    PREQUEST_CONTEXT reqContext = NULL;
    PREQUEST_CONTEXT reqContextMask;

    UNREFERENCED_PARAMETER(Interrupt);

    reqContextMask = SerialGetRequestContext(Extension->CurrentMaskRequest);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "In SerialFinishOldWait\n");

    if (Extension->IrpMaskLocation) {

        reqContext = SerialGetRequestContext(Extension->CurrentWaitRequest);

        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                         "The isr still owns the request %p, mask "
                         "location is %p\n"
                         "------- and system buffer is %p\n",
                         Extension->CurrentWaitRequest,Extension->IrpMaskLocation,
                         reqContext->SystemBuffer);
        //
        // The isr still "owns" the request.
        //

        *Extension->IrpMaskLocation = 0;
        Extension->IrpMaskLocation = NULL;

        reqContext->Information = sizeof(ULONG);

        //
        // We don't decrement the reference since the completion routine
        // will do that.
        //

        SerialInsertQueueDpc(Extension->CommWaitDpc);

    }

    //
    // Don't wipe out any historical data we are still interested in.
    //

    Extension->HistoryMask &= *((ULONG *)reqContextMask->SystemBuffer);

    Extension->IsrWaitMask = *((ULONG *)reqContextMask->SystemBuffer);
    SerialDbgPrintEx( TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                      "Set mask location of %p, in request %p, with "
                      "system buffer of %p\n",
                      Extension->IrpMaskLocation, Extension->CurrentMaskRequest,
                      reqContextMask->SystemBuffer);
    return FALSE;
}

VOID
SerialCancelWait(
     IN WDFREQUEST Request
    )

/*++

Routine Description:

    This routine is used to cancel a request that is waiting on
    a comm event.

Arguments:

    Device - Wdf handle for the device

    Request - Pointer to the WDFREQUEST for the current request

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension;
    WDFDEVICE  device = WdfIoQueueGetDevice(WdfRequestGetIoQueue(Request));

    UNREFERENCED_PARAMETER(Request);

    Extension = SerialGetDeviceExtension(device);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "Canceling wait for request %p\n",
                     Extension->CurrentWaitRequest);

    SerialTryToCompleteCurrent(Extension,
                               SerialGrabWaitFromIsr,
                               STATUS_CANCELLED,
                               &Extension->CurrentWaitRequest,
                               NULL, NULL, NULL,
                               NULL, NULL, SERIAL_REF_CANCEL);

}


VOID
SerialCompleteWait(
    IN WDFDPC Dpc
    )

{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfDpcGetParentObject(Dpc));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     ">SerialCompleteWait(%p)\n",
                     Extension);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "Completing wait for request %p\n",
                     Extension->CurrentWaitRequest);

    SerialTryToCompleteCurrent(Extension, NULL, STATUS_SUCCESS,
                               &Extension->CurrentWaitRequest, NULL, NULL, NULL,
                               NULL, NULL, SERIAL_REF_ISR);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                     "<SerialCompleteWait\n");
}


