/*++

Copyright (c) 1991, 1992, 1993 - 1997 Microsoft Corporation

Module Name:

    pnp.c

Abstract:

    This module contains the code that handles the plug and play
    IRPs for the serial driver.

Environment:

    Kernel mode

--*/

#include "precomp.h"
#include <initguid.h>
#include <ntddser.h>
#include <stdlib.h>

#if defined(EVENT_TRACING)
#include "pnp.tmh"
#endif

static const PHYSICAL_ADDRESS SerialPhysicalZero = {0};
static const SUPPORTED_BAUD_RATES SupportedBaudRates[] = {
        {75, SERIAL_BAUD_075},
        {110, SERIAL_BAUD_110},
        {135, SERIAL_BAUD_134_5},
        {150, SERIAL_BAUD_150},
        {300, SERIAL_BAUD_300},
        {600, SERIAL_BAUD_600},
        {1200, SERIAL_BAUD_1200},
        {1800, SERIAL_BAUD_1800},
        {2400, SERIAL_BAUD_2400},
        {4800, SERIAL_BAUD_4800},
        {7200, SERIAL_BAUD_7200},
        {9600, SERIAL_BAUD_9600},
        {14400, SERIAL_BAUD_14400},
        {19200, SERIAL_BAUD_19200},
        {38400, SERIAL_BAUD_38400},
        {56000, SERIAL_BAUD_56K},
        {57600, SERIAL_BAUD_57600},
        {115200, SERIAL_BAUD_115200},
        {128000, SERIAL_BAUD_128K},
        {SERIAL_BAUD_INVALID, SERIAL_BAUD_USER}
    };


#ifdef ALLOC_PRAGMA
#pragma alloc_text(PAGESRP0, SerialEvtDeviceAdd)
#pragma alloc_text(PAGESRP0, SerialEvtPrepareHardware)
#pragma alloc_text(PAGESRP0, SerialEvtReleaseHardware)
#pragma alloc_text(PAGESRP0, SerialEvtDeviceD0ExitPreInterruptsDisabled)
#pragma alloc_text(PAGESRP0, SerialMapHWResources)
#pragma alloc_text(PAGESRP0, SerialUnmapHWResources)
#pragma alloc_text(PAGESRP0, SerialEvtDeviceContextCleanup)
#pragma alloc_text(PAGESRP0, SerialDoExternalNaming)
#pragma alloc_text(PAGESRP0, SerialReportMaxBaudRate)
#pragma alloc_text(PAGESRP0, SerialUndoExternalNaming)
#pragma alloc_text(PAGESRP0, SerialInitController)
#pragma alloc_text(PAGESRP0, SerialGetMappedAddress)
#pragma alloc_text(PAGESRP0, SerialSetPowerPolicy)
#pragma alloc_text(PAGESRP0, SerialReadSymName)

#endif // ALLOC_PRAGMA

PVOID LocalMmMapIoSpace(
    _In_ PHYSICAL_ADDRESS PhysicalAddress,
    _In_ SIZE_T NumberOfBytes
    )
{
    typedef
    PVOID
    (*PFN_MM_MAP_IO_SPACE_EX) (
        _In_ PHYSICAL_ADDRESS PhysicalAddress,
        _In_ SIZE_T NumberOfBytes,
        _In_ ULONG Protect
        );

    UNICODE_STRING         name;
    PFN_MM_MAP_IO_SPACE_EX pMmMapIoSpaceEx;

    RtlInitUnicodeString(&name, L"MmMapIoSpaceEx");
    pMmMapIoSpaceEx = (PFN_MM_MAP_IO_SPACE_EX) (ULONG_PTR)MmGetSystemRoutineAddress(&name);

    if (pMmMapIoSpaceEx != NULL){
        //
        // Call WIN10 API if available
        //        
        return pMmMapIoSpaceEx(PhysicalAddress,
                               NumberOfBytes,
                               PAGE_READWRITE | PAGE_NOCACHE); 
    }

    //
    // Supress warning that MmMapIoSpace allocates executable memory.
    // This function is only used if the preferred API, MmMapIoSpaceEx
    // is not present. MmMapIoSpaceEx is available starting in WIN10.
    //
    #pragma warning(suppress: 30029)
    return MmMapIoSpace(PhysicalAddress, NumberOfBytes, MmNonCached); 
}

NTSTATUS
SerialEvtDeviceAdd(
    IN WDFDRIVER Driver,
    IN PWDFDEVICE_INIT DeviceInit
    )
/*++

Routine Description:

    EvtDeviceAdd is called by the framework in response to AddDevice
    call from the PnP manager.


Arguments:

    Driver - Handle to a framework driver object created in DriverEntry

    DeviceInit - Pointer to a framework-allocated WDFDEVICE_INIT structure.

Return Value:

    NTSTATUS

--*/

