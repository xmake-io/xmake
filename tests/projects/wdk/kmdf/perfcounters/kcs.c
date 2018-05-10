/*++

Copyright (c) Microsoft Corporation.  All rights reserved.

    THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
    KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
    PURPOSE.

Module Name:

    kcs.c

Abstract:

    This module contains sample code to demonstrate how to provide
    counter data from a kernel driver.

Environment:

    Kernel mode only.

--*/


#include <wdm.h>
#include "kcs.h"
#include "kcsCounters.h"

#pragma code_seg("PAGE")

DRIVER_INITIALIZE DriverEntry;
DRIVER_UNLOAD KcsUnload;

NTSTATUS
KcsAddGeometricInstance (
    _In_ PPCW_BUFFER Buffer,
    _In_ PCWSTR Name,
    _In_ ULONG MinimalValue,
    _In_ ULONG Amplitude
    )

/*++

Routine Description:

    This utility function adds instance to the callback buffer.

Arguments:

    Buffer - Data will be returned in this buffer.

    Name - Name of instances to be added.

    MinimalValue - Minimum value of the wave.

    Amplitude - Amplitude of the wave.

Return Value:

    NTSTATUS indicating if the function succeeded.

--*/

{
    ULONG Index;
    LARGE_INTEGER Timestamp;
    UNICODE_STRING UnicodeName;
    GEOMETRIC_WAVE_VALUES Values;

    PAGED_CODE();

    KeQuerySystemTime(&Timestamp);

    Index = (Timestamp.QuadPart / 10000000) % 10;

    Values.Triangle = MinimalValue + Amplitude * abs(5 - Index) / 5;
    Values.Square = MinimalValue + Amplitude * (Index < 5);

    RtlInitUnicodeString(&UnicodeName, Name);

    return KcsAddGeometricWave(Buffer, &UnicodeName, 0, &Values);
}

NTSTATUS NTAPI
KcsGeometricWaveCallback (
    _In_ PCW_CALLBACK_TYPE Type,
    _In_ PPCW_CALLBACK_INFORMATION Info,
    _In_opt_ PVOID Context
    )

/*++

Routine Description:

    This function returns the list of counter instances and counter data.

Arguments:

    Type - Request type.

    Info - Buffer for returned data.

    Context - Not used.

Return Value:

    NTSTATUS indicating if the function succeeded.

--*/

{
    NTSTATUS Status;
    UNICODE_STRING UnicodeName;

    UNREFERENCED_PARAMETER(Context);

    PAGED_CODE();

    switch (Type) {
    case PcwCallbackEnumerateInstances:

        //
        // Instances are being enumerated, so we add them without values.
        //

        RtlInitUnicodeString(&UnicodeName, L"Small Wave");
        Status = KcsAddGeometricWave(Info->EnumerateInstances.Buffer,
                                     &UnicodeName,
                                     0,
                                     NULL);
        if (!NT_SUCCESS(Status)) {
            return Status;
        }

        RtlInitUnicodeString(&UnicodeName, L"Medium Wave");
        Status = KcsAddGeometricWave(Info->EnumerateInstances.Buffer,
                                     &UnicodeName,
                                     0,
                                     NULL);
        if (!NT_SUCCESS(Status)) {
            return Status;
        }

        RtlInitUnicodeString(&UnicodeName, L"Large Wave");
        Status = KcsAddGeometricWave(Info->EnumerateInstances.Buffer,
                                     &UnicodeName,
                                     0,
                                     NULL);
        if (!NT_SUCCESS(Status)) {
            return Status;
        }

        break;

    case PcwCallbackCollectData:

        //
        // Add values for 3 instances of Geometric Wave Counter Set.
        //

        Status = KcsAddGeometricInstance(Info->CollectData.Buffer,
                                         L"Small Wave",
                                         40,
                                         20);
        if (!NT_SUCCESS(Status)) {
            return Status;
        }

        Status = KcsAddGeometricInstance(Info->CollectData.Buffer,
                                         L"Medium Wave",
                                         30,
                                         40);
        if (!NT_SUCCESS(Status)) {
            return Status;
        }

        Status = KcsAddGeometricInstance(Info->CollectData.Buffer,
                                         L"Large Wave",
                                         20,
                                         60);
        if (!NT_SUCCESS(Status)) {
            return Status;
        }

        break;
    }

    return STATUS_SUCCESS;
}

