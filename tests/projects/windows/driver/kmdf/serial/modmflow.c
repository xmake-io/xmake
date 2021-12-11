/*++

Copyright (c) Microsoft Corporation

Module Name:

    modmflow.c

Abstract:

    This module contains *MOST* of the code used to manipulate
    the modem control and status registers.  The vast majority
    of the remainder of flow control is concentrated in the
    Interrupt service routine.  A very small amount resides
    in the read code that pull characters out of the interrupt
    buffer.

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "modmflow.tmh"
#endif


EVT_WDF_INTERRUPT_SYNCHRONIZE SerialDecrementRTSCounter;
 
BOOLEAN
SerialSetDTR(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine which is only called at interrupt level is used
    to set the DTR in the modem control register.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{
    PSERIAL_DEVICE_EXTENSION Extension = Context;
    UCHAR ModemControl;

    UNREFERENCED_PARAMETER(Interrupt);

    ModemControl = READ_MODEM_CONTROL(Extension, Extension->Controller);

    ModemControl |= SERIAL_MCR_DTR;

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS,
                     "Setting DTR for %p\n", Extension->Controller);

    WRITE_MODEM_CONTROL(Extension, Extension->Controller, ModemControl);

    return FALSE;

}

BOOLEAN
SerialClrDTR(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine which is only called at interrupt level is used
    to clear the DTR in the modem control register.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;
    UCHAR ModemControl;

    UNREFERENCED_PARAMETER(Interrupt);

    ModemControl = READ_MODEM_CONTROL(Extension, Extension->Controller);

    ModemControl &= ~SERIAL_MCR_DTR;

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Clearing DTR for %p\n", Extension->Controller);

    WRITE_MODEM_CONTROL(Extension, Extension->Controller, ModemControl);

    return FALSE;

}

BOOLEAN
SerialSetRTS(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine which is only called at interrupt level is used
    to set the RTS in the modem control register.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;
    UCHAR ModemControl;

    UNREFERENCED_PARAMETER(Interrupt);

    ModemControl = READ_MODEM_CONTROL(Extension, Extension->Controller);

    ModemControl |= SERIAL_MCR_RTS;

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Setting Rts for %p\n", Extension->Controller);

    WRITE_MODEM_CONTROL(Extension, Extension->Controller, ModemControl);

    return FALSE;

}

BOOLEAN
SerialClrRTS(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine which is only called at interrupt level is used
    to clear the RTS in the modem control register.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;
    UCHAR ModemControl;

    UNREFERENCED_PARAMETER(Interrupt);

    ModemControl = READ_MODEM_CONTROL(Extension, Extension->Controller);

    ModemControl &= ~SERIAL_MCR_RTS;

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Clearing Rts for %p\n", Extension->Controller);

    WRITE_MODEM_CONTROL(Extension, Extension->Controller, ModemControl);

    return FALSE;

}

BOOLEAN
SerialSetupNewHandFlow(
    IN PSERIAL_DEVICE_EXTENSION Extension,
    IN PSERIAL_HANDFLOW NewHandFlow
    )

/*++

Routine Description:

    This routine adjusts the flow control based on new
    control flow.

Arguments:

    Extension - A pointer to the serial device extension.

    NewHandFlow - A pointer to a serial handflow structure
                  that is to become the new setup for flow
                  control.

Return Value:

    This routine always returns FALSE.

--*/

