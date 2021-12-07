/*++

Copyright (c) Microsoft Corporation

Module Name:

    ioctl.c

Abstract:

    This module contains the ioctl dispatcher as well as a couple
    of routines that are generally just called in response to
    ioctl calls.

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "ioctl.tmh"
#endif

EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGetModemUpdate;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialGetCommStatus;
EVT_WDF_INTERRUPT_SYNCHRONIZE SerialSetEscapeChar;

PCHAR
SerialGetIoctlName(
    IN ULONG      IoControlCode
    )
/*++

Routine Description:
    SerialGetIoctlName returns the name of the ioctl

--*/
{
    switch (IoControlCode)
    {
    case IOCTL_SERIAL_SET_BAUD_RATE : return "IOCTL_SERIAL_SET_BAUD_RATE";
    case IOCTL_SERIAL_GET_BAUD_RATE: return "IOCTL_SERIAL_GET_BAUD_RATE";
    case IOCTL_SERIAL_GET_MODEM_CONTROL: return "IOCTL_SERIAL_GET_MODEM_CONTROL";
    case IOCTL_SERIAL_SET_MODEM_CONTROL: return "IOCTL_SERIAL_SET_MODEM_CONTROL";
    case IOCTL_SERIAL_SET_FIFO_CONTROL: return "IOCTL_SERIAL_SET_FIFO_CONTROL";
    case IOCTL_SERIAL_SET_LINE_CONTROL: return "IOCTL_SERIAL_SET_LINE_CONTROL";
    case IOCTL_SERIAL_GET_LINE_CONTROL: return "IOCTL_SERIAL_GET_LINE_CONTROL";
    case IOCTL_SERIAL_SET_TIMEOUTS: return "IOCTL_SERIAL_SET_TIMEOUTS";
    case IOCTL_SERIAL_GET_TIMEOUTS: return "IOCTL_SERIAL_GET_TIMEOUTS";
    case IOCTL_SERIAL_SET_CHARS: return "IOCTL_SERIAL_SET_CHARS";
    case IOCTL_SERIAL_GET_CHARS: return "IOCTL_SERIAL_GET_CHARS";
    case IOCTL_SERIAL_SET_DTR: return "IOCTL_SERIAL_SET_DTR";
    case IOCTL_SERIAL_CLR_DTR: return "IOCTL_SERIAL_SET_DTR";
    case IOCTL_SERIAL_RESET_DEVICE: return "IOCTL_SERIAL_RESET_DEVICE";
    case IOCTL_SERIAL_SET_RTS: return "IOCTL_SERIAL_SET_RTS";
    case IOCTL_SERIAL_CLR_RTS: return "IOCTL_SERIAL_CLR_RTS";
    case IOCTL_SERIAL_SET_XOFF: return "IOCTL_SERIAL_SET_XOFF";
    case IOCTL_SERIAL_SET_XON: return "IOCTL_SERIAL_SET_XON";
    case IOCTL_SERIAL_SET_BREAK_ON: return "IOCTL_SERIAL_SET_BREAK_ON";
    case IOCTL_SERIAL_SET_BREAK_OFF: return "IOCTL_SERIAL_SET_BREAK_OFF";
    case IOCTL_SERIAL_SET_QUEUE_SIZE: return "IOCTL_SERIAL_SET_QUEUE_SIZE";
    case IOCTL_SERIAL_GET_WAIT_MASK: return "IOCTL_SERIAL_GET_WAIT_MASK";
    case IOCTL_SERIAL_SET_WAIT_MASK: return "IOCTL_SERIAL_SET_WAIT_MASK";
    case IOCTL_SERIAL_WAIT_ON_MASK: return "IOCTL_SERIAL_WAIT_ON_MASK";
    case IOCTL_SERIAL_IMMEDIATE_CHAR: return "IOCTL_SERIAL_IMMEDIATE_CHAR";
    case IOCTL_SERIAL_PURGE: return "IOCTL_SERIAL_PURGE";
    case IOCTL_SERIAL_GET_HANDFLOW: return "IOCTL_SERIAL_GET_HANDFLOW";
    case IOCTL_SERIAL_SET_HANDFLOW: return "IOCTL_SERIAL_SET_HANDFLOW";
    case IOCTL_SERIAL_GET_MODEMSTATUS: return "IOCTL_SERIAL_GET_MODEMSTATUS";
    case IOCTL_SERIAL_GET_DTRRTS: return "IOCTL_SERIAL_GET_DTRRTS";
    case IOCTL_SERIAL_GET_COMMSTATUS: return "IOCTL_SERIAL_GET_COMMSTATUS";
    case IOCTL_SERIAL_GET_PROPERTIES: return "IOCTL_SERIAL_GET_PROPERTIES";
    case IOCTL_SERIAL_XOFF_COUNTER: return "IOCTL_SERIAL_XOFF_COUNTER";
    case IOCTL_SERIAL_LSRMST_INSERT: return "IOCTL_SERIAL_LSRMST_INSERT";
    case IOCTL_SERIAL_CONFIG_SIZE: return "IOCTL_SERIAL_CONFIG_SIZE";
    case IOCTL_SERIAL_GET_STATS: return "IOCTL_SERIAL_GET_STATS";
    case IOCTL_SERIAL_CLEAR_STATS: return "IOCTL_SERIAL_CLEAR_STATS";
    default: return "UnKnown ioctl";
    }
}