{
    NTSTATUS                      status;
    PSERIAL_DEVICE_EXTENSION      pDevExt;
    static ULONG                  currentInstance = 0;
    WDF_FILEOBJECT_CONFIG         fileobjectConfig;
    WDFDEVICE                     device;
    WDF_PNPPOWER_EVENT_CALLBACKS  pnpPowerCallbacks;
    WDF_OBJECT_ATTRIBUTES         attributes;
    WDF_IO_QUEUE_CONFIG           queueConfig;
    WDFQUEUE                      defaultqueue;
    ULONG                         isMulti;
    PULONG                        countSoFar;
    WDF_INTERRUPT_CONFIG          interruptConfig;
    PSERIAL_INTERRUPT_CONTEXT     interruptContext;
    ULONG                         relinquishPowerPolicy;

    DECLARE_UNICODE_STRING_SIZE(deviceName, DEVICE_OBJECT_NAME_LENGTH);

    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "-->SerialEvtDeviceAdd\n");

    status = RtlUnicodeStringPrintf(&deviceName, L"%ws%u",
                                L"\\Device\\Serial",
                                currentInstance++);


    if (!NT_SUCCESS(status)) {
        return status;
    }

    status = WdfDeviceInitAssignName(DeviceInit,& deviceName);
    if (!NT_SUCCESS(status)) {
        return status;
    }

    WdfDeviceInitSetExclusive(DeviceInit, TRUE);
    WdfDeviceInitSetDeviceType(DeviceInit, FILE_DEVICE_SERIAL_PORT);

    WDF_OBJECT_ATTRIBUTES_INIT_CONTEXT_TYPE(&attributes, REQUEST_CONTEXT);

    WdfDeviceInitSetRequestAttributes(DeviceInit, &attributes);

    //
    // Zero out the PnpPowerCallbacks structure.
    //
    WDF_PNPPOWER_EVENT_CALLBACKS_INIT(&pnpPowerCallbacks);

    //
    // Set Callbacks for any of the functions we are interested in.
    // If no callback is set, Framework will take the default action
    // by itself.  These next two callbacks set up and tear down hardware state,
    // specifically that which only has to be done once.
    //

    pnpPowerCallbacks.EvtDevicePrepareHardware = SerialEvtPrepareHardware;
    pnpPowerCallbacks.EvtDeviceReleaseHardware = SerialEvtReleaseHardware;

    //
    // These two callbacks set up and tear down hardware state that must be
    // done every time the device moves in and out of the D0-working state.
    //

    pnpPowerCallbacks.EvtDeviceD0Entry         = SerialEvtDeviceD0Entry;
    pnpPowerCallbacks.EvtDeviceD0Exit          = SerialEvtDeviceD0Exit;

    //
    // Specify the callback for monitoring when the device's interrupt are
    // enabled or about to be disabled.
    //

    pnpPowerCallbacks.EvtDeviceD0EntryPostInterruptsEnabled = SerialEvtDeviceD0EntryPostInterruptsEnabled;
    pnpPowerCallbacks.EvtDeviceD0ExitPreInterruptsDisabled  = SerialEvtDeviceD0ExitPreInterruptsDisabled;

    //
    // Register the PnP and power callbacks.
    //
    WdfDeviceInitSetPnpPowerEventCallbacks(DeviceInit, &pnpPowerCallbacks);

    if ( !NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                         "WdfDeviceInitSetPnpPowerEventCallbacks failed %!STATUS!\n",
                         status);
        return status;
    }

    //
    // Find out if we own power policy
    //
    SerialGetFdoRegistryKeyValue( DeviceInit,
                                  L"SerialRelinquishPowerPolicy",
                                  &relinquishPowerPolicy );

    if(relinquishPowerPolicy) {
        //
        // FDO's are assumed to be power policy owner by default. So tell
        // the framework explicitly to relinquish the power policy ownership.
        //
        SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                         "RelinquishPowerPolicy due to registry settings\n");

        WdfDeviceInitSetPowerPolicyOwnership(DeviceInit, FALSE);
    }

    //
    // For Windows XP and below, we will register for the WDM Preprocess callback
    // for IRP_MJ_CREATE. This is done because, the Serenum filter doesn't handle
    // creates that are marked pending. Since framework always marks the IRP pending,
    // we are registering this WDM preprocess handler so that we can bypass the
    // framework and handle the create and close ourself. This workaround is need
    // only if you intend to install the Serenum as an upper filter.
    //
    if (RtlIsNtDdiVersionAvailable(NTDDI_VISTA) == FALSE) {

        status = WdfDeviceInitAssignWdmIrpPreprocessCallback(
                                                DeviceInit,
                                                SerialWdmDeviceFileCreate,
                                                IRP_MJ_CREATE,
                                                NULL, // pointer minor function table
                                                0); // number of entries in the table

        if (!NT_SUCCESS(status)) {
            SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                             "WdfDeviceInitAssignWdmIrpPreprocessCallback failed %!STATUS!\n",
                             status);
            return status;
        }

        status = WdfDeviceInitAssignWdmIrpPreprocessCallback(
                                                DeviceInit,
                                                SerialWdmFileClose,
                                                IRP_MJ_CLOSE,
                                                NULL, // pointer minor function table
                                                0); // number of entries in the table

        if (!NT_SUCCESS(status)) {
            SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                             "WdfDeviceInitAssignWdmIrpPreprocessCallback failed %!STATUS!\n",
                             status);
            return status;
        }

    } else {

        //
        // FileEvents can opt for Device level synchronization only if the ExecutionLevel
        // of the Device is passive. Since we can't choose passive execution-level for
        // device because we have chose to synchronize timers & dpcs with the device,
        // we will opt out of synchonization with the device for fileobjects.
        // Note: If the driver has to synchronize Create with the other I/O events,
        // it can create a queue and configure-dispatch create requests to the queue.
        //
        WDF_OBJECT_ATTRIBUTES_INIT(&attributes);
        attributes.SynchronizationScope = WdfSynchronizationScopeNone;

        //
        // Set Entry points for Create and Close..
        //
        WDF_FILEOBJECT_CONFIG_INIT(
                            &fileobjectConfig,
                            SerialEvtDeviceFileCreate,
                            SerialEvtFileClose,
                            WDF_NO_EVENT_CALLBACK // Cleanup
                            );

        WdfDeviceInitSetFileObjectConfig(
                        DeviceInit,
                        &fileobjectConfig,
                        &attributes
                        );
    }


    //
    // Since framework queues doesn't handle IRP_MJ_FLUSH_BUFFERS,
    // IRP_MJ_QUERY_INFORMATION and IRP_MJ_SET_INFORMATION requests,
    // we will register a preprocess callback to handle them.
    //
    status = WdfDeviceInitAssignWdmIrpPreprocessCallback(
                                            DeviceInit,
                                            SerialFlush,
                                            IRP_MJ_FLUSH_BUFFERS,
                                            NULL, // pointer minor function table
                                            0); // number of entries in the table

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                         "WdfDeviceInitAssignWdmIrpPreprocessCallback failed %!STATUS!\n",
                         status);
        return status;
    }

    status = WdfDeviceInitAssignWdmIrpPreprocessCallback(
                                        DeviceInit,
                                        SerialQueryInformationFile,
                                        IRP_MJ_QUERY_INFORMATION,
                                        NULL, // pointer minor function table
                                        0); // number of entries in the table

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                         "WdfDeviceInitAssignWdmIrpPreprocessCallback failed %!STATUS!\n",
                         status);
        return status;
    }
    status = WdfDeviceInitAssignWdmIrpPreprocessCallback(
                                        DeviceInit,
                                        SerialSetInformationFile,
                                        IRP_MJ_SET_INFORMATION,
                                        NULL, // pointer minor function table
                                        0); // number of entries in the table

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                         "WdfDeviceInitAssignWdmIrpPreprocessCallback failed %!STATUS!\n",
                         status);
        return status;
    }


    //
    // Create a device
    //
    WDF_OBJECT_ATTRIBUTES_INIT_CONTEXT_TYPE (&attributes,
                                            SERIAL_DEVICE_EXTENSION);
    //
    // Provide a callback to cleanup the context. This will be called
    // when the device is removed.
    //
    attributes.EvtCleanupCallback = SerialEvtDeviceContextCleanup;
    //
    // By opting for SynchronizationScopeDevice, we tell the framework to
    // synchronize callbacks events of all the objects directly associated
    // with the device. In this driver, we will associate queues, dpcs,
    // and timers. By doing that we don't have to worrry about synchronizing
    // access to device-context by Io Events, cancel-routine, timer and dpc
    // callbacks.
    //
    attributes.SynchronizationScope = WdfSynchronizationScopeDevice;

    status = WdfDeviceCreate(&DeviceInit, &attributes, &device);
    if (!NT_SUCCESS(status)) {

        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                       "SerialAddDevice - WdfDeviceCreate failed %!STATUS!\n",
                         status);
        return status;
    }

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     "Created device (%p) %wZ\n", device, &deviceName);

    pDevExt = SerialGetDeviceExtension (device);

    pDevExt->DriverObject = WdfDriverWdmGetDriverObject(Driver);

    //
    // This sample doesn't support multiport serial devices.
    // Multiport devices allow other pseudo-serial devices with extra
    // resources to specify another range of I/O ports.
    //
    if(!SerialGetRegistryKeyValue(device, L"MultiportDevice",  &isMulti)) {
        isMulti = 0;
    }

    if(isMulti) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                         "This sample doesn't support multiport devices\n");
        return STATUS_DEVICE_CONFIGURATION_ERROR;
    }

    //
    // Set up the device extension.
    //

    pDevExt = SerialGetDeviceExtension (device);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     "AddDevice PDO(0x%p) FDO(0x%p), Lower(0x%p) DevExt (0x%p)\n",
                    WdfDeviceWdmGetPhysicalDevice (device),
                    WdfDeviceWdmGetDeviceObject (device),
                    WdfDeviceWdmGetAttachedDevice(device),
                    pDevExt);

    pDevExt->DeviceIsOpened = FALSE;
    pDevExt->DeviceObject   = WdfDeviceWdmGetDeviceObject(device);
    pDevExt->WdfDevice = device;

    pDevExt->TxFifoAmount           = driverDefaults.TxFIFODefault;
    pDevExt->UartRemovalDetect      = driverDefaults.UartRemovalDetect;
    pDevExt->CreatedSymbolicLink    = FALSE;
    pDevExt->OwnsPowerPolicy = relinquishPowerPolicy ? FALSE : TRUE;

    status = SerialSetPowerPolicy(pDevExt);
    if(!NT_SUCCESS(status)){
        return status;
    }

    //
    // We create four manual queues below.
    // Read Queue..(how about using serial queue for read). Since requests
    // jump from queue to queue, we cannot configure the queues to receive a
    // particular type of request. For example, some of the IOCTLs end up
    // in read and write queue.
    //
    WDF_IO_QUEUE_CONFIG_INIT(&queueConfig,
                             WdfIoQueueDispatchManual);

    queueConfig.EvtIoStop = SerialEvtIoStop;
    queueConfig.EvtIoResume = SerialEvtIoResume;
    queueConfig.EvtIoCanceledOnQueue = SerialEvtCanceledOnQueue;

    status = WdfIoQueueCreate (device,
                               &queueConfig,
                               WDF_NO_OBJECT_ATTRIBUTES,
                               &pDevExt->ReadQueue
                               );

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, " WdfIoQueueCreate for Read failed %!STATUS!\n", status);
        return status;
    }

    //
    // Write Queue..
    //
    WDF_IO_QUEUE_CONFIG_INIT(&queueConfig,
                             WdfIoQueueDispatchManual);

    queueConfig.EvtIoStop = SerialEvtIoStop;
    queueConfig.EvtIoResume = SerialEvtIoResume;
    queueConfig.EvtIoCanceledOnQueue = SerialEvtCanceledOnQueue;

    status = WdfIoQueueCreate (device,
                               &queueConfig,
                               WDF_NO_OBJECT_ATTRIBUTES,
                               &pDevExt->WriteQueue
                               );

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,  " WdfIoQueueCreate for Write failed %!STATUS!\n", status);
        return status;
    }

    //
    // Mask Queue...
    //
    WDF_IO_QUEUE_CONFIG_INIT(&queueConfig,
                             WdfIoQueueDispatchManual
                             );

    queueConfig.EvtIoCanceledOnQueue = SerialEvtCanceledOnQueue;

    queueConfig.EvtIoStop = SerialEvtIoStop;
    queueConfig.EvtIoResume = SerialEvtIoResume;

    status = WdfIoQueueCreate (device,
                               &queueConfig,
                               WDF_NO_OBJECT_ATTRIBUTES,
                               &pDevExt->MaskQueue
                               );

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,  " WdfIoQueueCreate for Mask failed %!STATUS!\n",   status);
        return status;
    }

    //
    // Purge Queue..
    //
    WDF_IO_QUEUE_CONFIG_INIT(&queueConfig,
                             WdfIoQueueDispatchManual
                             );

    queueConfig.EvtIoCanceledOnQueue = SerialEvtCanceledOnQueue;

    queueConfig.EvtIoStop = SerialEvtIoStop;
    queueConfig.EvtIoResume = SerialEvtIoResume;

    status = WdfIoQueueCreate (device,
                               &queueConfig,
                               WDF_NO_OBJECT_ATTRIBUTES,
                               &pDevExt->PurgeQueue
                               );

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,  " WdfIoQueueCreate for Purge failed %!STATUS!\n",   status);
        return status;
    }

    //
    // All the incoming I/O requests are routed to the default queue and dispatch to the
    // appropriate callback events. These callback event will check to see if another
    // request is currently active. If so then it will forward it to other manual queues.
    // All the queues are auto managed by the framework in response to the PNP
    // and Power events.
    //
    WDF_IO_QUEUE_CONFIG_INIT_DEFAULT_QUEUE(
                &queueConfig,
                WdfIoQueueDispatchParallel
                );
    queueConfig.EvtIoRead   = SerialEvtIoRead;
    queueConfig.EvtIoWrite  = SerialEvtIoWrite;
    queueConfig.EvtIoDeviceControl = SerialEvtIoDeviceControl;
    queueConfig.EvtIoInternalDeviceControl = SerialEvtIoInternalDeviceControl;
    queueConfig.EvtIoCanceledOnQueue = SerialEvtCanceledOnQueue;

    queueConfig.EvtIoStop = SerialEvtIoStop;
    queueConfig.EvtIoResume = SerialEvtIoResume;

    status = WdfIoQueueCreate(device,
                                         &queueConfig,
                                         WDF_NO_OBJECT_ATTRIBUTES,
                                         &defaultqueue
                                         );
    if (!NT_SUCCESS(status)) {

        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "WdfIoQueueCreate failed %!STATUS!\n", status);
        return status;
    }

    //
    // Create WDFINTERRUPT object. Let us leave the ShareVector to  default value and
    // let the framework decide whether to share the interrupt or not based on the
    // ShareDisposition provided by the bus driver in the resource descriptor.
    //

    WDF_INTERRUPT_CONFIG_INIT(&interruptConfig,
                              SerialISR,
                              NULL);

    interruptConfig.EvtInterruptDisable = SerialEvtInterruptDisable;
    interruptConfig.EvtInterruptEnable = SerialEvtInterruptEnable;

    WDF_OBJECT_ATTRIBUTES_INIT_CONTEXT_TYPE(&attributes, SERIAL_INTERRUPT_CONTEXT);

    status = WdfInterruptCreate(device,
                                &interruptConfig,
                                &attributes,
                                &pDevExt->WdfInterrupt);

    if (!NT_SUCCESS(status)) {

        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Couldn't create interrupt for %wZ\n",
                  &pDevExt->DeviceName);
        return status;
    }

    //
    // Interrupt state wait lock...
    //
    WDF_OBJECT_ATTRIBUTES_INIT(&attributes);
    attributes.ParentObject = pDevExt->WdfInterrupt;

    interruptContext = SerialGetInterruptContext(pDevExt->WdfInterrupt);

    status = WdfWaitLockCreate(&attributes,
                               &interruptContext->InterruptStateLock
                               );

    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,  " WdfWaitLockCreate for InterruptStateLock failed %!STATUS!\n",   status);
        return status;
    }

    //
    // Set interrupt policy
    //
    SerialSetInterruptPolicy(pDevExt->WdfInterrupt);

    //
    // Timers and DPCs...
    //
    status = SerialCreateTimersAndDpcs(pDevExt);
    if (!NT_SUCCESS(status)) {

        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "SerialCreateTimersAndDpcs failed %x\n", status);
        return status;
    }

    //
    // Register with WMI.
    //
    status = SerialWmiRegistration(device);
    if(!NT_SUCCESS (status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "SerialWmiRegistration failed %!STATUS!\n", status);
        return status;

    }

    //
    // Upto this point, if we fail, we don't have to worry about freeing any resource because
    // framework will free all the objects.
    //
    //
    // Do the external naming.
    //

    status = SerialDoExternalNaming(pDevExt);
    if (!NT_SUCCESS(status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "External Naming Failed - Status %!STATUS!\n",
                      status);
        return status;
    }

    //
    // Finally increment the global system configuration that keeps track of number of serial ports.
    //
    countSoFar = &IoGetConfigurationInformation()->SerialCount;
    (*countSoFar)++;
    pDevExt->IsSystemConfigInfoUpdated = TRUE;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "<--SerialEvtDeviceAdd\n");

    return status;

}
#pragma warning(push)
#pragma warning(disable:28118) // this callback will run at IRQL=PASSIVE_LEVEL
_Use_decl_annotations_
VOID
SerialEvtDeviceContextCleanup (
    WDFOBJECT       Device
    )