{

    SERIAL_HANDFLOW New = *NewHandFlow;

    //
    // If the Extension->DeviceIsOpened is FALSE that means
    // we are entering this routine in response to an open request.
    // If that is so, then we always proceed with the work regardless
    // of whether things have changed.
    //

    //
    // First we take care of the DTR flow control.  We only
    // do work if something has changed.
    //

    if ((!Extension->DeviceIsOpened) ||
        ((Extension->HandFlow.ControlHandShake & SERIAL_DTR_MASK) !=
         (New.ControlHandShake & SERIAL_DTR_MASK))) {

        SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Processing DTR flow for %p\n",
                         Extension->Controller);

        if (New.ControlHandShake & SERIAL_DTR_MASK) {

            //
            // Well we might want to set DTR.
            //
            // Before we do, we need to check whether we are doing
            // dtr flow control.  If we are then we need to check
            // if then number of characters in the interrupt buffer
            // exceeds the XoffLimit.  If it does then we don't
            // enable DTR AND we set the RXHolding to record that
            // we are holding because of the dtr.
            //

            if ((New.ControlHandShake & SERIAL_DTR_MASK)
                == SERIAL_DTR_HANDSHAKE) {

                if ((Extension->BufferSize - New.XoffLimit) >
                    Extension->CharsInInterruptBuffer) {

                    //
                    // However if we are already holding we don't want
                    // to turn it back on unless we exceed the Xon
                    // limit.
                    //

                    if (Extension->RXHolding & SERIAL_RX_DTR) {

                        //
                        // We can assume that its DTR line is already low.
                        //

                        if (Extension->CharsInInterruptBuffer >
                            (ULONG)New.XonLimit) {

                            SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Removing DTR block on "
                                             "reception for %p\n",
                                             Extension->Controller);

                            Extension->RXHolding &= ~SERIAL_RX_DTR;
                            SerialSetDTR(Extension->WdfInterrupt, Extension);

                        }

                    } else {

                        SerialSetDTR(Extension->WdfInterrupt, Extension);

                    }

                } else {

                    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Setting DTR block on reception "
                                     "for %p\n", Extension->Controller);
                    Extension->RXHolding |= SERIAL_RX_DTR;
                    SerialClrDTR(Extension->WdfInterrupt, Extension);

                }

            } else {

                //
                // Note that if we aren't currently doing dtr flow control then
                // we MIGHT have been.  So even if we aren't currently doing
                // DTR flow control, we should still check if RX is holding
                // because of DTR.  If it is, then we should clear the holding
                // of this bit.
                //

                if (Extension->RXHolding & SERIAL_RX_DTR) {
                    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Removing dtr block of reception "
                                     "for %p\n", Extension->Controller);
                    Extension->RXHolding &= ~SERIAL_RX_DTR;
                }

                SerialSetDTR(Extension->WdfInterrupt, Extension);

            }

        } else {

            //
            // The end result here will be that DTR is cleared.
            //
            // We first need to check whether reception is being held
            // up because of previous DTR flow control.  If it is then
            // we should clear that reason in the RXHolding mask.
            //

            if (Extension->RXHolding & SERIAL_RX_DTR) {

                SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "removing dtr block of reception for"
                                 " %p\n", Extension->Controller);
                Extension->RXHolding &= ~SERIAL_RX_DTR;

            }

            SerialClrDTR(Extension->WdfInterrupt, Extension);

        }

    }

    //
    // Time to take care of the RTS Flow control.
    //
    // First we only do work if something has changed.
    //

    if ((!Extension->DeviceIsOpened) ||
        ((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK) !=
         (New.FlowReplace & SERIAL_RTS_MASK))) {

        SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Processing RTS flow %p\n",
                         Extension->Controller);

        if ((New.FlowReplace & SERIAL_RTS_MASK) ==
            SERIAL_RTS_HANDSHAKE) {

            //
            // Well we might want to set RTS.
            //
            // Before we do, we need to check whether we are doing
            // rts flow control.  If we are then we need to check
            // if then number of characters in the interrupt buffer
            // exceeds the XoffLimit.  If it does then we don't
            // enable RTS AND we set the RXHolding to record that
            // we are holding because of the rts.
            //

            if ((Extension->BufferSize - New.XoffLimit) >
                Extension->CharsInInterruptBuffer) {

                //
                // However if we are already holding we don't want
                // to turn it back on unless we exceed the Xon
                // limit.
                //

                if (Extension->RXHolding & SERIAL_RX_RTS) {

                    //
                    // We can assume that its RTS line is already low.
                    //

                    if (Extension->CharsInInterruptBuffer >
                        (ULONG)New.XonLimit) {

                       SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Removing rts block of "
                                        "reception for %p\n",
                                        Extension->Controller);
                        Extension->RXHolding &= ~SERIAL_RX_RTS;
                        SerialSetRTS(Extension->WdfInterrupt, Extension);

                    }

                } else {

                    SerialSetRTS(Extension->WdfInterrupt, Extension);

                }

            } else {

                SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Setting rts block of reception for "
                                 "%p\n", Extension->Controller);
                Extension->RXHolding |= SERIAL_RX_RTS;
                SerialClrRTS(Extension->WdfInterrupt, Extension);

            }

        } else if ((New.FlowReplace & SERIAL_RTS_MASK) ==
                   SERIAL_RTS_CONTROL) {

            //
            // Note that if we aren't currently doing rts flow control then
            // we MIGHT have been.  So even if we aren't currently doing
            // RTS flow control, we should still check if RX is holding
            // because of RTS.  If it is, then we should clear the holding
            // of this bit.
            //

            if (Extension->RXHolding & SERIAL_RX_RTS) {

                SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Clearing rts block of reception for "
                                 "%p\n", Extension->Controller);
                Extension->RXHolding &= ~SERIAL_RX_RTS;

            }

            SerialSetRTS(Extension->WdfInterrupt, Extension);

        } else if ((New.FlowReplace & SERIAL_RTS_MASK) ==
                   SERIAL_TRANSMIT_TOGGLE) {

            //
            // We first need to check whether reception is being held
            // up because of previous RTS flow control.  If it is then
            // we should clear that reason in the RXHolding mask.
            //

            if (Extension->RXHolding & SERIAL_RX_RTS) {

                SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "TOGGLE Clearing rts block of "
                                 "reception for %p\n", Extension->Controller);
                Extension->RXHolding &= ~SERIAL_RX_RTS;

            }

            //
            // We have to place the rts value into the Extension
            // now so that the code that tests whether the
            // rts line should be lowered will find that we
            // are "still" doing transmit toggling.  The code
            // for lowering can be invoked later by a timer so
            // it has to test whether it still needs to do its
            // work.
            //

            Extension->HandFlow.FlowReplace &= ~SERIAL_RTS_MASK;
            Extension->HandFlow.FlowReplace |= SERIAL_TRANSMIT_TOGGLE;

            //
            // The order of the tests is very important below.
            //
            // If there is a break then we should turn on the RTS.
            //
            // If there isn't a break but there are characters in
            // the hardware, then turn on the RTS.
            //
            // If there are writes pending that aren't being held
            // up, then turn on the RTS.
            //

            if ((Extension->TXHolding & SERIAL_TX_BREAK) ||
                ((SerialProcessLSR(Extension) & (SERIAL_LSR_THRE |
                                                 SERIAL_LSR_TEMT)) !=
                                                (SERIAL_LSR_THRE |
                                                 SERIAL_LSR_TEMT)) ||
                (Extension->CurrentWriteRequest || Extension->TransmitImmediate ||
                 (!IsQueueEmpty(Extension->WriteQueue)) &&
                 (!Extension->TXHolding))) {

                SerialSetRTS(Extension->WdfInterrupt, Extension);

            } else {

                //
                // This routine will check to see if it is time
                // to lower the RTS because of transmit toggle
                // being on.  If it is ok to lower it, it will,
                // if it isn't ok, it will schedule things so
                // that it will get lowered later.
                //

                Extension->CountOfTryingToLowerRTS++;
                SerialPerhapsLowerRTS(Extension->WdfInterrupt, Extension);

            }

        } else {

            //
            // The end result here will be that RTS is cleared.
            //
            // We first need to check whether reception is being held
            // up because of previous RTS flow control.  If it is then
            // we should clear that reason in the RXHolding mask.
            //

            if (Extension->RXHolding & SERIAL_RX_RTS) {

                SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_IOCTLS, "Clearing rts block of reception for"
                                 " %p\n", Extension->Controller);
                Extension->RXHolding &= ~SERIAL_RX_RTS;

            }

            SerialClrRTS(Extension->WdfInterrupt, Extension);

        }

    }

    //
    // We now take care of automatic receive flow control.
    // We only do work if things have changed.
    //

    if ((!Extension->DeviceIsOpened) ||
        ((Extension->HandFlow.FlowReplace & SERIAL_AUTO_RECEIVE) !=
         (New.FlowReplace & SERIAL_AUTO_RECEIVE))) {

        if (New.FlowReplace & SERIAL_AUTO_RECEIVE) {

            //
            // We wouldn't be here if it had been on before.
            //
            // We should check to see whether we exceed the turn
            // off limits.
            //
            // Note that since we are following the OS/2 flow
            // control rules we will never send an xon if
            // when enabling xon/xoff flow control we discover that
            // we could receive characters but we are held up do
            // to a previous Xoff.
            //

            if ((Extension->BufferSize - New.XoffLimit) <=
                Extension->CharsInInterruptBuffer) {

                //
                // Cause the Xoff to be sent.
                //

                Extension->RXHolding |= SERIAL_RX_XOFF;

                SerialProdXonXoff(
                    Extension,
                    FALSE
                    );

            }

        } else {

            //
            // The app has disabled automatic receive flow control.
            //
            // If transmission was being held up because of
            // an automatic receive Xoff, then we should
            // cause an Xon to be sent.
            //

            if (Extension->RXHolding & SERIAL_RX_XOFF) {

                Extension->RXHolding &= ~SERIAL_RX_XOFF;

                //
                // Cause the Xon to be sent.
                //

                SerialProdXonXoff(
                    Extension,
                    TRUE
                    );

            }

        }

    }

    //
    // We now take care of automatic transmit flow control.
    // We only do work if things have changed.
    //

    if ((!Extension->DeviceIsOpened) ||
        ((Extension->HandFlow.FlowReplace & SERIAL_AUTO_TRANSMIT) !=
         (New.FlowReplace & SERIAL_AUTO_TRANSMIT))) {

        if (New.FlowReplace & SERIAL_AUTO_TRANSMIT) {

            //
            // We wouldn't be here if it had been on before.
            //
            // There is some belief that if autotransmit
            // was just enabled, I should go look in what we
            // already received, and if we find the xoff character
            // then we should stop transmitting.  I think this
            // is an application bug.  For now we just care about
            // what we see in the future.
            //

            ;

        } else {

            //
            // The app has disabled automatic transmit flow control.
            //
            // If transmission was being held up because of
            // an automatic transmit Xoff, then we should
            // cause an Xon to be sent.
            //

            if (Extension->TXHolding & SERIAL_TX_XOFF) {

                Extension->TXHolding &= ~SERIAL_TX_XOFF;

                //
                // Cause the Xon to be sent.
                //

                SerialProdXonXoff(
                    Extension,
                    TRUE
                    );

            }

        }

    }

    //
    // At this point we can simply make sure that entire
    // handflow structure in the extension is updated.
    //

    Extension->HandFlow = New;

    return FALSE;

}