BOOLEAN
SerialGetStats(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    In sync with the interrpt service routine (which sets the perf stats)
    return the perf stats to the caller.


Arguments:

    Context - Pointer to a the request.

Return Value:

    This routine always returns FALSE.

--*/

{
    PREQUEST_CONTEXT reqContext = (PREQUEST_CONTEXT)Context;
    PSERIAL_DEVICE_EXTENSION extension = SerialGetDeviceExtension(WdfInterruptGetDevice(Interrupt));
    PSERIALPERF_STATS sp = reqContext->SystemBuffer;

    UNREFERENCED_PARAMETER(Interrupt);

    *sp = extension->PerfStats;
    return FALSE;

}


BOOLEAN
SerialClearStats(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    In sync with the interrpt service routine (which sets the perf stats)
    clear the perf stats.


Arguments:

    Context - Pointer to a the extension.

Return Value:

    This routine always returns FALSE.

--*/

{
    UNREFERENCED_PARAMETER(Interrupt);

    RtlZeroMemory(
        &((PSERIAL_DEVICE_EXTENSION)Context)->PerfStats,
        sizeof(SERIALPERF_STATS)
        );

    RtlZeroMemory(&((PSERIAL_DEVICE_EXTENSION)Context)->WmiPerfData,
                 sizeof(SERIAL_WMI_PERF_DATA));

    return FALSE;
}



BOOLEAN
SerialSetChars(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    This routine is used to set the special characters for the
    driver.

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and a pointer to a special characters
              structure.

Return Value:

    This routine always returns FALSE.

--*/

{
    UNREFERENCED_PARAMETER(Interrupt);

    ((PSERIAL_IOCTL_SYNC)Context)->Extension->SpecialChars =
        *((PSERIAL_CHARS)(((PSERIAL_IOCTL_SYNC)Context)->Data));

    return FALSE;
}


BOOLEAN
SerialSetBaud(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    This routine is used to set the baud rate of the device.

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and what should be the current
              baud rate.

Return Value:

    This routine always returns FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = ((PSERIAL_IOCTL_SYNC)Context)->Extension;
    USHORT Appropriate = PtrToUshort(((PSERIAL_IOCTL_SYNC)Context)->Data);

    UNREFERENCED_PARAMETER(Interrupt);

    WRITE_DIVISOR_LATCH(
        Extension,
        Extension->Controller,
        Appropriate
        );

    return FALSE;
}


BOOLEAN
SerialSetLineControl(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    This routine is used to set the buad rate of the device.

Arguments:

    Context - Pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    WRITE_LINE_CONTROL(Extension,
        Extension->Controller,
        Extension->LineControl
        );

    return FALSE;
}


BOOLEAN
SerialGetModemUpdate(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    This routine is simply used to call the interrupt level routine
    that handles modem status update.

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and a pointer to a ulong.

Return Value:

    This routine always returns FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = ((PSERIAL_IOCTL_SYNC)Context)->Extension;
    ULONG *Result = (ULONG *)(((PSERIAL_IOCTL_SYNC)Context)->Data);

    UNREFERENCED_PARAMETER(Interrupt);

    *Result = SerialHandleModemUpdate(
                  Extension,
                  FALSE
                  );

    return FALSE;
}



BOOLEAN
SerialSetMCRContents(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )
/*++

Routine Description:

    This routine is simply used to set the contents of the MCR

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and a pointer to a ulong.

Return Value:

    This routine always returns FALSE.

--*/
{
   PSERIAL_DEVICE_EXTENSION Extension = ((PSERIAL_IOCTL_SYNC)Context)->Extension;
   ULONG *Result = (ULONG *)(((PSERIAL_IOCTL_SYNC)Context)->Data);

   UNREFERENCED_PARAMETER(Interrupt);

   //
   // This is severe casting abuse!!!
   //
   WRITE_MODEM_CONTROL(Extension, Extension->Controller, (UCHAR)PtrToUlong(Result));

   return FALSE;
}




BOOLEAN
SerialGetMCRContents(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    This routine is simply used to get the contents of the MCR

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and a pointer to a ulong.

Return Value:

    This routine always returns FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = ((PSERIAL_IOCTL_SYNC)Context)->Extension;
    ULONG *Result = (ULONG *)(((PSERIAL_IOCTL_SYNC)Context)->Data);

    UNREFERENCED_PARAMETER(Interrupt);

    *Result = READ_MODEM_CONTROL(Extension, Extension->Controller);

    return FALSE;
}




BOOLEAN
SerialSetFCRContents(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )
/*++

Routine Description:

    This routine is simply used to set the contents of the FCR

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and a pointer to a ulong.

Return Value:

    This routine always returns FALSE.

--*/
{
   PSERIAL_DEVICE_EXTENSION Extension = ((PSERIAL_IOCTL_SYNC)Context)->Extension;
   ULONG *Result = (ULONG *)(((PSERIAL_IOCTL_SYNC)Context)->Data);

   UNREFERENCED_PARAMETER(Interrupt);

   //
   // This is severe casting abuse!!!
   //
   WRITE_FIFO_CONTROL(Extension, Extension->Controller, (UCHAR)*Result);

   return FALSE;
}



BOOLEAN
SerialGetCommStatus(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    This is used to get the current state of the serial driver.

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and a pointer to a serial status
              record.

Return Value:

    This routine always returns FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = ((PSERIAL_IOCTL_SYNC)Context)->Extension;
    PSERIAL_STATUS Stat = ((PSERIAL_IOCTL_SYNC)Context)->Data;

    UNREFERENCED_PARAMETER(Interrupt);

    Stat->Errors = Extension->ErrorWord;
    Extension->ErrorWord = 0;

    //
    // Eof isn't supported in binary mode
    //
    Stat->EofReceived = FALSE;

    Stat->AmountInInQueue = Extension->CharsInInterruptBuffer;

    Stat->AmountInOutQueue = Extension->TotalCharsQueued;

    if (Extension->WriteLength) {

        //
        // By definition if we have a writelength the we have
        // a current write request.
        //
     PREQUEST_CONTEXT reqContext = NULL;

        ASSERT(Extension->CurrentWriteRequest);
        ASSERT(Stat->AmountInOutQueue >= Extension->WriteLength);

     reqContext = SerialGetRequestContext(Extension->CurrentWriteRequest);
        Stat->AmountInOutQueue -= reqContext->Length - (Extension->WriteLength);

    }

    Stat->WaitForImmediate = Extension->TransmitImmediate;

    Stat->HoldReasons = 0;
    if (Extension->TXHolding) {

        if (Extension->TXHolding & SERIAL_TX_CTS) {

            Stat->HoldReasons |= SERIAL_TX_WAITING_FOR_CTS;

        }

        if (Extension->TXHolding & SERIAL_TX_DSR) {

            Stat->HoldReasons |= SERIAL_TX_WAITING_FOR_DSR;

        }

        if (Extension->TXHolding & SERIAL_TX_DCD) {

            Stat->HoldReasons |= SERIAL_TX_WAITING_FOR_DCD;

        }

        if (Extension->TXHolding & SERIAL_TX_XOFF) {

            Stat->HoldReasons |= SERIAL_TX_WAITING_FOR_XON;

        }

        if (Extension->TXHolding & SERIAL_TX_BREAK) {

            Stat->HoldReasons |= SERIAL_TX_WAITING_ON_BREAK;

        }

    }

    if (Extension->RXHolding & SERIAL_RX_DSR) {

        Stat->HoldReasons |= SERIAL_RX_WAITING_FOR_DSR;

    }

    if (Extension->RXHolding & SERIAL_RX_XOFF) {

        Stat->HoldReasons |= SERIAL_TX_WAITING_XOFF_SENT;

    }

    return FALSE;
}


BOOLEAN
SerialSetEscapeChar(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID         Context
    )

/*++

Routine Description:

    This is used to set the character that will be used to escape
    line status and modem status information when the application
    has set up that line status and modem status should be passed
    back in the data stream.

Arguments:

    Context - Pointer to the request that is specify the escape character.
              Implicitly - An escape character of 0 means no escaping
              will occur.

Return Value:

    This routine always returns FALSE.

--*/

{

    PREQUEST_CONTEXT reqContext = (PREQUEST_CONTEXT)Context;
    PSERIAL_DEVICE_EXTENSION extension = SerialGetDeviceExtension(WdfInterruptGetDevice(Interrupt));

    UNREFERENCED_PARAMETER(Interrupt);

    extension->EscapeChar = *(PUCHAR)reqContext->SystemBuffer;

    return FALSE;
}

VOID
SerialEvtIoDeviceControl(
    IN WDFQUEUE     Queue,
    IN WDFREQUEST   Request,
    IN size_t       OutputBufferLength,
    IN size_t       InputBufferLength,
    IN ULONG        IoControlCode
    )

/*++

Routine Description:

    This routine provides the initial processing for all of the
    Ioctrls for the serial device.

Arguments:

    Request - Pointer to the WDFREQUEST for the current request

Return Value:

    The function value is the final status of the call

--*/

{
    //
    // The status that gets returned to the caller and
    // set in the Request.
    //
    NTSTATUS Status;

    //
    // Just what it says.  This is the serial specific device
    // extension of the device object create for the serial driver.
    //
    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    PVOID buffer;
    PREQUEST_CONTEXT reqContext;
    size_t  bufSize;

    UNREFERENCED_PARAMETER(OutputBufferLength);
    UNREFERENCED_PARAMETER(InputBufferLength);

    reqContext = SerialGetRequestContext(Request);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, "%s for: %p\n",
                                    SerialGetIoctlName(IoControlCode), Request);

    Extension = SerialGetDeviceExtension(WdfIoQueueGetDevice(Queue));

    //
    // We expect to be open so all our pages are locked down.  This is, after
    // all, an IO operation, so the device should be open first.
    //

    if (Extension->DeviceIsOpened != TRUE) {
       SerialCompleteRequest(Request, STATUS_INVALID_DEVICE_REQUEST, 0);
       return;
    }


    if (SerialCompleteIfError(Extension, Request) != STATUS_SUCCESS) {

       SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS,
                    "<SerialEvtIoDeviceControl (2) %d\n", STATUS_CANCELLED);
       return;

    }

    reqContext = SerialGetRequestContext(Request);
    reqContext->Information = 0;
    reqContext->Status = STATUS_SUCCESS;
    reqContext->MajorFunction = IRP_MJ_DEVICE_CONTROL;


    Status = STATUS_SUCCESS;

    switch (IoControlCode) {

        case IOCTL_SERIAL_SET_BAUD_RATE : {

            ULONG BaudRate;
            //
            // Will hold the value of the appropriate divisor for
            // the requested baud rate.  If the baudrate is invalid
            // (because the device won't support that baud rate) then
            // this value is undefined.
            //
            // Note: in one sense the concept of a valid baud rate
            // is cloudy.  We could allow the user to request any
            // baud rate.  We could then calculate the divisor needed
            // for that baud rate.  As long as the divisor wasn't less
            // than one we would be "ok".  (The percentage difference
            // between the "true" divisor and the "rounded" value given
            // to the hardware might make it unusable, but... )  It would
            // really be up to the user to "Know" whether the baud rate
            // is suitable.  So much for theory, *We* only support a given
            // set of baud rates.
            //
            SHORT AppropriateDivisor;

            Status = WdfRequestRetrieveInputBuffer (Request, sizeof(SERIAL_BAUD_RATE), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            BaudRate = ((PSERIAL_BAUD_RATE)(buffer))->BaudRate;


            //
            // Get the baud rate from the request.  We pass it
            // to a routine which will set the correct divisor.
            //

            Status = SerialGetDivisorFromBaud(
                         Extension->ClockRate,
                         BaudRate,
                         &AppropriateDivisor
                         );


            if (NT_SUCCESS(Status)) {

                SERIAL_IOCTL_SYNC S;


                Extension->CurrentBaud = BaudRate;
                Extension->WmiCommData.BaudRate = BaudRate;

                S.Extension = Extension;
                S.Data = (PVOID) (ULONG_PTR) AppropriateDivisor;
                WdfInterruptSynchronize(
                    Extension->WdfInterrupt,
                    SerialSetBaud,
                    &S
                    );

            }

            break;
        }

        case IOCTL_SERIAL_GET_BAUD_RATE: {

            PSERIAL_BAUD_RATE Br;

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_BAUD_RATE), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            Br = (PSERIAL_BAUD_RATE)buffer;

            Br->BaudRate = Extension->CurrentBaud;

            reqContext->Information = sizeof(SERIAL_BAUD_RATE);

            break;

        }

        case IOCTL_SERIAL_GET_MODEM_CONTROL: {
            SERIAL_IOCTL_SYNC S;

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->Information = sizeof(ULONG);

            S.Extension = Extension;
            S.Data = buffer;

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialGetMCRContents,
                &S
                );

            break;
        }
        case IOCTL_SERIAL_SET_MODEM_CONTROL: {
            SERIAL_IOCTL_SYNC S;

            Status = WdfRequestRetrieveInputBuffer (Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            S.Extension = Extension;
            S.Data = buffer;


            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialSetMCRContents,
                &S
                );

            break;
        }
        case IOCTL_SERIAL_SET_FIFO_CONTROL: {
            SERIAL_IOCTL_SYNC S;

            Status = WdfRequestRetrieveInputBuffer (Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            S.Extension = Extension;
            S.Data = buffer;


            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialSetFCRContents,
                &S
                );

            break;
        }
        case IOCTL_SERIAL_SET_LINE_CONTROL: {

            PSERIAL_LINE_CONTROL Lc;
            UCHAR LData;
            UCHAR LStop;
            UCHAR LParity;
            UCHAR Mask = 0xff;

            Status = WdfRequestRetrieveInputBuffer (Request, sizeof(SERIAL_LINE_CONTROL), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            //
            // Points to the line control record in the Request.
            //
            Lc =  (PSERIAL_LINE_CONTROL)buffer;

            switch (Lc->WordLength) {
                case 5: {

                    LData = SERIAL_5_DATA;
                    Mask = 0x1f;
                    break;

                }
                case 6: {

                    LData = SERIAL_6_DATA;
                    Mask = 0x3f;
                    break;

                }
                case 7: {

                    LData = SERIAL_7_DATA;
                    Mask = 0x7f;
                    break;

                }
                case 8: {

                    LData = SERIAL_8_DATA;
                    break;

                }
                default: {

                    Status = STATUS_INVALID_PARAMETER;
                    goto DoneWithIoctl;

                }

            }

            Extension->WmiCommData.BitsPerByte = Lc->WordLength;

            switch (Lc->Parity) {

                case NO_PARITY: {
                    Extension->WmiCommData.Parity = SERIAL_WMI_PARITY_NONE;
                    LParity = SERIAL_NONE_PARITY;
                    break;

                }
                case EVEN_PARITY: {
                    Extension->WmiCommData.Parity = SERIAL_WMI_PARITY_EVEN;
                    LParity = SERIAL_EVEN_PARITY;
                    break;

                }
                case ODD_PARITY: {
                    Extension->WmiCommData.Parity = SERIAL_WMI_PARITY_ODD;
                    LParity = SERIAL_ODD_PARITY;
                    break;

                }
                case SPACE_PARITY: {
                    Extension->WmiCommData.Parity = SERIAL_WMI_PARITY_SPACE;
                    LParity = SERIAL_SPACE_PARITY;
                    break;

                }
                case MARK_PARITY: {
                    Extension->WmiCommData.Parity = SERIAL_WMI_PARITY_MARK;
                    LParity = SERIAL_MARK_PARITY;
                    break;

                }
                default: {

                    Status = STATUS_INVALID_PARAMETER;
                    goto DoneWithIoctl;
                    break;
                }

            }

            switch (Lc->StopBits) {

                case STOP_BIT_1: {
                    Extension->WmiCommData.StopBits = SERIAL_WMI_STOP_1;
                    LStop = SERIAL_1_STOP;
                    break;
                }
                case STOP_BITS_1_5: {

                    if (LData != SERIAL_5_DATA) {

                        Status = STATUS_INVALID_PARAMETER;
                        goto DoneWithIoctl;
                    }
                    Extension->WmiCommData.StopBits = SERIAL_WMI_STOP_1_5;
                    LStop = SERIAL_1_5_STOP;
                    break;

                }
                case STOP_BITS_2: {

                    if (LData == SERIAL_5_DATA) {

                        Status = STATUS_INVALID_PARAMETER;
                        goto DoneWithIoctl;
                    }
                    Extension->WmiCommData.StopBits = SERIAL_WMI_STOP_2;
                    LStop = SERIAL_2_STOP;
                    break;

                }
                default: {

                    Status = STATUS_INVALID_PARAMETER;
                    goto DoneWithIoctl;
                }

            }

            Extension->LineControl =
                (UCHAR)((Extension->LineControl & SERIAL_LCR_BREAK) |
                        (LData | LParity | LStop));
            Extension->ValidDataMask = Mask;

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialSetLineControl,
                Extension
                );

            break;
        }
        case IOCTL_SERIAL_GET_LINE_CONTROL: {

            PSERIAL_LINE_CONTROL Lc;

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_LINE_CONTROL), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            Lc = (PSERIAL_LINE_CONTROL)buffer;

            RtlZeroMemory(buffer, OutputBufferLength);

            if ((Extension->LineControl & SERIAL_DATA_MASK) == SERIAL_5_DATA) {
                Lc->WordLength = 5;
            } else if ((Extension->LineControl & SERIAL_DATA_MASK)
                        == SERIAL_6_DATA) {
                Lc->WordLength = 6;
            } else if ((Extension->LineControl & SERIAL_DATA_MASK)
                        == SERIAL_7_DATA) {
                Lc->WordLength = 7;
            } else if ((Extension->LineControl & SERIAL_DATA_MASK)
                        == SERIAL_8_DATA) {
                Lc->WordLength = 8;
            }

            if ((Extension->LineControl & SERIAL_PARITY_MASK)
                    == SERIAL_NONE_PARITY) {
                Lc->Parity = NO_PARITY;
            } else if ((Extension->LineControl & SERIAL_PARITY_MASK)
                    == SERIAL_ODD_PARITY) {
                Lc->Parity = ODD_PARITY;
            } else if ((Extension->LineControl & SERIAL_PARITY_MASK)
                    == SERIAL_EVEN_PARITY) {
                Lc->Parity = EVEN_PARITY;
            } else if ((Extension->LineControl & SERIAL_PARITY_MASK)
                    == SERIAL_MARK_PARITY) {
                Lc->Parity = MARK_PARITY;
            } else if ((Extension->LineControl & SERIAL_PARITY_MASK)
                    == SERIAL_SPACE_PARITY) {
                Lc->Parity = SPACE_PARITY;
            }

            if (Extension->LineControl & SERIAL_2_STOP) {
                if (Lc->WordLength == 5) {
                    Lc->StopBits = STOP_BITS_1_5;
                } else {
                    Lc->StopBits = STOP_BITS_2;
                }
            } else {
                Lc->StopBits = STOP_BIT_1;
            }

            reqContext->Information = sizeof(SERIAL_LINE_CONTROL);

            break;
        }
        case IOCTL_SERIAL_SET_TIMEOUTS: {

            PSERIAL_TIMEOUTS NewTimeouts;

            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(SERIAL_TIMEOUTS), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            NewTimeouts =(PSERIAL_TIMEOUTS)buffer;

            if ((NewTimeouts->ReadIntervalTimeout == MAXULONG) &&
                (NewTimeouts->ReadTotalTimeoutMultiplier == MAXULONG) &&
                (NewTimeouts->ReadTotalTimeoutConstant == MAXULONG)) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }


            Extension->Timeouts.ReadIntervalTimeout =
                NewTimeouts->ReadIntervalTimeout;

            Extension->Timeouts.ReadTotalTimeoutMultiplier =
                NewTimeouts->ReadTotalTimeoutMultiplier;

            Extension->Timeouts.ReadTotalTimeoutConstant =
                NewTimeouts->ReadTotalTimeoutConstant;

            Extension->Timeouts.WriteTotalTimeoutMultiplier =
                NewTimeouts->WriteTotalTimeoutMultiplier;

            Extension->Timeouts.WriteTotalTimeoutConstant =
                NewTimeouts->WriteTotalTimeoutConstant;

            break;
        }
        case IOCTL_SERIAL_GET_TIMEOUTS: {

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_TIMEOUTS), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            *((PSERIAL_TIMEOUTS)buffer) = Extension->Timeouts;
            reqContext->Information = sizeof(SERIAL_TIMEOUTS);

            break;
        }
        case IOCTL_SERIAL_SET_CHARS: {

            SERIAL_IOCTL_SYNC S;
            PSERIAL_CHARS NewChars;

           Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(SERIAL_CHARS), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            NewChars = (PSERIAL_CHARS)buffer;

            //
            // The only thing that can be wrong with the chars
            // is that the xon and xoff characters are the
            // same.
            //
#if 0
            if (NewChars->XonChar == NewChars->XoffChar) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }
#endif

            //
            // We acquire the control lock so that only
            // one request can GET or SET the characters
            // at a time.  The sets could be synchronized
            // by the interrupt spinlock, but that wouldn't
            // prevent multiple gets at the same time.
            //

            S.Extension = Extension;
            S.Data = NewChars;

            //
            // Under the protection of the lock, make sure that
            // the xon and xoff characters aren't the same as
            // the escape character.
            //

            if (Extension->EscapeChar) {

                if ((Extension->EscapeChar == NewChars->XonChar) ||
                    (Extension->EscapeChar == NewChars->XoffChar)) {

                    Status = STATUS_INVALID_PARAMETER;
                    break;

                }

            }

            Extension->WmiCommData.XonCharacter = NewChars->XonChar;
            Extension->WmiCommData.XoffCharacter = NewChars->XoffChar;

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialSetChars,
                &S
                );


            break;

        }
        case IOCTL_SERIAL_GET_CHARS: {

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_CHARS), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            *((PSERIAL_CHARS)buffer) = Extension->SpecialChars;
            reqContext->Information = sizeof(SERIAL_CHARS);


            break;
        }
        case IOCTL_SERIAL_SET_DTR:
        case IOCTL_SERIAL_CLR_DTR: {


            //
            // We acquire the lock so that we can check whether
            // automatic dtr flow control is enabled.  If it is
            // then we return an error since the app is not allowed
            // to touch this if it is automatic.
            //

            if ((Extension->HandFlow.ControlHandShake & SERIAL_DTR_MASK)
                == SERIAL_DTR_HANDSHAKE) {

                Status = STATUS_INVALID_PARAMETER;

            } else {

                WdfInterruptSynchronize(
                    Extension->WdfInterrupt,
                    ((IoControlCode ==
                     IOCTL_SERIAL_SET_DTR)?
                     (SerialSetDTR):(SerialClrDTR)),
                    Extension
                    );

            }

            break;
        }
        case IOCTL_SERIAL_RESET_DEVICE: {

            break;
        }
        case IOCTL_SERIAL_SET_RTS:
        case IOCTL_SERIAL_CLR_RTS: {

            //
            // We acquire the lock so that we can check whether
            // automatic rts flow control or transmit toggleing
            // is enabled.  If it is then we return an error since
            // the app is not allowed to touch this if it is automatic
            // or toggling.
            //

            if (((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK)
                 == SERIAL_RTS_HANDSHAKE) ||
                ((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK)
                 == SERIAL_TRANSMIT_TOGGLE)) {

                Status = STATUS_INVALID_PARAMETER;

            } else {

                WdfInterruptSynchronize(
                    Extension->WdfInterrupt,
                    ((IoControlCode ==
                     IOCTL_SERIAL_SET_RTS)?
                     (SerialSetRTS):(SerialClrRTS)),
                    Extension
                    );

            }

            break;

        }
        case IOCTL_SERIAL_SET_XOFF: {

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialPretendXoff,
                Extension
                );

            break;

        }
        case IOCTL_SERIAL_SET_XON: {

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialPretendXon,
                Extension
                );

            break;

        }
        case IOCTL_SERIAL_SET_BREAK_ON: {

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialTurnOnBreak,
                Extension
                );

            break;
        }
        case IOCTL_SERIAL_SET_BREAK_OFF: {

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialTurnOffBreak,
                Extension
                );

            break;
        }
        case IOCTL_SERIAL_SET_QUEUE_SIZE: {

            //
            // Type ahead buffer is fixed, so we just validate
            // the the users request is not bigger that our
            // own internal buffer size.
            //

            PSERIAL_QUEUE_SIZE Rs;

            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(SERIAL_QUEUE_SIZE), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            ASSERT(Extension->InterruptReadBuffer);

            Rs =   (PSERIAL_QUEUE_SIZE)buffer;

            reqContext->SystemBuffer = buffer;

            //
            // We have to allocate the memory for the new
            // buffer while we're still in the context of the
            // caller.  We don't even try to protect this
            // with a lock because the value could be stale
            // as soon as we release the lock - The only time
            // we will know for sure is when we actually try
            // to do the resize.
            //

            if (Rs->InSize <= Extension->BufferSize) {

                Status = STATUS_SUCCESS;
                break;

            }

            reqContext->Type3InputBuffer =
                    ExAllocatePoolWithQuotaTag(
                        NonPagedPoolNx | POOL_QUOTA_FAIL_INSTEAD_OF_RAISE,
                        Rs->InSize,
                        POOL_TAG
                        );

            if (!reqContext->Type3InputBuffer) {

                Status = STATUS_INSUFFICIENT_RESOURCES;
                break;

            }

            //
            // Well the data passed was big enough.  Do the request.
            //
            // There are two reason we place it in the read queue:
            //
            // 1) We want to serialize these resize requests so that
            //    they don't contend with each other.
            //
            // 2) We want to serialize these requests with reads since
            //    we don't want reads and resizes contending over the
            //    read buffer.
            //


            SerialStartOrQueue(
                       Extension,
                       Request,
                       Extension->ReadQueue,
                       &Extension->CurrentReadRequest,
                       SerialStartRead
                       );

            return;
        }
        case IOCTL_SERIAL_GET_WAIT_MASK: {

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            //
            // Simple scalar read.  No reason to acquire a lock.
            //

            reqContext->Information = sizeof(ULONG);

            *((ULONG *)buffer) = Extension->IsrWaitMask;

            break;

        }
        case IOCTL_SERIAL_SET_WAIT_MASK: {

            ULONG NewMask;

            SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "In Ioctl processing for set mask\n");

            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            NewMask = *((ULONG *)buffer);
            reqContext->SystemBuffer = buffer;

            //
            // Make sure that the mask only contains valid
            // waitable events.
            //

            if (NewMask & ~(SERIAL_EV_RXCHAR   |
                            SERIAL_EV_RXFLAG   |
                            SERIAL_EV_TXEMPTY  |
                            SERIAL_EV_CTS      |
                            SERIAL_EV_DSR      |
                            SERIAL_EV_RLSD     |
                            SERIAL_EV_BREAK    |
                            SERIAL_EV_ERR      |
                            SERIAL_EV_RING     |
                            SERIAL_EV_PERR     |
                            SERIAL_EV_RX80FULL |
                            SERIAL_EV_EVENT1   |
                            SERIAL_EV_EVENT2)) {

                SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Unknown mask %x\n", NewMask);

                Status = STATUS_INVALID_PARAMETER;
                break;

            }

            //
            // Either start this request or put it on the
            // queue.
            //

            SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Starting or queuing set mask request %p"
                             "\n", Request);

            SerialStartOrQueue(Extension, Request, Extension->MaskQueue,
                                      &Extension->CurrentMaskRequest,
                                      SerialStartMask);
            return;

        }
        case IOCTL_SERIAL_WAIT_ON_MASK: {

            SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "In Ioctl processing for wait mask\n");

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->SystemBuffer = buffer;

            //
            // Either start this request or put it on the
            // queue.
            //

            SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Starting or queuing wait mask request"
                             "%p\n", Request);

            SerialStartOrQueue(
                       Extension,
                       Request,
                       Extension->MaskQueue,
                       &Extension->CurrentMaskRequest,
                       SerialStartMask
                       );
            return;
        }
        case IOCTL_SERIAL_IMMEDIATE_CHAR: {

            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(UCHAR), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->SystemBuffer = buffer;

            if (Extension->CurrentImmediateRequest) {

                Status = STATUS_INVALID_PARAMETER;

            } else {

                //
                // We can queue the char.  We need to set
                // a cancel routine because flow control could
                // keep the char from transmitting.  Make sure
                // that the request hasn't already been canceled.
                //

                Extension->CurrentImmediateRequest = Request;
                Extension->TotalCharsQueued++;
                SerialStartImmediate(Extension);
                return;

            }

            break;

        }
        case IOCTL_SERIAL_PURGE: {

            ULONG Mask;

            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            //
            // Check to make sure that the mask only has
            // 0 or the other appropriate values.
            //

            Mask = *((ULONG *)(buffer));

            if ((!Mask) || (Mask & (~(SERIAL_PURGE_TXABORT |
                                      SERIAL_PURGE_RXABORT |
                                      SERIAL_PURGE_TXCLEAR |
                                      SERIAL_PURGE_RXCLEAR
                                     )
                                   )
                           )) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }

            reqContext->SystemBuffer = buffer;

            //
            // Either start this request or put it on the
            // queue.
            //

            SerialStartOrQueue(
                       Extension,
                       Request,
                       Extension->PurgeQueue,
                       &Extension->CurrentPurgeRequest,
                       SerialStartPurge
                       );
            return;
        }
        case IOCTL_SERIAL_GET_HANDFLOW: {

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_HANDFLOW), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->Information = sizeof(SERIAL_HANDFLOW);

            *((PSERIAL_HANDFLOW)buffer) = Extension->HandFlow;

            break;

        }
        case IOCTL_SERIAL_SET_HANDFLOW: {

            SERIAL_IOCTL_SYNC S;
            PSERIAL_HANDFLOW HandFlow;

            //
            // Make sure that the hand shake and control is the
            // right size.
            //

            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(SERIAL_HANDFLOW), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            HandFlow = (PSERIAL_HANDFLOW)buffer;

            //
            // Make sure that there are no invalid bits set in
            // the control and handshake.
            //

            if (HandFlow->ControlHandShake & SERIAL_CONTROL_INVALID) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }

            if (HandFlow->FlowReplace & SERIAL_FLOW_INVALID) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }

            //
            // Make sure that the app hasn't set an invlid DTR mode.
            //

            if ((HandFlow->ControlHandShake & SERIAL_DTR_MASK) ==
                SERIAL_DTR_MASK) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }

            //
            // Make sure that haven't set totally invalid xon/xoff
            // limits.
            //

            if ((HandFlow->XonLimit < 0) ||
                ((ULONG)HandFlow->XonLimit > Extension->BufferSize)) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }

            if ((HandFlow->XoffLimit < 0) ||
                ((ULONG)HandFlow->XoffLimit > Extension->BufferSize)) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }

            S.Extension = Extension;
            S.Data = HandFlow;

            //
            // Under the protection of the lock, make sure that
            // we aren't turning on error replacement when we
            // are doing line status/modem status insertion.
            //

            if (Extension->EscapeChar) {

                if (HandFlow->FlowReplace & SERIAL_ERROR_CHAR) {

                    Status = STATUS_INVALID_PARAMETER;
                    break;

                }

            }

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialSetHandFlow,
                &S
                );

            break;

        }
        case IOCTL_SERIAL_GET_MODEMSTATUS: {

            SERIAL_IOCTL_SYNC S;

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->Information = sizeof(ULONG);

            S.Extension = Extension;
            S.Data = buffer;

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialGetModemUpdate,
                &S
                );

            break;

        }
        case IOCTL_SERIAL_GET_DTRRTS: {

            ULONG ModemControl;

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->Information = sizeof(ULONG);
            reqContext->Status = STATUS_SUCCESS;

            //
            // Reading this hardware has no effect on the device.
            //

            ModemControl = READ_MODEM_CONTROL(Extension, Extension->Controller);

            ModemControl &= SERIAL_DTR_STATE | SERIAL_RTS_STATE;

            *(PULONG)buffer = ModemControl;

            break;

        }
        case IOCTL_SERIAL_GET_COMMSTATUS: {

            SERIAL_IOCTL_SYNC S;

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_STATUS), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->Information = sizeof(SERIAL_STATUS);

            S.Extension = Extension;
            S.Data =  buffer;

            //
            // Acquire the cancel spin lock so nothing much
            // changes while were getting the state.
            //

            //IoAcquireCancelSpinLock(&OldIrql);

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialGetCommStatus,
                &S
                );

            //IoReleaseCancelSpinLock(OldIrql);

            break;

        }
        case IOCTL_SERIAL_GET_PROPERTIES: {


            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_COMMPROP), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            //
            // No synchronization is required since this information
            // is "static".
            //

            SerialGetProperties(
                Extension,
                buffer
                );

            reqContext->Information = sizeof(SERIAL_COMMPROP);
            reqContext->Status = STATUS_SUCCESS;

            break;
        }
        case IOCTL_SERIAL_XOFF_COUNTER: {

            PSERIAL_XOFF_COUNTER Xc;

            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(SERIAL_XOFF_COUNTER), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            Xc = (PSERIAL_XOFF_COUNTER)buffer;

            if (Xc->Counter <= 0) {

                Status = STATUS_INVALID_PARAMETER;
                break;

            }
            reqContext->SystemBuffer = buffer;

            //
            // There is no output, so make that clear now
            //

            reqContext->Information = 0;

            //
            // So far so good.  Put the request onto the write queue.
            //

            SerialStartOrQueue(
                       Extension,
                       Request,
                       Extension->WriteQueue,
                       &Extension->CurrentWriteRequest,
                       SerialStartWrite
                       );
            return;

        }
        case IOCTL_SERIAL_LSRMST_INSERT: {

            PUCHAR escapeChar;
            SERIAL_IOCTL_SYNC S;

            //
            // Make sure we get a byte.
            //
            Status = WdfRequestRetrieveInputBuffer ( Request, sizeof(UCHAR), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->SystemBuffer = buffer;

            escapeChar = (PUCHAR)buffer;

            if (*escapeChar) {

                //
                // We've got some escape work to do.  We will make sure that
                // the character is not the same as the Xon or Xoff character,
                // or that we are already doing error replacement.
                //

                if ((*escapeChar == Extension->SpecialChars.XoffChar) ||
                    (*escapeChar == Extension->SpecialChars.XonChar) ||
                    (Extension->HandFlow.FlowReplace & SERIAL_ERROR_CHAR)) {

                    Status = STATUS_INVALID_PARAMETER;

                    break;

                }

            }

            S.Extension = Extension;
            S.Data = buffer;

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialSetEscapeChar,
                reqContext
                );

            break;

        }
        case IOCTL_SERIAL_CONFIG_SIZE: {

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(ULONG), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->Information = sizeof(ULONG);
            reqContext->Status = STATUS_SUCCESS;

            *(PULONG)buffer = 0;

            break;
        }
        case IOCTL_SERIAL_GET_STATS: {

            Status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIALPERF_STATS), &buffer, &bufSize );
            if( !NT_SUCCESS(Status) ) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", Status);
                break;
            }

            reqContext->SystemBuffer = buffer;

            reqContext->Information = sizeof(SERIALPERF_STATS);
            reqContext->Status = STATUS_SUCCESS;

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialGetStats,
                reqContext
                );

            break;
        }
        case IOCTL_SERIAL_CLEAR_STATS: {

            WdfInterruptSynchronize(
                Extension->WdfInterrupt,
                SerialClearStats,
                Extension
                );
            break;
        }
        default: {

            Status = STATUS_INVALID_PARAMETER;
            break;
        }
    }