/*++

Routine Description:

   EvtDeviceContextCleanup event callback cleans up anything done in
   EvtDeviceAdd, except those things that are automatically cleaned
   up by the Framework.

   In a driver derived from this sample, it's quite likely that this function could
   be deleted.

Arguments:

    Device - Handle to a framework device object.

Return Value:

    VOID

--*/
{
    PSERIAL_DEVICE_EXTENSION deviceExtension;
    PULONG countSoFar;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "--> SerialDeviceContextCleanup\n");

    PAGED_CODE();

    deviceExtension = SerialGetDeviceExtension (Device);

    if (deviceExtension->InterruptReadBuffer != NULL) {
       ExFreePool(deviceExtension->InterruptReadBuffer);
       deviceExtension->InterruptReadBuffer = NULL;
    }
    
    //
    // Update the global configuration count for serial device.
    //
    if(deviceExtension->IsSystemConfigInfoUpdated) {
        countSoFar = &IoGetConfigurationInformation()->SerialCount;
        (*countSoFar)--;
    }

    SerialUndoExternalNaming(deviceExtension);

    return;
}
#pragma warning(pop) // enable 28118 again

NTSTATUS
SerialEvtPrepareHardware(
    WDFDEVICE Device,
    WDFCMRESLIST Resources,
    WDFCMRESLIST ResourcesTranslated
    )
/*++

Routine Description:

    SerialEvtPrepareHardware event callback performs operations that are necessary
    to make the device operational. The framework calls the driver's
    SerialEvtPrepareHardware callback when the PnP manager sends an IRP_MN_START_DEVICE
    request to the driver stack.

Arguments:

    Device - Handle to a framework device object.

    Resources - Handle to a collection of framework resource objects.
                This collection identifies the raw (bus-relative) hardware
                resources that have been assigned to the device.

    ResourcesTranslated - Handle to a collection of framework resource objects.
                This collection identifies the translated (system-physical)
                hardware resources that have been assigned to the device.
                The resources appear from the CPU's point of view.
                Use this list of resources to map I/O space and
                device-accessible memory into virtual address space

Return Value:

    WDF status code

--*/
{
    PSERIAL_DEVICE_EXTENSION pDevExt;
    NTSTATUS status;
    CONFIG_DATA config;
    PCONFIG_DATA pConfig = &config;
    ULONG defaultClockRate = 1843200;

    PAGED_CODE();

    SerialDbgPrintEx (TRACE_LEVEL_INFORMATION, DBG_PNP, "--> SerialEvtPrepareHardware\n");
    //
    // Get the Device Extension..
    //
    pDevExt = SerialGetDeviceExtension (Device);

    RtlZeroMemory(pConfig, sizeof(CONFIG_DATA));

    //
    // Initialize a config data structure with default values for those that
    // may not already be initialized.
    //

    pConfig->LogFifo = driverDefaults.LogFifoDefault;


    //
    // Get the hw resources for the device.
    //

    status = SerialMapHWResources(Device, Resources, ResourcesTranslated, pConfig);

    if (!NT_SUCCESS(status)) {
        goto End;
    }

    //
    // Open the "Device Parameters" section of registry for this device and get parameters.
    //

    if(!SerialGetRegistryKeyValue (Device,
                                  L"DisablePort",
                                  &pConfig->DisablePort)){
        pConfig->DisablePort = 0;
    }

    if(!SerialGetRegistryKeyValue (Device,
                                   L"ForceFifoEnable",
                                   &pConfig->ForceFifoEnable)){
        pConfig->ForceFifoEnable = driverDefaults.ForceFifoEnableDefault;
    }

    if(!SerialGetRegistryKeyValue (Device,
                                   L"RxFIFO",
                                   &pConfig->RxFIFO)){
        pConfig->RxFIFO = driverDefaults.RxFIFODefault;
    }

    if(!SerialGetRegistryKeyValue (Device,
                                   L"TxFIFO",
                                   &pConfig->TxFIFO)){
        pConfig->TxFIFO = driverDefaults.TxFIFODefault;
    }

    if(!SerialGetRegistryKeyValue (Device,
                                   L"Share System Interrupt",
                                   &pConfig->PermitShare)){
        pConfig->PermitShare = driverDefaults.PermitShareDefault;
    }

    if(!SerialGetRegistryKeyValue (Device,
                                   L"ClockRate",
                                   &pConfig->ClockRate)) {
        pConfig->ClockRate = defaultClockRate;
    }

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "Com Port ClockRate: %x\n",
                    pConfig->ClockRate);

    if(!SerialGetRegistryKeyValue(Device,
                                 L"TL16C550C Auto Flow Control",
                                 &pConfig->TL16C550CAFC)){
        pConfig->TL16C550CAFC = 0;
    }

    status = SerialInitController(pDevExt, pConfig);

    if (NT_SUCCESS(status)) {
    }
End:

   SerialDbgPrintEx (TRACE_LEVEL_INFORMATION, DBG_PNP, "<-- SerialEvtPrepareHardware 0x%x\n", status);

   return status;
}

NTSTATUS
SerialEvtReleaseHardware(
    IN  WDFDEVICE Device,
    IN  WDFCMRESLIST ResourcesTranslated
    )
/*++

Routine Description:

    EvtDeviceReleaseHardware is called by the framework whenever the PnP manager
    is revoking ownership of our resources.  This may be in response to either
    IRP_MN_STOP_DEVICE or IRP_MN_REMOVE_DEVICE.  The callback is made before
    passing down the IRP to the lower driver.

    In this callback, do anything necessary to free those resources.
    In this driver, we will not receive this callback when there is open handle to
    the device. We explicitly tell the framework (WdfDeviceSetStaticStopRemove) to
    fail stop and query-remove when handle is open.

Arguments:

    Device - Handle to a framework device object.

    ResourcesTranslated - Handle to a collection of framework resource objects.
                This collection identifies the translated (system-physical)
                hardware resources that have been assigned to the device.
                The resources appear from the CPU's point of view.
                Use this list of resources to map I/O space and
                device-accessible memory into virtual address space

Return Value:

    NTSTATUS - Failures will be logged, but not acted on.

--*/
{
    PSERIAL_DEVICE_EXTENSION pDevExt;

    UNREFERENCED_PARAMETER(ResourcesTranslated);

    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     "--> SerialEvtReleaseHardware\n");

    pDevExt = SerialGetDeviceExtension (Device);

    //
    // Reset and put the device into a known initial state before releasing the hw resources.
    // In this driver we can recieve this callback only when there is no handle open because
    // we tell the framework to disable stop by calling WdfDeviceSetStaticStopRemove.
    // Since we have already reset the device in our close handler, we don't have to
    // do anything other than unmapping the I/O resources.
    //

    //
    // Unmap any Memory-Mapped registers. Disconnecting from the interrupt will
    // be done automatically by the framework.
    //
    SerialUnmapHWResources(pDevExt);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     "<-- SerialEvtReleaseHardware\n");

    return STATUS_SUCCESS;
}


NTSTATUS
SerialEvtDeviceD0EntryPostInterruptsEnabled(
    IN WDFDEVICE Device,
    IN WDF_POWER_DEVICE_STATE PreviousState
    )
/*++

Routine Description:

    EvtDeviceD0EntryPostInterruptsEnabled is called by the framework after the
    driver has enabled the device's hardware interrupts.

    This function is not marked pageable because this function is in the
    device power up path. When a function is marked pagable and the code
    section is paged out, it will generate a page fault which could impact
    the fast resume behavior because the client driver will have to wait
    until the system drivers can service this page fault.

Arguments:

    Device - Handle to a framework device object.

    PreviousState - A WDF_POWER_DEVICE_STATE-typed enumerator that identifies
                    the previous device power state.

Return Value:

    NTSTATUS - Failures will be logged, but not acted on.

--*/
{
    PSERIAL_DEVICE_EXTENSION extension = SerialGetDeviceExtension(Device);
    PSERIAL_INTERRUPT_CONTEXT interruptContext = SerialGetInterruptContext(extension->WdfInterrupt);
    WDF_INTERRUPT_INFO info;

    UNREFERENCED_PARAMETER(PreviousState);

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     "--> SerialEvtDeviceD0EntryPostInterruptsEnabled\n");
    //
    // The following lines of code show how to call WdfInterruptGetInfo.
    //
    WDF_INTERRUPT_INFO_INIT(&info);
    WdfInterruptGetInfo(extension->WdfInterrupt, &info);

    WdfWaitLockAcquire(interruptContext->InterruptStateLock, NULL);
    interruptContext->IsInterruptConnected = TRUE;
    WdfWaitLockRelease(interruptContext->InterruptStateLock);

    return STATUS_SUCCESS;
}


NTSTATUS
SerialEvtDeviceD0ExitPreInterruptsDisabled(
    IN WDFDEVICE Device,
    IN WDF_POWER_DEVICE_STATE TargetState
    )