BOOLEAN
SerialSetHandFlow(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to set the handshake and control
    flow in the device extension.

Arguments:

    Context - Pointer to a structure that contains a pointer to
              the device extension and a pointer to a handflow
              structure..

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_IOCTL_SYNC S = Context;
    PSERIAL_DEVICE_EXTENSION Extension = S->Extension;
    PSERIAL_HANDFLOW HandFlow = S->Data;

    UNREFERENCED_PARAMETER(Interrupt);

    SerialSetupNewHandFlow(
        Extension,
        HandFlow
        );

    SerialHandleModemUpdate(
        Extension,
        FALSE
        );

    return FALSE;

}

BOOLEAN
SerialTurnOnBreak(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine will turn on break in the hardware and
    record the fact the break is on, in the extension variable
    that holds reasons that transmission is stopped.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UCHAR OldLineControl;

    UNREFERENCED_PARAMETER(Interrupt);

    if ((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK) ==
        SERIAL_TRANSMIT_TOGGLE) {

        SerialSetRTS(Extension->WdfInterrupt, Extension);

    }

    OldLineControl = READ_LINE_CONTROL(Extension, Extension->Controller);

    OldLineControl |= SERIAL_LCR_BREAK;

    WRITE_LINE_CONTROL(Extension,
        Extension->Controller,
        OldLineControl
        );

    Extension->TXHolding |= SERIAL_TX_BREAK;

    return FALSE;

}