NTSTATUS
KcsAddTrignometricInstance (
    _In_ PPCW_BUFFER Buffer,
    _In_ PCWSTR Name,
    _In_ ULONG MinimalValue,
    _In_ ULONG Amplitude
    )

/*++

Routine Description:

    This utility function adds instance to the callback buffer.

Arguments:

    Buffer - Data will be returned in this buffer.

    Name - Name of instances to be added.

    MinimalValue - Minimum value of the wave.

    Amplitude - Amplitude of the wave.

Return Value:

    NTSTATUS indicating if the function succeeded.

--*/

{
    double Angle;
    KFLOATING_SAVE FloatSave;
    NTSTATUS Status;
    LARGE_INTEGER Timestamp;
    UNICODE_STRING UnicodeName;
    TRIGNOMETRIC_WAVE_VALUES Values;

    PAGED_CODE();

    Status = KeSaveFloatingPointState(&FloatSave);
    if (!NT_SUCCESS(Status)) {
        return Status;
    }

    KeQuerySystemTime(&Timestamp);

    Angle = (double)(Timestamp.QuadPart / 400000) * (22/7) / 180;

    Values.Constant = MinimalValue;
    Values.Cosine = (ULONG)(MinimalValue + Amplitude * cos(Angle));
    Values.Sine = (ULONG)(MinimalValue + Amplitude * sin(Angle));

    KeRestoreFloatingPointState(&FloatSave);

    //
    // Add instance name & values to the caller's buffer.
    //

    RtlInitUnicodeString(&UnicodeName, Name);

    return KcsAddTrignometricWave(Buffer, &UnicodeName, 0, &Values);
}

NTSTATUS NTAPI
KcsTrignometricWaveCallback (
    _In_ PCW_CALLBACK_TYPE Type,
    _In_ PPCW_CALLBACK_INFORMATION Info,
    _In_opt_ PVOID Context
    )

/*++

Routine Description:

    This function returns the list of counter instances and counter data.

Arguments:

    Type - Request type.

    Info - Buffer for returned data.

    Context - Not used.

Return Value:

    NTSTATUS indicating if the function succeeded.

--*/

{
    NTSTATUS Status;
    UNICODE_STRING UnicodeName;

    UNREFERENCED_PARAMETER(Context);

    PAGED_CODE();

    switch (Type) {
    case PcwCallbackEnumerateInstances:
        RtlInitUnicodeString(&UnicodeName, L"default");
        Status = KcsAddTrignometricWave(Info->EnumerateInstances.Buffer,
                                        &UnicodeName,
                                        0,
                                        NULL);
        if (!NT_SUCCESS(Status)) {
            return Status;
        }

        break;

    case PcwCallbackCollectData:

        //
        // Add values for Single Instance of Trignometirc Wave Counter Set.
        //

        return KcsAddTrignometricInstance(Info->CollectData.Buffer,
                                          L"default",
                                          50,
                                          30);
    }

    return STATUS_SUCCESS;
}

VOID
KcsUnload (
    _In_ PDRIVER_OBJECT DriverObject
    )
 
/*++

Routine Description:

    This function unregisters countersets

Arguments:

    DriverObject - Not used.

Return Value:

    None.

--*/

{
    UNREFERENCED_PARAMETER(DriverObject);

    PAGED_CODE();

    //
    // Unregister Countersets.
    //

    KcsUnregisterGeometricWave();
    KcsUnregisterTrignometricWave();
}

NTSTATUS
DriverEntry (
    _In_ PDRIVER_OBJECT DriverObject,
    _In_ PUNICODE_STRING RegistryPath
    )

/*++

Routine Description:

    This function registers countersets on initial loading of the driver.

Arguments:

    DriverObject - Supplies the driver object of the driver being loaded.

    RegistryPath - Not used.

Return Value:

    NTSTATUS indicating if driver was properly loaded.

--*/

{
    NTSTATUS Status;

    UNREFERENCED_PARAMETER(RegistryPath);

    PAGED_CODE();

    //
    // Register Countersets.
    //

    Status = KcsRegisterGeometricWave(KcsGeometricWaveCallback, NULL);
    if (!NT_SUCCESS(Status)) {
        return Status;
    }

    Status = KcsRegisterTrignometricWave(KcsTrignometricWaveCallback, NULL);
    if (!NT_SUCCESS(Status)) {
        KcsUnregisterTrignometricWave();
        return Status;
    }

    //
    // Success path - set up unload routine and return success.
    //

    DriverObject->DriverUnload = KcsUnload;

    return STATUS_SUCCESS;
}