/*++

Routine Description:

    EvtDeviceD0ExitPreInterruptsDisabled is called by the framework before the
    driver disables the device's hardware interrupts.

Arguments:

    Device - Handle to a framework device object.

    TargetState - A WDF_POWER_DEVICE_STATE-typed enumerator that identifies the
                  device power state that the device is about to enter.

Return Value:

    NTSTATUS - Failures will be logged, but not acted on.

--*/
{
    PSERIAL_DEVICE_EXTENSION extension = SerialGetDeviceExtension(Device);
    PSERIAL_INTERRUPT_CONTEXT interruptContext = SerialGetInterruptContext(extension->WdfInterrupt);

    UNREFERENCED_PARAMETER(TargetState);
    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     "--> SerialEvtDeviceD0ExitPreInterruptsDisabled\n");

    WdfWaitLockAcquire(interruptContext->InterruptStateLock, NULL);
    interruptContext->IsInterruptConnected = FALSE;
    WdfWaitLockRelease(interruptContext->InterruptStateLock);

    return STATUS_SUCCESS;
}


NTSTATUS
SerialSetPowerPolicy(
    IN PSERIAL_DEVICE_EXTENSION DeviceExtension
    )
{
    WDF_DEVICE_POWER_POLICY_IDLE_SETTINGS idleSettings;
    //WDF_POWER_POLICY_EVENT_CALLBACKS    powerPolicyCallbacks;
    NTSTATUS    status = STATUS_SUCCESS;
    WDFDEVICE hDevice = DeviceExtension->WdfDevice;
    ULONG powerOnClose;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     "--> SerialSetPowerPolicy\n");

    PAGED_CODE();

    //
    // Find out whether we want to power down the device when there no handles open.
    //
    SerialGetRegistryKeyValue(hDevice, L"EnablePowerManagement",  &powerOnClose);
    DeviceExtension->RetainPowerOnClose = powerOnClose ? TRUE : FALSE;

    //
    // In some drivers, the device must be specifically programmed to enable
    // wake signals.  UARTs were designed long, long before such a concept.  So
    // this driver, which just drives UARTs, doesn't register wake arm/disarm
    // callbacks.  Arming or disarming for UARTs has to be handled by side-band
    // code that controls hardware designed more recently.  In this case, ACPI
    // is handling it.  If one were to write a driver which implemented a more
    // modern serial device, one might need to use these callbacks.
    //

    //
    // Init the power policy callbacks
    //
    //WDF_POWER_POLICY_EVENT_CALLBACKS_INIT(&powerPolicyCallbacks);

    //
    // This group of three callbacks allows this sample driver to manage
    // arming the device for wake from the S0 state.
    //

    //powerPolicyCallbacks.EvtDeviceArmWakeFromS0 = SerialEvtDeviceWakeArmS0;
    //powerPolicyCallbacks.EvtDeviceDisarmWakeFromS0 = SerialEvtDeviceWakeDisarmS0;
    //powerPolicyCallbacks.EvtDeviceWakeFromS0Triggered = SerialEvtDeviceWakeTriggeredS0;

    //
    // This group of three callbacks allows the device to be armed for wake
    // from Sx (S1, S2, S3 or S4.)  Networking devices can optionally be put
    // into a state where a packet sent to them will cause the device's wake
    // signal to be triggered, which causes the machine to wake, moving back
    // into the S0 state.
    //

    //powerPolicyCallbacks.EvtDeviceArmWakeFromSx = SerialEvtDeviceWakeArmSx;
    //powerPolicyCallbacks.EvtDeviceDisarmWakeFromSx = SerialEvtDeviceWakeDisarmSx;
    //powerPolicyCallbacks.EvtDeviceWakeFromSxTriggered = SerialEvtDeviceWakeTriggeredSx;

    //
    // Register the power policy callbacks.
    //
    //WdfDeviceSetPowerPolicyEventCallbacks(hDevice, &powerPolicyCallbacks);

    //
    // Init the idle policy structure. By setting IdleCannotWakeFromS0 we tell the framework
    // to power down the device without arming for wake. The only way the device can come
    // back to D0 is when we call WdfDeviceStopIdle in SerialEvtDeviceFileCreate.
    // We can't choose IdleCanWakeFromS0 by default is because onboard serial ports typically
    // don't have wake capability. If the driver is used for plugin boards that does support
    // wait-wake, you can update the settings to match that. If MS provided modem driver
    // is used on ports that does support wake on ring, then it will update the settings
    // by sending an internal ioctl to us.
    //
    WDF_DEVICE_POWER_POLICY_IDLE_SETTINGS_INIT(&idleSettings, IdleCannotWakeFromS0);
    if(DeviceExtension->OwnsPowerPolicy && !DeviceExtension->RetainPowerOnClose) {
        //
        // Since we don't have to retain power when there are no open handles, we
        // register for idle power management to save power. Check the use of
        // WdfDeviceStopIdle in SerialEvtDeviceFileCreate.
        //
        idleSettings.UserControlOfIdleSettings = IdleAllowUserControl;

        status = WdfDeviceAssignS0IdleSettings(hDevice, &idleSettings);
        if ( !NT_SUCCESS(status)) {
            SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                                "WdfDeviceSetPowerPolicyS0IdlePolicy failed %x \n", status);
            return status;
        }
    }


    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "<-- SerialSetPowerPolicy\n");

    return status;
}

UINT32
SerialReportMaxBaudRate(ULONG Bauds)
/*++

Routine Description:

    This routine returns the max baud rate given a selection of rates

Arguments:

   Bauds  -  Bit-encoded list of supported bauds


  Return Value:

   The max baud rate listed in Bauds

--*/
{
    int i;

    PAGED_CODE();

    for(i=0; SupportedBaudRates[i].BaudRate != SERIAL_BAUD_INVALID; i++) {

        if(Bauds & SupportedBaudRates[i].Mask) {
            return SupportedBaudRates[i].BaudRate;
        }
    }

    //
    // We're in bad shape
    //

    return 0;
}

NTSTATUS
SerialInitController(
    IN PSERIAL_DEVICE_EXTENSION pDevExt,
    IN PCONFIG_DATA PConfigData
    )
/*++

Routine Description:

    Really too many things to mention here.  In general initializes
    kernel synchronization structures, allocates the typeahead buffer,
    sets up defaults, etc.

Arguments:

    PDevObj       - Device object for the device to be started

    PConfigData   - Pointer to a record for a single port.

Return Value:

    STATUS_SUCCCESS if everything went ok.  A !NT_SUCCESS status
    otherwise.

--*/

{
    NTSTATUS status = STATUS_SUCCESS;
    SHORT junk;
    int i;

    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "--> SerialInitController for %wZ\n",
                                                    &pDevExt->DeviceName);

    //
    // Save the value of clock input to the part.  We use this to calculate
    // the divisor latch value.  The value is in Hertz.
    //

    pDevExt->ClockRate = PConfigData->ClockRate;


    //
    // Save if we have to enable TI's auto flow control
    //


    pDevExt->TL16C550CAFC = PConfigData->TL16C550CAFC;


    //
    // Map the memory for the control registers for the serial device
    // into virtual memory.
    //
    pDevExt->Controller =
      SerialGetMappedAddress(PConfigData->TrController,
                             PConfigData->SpanOfController,
                             (BOOLEAN)PConfigData->AddressSpace,
                             &pDevExt->UnMapRegisters);


    if (!pDevExt->Controller) {

      SerialLogError(
                    pDevExt->DriverObject,
                    pDevExt->DeviceObject,
                    PConfigData->TrController,
                    SerialPhysicalZero,
                    0,
                    0,
                    0,
                    7,
                    STATUS_SUCCESS,
                    SERIAL_REGISTERS_NOT_MAPPED,
                    pDevExt->DeviceName.Length+sizeof(WCHAR),
                    pDevExt->DeviceName.Buffer,
                    0,
                    NULL
                    );

      SerialDbgPrintEx(TRACE_LEVEL_WARNING, DBG_PNP, "Could not map memory for device "
                       "registers for %wZ\n", &pDevExt->DeviceName);

      pDevExt->UnMapRegisters = FALSE;
      status = STATUS_NONE_MAPPED;
      goto ExtensionCleanup;

    }

    pDevExt->AddressSpace          = PConfigData->AddressSpace;
    pDevExt->SpanOfController      = PConfigData->SpanOfController;

    //
    // Save off the interface type and the bus number.
    //

    pDevExt->Vector = PConfigData->TrVector;
    pDevExt->Irql = (UCHAR)PConfigData->TrIrql;
    pDevExt->InterruptMode = PConfigData->InterruptMode;
    pDevExt->Affinity = PConfigData->Affinity;

    //
    // If the user said to permit sharing within the device, propagate this
    // through.
    //

    pDevExt->PermitShare = PConfigData->PermitShare;


    //
    // Before we test whether the port exists (which will enable the FIFO)
    // convert the rx trigger value to what should be used in the register.
    //
    // If a bogus value was given - crank them down to 1.
    //
    // If this is a "souped up" UART with like a 64 byte FIFO, they
    // should use the appropriate "spoofing" value to get the desired
    // results.  I.e., if on their chip 0xC0 in the FCR is for 64 bytes,
    // they should specify 14 in the registry.
    //

    switch (PConfigData->RxFIFO) {

    case 1:

      pDevExt->RxFifoTrigger = SERIAL_1_BYTE_HIGH_WATER;
      break;

    case 4:

      pDevExt->RxFifoTrigger = SERIAL_4_BYTE_HIGH_WATER;
      break;

    case 8:

      pDevExt->RxFifoTrigger = SERIAL_8_BYTE_HIGH_WATER;
      break;

    case 14:

      pDevExt->RxFifoTrigger = SERIAL_14_BYTE_HIGH_WATER;
      break;

    default:

      pDevExt->RxFifoTrigger = SERIAL_1_BYTE_HIGH_WATER;
      break;

    }


    if (PConfigData->TxFIFO < 1) {

      pDevExt->TxFifoAmount = 1;

    } else {

      pDevExt->TxFifoAmount = PConfigData->TxFIFO;

    }

    if (!SerialDoesPortExist(
                           pDevExt,
                           &pDevExt->DeviceName,
                           PConfigData->ForceFifoEnable,
                           PConfigData->LogFifo
                           )) {

      //
      // We couldn't verify that there was actually a
      // port. No need to log an error as the port exist
      // code will log exactly why.
      //

      SerialDbgPrintEx(TRACE_LEVEL_WARNING, DBG_PNP, "DoesPortExist test failed for "
                       "%wZ\n", &pDevExt->DeviceName);

      status = STATUS_NO_SUCH_DEVICE;
      goto ExtensionCleanup;

    }


    //
    // If the user requested that we disable the port, then
    // do it now.  Log the fact that the port has been disabled.
    //

    if (PConfigData->DisablePort) {

      SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "disabled port %wZ as requested in "
                       "configuration\n", &pDevExt->DeviceName);

      status = STATUS_NO_SUCH_DEVICE;

      SerialLogError(
                    pDevExt->DriverObject,
                    pDevExt->DeviceObject,
                    PConfigData->TrController,
                    SerialPhysicalZero,
                    0,
                    0,
                    0,
                    57,
                    STATUS_SUCCESS,
                    SERIAL_DISABLED_PORT,
                    pDevExt->DeviceName.Length+sizeof(WCHAR),
                    pDevExt->DeviceName.Buffer,
                    0,
                    NULL
                    );

      goto ExtensionCleanup;

    }



    //
    // Set up the default device control fields.
    // Note that if the values are changed after
    // the file is open, they do NOT revert back
    // to the old value at file close.
    //

    pDevExt->SpecialChars.XonChar      = SERIAL_DEF_XON;
    pDevExt->SpecialChars.XoffChar     = SERIAL_DEF_XOFF;
    pDevExt->HandFlow.ControlHandShake = SERIAL_DTR_CONTROL;
    pDevExt->HandFlow.FlowReplace      = SERIAL_RTS_CONTROL;


    //
    // Default Line control protocol. 7E1
    //
    // Seven data bits.
    // Even parity.
    // 1 Stop bits.
    //

    pDevExt->LineControl = SERIAL_7_DATA |
                           SERIAL_EVEN_PARITY |
                           SERIAL_NONE_PARITY;

    pDevExt->ValidDataMask = 0x7f;
    pDevExt->CurrentBaud   = 1200;


    //
    // We set up the default xon/xoff limits.
    //
    // This may be a bogus value.  It looks like the BufferSize
    // is not set up until the device is actually opened.
    //

    pDevExt->HandFlow.XoffLimit    = pDevExt->BufferSize >> 3;
    pDevExt->HandFlow.XonLimit     = pDevExt->BufferSize >> 1;

    pDevExt->BufferSizePt8 = ((3*(pDevExt->BufferSize>>2))+
                                  (pDevExt->BufferSize>>4));

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, " The default interrupt read buffer size is: %d\n"
                    "------  The XoffLimit is                         : %d\n"
                    "------  The XonLimit is                          : %d\n"
                    "------  The pt 8 size is                         : %d\n",
                    pDevExt->BufferSize, pDevExt->HandFlow.XoffLimit,
                    pDevExt->HandFlow.XonLimit, pDevExt->BufferSizePt8);


    //
    // Go through all the "named" baud rates to find out which ones
    // can be supported with this port.
    //
    //

    pDevExt->SupportedBauds = SERIAL_BAUD_USER;


    for(i=0; SupportedBaudRates[i].BaudRate != SERIAL_BAUD_INVALID; i++) {

        if (!NT_ERROR(SerialGetDivisorFromBaud(
                                            pDevExt->ClockRate,
                                            (LONG)SupportedBaudRates[i].BaudRate,
                                            &junk
                                            ))) {

            pDevExt->SupportedBauds |= SupportedBaudRates[i].Mask;
         }
    }




    //
    // Mark this device as not being opened by anyone.  We keep a
    // variable around so that spurious interrupts are easily
    // dismissed by the ISR.
    //

    SetDeviceIsOpened(pDevExt, FALSE, FALSE);

    //
    // Store values into the extension for interval timing.
    //

    //
    // If the interval timer is less than a second then come
    // in with a short "polling" loop.
    //
    // For large (> then 2 seconds) use a 1 second poller.
    //

    pDevExt->ShortIntervalAmount.QuadPart  = -1;
    pDevExt->LongIntervalAmount.QuadPart   = -10000000;
    pDevExt->CutOverAmount.QuadPart        = 200000000;

    DISABLE_ALL_INTERRUPTS (pDevExt, pDevExt->Controller);

    WRITE_MODEM_CONTROL(pDevExt, pDevExt->Controller, (UCHAR)0);

    // make sure there is no escape character currently set
    pDevExt->EscapeChar = 0;
    //
    // This should set up everything as it should be when
    // a device is to be opened.  We do need to lower the
    // modem lines, and disable the recalcitrant fifo
    // so that it will show up if the user boots to dos.
    //

    // __WARNING_IRQ_SET_TOO_HIGH:  we are calling interrupt synchronize routine directly. Suppress it because interrupt is not connected yet.
    // __WARNING_INVALID_PARAM_VALUE_1: Interrupt is UNREFERENCED_PARAMETER, so it can be NULL