BOOLEAN
SerialTurnOffBreak(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine will turn off break in the hardware and
    record the fact the break is off, in the extension variable
    that holds reasons that transmission is stopped.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UCHAR OldLineControl;

    UNREFERENCED_PARAMETER(Interrupt);

    if (Extension->TXHolding & SERIAL_TX_BREAK) {

        //
        // We actually have a good reason for testing if transmission
        // is holding instead of blindly clearing the bit.
        //
        // If transmission actually was holding and the result of
        // clearing the bit is that we should restart transmission
        // then we will poke the interrupt enable bit, which will
        // cause an actual interrupt and transmission will then
        // restart on its own.
        //
        // If transmission wasn't holding and we poked the bit
        // then we would interrupt before a character actually made
        // it out and we could end up over writing a character in
        // the transmission hardware.

        OldLineControl = READ_LINE_CONTROL(Extension, Extension->Controller);

        OldLineControl &= ~SERIAL_LCR_BREAK;

        WRITE_LINE_CONTROL(Extension,
            Extension->Controller,
            OldLineControl
            );

        Extension->TXHolding &= ~SERIAL_TX_BREAK;

        if (!Extension->TXHolding &&
            (Extension->TransmitImmediate ||
             Extension->WriteLength) &&
             Extension->HoldingEmpty) {

            DISABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
            ENABLE_ALL_INTERRUPTS(Extension, Extension->Controller);

        } else {

            //
            // The following routine will lower the rts if we
            // are doing transmit toggleing and there is no
            // reason to keep it up.
            //

            Extension->CountOfTryingToLowerRTS++;
            SerialPerhapsLowerRTS(Extension->WdfInterrupt, Extension);

        }

    }

    return FALSE;

}

