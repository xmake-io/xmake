/*++

Copyright (c) Microsoft Corporation

Module Name:

    power.c

Abstract:

    This module contains the code that handles the power IRPs for the serial
    driver.

Environment:

    Kernel mode

--*/

#include "precomp.h"


#if defined(EVENT_TRACING)
#include "power.tmh"
#endif


PCHAR
DbgDevicePowerString(
    IN WDF_POWER_DEVICE_STATE Type
    );

#ifdef ALLOC_PRAGMA
#pragma alloc_text(PAGESER,SerialEvtDeviceD0Exit)
#pragma alloc_text(PAGESER,SerialSaveDeviceState)
#endif // ALLOC_PRAGMA

PCHAR
DbgDevicePowerString(
    IN WDF_POWER_DEVICE_STATE Type
    )
/*++

Updated Routine Description:
    DbgDevicePowerString does not change in this stage of the function driver.

--*/
{

    switch (Type)
    {
    case WdfPowerDeviceInvalid:
        return "WdfPowerDeviceInvalid";
    case WdfPowerDeviceD0:
        return "WdfPowerDeviceD0";
    case WdfPowerDeviceD1:
        return "WdfPowerDeviceD1";
    case WdfPowerDeviceD2:
        return "WdfPowerDeviceD2";
    case WdfPowerDeviceD3:
        return "WdfPowerDeviceD3";
    case WdfPowerDeviceD3Final:
        return "WdfPowerDeviceD3Final";
    case WdfPowerDevicePrepareForHibernation:
        return "WdfPowerDevicePrepareForHibernation";
    case WdfPowerDeviceMaximum:
        return "WdfPowerDeviceMaximum";
    default:
        return "UnKnown Device Power State";
    }
}

NTSTATUS
SerialEvtDeviceD0Entry(
    IN  WDFDEVICE Device,
    IN  WDF_POWER_DEVICE_STATE PreviousState
    )
/*++

Routine Description:

    EvtDeviceD0Entry event callback must perform any operations that are
    necessary before the specified device is used.  It will be called every
    time the hardware needs to be (re-)initialized.  This includes after
    IRP_MN_START_DEVICE, IRP_MN_CANCEL_STOP_DEVICE, IRP_MN_CANCEL_REMOVE_DEVICE,
    IRP_MN_SET_POWER-D0.

    This function is not marked pageable because this function is in the
    device power up path. When a function is marked pagable and the code
    section is paged out, it will generate a page fault which could impact
    the fast resume behavior because the client driver will have to wait
    until the system drivers can service this page fault.

    This function runs at PASSIVE_LEVEL, even though it is not paged.  A
    driver can optionally make this function pageable if DO_POWER_PAGABLE
    is set.  Even if DO_POWER_PAGABLE isn't set, this function still runs
    at PASSIVE_LEVEL.  In this case, though, the function absolutely must
    not do anything that will cause a page fault.

Arguments:

    Device - Handle to a framework device object.

    PreviousState - Device power state which the device was in most recently.
        If the device is being newly started, this will be
        PowerDeviceUnspecified.

Return Value:

    NTSTATUS

--*/
{
    PSERIAL_DEVICE_EXTENSION deviceExtension;
    PSERIAL_DEVICE_STATE pDevState;
    SHORT divisor;
    SERIAL_IOCTL_SYNC S;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_POWER,
                "-->SerialEvtDeviceD0Entry - coming from %s\n", DbgDevicePowerString(PreviousState));

    deviceExtension = SerialGetDeviceExtension (Device);
    pDevState = &deviceExtension->DeviceState;

    //
    // Restore the state of the UART.  First, that involves disabling
    // interrupts both via OUT2 and IER.
    //

    WRITE_MODEM_CONTROL(deviceExtension, deviceExtension->Controller, 0);
    DISABLE_ALL_INTERRUPTS(deviceExtension, deviceExtension->Controller);

    //
    // Set the baud rate
    //

    SerialGetDivisorFromBaud(deviceExtension->ClockRate, deviceExtension->CurrentBaud, &divisor);
    S.Extension = deviceExtension;
    S.Data = (PVOID) (ULONG_PTR) divisor;