#pragma warning(suppress: __WARNING_IRQ_SET_TOO_HIGH; suppress: __WARNING_INVALID_PARAM_VALUE_1) 
    SerialReset(NULL, pDevExt);

#pragma warning(suppress: __WARNING_IRQ_SET_TOO_HIGH; suppress: __WARNING_INVALID_PARAM_VALUE_1) 
    SerialMarkClose(NULL, pDevExt);

#pragma warning(suppress: __WARNING_IRQ_SET_TOO_HIGH; suppress: __WARNING_INVALID_PARAM_VALUE_1) 
    SerialClrRTS(NULL, pDevExt);

#pragma warning(suppress: __WARNING_IRQ_SET_TOO_HIGH; suppress: __WARNING_INVALID_PARAM_VALUE_1) 
    SerialClrDTR(NULL, pDevExt);

    //
    // Fill in WMI hardware data
    //
    pDevExt->WmiHwData.IrqNumber = pDevExt->Irql;
    pDevExt->WmiHwData.IrqLevel = pDevExt->Irql;
    pDevExt->WmiHwData.IrqVector = pDevExt->Vector;
    pDevExt->WmiHwData.IrqAffinityMask = pDevExt->Affinity;
    pDevExt->WmiHwData.InterruptType = pDevExt->InterruptMode == Latched
       ? SERIAL_WMI_INTTYPE_LATCHED : SERIAL_WMI_INTTYPE_LEVEL;
    pDevExt->WmiHwData.BaseIOAddress = (ULONG_PTR)pDevExt->Controller;

    //
    // Fill in WMI device state data (as defaults)
    //

    pDevExt->WmiCommData.BaudRate = pDevExt->CurrentBaud;
    pDevExt->WmiCommData.BitsPerByte = (pDevExt->LineControl & 0x03) + 5;
    pDevExt->WmiCommData.ParityCheckEnable = (pDevExt->LineControl & 0x08)
       ? TRUE : FALSE;

    switch (pDevExt->LineControl & SERIAL_PARITY_MASK) {
    case SERIAL_NONE_PARITY:
       pDevExt->WmiCommData.Parity = SERIAL_WMI_PARITY_NONE;
       break;

    case SERIAL_ODD_PARITY:
       pDevExt->WmiCommData.Parity = SERIAL_WMI_PARITY_ODD;
       break;

    case SERIAL_EVEN_PARITY:
       pDevExt->WmiCommData.Parity = SERIAL_WMI_PARITY_EVEN;
       break;

    case SERIAL_MARK_PARITY:
       pDevExt->WmiCommData.Parity = SERIAL_WMI_PARITY_MARK;
       break;

    case SERIAL_SPACE_PARITY:
       pDevExt->WmiCommData.Parity = SERIAL_WMI_PARITY_SPACE;
       break;

    default:
       ASSERTMSG(0, "Illegal Parity setting for WMI");
       pDevExt->WmiCommData.Parity = SERIAL_WMI_PARITY_NONE;
       break;
    }

    pDevExt->WmiCommData.StopBits = pDevExt->LineControl & SERIAL_STOP_MASK
       ? (pDevExt->WmiCommData.BitsPerByte == 5 ? SERIAL_WMI_STOP_1_5
          : SERIAL_WMI_STOP_2) : SERIAL_WMI_STOP_1;
    pDevExt->WmiCommData.XoffCharacter = pDevExt->SpecialChars.XoffChar;
    pDevExt->WmiCommData.XoffXmitThreshold = pDevExt->HandFlow.XoffLimit;
    pDevExt->WmiCommData.XonCharacter = pDevExt->SpecialChars.XonChar;
    pDevExt->WmiCommData.XonXmitThreshold = pDevExt->HandFlow.XonLimit;
    pDevExt->WmiCommData.MaximumBaudRate
       = SerialReportMaxBaudRate(pDevExt->SupportedBauds);
    pDevExt->WmiCommData.MaximumOutputBufferSize = (UINT32)((ULONG)-1);
    pDevExt->WmiCommData.MaximumInputBufferSize = (UINT32)((ULONG)-1);
    pDevExt->WmiCommData.Support16BitMode = FALSE;
    pDevExt->WmiCommData.SupportDTRDSR = TRUE;
    pDevExt->WmiCommData.SupportIntervalTimeouts = TRUE;
    pDevExt->WmiCommData.SupportParityCheck = TRUE;
    pDevExt->WmiCommData.SupportRTSCTS = TRUE;
    pDevExt->WmiCommData.SupportXonXoff = TRUE;
    pDevExt->WmiCommData.SettableBaudRate = TRUE;
    pDevExt->WmiCommData.SettableDataBits = TRUE;
    pDevExt->WmiCommData.SettableFlowControl = TRUE;
    pDevExt->WmiCommData.SettableParity = TRUE;
    pDevExt->WmiCommData.SettableParityCheck = TRUE;
    pDevExt->WmiCommData.SettableStopBits = TRUE;
    pDevExt->WmiCommData.IsBusy = FALSE;

    //
    // Common error path cleanup.  If the status is
    // bad, get rid of the device extension, device object
    // and any memory associated with it.
    //

ExtensionCleanup: ;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "<-- SerialInitController %x\n", status);

    return status;
}


NTSTATUS
SerialMapHWResources(
        IN WDFDEVICE Device,
        IN WDFCMRESLIST PResList,
        IN WDFCMRESLIST PTrResList,
        OUT PCONFIG_DATA PConfig
        )
/*++

Routine Description:

    This routine will get the configuration information and put
    it and the translated values into CONFIG_DATA structures.

Arguments:

    Device - Handle to a framework device object.

    Resources - Handle to a collection of framework resource objects.
                This collection identifies the raw (bus-relative) hardware
                resources that have been assigned to the device.

    ResourcesTranslated - Handle to a collection of framework resource objects.
                This collection identifies the translated (system-physical)
                hardware resources that have been assigned to the device.
                The resources appear from the CPU's point of view.
                Use this list of resources to map I/O space and
                device-accessible memory into virtual address space

Return Value:

    STATUS_SUCCESS if consistant configuration was found - otherwise.
    returns STATUS_SERIAL_NO_DEVICE_INITED.

--*/