BOOLEAN
SerialPretendXoff(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to process the Ioctl that request the
    driver to act as if an Xoff was received.  Even if the
    driver does not have automatic Xoff/Xon flowcontrol - This
    still will stop the transmission.  This is the OS/2 behavior
    and is not well specified for Windows.  Therefore we adopt
    the OS/2 behavior.

    Note: If the driver does not have automatic Xoff/Xon enabled
    then the only way to restart transmission is for the
    application to request we "act" as if we saw the xon.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    Extension->TXHolding |= SERIAL_TX_XOFF;

    if ((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK) ==
        SERIAL_TRANSMIT_TOGGLE) {

        SerialInsertQueueDpc(
            Extension->StartTimerLowerRTSDpc
            )?Extension->CountOfTryingToLowerRTS++:0;

    }

    return FALSE;

}

BOOLEAN
SerialPretendXon(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine is used to process the Ioctl that request the
    driver to act as if an Xon was received.

    Note: If the driver does not have automatic Xoff/Xon enabled
    then the only way to restart transmission is for the
    application to request we "act" as if we saw the xon.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    This routine always returns FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    if (Extension->TXHolding) {

        //
        // We actually have a good reason for testing if transmission
        // is holding instead of blindly clearing the bit.
        //
        // If transmission actually was holding and the result of
        // clearing the bit is that we should restart transmission
        // then we will poke the interrupt enable bit, which will
        // cause an actual interrupt and transmission will then
        // restart on its own.
        //
        // If transmission wasn't holding and we poked the bit
        // then we would interrupt before a character actually made
        // it out and we could end up over writing a character in
        // the transmission hardware.

        Extension->TXHolding &= ~SERIAL_TX_XOFF;

        if (!Extension->TXHolding &&
            (Extension->TransmitImmediate ||
             Extension->WriteLength) &&
             Extension->HoldingEmpty) {

            DISABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
            ENABLE_ALL_INTERRUPTS(Extension, Extension->Controller);

        }

    }

    return FALSE;

}

VOID
SerialHandleReducedIntBuffer(
    IN PSERIAL_DEVICE_EXTENSION Extension
    )

/*++

Routine Description:

    This routine is called to handle a reduction in the number
    of characters in the interrupt (typeahead) buffer.  It
    will check the current output flow control and re-enable transmission
    as needed.

    NOTE: This routine assumes that it is working at interrupt level.

Arguments:

    Extension - A pointer to the device extension.

Return Value:

    None.

--*/

{


    //
    // If we are doing receive side flow control and we are
    // currently "holding" then because we've emptied out
    // some characters from the interrupt buffer we need to
    // see if we can "re-enable" reception.
    //

    if (Extension->RXHolding) {

        if (Extension->CharsInInterruptBuffer <=
            (ULONG)Extension->HandFlow.XonLimit) {

            if (Extension->RXHolding & SERIAL_RX_DTR) {

                Extension->RXHolding &= ~SERIAL_RX_DTR;
                SerialSetDTR(Extension->WdfInterrupt, Extension);

            }

            if (Extension->RXHolding & SERIAL_RX_RTS) {

                Extension->RXHolding &= ~SERIAL_RX_RTS;
                SerialSetRTS(Extension->WdfInterrupt, Extension);

            }

            if (Extension->RXHolding & SERIAL_RX_XOFF) {

                //
                // Prod the transmit code to send xon.
                //

                SerialProdXonXoff(
                    Extension,
                    TRUE
                    );

            }

        }

    }

}

VOID
SerialProdXonXoff(
    IN PSERIAL_DEVICE_EXTENSION Extension,
    IN BOOLEAN SendXon
    )

/*++

Routine Description:

    This routine will set up the SendXxxxChar variables if
    necessary and determine if we are going to be interrupting
    because of current transmission state.  It will cause an
    interrupt to occur if neccessary, to send the xon/xoff char.

    NOTE: This routine assumes that it is called at interrupt
          level.

Arguments:

    Extension - A pointer to the serial device extension.

    SendXon - If a character is to be send, this indicates whether
              it should be an Xon or an Xoff.

Return Value:

    None.

--*/

{

    //
    // We assume that if the prodding is called more than
    // once that the last prod has set things up appropriately.
    //
    // We could get called before the character is sent out
    // because the send of the character was blocked because
    // of hardware flow control (or break).
    //

    if (!Extension->SendXonChar && !Extension->SendXoffChar
        && Extension->HoldingEmpty) {

        DISABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
        ENABLE_ALL_INTERRUPTS(Extension, Extension->Controller);

    }

    if (SendXon) {

        Extension->SendXonChar = TRUE;
        Extension->SendXoffChar = FALSE;

    } else {

        Extension->SendXonChar = FALSE;
        Extension->SendXoffChar = TRUE;

    }

}