#pragma prefast(suppress: __WARNING_INFERRED_IRQ_TOO_LOW, "PFD warning that we are calling interrupt synchronize routine directly. Suppress it because interrupt is disabled above.")
    SerialSetBaud(deviceExtension->WdfInterrupt, &S);

    //
    // Reset / Re-enable the FIFO's
    //

    if (deviceExtension->FifoPresent) {
       WRITE_FIFO_CONTROL(deviceExtension, deviceExtension->Controller, (UCHAR)0);
       READ_RECEIVE_BUFFER(deviceExtension, deviceExtension->Controller);
       WRITE_FIFO_CONTROL(deviceExtension, deviceExtension->Controller,
                          (UCHAR)(SERIAL_FCR_ENABLE | deviceExtension->RxFifoTrigger
                                  | SERIAL_FCR_RCVR_RESET
                                  | SERIAL_FCR_TXMT_RESET));
    } else {
       WRITE_FIFO_CONTROL(deviceExtension, deviceExtension->Controller, (UCHAR)0);
    }

    //
    // Restore a couple more registers
    //

    WRITE_INTERRUPT_ENABLE(deviceExtension, deviceExtension->Controller, pDevState->IER);
    WRITE_LINE_CONTROL(deviceExtension, deviceExtension->Controller, pDevState->LCR);

    //
    // Clear out any stale interrupts
    //

    READ_INTERRUPT_ID_REG(deviceExtension, deviceExtension->Controller);
    READ_LINE_STATUS(deviceExtension, deviceExtension->Controller);
    READ_MODEM_STATUS(deviceExtension, deviceExtension->Controller);

    //
    // TODO:  move this code to EvtInterruptEnable.
    //

    if (deviceExtension->DeviceState.Reopen == TRUE) {
       SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_POWER, "Reopening device\n");

       SetDeviceIsOpened(deviceExtension, TRUE, FALSE);

       //
       // This enables interrupts on the device!
       //

       WRITE_MODEM_CONTROL(deviceExtension, deviceExtension->Controller,
                           (UCHAR)(pDevState->MCR | SERIAL_MCR_OUT2));

       //
       // Refire the state machine
       //

       DISABLE_ALL_INTERRUPTS(deviceExtension, deviceExtension->Controller);
       ENABLE_ALL_INTERRUPTS(deviceExtension, deviceExtension->Controller);
    }

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_POWER, "<--SerialEvtDeviceD0Entry\n");

    return STATUS_SUCCESS;
}


NTSTATUS
SerialEvtDeviceD0Exit(
    IN  WDFDEVICE Device,
    IN  WDF_POWER_DEVICE_STATE TargetState
    )
/*++

Routine Description:

   EvtDeviceD0Exit event callback must perform any operations that are
   necessary before the specified device is moved out of the D0 state.  If the
   driver needs to save hardware state before the device is powered down, then
   that should be done here.

   This function runs at PASSIVE_LEVEL, though it is generally not paged.  A
   driver can optionally make this function pageable if DO_POWER_PAGABLE is set.

   Even if DO_POWER_PAGABLE isn't set, this function still runs at
   PASSIVE_LEVEL.  In this case, though, the function absolutely must not do
   anything that will cause a page fault.

Arguments:

    Device - Handle to a framework device object.

    TargetState - Device power state which the device will be put in once this
        callback is complete.

Return Value:

    NTSTATUS

--*/
{
    PSERIAL_DEVICE_EXTENSION deviceExtension;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_POWER,
                "-->SerialEvtDeviceD0Exit - moving to %s\n", DbgDevicePowerString(TargetState));

    PAGED_CODE();

    deviceExtension = SerialGetDeviceExtension (Device);

    if (deviceExtension->DeviceIsOpened == TRUE) {
        LARGE_INTEGER charTime;

        SetDeviceIsOpened(deviceExtension, FALSE, TRUE);

        charTime.QuadPart = -SerialGetCharTime(deviceExtension).QuadPart;

        //
        // Shut down the chip
        //

        SerialDisableUART(deviceExtension);

        //
        // Drain the device
        //

        SerialDrainUART(deviceExtension, &charTime);

        //
        // Save the device state
        //

        SerialSaveDeviceState(deviceExtension);
    }
    else
    {
        SetDeviceIsOpened(deviceExtension, FALSE, FALSE);
    }

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_POWER, "<--SerialEvtDeviceD0Exit\n");

    return STATUS_SUCCESS;
}


VOID
SerialSaveDeviceState(IN PSERIAL_DEVICE_EXTENSION PDevExt)
/*++

Routine Description:

    This routine saves the device state of the UART

Arguments:

    PDevExt - Pointer to the device extension for the devobj to save the state
              for.

Return Value:

    VOID


--*/
{
   PSERIAL_DEVICE_STATE pDevState = &PDevExt->DeviceState;

   PAGED_CODE();

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_POWER, "Entering SerialSaveDeviceState\n");

   //
   // Read necessary registers direct
   //

   pDevState->IER = READ_INTERRUPT_ENABLE(PDevExt, PDevExt->Controller);
   pDevState->MCR = READ_MODEM_CONTROL(PDevExt, PDevExt->Controller);
   pDevState->LCR = READ_LINE_CONTROL(PDevExt, PDevExt->Controller);

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_POWER, "Leaving SerialSaveDeviceState\n");
}


VOID
SetDeviceIsOpened(IN PSERIAL_DEVICE_EXTENSION PDevExt, IN BOOLEAN DeviceIsOpened, IN BOOLEAN Reopen)
{

    PDevExt->DeviceIsOpened     = DeviceIsOpened;
    PDevExt->DeviceState.Reopen = Reopen;

}



