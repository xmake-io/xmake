/*++

Copyright (c) 1997 Microsoft Corporation

Module Name:

    wmi.c

Abstract:

    This module contains the code that handles the wmi IRPs for the
    serial driver.

Environment:

    Kernel mode

--*/

#include "precomp.h"
#include <wmistr.h>

#if defined(EVENT_TRACING)
#include "wmi.tmh"
#endif

EVT_WDF_WMI_INSTANCE_QUERY_INSTANCE EvtWmiQueryPortName;
EVT_WDF_WMI_INSTANCE_QUERY_INSTANCE EvtWmiQueryPortCommData;
EVT_WDF_WMI_INSTANCE_QUERY_INSTANCE EvtWmiQueryPortHWData;
EVT_WDF_WMI_INSTANCE_QUERY_INSTANCE EvtWmiQueryPortPerfData;
EVT_WDF_WMI_INSTANCE_QUERY_INSTANCE EvtWmiQueryPortPropData;

NTSTATUS
SerialWmiRegisterInstance(
    WDFDEVICE Device,
    const GUID* Guid,
    ULONG MinInstanceBufferSize,
    PFN_WDF_WMI_INSTANCE_QUERY_INSTANCE EvtWmiInstanceQueryInstance
    );

#ifdef ALLOC_PRAGMA
#pragma alloc_text(PAGESRP0, SerialWmiRegistration)
#pragma alloc_text(PAGESRP0, SerialWmiRegisterInstance)
#pragma alloc_text(PAGESRP0, EvtWmiQueryPortName)
#pragma alloc_text(PAGESRP0, EvtWmiQueryPortCommData)
#pragma alloc_text(PAGESRP0, EvtWmiQueryPortHWData)
#pragma alloc_text(PAGESRP0, EvtWmiQueryPortPerfData)
#pragma alloc_text(PAGESRP0, EvtWmiQueryPortPropData)
#endif

NTSTATUS
SerialWmiRegisterInstance(
    WDFDEVICE Device,
    const GUID* Guid,
    ULONG MinInstanceBufferSize,
    PFN_WDF_WMI_INSTANCE_QUERY_INSTANCE EvtWmiInstanceQueryInstance
    )
{
    WDF_WMI_PROVIDER_CONFIG providerConfig;
    WDF_WMI_INSTANCE_CONFIG instanceConfig;

    PAGED_CODE();

    //
    // Create and register WMI providers and instances  blocks
    //
    WDF_WMI_PROVIDER_CONFIG_INIT(&providerConfig, Guid);
    providerConfig.MinInstanceBufferSize = MinInstanceBufferSize;

    WDF_WMI_INSTANCE_CONFIG_INIT_PROVIDER_CONFIG(&instanceConfig, &providerConfig);
    instanceConfig.Register = TRUE;
    instanceConfig.EvtWmiInstanceQueryInstance = EvtWmiInstanceQueryInstance;

    return WdfWmiInstanceCreate(Device,
                                &instanceConfig,
                                WDF_NO_OBJECT_ATTRIBUTES,
                                WDF_NO_HANDLE);
}

NTSTATUS
SerialWmiRegistration(
    WDFDEVICE      Device
)
/*++
Routine Description

    Registers with WMI as a data provider for this
    instance of the device

--*/
{
    NTSTATUS        status = STATUS_SUCCESS;
    PSERIAL_DEVICE_EXTENSION pDevExt;

    PAGED_CODE();

    pDevExt = SerialGetDeviceExtension (Device);

    //
    // Fill in wmi perf data (all zero's)
    //
    RtlZeroMemory(&pDevExt->WmiPerfData, sizeof(pDevExt->WmiPerfData));

    status = SerialWmiRegisterInstance(Device,
                                       &MSSerial_PortName_GUID,
                                       0,
                                       EvtWmiQueryPortName);
    if (!NT_SUCCESS(status)) {
        return status;
    }

    status = SerialWmiRegisterInstance(Device,
                                       &MSSerial_CommInfo_GUID,
                                       sizeof(SERIAL_WMI_COMM_DATA),
                                       EvtWmiQueryPortCommData);
    if (!NT_SUCCESS(status)) {
        return status;
    }

    status = SerialWmiRegisterInstance(Device,
                                       &MSSerial_HardwareConfiguration_GUID,
                                       sizeof(SERIAL_WMI_HW_DATA),
                                       EvtWmiQueryPortHWData);
    if (!NT_SUCCESS(status)) {
        return status;
    }

    status = SerialWmiRegisterInstance(Device,
                                       &MSSerial_PerformanceInformation_GUID,
                                       sizeof(SERIAL_WMI_PERF_DATA),
                                       EvtWmiQueryPortPerfData);
    if (!NT_SUCCESS(status)) {
        return status;
    }

    status = SerialWmiRegisterInstance(Device,
                                       &MSSerial_CommProperties_GUID,
                                       sizeof(SERIAL_COMMPROP) + sizeof(ULONG),
                                       EvtWmiQueryPortPropData);

    if (!NT_SUCCESS(status)) {
        return status;
    }

    return status;
}