ULONG
SerialHandleModemUpdate(
    IN PSERIAL_DEVICE_EXTENSION Extension,
    IN BOOLEAN DoingTX
    )

/*++

Routine Description:

    This routine will be to check on the modem status, and
    handle any appropriate event notification as well as
    any flow control appropriate to modem status lines.

    NOTE: This routine assumes that it is called at interrupt
          level.

Arguments:

    Extension - A pointer to the serial device extension.

    DoingTX - This boolean is used to indicate that this call
              came from the transmit processing code.  If this
              is true then there is no need to cause a new interrupt
              since the code will be trying to send the next
              character as soon as this call finishes.

Return Value:

    This returns the old value of the modem status register
    (extended into a ULONG).

--*/

{

    //
    // We keep this local so that after we are done
    // examining the modem status and we've updated
    // the transmission holding value, we know whether
    // we've changed from needing to hold up transmission
    // to transmission being able to proceed.
    //
    ULONG OldTXHolding = Extension->TXHolding;

    //
    // Holds the value in the mode status register.
    //
    UCHAR ModemStatus;
    PREQUEST_CONTEXT reqContext;

    ModemStatus =
    READ_MODEM_STATUS(Extension, Extension->Controller);


    //
    // If we are placeing the modem status into the data stream
    // on every change, we should do it now.
    //

    if (Extension->EscapeChar) {

        if (ModemStatus & (SERIAL_MSR_DCTS |
                           SERIAL_MSR_DDSR |
                           SERIAL_MSR_TERI |
                           SERIAL_MSR_DDCD)) {

            SerialPutChar(
                Extension,
                Extension->EscapeChar
                );
            SerialPutChar(
                Extension,
                SERIAL_LSRMST_MST
                );
            SerialPutChar(
                Extension,
                ModemStatus
                );

        }

    }


    //
    // Take care of input flow control based on sensitivity
    // to the DSR.  This is done so that the application won't
    // see spurious data generated by odd devices.
    //
    // Basically, if we are doing dsr sensitivity then the
    // driver should only accept data when the dsr bit is
    // set.
    //

    if (Extension->HandFlow.ControlHandShake & SERIAL_DSR_SENSITIVITY) {

        if (ModemStatus & SERIAL_MSR_DSR) {

            //
            // The line is high.  Simply make sure that
            // RXHolding does't have the DSR bit.
            //

            Extension->RXHolding &= ~SERIAL_RX_DSR;

        } else {

            Extension->RXHolding |= SERIAL_RX_DSR;

        }

    } else {

        //
        // We don't have sensitivity due to DSR.  Make sure we
        // arn't holding. (We might have been, but the app just
        // asked that we don't hold for this reason any more.)
        //

        Extension->RXHolding &= ~SERIAL_RX_DSR;

    }

    //
    // Check to see if we have a wait
    // pending on the modem status events.  If we
    // do then we schedule a dpc to satisfy
    // that wait.
    //

    if (Extension->IsrWaitMask) {

        if ((Extension->IsrWaitMask & SERIAL_EV_CTS) &&
            (ModemStatus & SERIAL_MSR_DCTS)) {

            Extension->HistoryMask |= SERIAL_EV_CTS;

        }

        if ((Extension->IsrWaitMask & SERIAL_EV_DSR) &&
            (ModemStatus & SERIAL_MSR_DDSR)) {

            Extension->HistoryMask |= SERIAL_EV_DSR;

        }

        if ((Extension->IsrWaitMask & SERIAL_EV_RING) &&
            (ModemStatus & SERIAL_MSR_TERI)) {

            Extension->HistoryMask |= SERIAL_EV_RING;

        }

        if ((Extension->IsrWaitMask & SERIAL_EV_RLSD) &&
            (ModemStatus & SERIAL_MSR_DDCD)) {

            Extension->HistoryMask |= SERIAL_EV_RLSD;

        }

        if (Extension->IrpMaskLocation &&
            Extension->HistoryMask) {

            *Extension->IrpMaskLocation =
             Extension->HistoryMask;
            Extension->IrpMaskLocation = NULL;
            Extension->HistoryMask = 0;

            reqContext = SerialGetRequestContext(Extension->CurrentWaitRequest);
            reqContext->Information = sizeof(ULONG);
            SerialInsertQueueDpc(
                Extension->CommWaitDpc
                );

        }

    }

    //
    // If the app has modem line flow control then
    // we check to see if we have to hold up transmission.
    //

    if (Extension->HandFlow.ControlHandShake &
        SERIAL_OUT_HANDSHAKEMASK) {

        if (Extension->HandFlow.ControlHandShake &
            SERIAL_CTS_HANDSHAKE) {

            if (ModemStatus & SERIAL_MSR_CTS) {

                Extension->TXHolding &= ~SERIAL_TX_CTS;

            } else {

                Extension->TXHolding |= SERIAL_TX_CTS;

            }

        } else {

            Extension->TXHolding &= ~SERIAL_TX_CTS;

        }

        if (Extension->HandFlow.ControlHandShake &
            SERIAL_DSR_HANDSHAKE) {

            if (ModemStatus & SERIAL_MSR_DSR) {

                Extension->TXHolding &= ~SERIAL_TX_DSR;

            } else {

                Extension->TXHolding |= SERIAL_TX_DSR;

            }

        } else {

            Extension->TXHolding &= ~SERIAL_TX_DSR;

        }

        if (Extension->HandFlow.ControlHandShake &
            SERIAL_DCD_HANDSHAKE) {

            if (ModemStatus & SERIAL_MSR_DCD) {

                Extension->TXHolding &= ~SERIAL_TX_DCD;

            } else {

                Extension->TXHolding |= SERIAL_TX_DCD;

            }

        } else {

            Extension->TXHolding &= ~SERIAL_TX_DCD;

        }

        //
        // If we hadn't been holding, and now we are then
        // queue off a dpc that will lower the RTS line
        // if we are doing transmit toggling.
        //

        if (!OldTXHolding && Extension->TXHolding  &&
            ((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK) ==
              SERIAL_TRANSMIT_TOGGLE)) {

            SerialInsertQueueDpc(
                Extension->StartTimerLowerRTSDpc
                )?Extension->CountOfTryingToLowerRTS++:0;

        }

        //
        // We've done any adjusting that needed to be
        // done to the holding mask given updates
        // to the modem status.  If the Holding mask
        // is clear (and it wasn't clear to start)
        // and we have "write" work to do set things
        // up so that the transmission code gets invoked.
        //

        if (!DoingTX && OldTXHolding && !Extension->TXHolding) {

            if (!Extension->TXHolding &&
                (Extension->TransmitImmediate ||
                 Extension->WriteLength) &&
                 Extension->HoldingEmpty) {

                DISABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
                ENABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
            }

        }

    } else {

        //
        // We need to check if transmission is holding
        // up because of modem status lines.  What
        // could have occured is that for some strange
        // reason, the app has asked that we no longer
        // stop doing output flow control based on
        // the modem status lines.  If however, we
        // *had* been held up because of the status lines
        // then we need to clear up those reasons.
        //

        if (Extension->TXHolding & (SERIAL_TX_DCD |
                                    SERIAL_TX_DSR |
                                    SERIAL_TX_CTS)) {

            Extension->TXHolding &= ~(SERIAL_TX_DCD |
                                      SERIAL_TX_DSR |
                                      SERIAL_TX_CTS);


            if (!DoingTX && OldTXHolding && !Extension->TXHolding) {

                if (!Extension->TXHolding &&
                    (Extension->TransmitImmediate ||
                     Extension->WriteLength) &&
                     Extension->HoldingEmpty) {

                    DISABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
                    ENABLE_ALL_INTERRUPTS(Extension, Extension->Controller);
                }

            }

        }

    }

    return ((ULONG)ModemStatus);
}