DoneWithIoctl:;

    reqContext->Status = Status;

    SerialCompleteRequest(Request, Status, reqContext->Information);

    return;

}


VOID
SerialGetProperties(
    IN PSERIAL_DEVICE_EXTENSION Extension,
    IN PSERIAL_COMMPROP Properties
    )

/*++

Routine Description:

    This function returns the capabilities of this particular
    serial device.

Arguments:

    Extension - The serial device extension.

    Properties - The structure used to return the properties

Return Value:

    None.

--*/

{


    RtlZeroMemory(
        Properties,
        sizeof(SERIAL_COMMPROP)
        );

    Properties->PacketLength = sizeof(SERIAL_COMMPROP);
    Properties->PacketVersion = 2;
    Properties->ServiceMask = SERIAL_SP_SERIALCOMM;
    Properties->MaxTxQueue = 0;
    Properties->MaxRxQueue = 0;

    Properties->MaxBaud = SERIAL_BAUD_USER;
    Properties->SettableBaud = Extension->SupportedBauds;

    Properties->ProvSubType = SERIAL_SP_RS232;
    Properties->ProvCapabilities = SERIAL_PCF_DTRDSR |
                                   SERIAL_PCF_RTSCTS |
                                   SERIAL_PCF_CD     |
                                   SERIAL_PCF_PARITY_CHECK |
                                   SERIAL_PCF_XONXOFF |
                                   SERIAL_PCF_SETXCHAR |
                                   SERIAL_PCF_TOTALTIMEOUTS |
                                   SERIAL_PCF_INTTIMEOUTS;
    Properties->SettableParams = SERIAL_SP_PARITY |
                                 SERIAL_SP_BAUD |
                                 SERIAL_SP_DATABITS |
                                 SERIAL_SP_STOPBITS |
                                 SERIAL_SP_HANDSHAKING |
                                 SERIAL_SP_PARITY_CHECK |
                                 SERIAL_SP_CARRIER_DETECT;


    Properties->SettableData = SERIAL_DATABITS_5 |
                               SERIAL_DATABITS_6 |
                               SERIAL_DATABITS_7 |
                               SERIAL_DATABITS_8;
    Properties->SettableStopParity = SERIAL_STOPBITS_10 |
                                     SERIAL_STOPBITS_15 |
                                     SERIAL_STOPBITS_20 |
                                     SERIAL_PARITY_NONE |
                                     SERIAL_PARITY_ODD  |
                                     SERIAL_PARITY_EVEN |
                                     SERIAL_PARITY_MARK |
                                     SERIAL_PARITY_SPACE;
    Properties->CurrentTxQueue = 0;
    Properties->CurrentRxQueue = Extension->BufferSize;

}