{
   PSERIAL_DEVICE_EXTENSION pDevExt;
   NTSTATUS status = STATUS_SUCCESS;
   ULONG i;
   PCM_PARTIAL_RESOURCE_DESCRIPTOR  pPartialTrResourceDesc, pPartialRawResourceDesc;
   ULONG gotInt = 0;
   ULONG gotIO = 0;
   ULONG ioResIndex = 0;
   ULONG curIoIndex = 0;
   ULONG gotMem = 0;
   BOOLEAN DebugPortInUse = FALSE;

   PAGED_CODE();

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "--> SerialMapHWResources\n");

   //
   // Get the DeviceExtension..
   //
   pDevExt = SerialGetDeviceExtension (Device);

   if ((PResList == NULL) || (PTrResList == NULL)) {
        ASSERT(PResList != NULL);
        ASSERT(PTrResList != NULL);
        status = STATUS_INSUFFICIENT_RESOURCES;
        goto End;
   }

    for (i = 0; i < WdfCmResourceListGetCount(PTrResList); i++) {

        pPartialTrResourceDesc = WdfCmResourceListGetDescriptor(PTrResList, i);
        pPartialRawResourceDesc = WdfCmResourceListGetDescriptor(PResList, i);

        switch (pPartialTrResourceDesc->Type) {
        case CmResourceTypePort:

            ASSERT(!(pPartialTrResourceDesc->u.Port.Length == SERIAL_STATUS_LENGTH));

            if (gotIO == 0) {

                if (curIoIndex == ioResIndex) {

                    gotIO = 1;
                    PConfig->TrController  = pPartialTrResourceDesc->u.Port.Start;

                    if (!PConfig->TrController.LowPart) {
                        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Bogus port address %x\n",
                                            PConfig->TrController.LowPart);
                        status = STATUS_DEVICE_CONFIGURATION_ERROR;
                        goto End;
                    }
                    //
                    // We need the raw address to check if the debugger is using the com port
                    //
                    PConfig->Controller  = pPartialRawResourceDesc->u.Port.Start;
                    PConfig->AddressSpace  = pPartialTrResourceDesc->Flags;
                    pDevExt->SerialReadUChar = SerialReadPortUChar;
                    pDevExt->SerialWriteUChar = SerialWritePortUChar;

                } else {
                    curIoIndex++;
                }
        }

        break;

        //
        // If this is 8 bytes long and we haven't found any I/O range,
        // then this is probably a fancy-pants machine with memory replacing
        // IO space
        //
        case CmResourceTypeMemory:

        ASSERT(!(pPartialTrResourceDesc->u.Port.Length == SERIAL_STATUS_LENGTH));

        if ((gotMem == 0) && (gotIO == 0)
                         && (pPartialTrResourceDesc->u.Memory.Length
                         == (SERIAL_REGISTER_SPAN + SERIAL_STATUS_LENGTH))) {
            gotMem = 1;
            PConfig->TrController = pPartialTrResourceDesc->u.Memory.Start;

            if (!PConfig->TrController.LowPart) {
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Bogus I/O memory address %x\n",
                                    PConfig->TrController.LowPart);
                status = STATUS_DEVICE_CONFIGURATION_ERROR;
                goto End;
            }

            PConfig->Controller = pPartialRawResourceDesc->u.Memory.Start;
            PConfig->AddressSpace = CM_RESOURCE_PORT_MEMORY;
            PConfig->SpanOfController = SERIAL_REGISTER_SPAN;
            pDevExt->SerialReadUChar = SerialReadRegisterUChar;
            pDevExt->SerialWriteUChar = SerialWriteRegisterUChar;
        }
        break;

        case CmResourceTypeInterrupt:
            if (gotInt == 0) {
                gotInt = 1;
                PConfig->TrVector = pPartialTrResourceDesc->u.Interrupt.Vector;

                if (!PConfig->TrVector) {
                    SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Bogus vector 0\n");
                    status = STATUS_DEVICE_CONFIGURATION_ERROR;
                    goto End;
                }

               if (pPartialTrResourceDesc->ShareDisposition == CmResourceShareShared) {
                    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "Sharing interrupt with other devices \n");
                } else {
                    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "Interrupt is not shared with other devices\n");
                }

                PConfig->TrIrql = pPartialTrResourceDesc->u.Interrupt.Level;
                PConfig->Affinity = pPartialTrResourceDesc->u.Interrupt.Affinity;
            }
        break;

        default:   break;
        }   // switch (pPartialTrResourceDesc->Type)

    }       // for (i = 0;     i < WdfCollectionGetCount

   if(!((gotMem  || gotIO) && gotInt) )
   {
        status = STATUS_INSUFFICIENT_RESOURCES;
        goto End;
   }

   //
   // First check what type of AddressSpace this port is in. Then check
   // if the debugger is using this port. If it is, set DebugPortInUse to TRUE.
   //
   if(PConfig->AddressSpace == CM_RESOURCE_PORT_MEMORY) {

        PHYSICAL_ADDRESS  KdComPhysical;

        KdComPhysical = MmGetPhysicalAddress(*KdComPortInUse);

        if(KdComPhysical.LowPart == PConfig->Controller.LowPart) {
            DebugPortInUse = TRUE;
        }

   } else {
              //
              // This compare is done using **untranslated** values since that is what
              // the kernel shoves in regardless of the architecture.
              //

        if ((*KdComPortInUse) == (ULongToPtr(PConfig->Controller.LowPart)))    {
            DebugPortInUse = TRUE;
        }
   }

   if (DebugPortInUse) {

      SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Kernel debugger is using port at "
                       "address %p\n", *KdComPortInUse);
      SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Serial driver will not load port\n");

      SerialLogError(
                    pDevExt->DriverObject,
                    NULL,
                    PConfig->TrController,
                    SerialPhysicalZero,
                    0,
                    0,
                    0,
                    3,
                    STATUS_SUCCESS,
                    SERIAL_KERNEL_DEBUGGER_ACTIVE,
                    pDevExt->DeviceName.Length+sizeof(WCHAR),
                    pDevExt->DeviceName.Buffer,
                    0,
                    NULL
                    );

      status = STATUS_INSUFFICIENT_RESOURCES;
      goto End;
   }

End:

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "<-- SerialMapHWResources %x\n", status);

   return status;
}

VOID
SerialUnmapHWResources(
    IN PSERIAL_DEVICE_EXTENSION PDevExt
    )
/*++

Routine Description:

    Releases resources (not pool) stored in the device extension.

Arguments:

    PDevExt - Pointer to the device extension to release resources from.

Return Value:

    VOID

--*/
{
   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "-->SerialUnMapResources(%p)\n",
                    PDevExt);
   PAGED_CODE();

   //
   // If necessary, unmap the device registers.
   //

   if (PDevExt->UnMapRegisters) {
      MmUnmapIoSpace(PDevExt->Controller, PDevExt->SpanOfController);
      PDevExt->UnMapRegisters = FALSE;
   }

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "<--SerialUnMapResources\n");
}


NTSTATUS
SerialReadSymName(
    IN                           WDFDEVICE Device,
    _Out_writes_bytes_(*SizeOfRegName) PWSTR RegName,
    _Inout_                      PUSHORT SizeOfRegName
    )
{
    NTSTATUS status;
    WDFKEY hKey;
    UNICODE_STRING value;
    UNICODE_STRING valueName;
    USHORT requiredLength;

    PAGED_CODE();

    value.Buffer = RegName;
    value.MaximumLength = *SizeOfRegName;
    value.Length = 0;

    status = WdfDeviceOpenRegistryKey(Device,
                      PLUGPLAY_REGKEY_DEVICE,
                      STANDARD_RIGHTS_ALL,
                      WDF_NO_OBJECT_ATTRIBUTES,
                      &hKey);

    if (NT_SUCCESS (status)) {
        //
        // Fetch PortName which contains the suggested REG_SZ symbolic name.
        //


        RtlInitUnicodeString(&valueName, L"PortName");

        status = WdfRegistryQueryUnicodeString (hKey,
                          &valueName,
                          &requiredLength,
                          &value);

        if (!NT_SUCCESS (status)) {
            //
            // This is for PCMCIA which currently puts the name under Identifier.
            //

            RtlInitUnicodeString(&valueName, L"Identifier");
            status = WdfRegistryQueryUnicodeString (hKey,
                                  &valueName,
                                  &requiredLength,
                                  &value);

            if (!NT_SUCCESS(status)) {
                //
                // Hmm.  Either we have to pick a name or bail...
                //
                SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Getting PortName/Identifier failed - %x\n", status);
            }
        }

        WdfRegistryClose(hKey);
    }

    if(NT_SUCCESS(status)) {
        //
        // NULL terminate the string and return number of characters in the string.
        //
        if(value.Length > *SizeOfRegName - sizeof(WCHAR)) {
            return STATUS_UNSUCCESSFUL;
        }

        *SizeOfRegName = value.Length;
        RegName[*SizeOfRegName/sizeof(WCHAR)] = UNICODE_NULL;
    }
    return status;
}


NTSTATUS
SerialDoExternalNaming(IN PSERIAL_DEVICE_EXTENSION PDevExt)

/*++

Routine Description:

    This routine will be used to create a symbolic link
    to the driver name in the given object directory.

    It will also create an entry in the device map for
    this device - IF we could create the symbolic link.

Arguments:

    Extension - Pointer to the device extension.

Return Value:

    None.

--*/