BOOLEAN
SerialPerhapsLowerRTS(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine checks that the software reasons for lowering
    the RTS lines are present.  If so, it will then cause the
    line status register to be read (and any needed processing
    implied by the status register to be done), and if the
    shift register is empty it will lower the line.  If the
    shift register isn't empty, this routine will queue off
    a dpc that will start a timer, that will basically call
    us back to try again.

    NOTE: This routine assumes that it is called at interrupt
          level.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    Always FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    //
    // We first need to test if we are actually still doing
    // transmit toggle flow control.  If we aren't then
    // we have no reason to try be here.
    //

    if ((Extension->HandFlow.FlowReplace & SERIAL_RTS_MASK) ==
        SERIAL_TRANSMIT_TOGGLE) {

        //
        // The order of the tests is very important below.
        //
        // If there is a break then we should leave on the RTS,
        // because when the break is turned off, it will submit
        // the code to shut down the RTS.
        //
        // If there are writes pending that aren't being held
        // up, then leave on the RTS, because the end of the write
        // code will cause this code to be reinvoked.  If the writes
        // are being held up, its ok to lower the RTS because the
        // upon trying to write the first character after transmission
        // is restarted, we will raise the RTS line.
        //

        if ((Extension->TXHolding & SERIAL_TX_BREAK) ||
            (Extension->CurrentWriteRequest || Extension->TransmitImmediate ||
             (!IsQueueEmpty(Extension->WriteQueue)) &&
             (!Extension->TXHolding))) {

            NOTHING;

        } else {

            //
            // Looks good so far.  Call the line status check and processing
            // code, it will return the "current" line status value.  If
            // the holding and shift register are clear, lower the RTS line,
            // if they aren't clear, queue of a dpc that will cause a timer
            // to reinvoke us later.  We do this code here because no one
            // but this routine cares about the characters in the hardware,
            // so no routine by this routine will bother invoking to test
            // if the hardware is empty.
            //

            if ((SerialProcessLSR(Extension) &
                 (SERIAL_LSR_THRE | SERIAL_LSR_TEMT)) !=
                 (SERIAL_LSR_THRE | SERIAL_LSR_TEMT)) {

                //
                // Well it's not empty, try again later.
                //

                SerialInsertQueueDpc(
                    Extension->StartTimerLowerRTSDpc
                    )?Extension->CountOfTryingToLowerRTS++:0;


            } else {

                //
                // Nothing in the hardware, Lower the RTS.
                //

                SerialClrRTS(Extension->WdfInterrupt, Extension);


            }

        }

    }

    //
    // We decement the counter to indicate that we've reached
    // the end of the execution path that is trying to push
    // down the RTS line.
    //

    Extension->CountOfTryingToLowerRTS--;

    return FALSE;
}