VOID
SerialEvtIoInternalDeviceControl(
    IN WDFQUEUE     Queue,
    IN WDFREQUEST Request,
    IN size_t      OutputBufferLength,
    IN size_t      InputBufferLength,
    IN ULONG      IoControlCode
)
/*++

Routine Description:

    This routine provides the initial processing for all of the
    internal Ioctrls for the serial device.

Arguments:

    PDevObj - Pointer to the device object for this device

    PIrp - Pointer to the WDFREQUEST for the current request

Return Value:

    The function value is the final status of the call

--*/

{
    NTSTATUS status;
    PSERIAL_DEVICE_EXTENSION pDevExt = NULL;
    PVOID buffer;
    PREQUEST_CONTEXT reqContext;
    WDF_DEVICE_POWER_POLICY_WAKE_SETTINGS wakeSettings;
    size_t  bufSize;

    UNREFERENCED_PARAMETER(OutputBufferLength);
    UNREFERENCED_PARAMETER(InputBufferLength);

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "SerialEvtIoInternalDeviceControl for: %p\n", Request);

    pDevExt = SerialGetDeviceExtension(WdfIoQueueGetDevice(Queue));

    if (SerialCompleteIfError(pDevExt, Request) != STATUS_SUCCESS) {

       SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS,
                    "<SerialEvtIoDeviceControl (2) %d\n", STATUS_CANCELLED);
       return;

    }

    reqContext = SerialGetRequestContext(Request);
    reqContext->Information = 0;
    reqContext->Status = STATUS_SUCCESS;
    reqContext->MajorFunction = IRP_MJ_INTERNAL_DEVICE_CONTROL;

    switch (IoControlCode) {

    case IOCTL_SERIAL_INTERNAL_DO_WAIT_WAKE:
        //
        // Init wait-wake policy structure.
        //
        WDF_DEVICE_POWER_POLICY_WAKE_SETTINGS_INIT(&wakeSettings);
        //
        // Override the default settings from allow user control to do not allow.
        //
        wakeSettings.UserControlOfWakeSettings = IdleDoNotAllowUserControl;
        status = WdfDeviceAssignSxWakeSettings(pDevExt->WdfDevice, &wakeSettings);
        if (!NT_SUCCESS(status)) {
            SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "WdfDeviceAssignSxWakeSettings failed %x \n", status);
            break;
        }

       pDevExt->IsWakeEnabled = TRUE;
       status = STATUS_SUCCESS;
       break;

    case IOCTL_SERIAL_INTERNAL_CANCEL_WAIT_WAKE:

       WDF_DEVICE_POWER_POLICY_WAKE_SETTINGS_INIT(&wakeSettings);
       //
       // Override the default settings.
       //
       wakeSettings.Enabled = WdfFalse; // Disables wait-wake
       wakeSettings.UserControlOfWakeSettings = IdleDoNotAllowUserControl;
       status = WdfDeviceAssignSxWakeSettings(pDevExt->WdfDevice, &wakeSettings);
       if (!NT_SUCCESS(status)) {
           SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "WdfDeviceAssignSxWakeSettings failed %x \n", status);
           break;
       }

       pDevExt->IsWakeEnabled = FALSE;
       status = STATUS_SUCCESS;
       break;


    //
    // Put the serial port in a "filter-driver" appropriate state
    //
    // WARNING: This code assumes it is being called by a trusted kernel
    // entity and no checking is done on the validity of the settings
    // passed to IOCTL_SERIAL_INTERNAL_RESTORE_SETTINGS
    //
    // If validity checking is desired, the regular ioctl's should be used
    //

    case IOCTL_SERIAL_INTERNAL_BASIC_SETTINGS:
    case IOCTL_SERIAL_INTERNAL_RESTORE_SETTINGS: {

       SERIAL_BASIC_SETTINGS   basic;
       PSERIAL_BASIC_SETTINGS  pBasic;
       SERIAL_IOCTL_SYNC       S;

       if (IoControlCode == IOCTL_SERIAL_INTERNAL_BASIC_SETTINGS) {


         //
         // Check the buffer size
         //
         status = WdfRequestRetrieveOutputBuffer ( Request, sizeof(SERIAL_BASIC_SETTINGS), &buffer, &bufSize );
         if( !NT_SUCCESS(status) ) {
            SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", status);
            break;
         }

         reqContext->SystemBuffer = buffer;

          //
          // Everything is 0 -- timeouts and flow control and fifos.  If
          // We add additional features, this zero memory method
          // may not work.
          //

          RtlZeroMemory(&basic, sizeof(SERIAL_BASIC_SETTINGS));

          basic.TxFifo = 1;
          basic.RxFifo = SERIAL_1_BYTE_HIGH_WATER;

          reqContext->Information = sizeof(SERIAL_BASIC_SETTINGS);
          pBasic = (PSERIAL_BASIC_SETTINGS)buffer;

          //
          // Save off the old settings
          //

          RtlCopyMemory(&pBasic->Timeouts, &pDevExt->Timeouts,
                        sizeof(SERIAL_TIMEOUTS));

          RtlCopyMemory(&pBasic->HandFlow, &pDevExt->HandFlow,
                        sizeof(SERIAL_HANDFLOW));

          pBasic->RxFifo = pDevExt->RxFifoTrigger;
          pBasic->TxFifo = pDevExt->TxFifoAmount;

          //
          // Point to our new settings
          //

          pBasic = &basic;
       } else { // restoring settings

          status = WdfRequestRetrieveInputBuffer ( Request, sizeof(SERIAL_BASIC_SETTINGS), &buffer, &bufSize );
          if( !NT_SUCCESS(status) ) {
              SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_IOCTLS, "Could not get request memory buffer %X\n", status);
              break;
          }

          pBasic = (PSERIAL_BASIC_SETTINGS)buffer;
       }

       //
       // Set the timeouts
       //

       RtlCopyMemory(&pDevExt->Timeouts, &pBasic->Timeouts,
                     sizeof(SERIAL_TIMEOUTS));

       //
       // Set flowcontrol
       //

       S.Extension = pDevExt;
       S.Data = &pBasic->HandFlow;
       WdfInterruptSynchronize(pDevExt->WdfInterrupt, SerialSetHandFlow, &S);

       if (pDevExt->FifoPresent) {
          pDevExt->TxFifoAmount = pBasic->TxFifo;
          pDevExt->RxFifoTrigger = (UCHAR)pBasic->RxFifo;

          WRITE_FIFO_CONTROL(pDevExt, pDevExt->Controller, (UCHAR)0);
          READ_RECEIVE_BUFFER(pDevExt, pDevExt->Controller);
          WRITE_FIFO_CONTROL(pDevExt, pDevExt->Controller,
                             (UCHAR)(SERIAL_FCR_ENABLE | pDevExt->RxFifoTrigger
                                     | SERIAL_FCR_RCVR_RESET
                                     | SERIAL_FCR_TXMT_RESET));
       } else {
          pDevExt->TxFifoAmount = pDevExt->RxFifoTrigger = 0;
          WRITE_FIFO_CONTROL(pDevExt, pDevExt->Controller, (UCHAR)0);
       }


       break;
    }

    default:
       status = STATUS_INVALID_PARAMETER;
       break;

    }

    reqContext->Status = status;

    SerialCompleteRequest(Request, reqContext->Status, reqContext->Information);

    return;
}