{
    NTSTATUS status = STATUS_SUCCESS;
    WCHAR pRegName[SYMBOLIC_NAME_LENGTH];
    USHORT nameSize = sizeof(pRegName);
    WDFSTRING stringHandle = NULL;
    WDF_OBJECT_ATTRIBUTES attributes;
    DECLARE_UNICODE_STRING_SIZE(symbolicLinkName,SYMBOLIC_NAME_LENGTH ) ;

    PAGED_CODE();

    WDF_OBJECT_ATTRIBUTES_INIT(&attributes);
    attributes.ParentObject = PDevExt->WdfDevice;
    status = WdfStringCreate(NULL, &attributes, &stringHandle);
    if(!NT_SUCCESS(status)){
        goto SerialDoExternalNamingError;
    }

    status = WdfDeviceRetrieveDeviceName(PDevExt->WdfDevice, stringHandle);
    if(!NT_SUCCESS(status)){
        goto SerialDoExternalNamingError;
    }

    //
    // Since we are storing the buffer pointer of the string handle in our
    // extension, we will hold onto string handle until the device is deleted.
    //
    WdfStringGetUnicodeString(stringHandle, &PDevExt->DeviceName);

    SerialGetRegistryKeyValue(PDevExt->WdfDevice, L"SerialSkipExternalNaming",  &PDevExt->SkipNaming);

    if (PDevExt->SkipNaming) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Skipping external naming due to registry settings\n");
        return STATUS_SUCCESS;
    }

    status = SerialReadSymName(PDevExt->WdfDevice, pRegName, &nameSize);
    if (!NT_SUCCESS(status)) {
        goto SerialDoExternalNamingError;
    }

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "DosName is %ws\n", pRegName);

    status = RtlUnicodeStringPrintf(&symbolicLinkName,
                                    L"%ws%ws",
                                    L"\\DosDevices\\",
                                    pRegName);

    if (!NT_SUCCESS(status)) {
      goto SerialDoExternalNamingError;
    }

    status = WdfDeviceCreateSymbolicLink(PDevExt->WdfDevice, &symbolicLinkName);

    if (!NT_SUCCESS(status)) {

      SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Couldn't create the symbolic link for port %wZ\n", &symbolicLinkName);

      goto SerialDoExternalNamingError;

    }


    PDevExt->CreatedSymbolicLink = TRUE;

    status = RtlWriteRegistryValue(RTL_REGISTRY_DEVICEMAP, SERIAL_DEVICE_MAP,
                                   PDevExt->DeviceName.Buffer,
                                   REG_SZ,
                                   pRegName,
                                   nameSize + sizeof(WCHAR));

    if (!NT_SUCCESS(status)) {

      SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Couldn't create the device map entry\n"
                       "------- for port %ws\n", PDevExt->DeviceName.Buffer);

      goto SerialDoExternalNamingError;
    }

    PDevExt->CreatedSerialCommEntry = TRUE;

    //
    // Make the device visible via a device association as well.
    // The reference string is the eight digit device index
    //
    status = WdfDeviceCreateDeviceInterface(PDevExt->WdfDevice,
                                            (LPGUID) &GUID_DEVINTERFACE_COMPORT,
                                            NULL);

    if (!NT_SUCCESS (status)) {
        SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP, "Couldn't register class association\n"
                       "for port %wZ\n", &PDevExt->DeviceName);

        goto SerialDoExternalNamingError;
    }

    return status;

    SerialDoExternalNamingError:;

    //
    // Clean up error conditions
    //

    PDevExt->DeviceName.Buffer = NULL;

    if (PDevExt->CreatedSerialCommEntry) {
        _Analysis_assume_(NULL != PDevExt->DeviceName.Buffer);
        RtlDeleteRegistryValue(RTL_REGISTRY_DEVICEMAP, SERIAL_DEVICE_MAP,
                               PDevExt->DeviceName.Buffer);
    }

    if(stringHandle) {
        WdfObjectDelete(stringHandle);
    }
    
    return status;
}


VOID
SerialUndoExternalNaming(IN PSERIAL_DEVICE_EXTENSION Extension)

/*++

Routine Description:

    This routine will be used to delete a symbolic link
    to the driver name in the given object directory.

    It will also delete an entry in the device map for
    this device if the symbolic link had been created.

Arguments:

    Extension - Pointer to the device extension.

Return Value:

    None.

--*/

{

   NTSTATUS status;
   PWCHAR   deviceName = Extension->DeviceName.Buffer;

   PAGED_CODE();

   SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                    "In SerialUndoExternalNaming for extension: "
                    "%p of port %ws\n", Extension, deviceName);

   //
   // Maybe there is nothing for us to do
   //

   if (Extension->SkipNaming) {
      return;
   }

   //
   // We're cleaning up here.  One reason we're cleaning up
   // is that we couldn't allocate space for the NtNameOfPort.
   //

   if ((deviceName !=  NULL)  && Extension->CreatedSerialCommEntry) {

      status = RtlDeleteRegistryValue(RTL_REGISTRY_DEVICEMAP,
                                      SERIAL_DEVICE_MAP,
                                      deviceName);
      if (!NT_SUCCESS(status)) {

         SerialDbgPrintEx(TRACE_LEVEL_ERROR, DBG_PNP,
                          "Couldn't delete value entry %ws\n",
                          deviceName);

      }
   }
}

VOID
SerialPurgePendingRequests(PSERIAL_DEVICE_EXTENSION pDevExt)
/*++

Routine Description:

   This routine completes any irps pending for the passed device object.

Arguments:

    PDevObj - Pointer to the device object whose irps must die.

Return Value:

    VOID

--*/
{
    NTSTATUS status;

    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                     ">SerialPurgePendingRequests(%p)\n", pDevExt);

    //
    // Then cancel all the reads and writes.
    //

    SerialPurgeRequests(pDevExt->WriteQueue,  &pDevExt->CurrentWriteRequest);

    SerialPurgeRequests(pDevExt->ReadQueue,  &pDevExt->CurrentReadRequest);

    //
    // Next get rid of purges.
    //

    SerialPurgeRequests(pDevExt->PurgeQueue,  &pDevExt->CurrentPurgeRequest);

    //
    // Get rid of any mask operations.
    //

    SerialPurgeRequests( pDevExt->MaskQueue,   &pDevExt->CurrentMaskRequest);

    //
    // Now get rid of pending wait mask request.
    //

    if (pDevExt->CurrentWaitRequest) {

        status = SerialClearCancelRoutine(pDevExt->CurrentWaitRequest, TRUE );
        if (NT_SUCCESS(status)) {

            SerialCompleteRequest(pDevExt->CurrentWaitRequest, STATUS_CANCELLED, 0);
            pDevExt->CurrentWaitRequest = NULL;

        }

    }
    SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP, "<SerialPurgePendingRequests\n");
}

BOOLEAN
SerialDoesPortExist(
                   IN PSERIAL_DEVICE_EXTENSION Extension,
                   IN PUNICODE_STRING InsertString,
                   IN ULONG ForceFifo,
                   IN ULONG LogFifo
                   )

/*++

Routine Description:

    This routine examines several of what might be the serial device
    registers.  It ensures that the bits that should be zero are zero.

    In addition, this routine will determine if the device supports
    fifo's.  If it does it will enable the fifo's and turn on a boolean
    in the extension that indicates the fifo's presence.

    NOTE: If there is indeed a serial port at the address specified
          it will absolutely have interrupts inhibited upon return
          from this routine.

    NOTE: Since this routine should be called fairly early in
          the device driver initialization, the only element
          that needs to be filled in is the base register address.

    NOTE: These tests all assume that this code is the only
          code that is looking at these ports or this memory.

          This is a not to unreasonable assumption even on
          multiprocessor systems.

Arguments:

    Extension - A pointer to a serial device extension.
    InsertString - String to place in an error log entry.
    ForceFifo - !0 forces the fifo to be left on if found.
    LogFifo - !0 forces a log message if fifo found.

Return Value:

    Will return true if the port really exists, otherwise it
    will return false.

--*/

{


   UCHAR regContents;
   BOOLEAN returnValue = TRUE;
   UCHAR oldIERContents;
   UCHAR oldLCRContents;
   USHORT value1;
   USHORT value2;
   KIRQL oldIrql;

   //
   // Save of the line control.
   //

   oldLCRContents = READ_LINE_CONTROL(Extension, Extension->Controller);

   //
   // Make sure that we are *aren't* accessing the divsior latch.
   //

   WRITE_LINE_CONTROL(Extension,
                     Extension->Controller,
                     (UCHAR)(oldLCRContents & ~SERIAL_LCR_DLAB)
                     );

   oldIERContents = READ_INTERRUPT_ENABLE(Extension, Extension->Controller);

   //
   // Go up to power level for a very short time to prevent
   // any interrupts from this device from coming in.
   //

   KeRaiseIrql(
              POWER_LEVEL,
              &oldIrql
              );

   WRITE_INTERRUPT_ENABLE(Extension,
                         Extension->Controller,
                         0x0f
                         );

   value1 = READ_INTERRUPT_ENABLE(Extension, Extension->Controller);
   value1 = value1 << 8;
   value1 |= READ_RECEIVE_BUFFER(Extension, Extension->Controller);

   READ_DIVISOR_LATCH(Extension,
                      Extension->Controller,
                      (PSHORT) &value2
                      );

   WRITE_LINE_CONTROL(Extension,
                     Extension->Controller,
                     oldLCRContents
                     );

   //
   // Put the ier back to where it was before.  If we are on a
   // level sensitive port this should prevent the interrupts
   // from coming in.  If we are on a latched, we don't care
   // cause the interrupts generated will just get dropped.
   //

   WRITE_INTERRUPT_ENABLE(Extension,
                         Extension->Controller,
                         oldIERContents
                         );

   KeLowerIrql(oldIrql);

   if (value1 == value2) {

      SerialLogError(
                    Extension->DeviceObject->DriverObject,
                    Extension->DeviceObject,
                    SerialPhysicalZero,
                    SerialPhysicalZero,
                    0,
                    0,
                    0,
                    62,
                    STATUS_SUCCESS,
                    SERIAL_DLAB_INVALID,
                    InsertString->Length+sizeof(WCHAR),
                    InsertString->Buffer,
                    0,
                    NULL
                    );
      returnValue = FALSE;
      goto AllDone;

   }

   AllDone: ;


   //
   // If we think that there is a serial device then we determine
   // if a fifo is present.
   //

   if (returnValue) {

      //
      // Well, we think it's a serial device.  Absolutely
      // positively, prevent interrupts from occuring.
      //
      // We disable all the interrupt enable bits, and
      // push down all the lines in the modem control
      // We only needed to push down OUT2 which in
      // PC's must also be enabled to get an interrupt.
      //

      DISABLE_ALL_INTERRUPTS(Extension, Extension->Controller);

      WRITE_MODEM_CONTROL(Extension, Extension->Controller, (UCHAR)0);

      //
      // See if this is a 16550.  We do this by writing to
      // what would be the fifo control register with a bit
      // pattern that tells the device to enable fifo's.
      // We then read the iterrupt Id register to see if the
      // bit pattern is present that identifies the 16550.
      //

      WRITE_FIFO_CONTROL(Extension,
                        Extension->Controller,
                        SERIAL_FCR_ENABLE
                        );

      regContents = READ_INTERRUPT_ID_REG(Extension, Extension->Controller);

      if (regContents & SERIAL_IIR_FIFOS_ENABLED) {

         //
         // Save off that the device supports fifos.
         //

         Extension->FifoPresent = TRUE;

         //
         // There is a fine new "super" IO chip out there that
         // will get stuck with a line status interrupt if you
         // attempt to clear the fifo and enable it at the same
         // time if data is present.  The best workaround seems
         // to be that you should turn off the fifo read a single
         // byte, and then re-enable the fifo.
         //

         WRITE_FIFO_CONTROL(Extension,
                           Extension->Controller,
                           (UCHAR)0
                           );

         READ_RECEIVE_BUFFER(Extension, Extension->Controller);

         //
         // There are fifos on this card.  Set the value of the
         // receive fifo to interrupt when 4 characters are present.
         //

         WRITE_FIFO_CONTROL(Extension, Extension->Controller,
                            (UCHAR)(SERIAL_FCR_ENABLE
                                    | Extension->RxFifoTrigger
                                    | SERIAL_FCR_RCVR_RESET
                                    | SERIAL_FCR_TXMT_RESET));

      }

      //
      // The !Extension->FifoPresent is included in the test so that
      // broken chips like the WinBond will still work after we test
      // for the fifo.
      //

      if (!ForceFifo || !Extension->FifoPresent) {

         Extension->FifoPresent = FALSE;
         WRITE_FIFO_CONTROL(Extension,
                           Extension->Controller,
                           (UCHAR)0
                           );

      }

      if (Extension->FifoPresent) {

         if (LogFifo) {

            SerialLogError(
                          Extension->DeviceObject->DriverObject,
                          Extension->DeviceObject,
                          SerialPhysicalZero,
                          SerialPhysicalZero,
                          0,
                          0,
                          0,
                          15,
                          STATUS_SUCCESS,
                          SERIAL_FIFO_PRESENT,
                          InsertString->Length+sizeof(WCHAR),
                          InsertString->Buffer,
                          0,
                          NULL
                          );

         }

         SerialDbgPrintEx(TRACE_LEVEL_INFORMATION, DBG_PNP,
                          "Fifo's detected at port address: %p\n",
                          Extension->Controller);
      }
   }

   return returnValue;
}