VOID
SerialStartTimerLowerRTS(
    IN WDFDPC Dpc
    )

/*++

Routine Description:

    This routine starts a timer that when it expires will start
    a dpc that will check if it can lower the rts line because
    there are no characters in the hardware.

Arguments:

    Dpc - Not Used.

    DeferredContext - Really points to the device extension.

    SystemContext1 - Not Used.

    SystemContext2 - Not Used.

Return Value:

    None.

--*/

{
    LARGE_INTEGER CharTime;
    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfDpcGetParentObject(Dpc));



    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, ">SerialStartTimerLowerRTS(%p)\n",
                     Extension);


    //
    // Since all the callbacks into the driver are serialized, we don't have
    // synchronize the access to any of the Extension variables.
    //

    CharTime = SerialGetCharTime(Extension);

    CharTime.QuadPart = -CharTime.QuadPart;

    if (SerialSetTimer(
            Extension->LowerRTSTimer,
            CharTime
            )) {

        //
        // The timer was already in the timer queue.  This implies
        // that one path of execution that was trying to lower
        // the RTS has "died".  Synchronize with the ISR so that
        // we can lower the count.
        //

        WdfInterruptSynchronize(
            Extension->WdfInterrupt,
            SerialDecrementRTSCounter,
            Extension
            );

    }


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_IOCTLS, "<SerialStartTimerLowerRTS\n");

}

VOID
SerialInvokePerhapsLowerRTS(
    IN WDFTIMER Timer
    )

/*++

Routine Description:

    This dpc routine exists solely to call the code that
    tests if the rts line should be lowered when TRANSMIT
    TOGGLE flow control is being used.

Arguments:

     WDFTIMER

Return Value:

    None.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = NULL;

    Extension = SerialGetDeviceExtension(WdfTimerGetParentObject(Timer));

    WdfInterruptSynchronize(
        Extension->WdfInterrupt,
        SerialPerhapsLowerRTS,
        Extension
        );

}

BOOLEAN
SerialDecrementRTSCounter(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This routine checks that the software reasons for lowering
    the RTS lines are present.  If so, it will then cause the
    line status register to be read (and any needed processing
    implied by the status register to be done), and if the
    shift register is empty it will lower the line.  If the
    shift register isn't empty, this routine will queue off
    a dpc that will start a timer, that will basically call
    us back to try again.

    NOTE: This routine assumes that it is called at interrupt
          level.

Arguments:

    Context - Really a pointer to the device extension.

Return Value:

    Always FALSE.

--*/

{

    PSERIAL_DEVICE_EXTENSION Extension = Context;

    UNREFERENCED_PARAMETER(Interrupt);

    Extension->CountOfTryingToLowerRTS--;

    return FALSE;

}