//
// WMI Call back functions
//

NTSTATUS
EvtWmiQueryPortName(
    IN  WDFWMIINSTANCE WmiInstance,
    IN  ULONG OutBufferSize,
    IN  PVOID OutBuffer,
    OUT PULONG BufferUsed
    )
{
    WDFDEVICE device;
    WCHAR pRegName[SYMBOLIC_NAME_LENGTH];
    UNICODE_STRING string;
    USHORT nameSize = sizeof(pRegName);
    NTSTATUS status;

    PAGED_CODE();

    device = WdfWmiInstanceGetDevice(WmiInstance);

    status = SerialReadSymName(device, pRegName, &nameSize);
    if (!NT_SUCCESS(status)) {
        return status;
    }

    RtlInitUnicodeString(&string, pRegName);

    return WDF_WMI_BUFFER_APPEND_STRING(OutBuffer,
                                        OutBufferSize,
                                        &string,
                                        BufferUsed);
}

NTSTATUS
EvtWmiQueryPortCommData(
    IN  WDFWMIINSTANCE WmiInstance,
    IN  ULONG  OutBufferSize,
    IN  PVOID  OutBuffer,
    OUT PULONG BufferUsed
    )
{
    PSERIAL_DEVICE_EXTENSION pDevExt;

    UNREFERENCED_PARAMETER(OutBufferSize);

    PAGED_CODE();

    pDevExt = SerialGetDeviceExtension (WdfWmiInstanceGetDevice(WmiInstance));

    *BufferUsed = sizeof(SERIAL_WMI_COMM_DATA);

    if (OutBufferSize < *BufferUsed) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }

    *(PSERIAL_WMI_COMM_DATA)OutBuffer = pDevExt->WmiCommData;

    return STATUS_SUCCESS;
}

NTSTATUS
EvtWmiQueryPortHWData(
    IN  WDFWMIINSTANCE WmiInstance,
    IN  ULONG  OutBufferSize,
    IN  PVOID  OutBuffer,
    OUT PULONG BufferUsed
    )
{
    PSERIAL_DEVICE_EXTENSION pDevExt;

    UNREFERENCED_PARAMETER(OutBufferSize);

    PAGED_CODE();

    pDevExt = SerialGetDeviceExtension (WdfWmiInstanceGetDevice(WmiInstance));

    *BufferUsed = sizeof(SERIAL_WMI_HW_DATA);

    if (OutBufferSize < *BufferUsed) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }
    
    *(PSERIAL_WMI_HW_DATA)OutBuffer = pDevExt->WmiHwData;

    return STATUS_SUCCESS;
}

NTSTATUS
EvtWmiQueryPortPerfData(
    IN  WDFWMIINSTANCE WmiInstance,
    IN  ULONG OutBufferSize,
    IN  PVOID OutBuffer,
    OUT PULONG BufferUsed
    )
{
    PSERIAL_DEVICE_EXTENSION pDevExt;

    UNREFERENCED_PARAMETER(OutBufferSize);

    PAGED_CODE();

    pDevExt = SerialGetDeviceExtension (WdfWmiInstanceGetDevice(WmiInstance));

    *BufferUsed = sizeof(SERIAL_WMI_PERF_DATA);

    if (OutBufferSize < *BufferUsed) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }

    *(PSERIAL_WMI_PERF_DATA)OutBuffer = pDevExt->WmiPerfData;

    return STATUS_SUCCESS;
}

NTSTATUS
EvtWmiQueryPortPropData(
    IN  WDFWMIINSTANCE WmiInstance,
    IN  ULONG OutBufferSize,
    IN  PVOID OutBuffer,
    OUT PULONG BufferUsed
    )
{
    PSERIAL_DEVICE_EXTENSION pDevExt;

    UNREFERENCED_PARAMETER(OutBufferSize);

    PAGED_CODE();

    pDevExt = SerialGetDeviceExtension (WdfWmiInstanceGetDevice(WmiInstance));

    *BufferUsed = sizeof(SERIAL_COMMPROP) + sizeof(ULONG);

    if (OutBufferSize < *BufferUsed) {
        return STATUS_INSUFFICIENT_RESOURCES;
    }

    SerialGetProperties(
            pDevExt,
            (PSERIAL_COMMPROP)OutBuffer
            );

    *((PULONG)(((PSERIAL_COMMPROP)OutBuffer)->ProvChar)) = 0;

    return STATUS_SUCCESS;
}