BOOLEAN
SerialReset(
    IN WDFINTERRUPT  Interrupt,
    IN PVOID Context
    )

/*++

Routine Description:

    This places the hardware in a standard configuration.

    NOTE: This assumes that it is called at interrupt level.


Arguments:

    Context - The device extension for serial device
    being managed.

Return Value:

    Always FALSE.

--*/

{

   PSERIAL_DEVICE_EXTENSION extension = Context;
   UCHAR regContents;
   UCHAR oldModemControl;
   ULONG i;

   UNREFERENCED_PARAMETER(Interrupt);

   //
   // Adjust the out2 bit.
   // This will also prevent any interrupts from occuring.
   //

   oldModemControl = READ_MODEM_CONTROL(extension, extension->Controller);

   WRITE_MODEM_CONTROL(extension, extension->Controller,
                       (UCHAR)(oldModemControl & ~SERIAL_MCR_OUT2));

   //
   // Reset the fifo's if there are any.
   //

   if (extension->FifoPresent) {

      //
      // There is a fine new "super" IO chip out there that
      // will get stuck with a line status interrupt if you
      // attempt to clear the fifo and enable it at the same
      // time if data is present.  The best workaround seems
      // to be that you should turn off the fifo read a single
      // byte, and then re-enable the fifo.
      //

      WRITE_FIFO_CONTROL(extension,
                        extension->Controller,
                        (UCHAR)0
                        );

      READ_RECEIVE_BUFFER(extension, extension->Controller);

      WRITE_FIFO_CONTROL(extension,
                        extension->Controller,
                        (UCHAR)(SERIAL_FCR_ENABLE | extension->RxFifoTrigger |
                                SERIAL_FCR_RCVR_RESET | SERIAL_FCR_TXMT_RESET)
                        );

   }

   //
   // Make sure that the line control set up correct.
   //
   // 1) Make sure that the Divisor latch select is set
   //    up to select the transmit and receive register.
   //
   // 2) Make sure that we aren't in a break state.
   //

   regContents = READ_LINE_CONTROL(extension, extension->Controller);
   regContents &= ~(SERIAL_LCR_DLAB | SERIAL_LCR_BREAK);

   WRITE_LINE_CONTROL(extension,
                     extension->Controller,
                     regContents
                     );

   //
   // Read the receive buffer until the line status is
   // clear.  (Actually give up after a 5 reads.)
   //

   for (i = 0;
       i < 5;
       i++
       ) {
                                              #pragma warning(disable: 4127)
      if (IsNotNEC_98) {
                                              #pragma warning(default: 4127)
         READ_RECEIVE_BUFFER(extension, extension->Controller);
         if (!(READ_LINE_STATUS(extension, extension->Controller) & 1)) {

            break;

         }
      } else {
          //
          // I get incorrect data when read enpty buffer.
          // But do not read no data! for PC98!
          //
          if (!(READ_LINE_STATUS(extension, extension->Controller) & 1)) {

             break;

          }
          READ_RECEIVE_BUFFER(extension, extension->Controller);
      }

   }

   //
   // Read the modem status until the low 4 bits are
   // clear.  (Actually give up after a 5 reads.)
   //

   for (i = 0;
       i < 1000;
       i++
       ) {

      if (!(READ_MODEM_STATUS(extension, extension->Controller) & 0x0f)) {

         break;

      }

   }

   //
   // Now we set the line control, modem control, and the
   // baud to what they should be.
   //

   //
   // See if we have to enable special Auto Flow Control
   //

   if (extension->TL16C550CAFC) {
      oldModemControl = READ_MODEM_CONTROL(extension, extension->Controller);

      WRITE_MODEM_CONTROL(extension, extension->Controller,
                          (UCHAR)(oldModemControl | SERIAL_MCR_TL16C550CAFE));
   }



   SerialSetLineControl(extension->WdfInterrupt, extension);

   SerialSetupNewHandFlow(
                         extension,
                         &extension->HandFlow
                         );

   SerialHandleModemUpdate(
                          extension,
                          FALSE
                          );

   {
      SHORT  appropriateDivisor;
      SERIAL_IOCTL_SYNC s;

      SerialGetDivisorFromBaud( extension->ClockRate,
                                extension->CurrentBaud,
                                &appropriateDivisor );

      s.Extension = extension;
      s.Data = (PVOID) (ULONG_PTR) appropriateDivisor;
      SerialSetBaud(extension->WdfInterrupt, &s);
   }

   //
   // Enable which interrupts we want to receive.
   //
   // NOTE NOTE: This does not actually let interrupts
   // occur.  We must still raise the OUT2 bit in the
   // modem control register.  We will do that on open.
   //

   ENABLE_ALL_INTERRUPTS(extension, extension->Controller);

   //
   // Read the interrupt id register until the low bit is
   // set.  (Actually give up after a 5 reads.)
   //

   for (i = 0;
       i < 5;
       i++
       ) {

      if (READ_INTERRUPT_ID_REG(extension, extension->Controller) & 0x01) {

         break;

      }

   }

   //
   // Now we know that nothing could be transmitting at this point
   // so we set the HoldingEmpty indicator.
   //

   extension->HoldingEmpty = TRUE;

   return FALSE;
}



PVOID
SerialGetMappedAddress(
    PHYSICAL_ADDRESS IoAddress,
    ULONG NumberOfBytes,
    ULONG AddressSpace,
    PBOOLEAN MappedAddress
    )

/*++

Routine Description:

    This routine maps an IO address to system address space.

Arguments:

    IoAddress - base device address to be mapped.
    NumberOfBytes - number of bytes for which address is valid.
    AddressSpace - Denotes whether the address is in io space or memory.
    MappedAddress - indicates whether the address was mapped.
                    This only has meaning if the address returned
                    is non-null.

Return Value:

    Mapped address

--*/

{
   PVOID address;

   PAGED_CODE();

   //
   // Map the device base address into the virtual address space
   // if the address is in memory space.
   //

   if (!AddressSpace) {

      address = LocalMmMapIoSpace(IoAddress,
                                  NumberOfBytes);

      *MappedAddress = (BOOLEAN)((address)?(TRUE):(FALSE));


   } else {

      address = ULongToPtr(IoAddress.LowPart);
      *MappedAddress = FALSE;

   }

   return address;
}

VOID
SerialSetInterruptPolicy(
   _In_ WDFINTERRUPT WdfInterrupt
   )
/*++

Routine Description:

    This routine shows how to set the interrupt policy preferences.

Arguments:

    WdfInterrupt - Interrupt object handle.

Return Value:

    None

--*/
{
    WDF_INTERRUPT_EXTENDED_POLICY   policyAndGroup;
#ifdef SERIAL_SELECT_INTERRUPT_GROUP
    USHORT                          groupCount      = 1;
    USHORT                          group           = 0;
    UNICODE_STRING                  funcName;
    PFN_KE_GET_ACTIVE_GROUP_COUNT   fnKeQueryActiveGroupCount;
    PFN_KE_QUERY_GROUP_AFFINITY     fnKeQueryGroupAffinity;
    KAFFINITY                       groupAffinity   = (KAFFINITY)1;
#endif

    WDF_INTERRUPT_EXTENDED_POLICY_INIT(&policyAndGroup);
    policyAndGroup.Priority = WdfIrqPriorityNormal;

#ifdef SERIAL_SELECT_INTERRUPT_GROUP
    //
    // If OS supports groups, find how many they are.
    //
    RtlInitUnicodeString(&funcName, L"KeQueryActiveGroupCount");
    fnKeQueryActiveGroupCount = (PFN_KE_GET_ACTIVE_GROUP_COUNT)
        MmGetSystemRoutineAddress(&funcName);
    
    if (fnKeQueryActiveGroupCount != NULL) {
        groupCount = fnKeQueryActiveGroupCount();
        
        //
        // Make sure there is at least one group for the boot processor.
        //
        if (0 == groupCount) {
            groupCount = 1;
        }
    }
    
    if (groupCount <= SERIAL_PREFERRED_INTERRUPT_GROUP) {
        group = groupCount - 1;
    }
    else {
        group = SERIAL_PREFERRED_INTERRUPT_GROUP;
    }

    //
    // Get the group affinity.
    //
    RtlInitUnicodeString(&funcName, L"KeQueryGroupAffinity");
    fnKeQueryGroupAffinity = (PFN_KE_QUERY_GROUP_AFFINITY)
        MmGetSystemRoutineAddress(&funcName);

    if (fnKeQueryGroupAffinity != NULL) {
        groupAffinity = fnKeQueryGroupAffinity(group);

        //
        // Active groups have at least one processor.
        //
        if ((KAFFINITY)0 == groupAffinity) {
            groupAffinity = (KAFFINITY)1;
        }
    }
    
    //
    // Initialize group.
    //
    policyAndGroup.Policy = WdfIrqPolicySpecifiedProcessors;
    policyAndGroup.TargetProcessorSetAndGroup.Group = group;
    policyAndGroup.TargetProcessorSetAndGroup.Mask  = groupAffinity;
#endif

    //
    // Set interrupt policy and group preference.
    //
    WdfInterruptSetExtendedPolicy(WdfInterrupt, &policyAndGroup);
}

