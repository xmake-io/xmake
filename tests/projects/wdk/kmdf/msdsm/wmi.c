
/*++

Copyright (C) 2004-2010  Microsoft Corporation

Module Name:

    wmi.c

Abstract:

    This driver is the Microsoft Device Specific Module (DSM).
    It exports behaviours that mpio.sys will use to determine how to
    multipath SPC-3 compliant devices.

    This file contains WMI related functions.

Environment:

    kernel mode only

Notes:

--*/



#include "precomp.h"
#include "msdsmwmi.h"
#include "msdsmdsm.h"

#ifdef DEBUG_USE_WPP
#include "wmi.tmh"
#endif

#pragma warning (disable:4305)

extern BOOLEAN DoAssert;

#define USE_BINARY_MOF_RESOURCE

#define DSM_INVALID_LOAD_BALANCE_POLICY STATUS_INVALID_PARAMETER
#define DSM_UNSUPPORTED_VERSION         STATUS_NOT_SUPPORTED

//
// Max length for each of the DeviceId strings (supported device list)
// NOTE: This must be kept in sync with msdsmdsm.mof
//
#define MSDSM_MAX_DEVICE_ID_LENGTH          31
#define MSDSM_MAX_DEVICE_ID_SIZE            (MSDSM_MAX_DEVICE_ID_LENGTH * sizeof(WCHAR))

//
// List of supported DSM-centric guids
//
GUID MSDSM_SUPPORTED_DEVICES_LISTGUID = MSDSM_SUPPORTED_DEVICES_LISTGuid;
GUID MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICYGUID = MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICYGuid;
GUID MSDSM_DEFAULT_LOAD_BALANCE_POLICYGUID = MSDSM_DEFAULT_LOAD_BALANCE_POLICYGuid;

//
// Symbolic names for the DSM-centric guid indexes
//
#define MSDSM_SUPPORTED_DEVICES_LISTGUID_Index              0
#define MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICYGUID_Index 1
#define MSDSM_DEFAULT_LOAD_BALANCE_POLICYGUID_Index         2

WMIGUIDREGINFO MSDsmGuidList[] = {
    {
        &MSDSM_SUPPORTED_DEVICES_LISTGUID,
        1,
        0
    },

    {
        &MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICYGUID,
        1,
        0
    },

    {
        &MSDSM_DEFAULT_LOAD_BALANCE_POLICYGUID,
        1,
        0
    }
};

#define MSDsmGuidCount (sizeof(MSDsmGuidList) / sizeof(WMIGUIDREGINFO))

//
// List of supported Device-centric guids
//
GUID DSM_LBOperationsGUID = DSM_LB_OperationsGuid;
GUID DSM_QueryLBPolicyGUID  = DSM_QueryLBPolicyGuid;
GUID DSM_QuerySupportedLBPoliciesGUID = DSM_QuerySupportedLBPoliciesGuid;
GUID DSM_QueryDsmUniqueIdGUID = DSM_QueryUniqueIdGuid;
GUID DSM_QueryLBPolicyV2GUID = DSM_QueryLBPolicy_V2Guid;
GUID DSM_QuerySupportedLBPoliciesV2GUID = DSM_QuerySupportedLBPolicies_V2Guid;
GUID MSDSM_DEVICE_PERFGUID = MSDSM_DEVICE_PERFGuid;
GUID MSDSM_WMI_METHODSGUID = MSDSM_WMI_METHODSGuid;

//
// Symbolic names for the Device-centric guid indexes
//
#define DSM_LBOperationsGUID_Index                  0
#define DSM_QueryLBPolicyGUID_Index                 1
#define DSM_QuerySupportedLBPoliciesGUID_Index      2
#define DSM_QueryDsmUniqueIdGUID_Index              3
#define DSM_QueryLBPolicyV2GUID_Index               4
#define DSM_QuerySupportedLBPoliciesV2GUID_Index    5
#define MSDSM_DEVICE_PERFGuidIndex                  6
#define MSDSM_WMI_METHODSGuidIndex                  7

WMIGUIDREGINFO DsmGuidList[] = {
    {
        &DSM_LBOperationsGUID,
        1,
        0
    },

    {
        &DSM_QueryLBPolicyGUID,
        1,
        0
    },

    {
        &DSM_QuerySupportedLBPoliciesGUID,
        1,
        0
    },

    {
        &DSM_QueryDsmUniqueIdGUID,
        1,
        0
    },

    {
        &DSM_QueryLBPolicyV2GUID,
        1,
        0
    },

    {
        &DSM_QuerySupportedLBPoliciesV2GUID,
        1,
        0
    },

    {
        &MSDSM_DEVICE_PERFGUID,
        1,
        0
    },

    {
        &MSDSM_WMI_METHODSGUID,
        1,
        0
    }
};

#define DsmGuidCount (sizeof(DsmGuidList) / sizeof(WMIGUIDREGINFO))

VOID
DsmpDsmWmiInitialize(
    _In_ IN PDSM_WMILIB_CONTEXT WmiGlobalInfo,
    _In_ IN PUNICODE_STRING RegistryPath
    )
/*++

Routine Description:

    This routine intializes the DSM-specific WmiGlobalInfo structure that is passed
    back to MPIO during DriverEntry.

Arguments:

    WmiGlobalInfo - WMI information structure to initialize.
    RegistryPath  - Registry path to the service key for this driver.

Return Value:

    None

--*/
{
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_INIT,
                "DsmpDsmWmiInitialize (RegPath %ws): Entering function.\n",
                RegistryPath->Buffer));

    RtlZeroMemory(WmiGlobalInfo, sizeof(DSM_WMILIB_CONTEXT));

    //
    // Build the mof resource name. This tells wmi via the busdriver,
    // where to find the mof data. This is found in the .rc.
    //
    RtlInitUnicodeString(&WmiGlobalInfo->MofResourceName, L"DsmMofResourceName");

    //
    // This will jam in the entry points and guids for supported WMI
    // operations. SetDataBlock, SetDataItem, ExecuteMethod and FunctionControl are
    // currently not needed, so leave them set to zero.
    //
    WmiGlobalInfo->GuidCount = MSDsmGuidCount;
    WmiGlobalInfo->GuidList = MSDsmGuidList;

    WmiGlobalInfo->QueryWmiDataBlockEx = DsmGlobalQueryData;
    WmiGlobalInfo->SetWmiDataBlockEx = DsmGlobalSetData;

    //
    // Allocate a buffer for the reg. path.
    //
    WmiGlobalInfo->RegistryPath.Buffer = DsmpAllocatePool(NonPagedPoolNx,
                                                          RegistryPath->MaximumLength,
                                                          DSM_TAG_REG_PATH);
    if (WmiGlobalInfo->RegistryPath.Buffer) {

        //
        // Set maximum length of the new string and copy it.
        //
        WmiGlobalInfo->RegistryPath.MaximumLength = RegistryPath->MaximumLength;

        RtlCopyUnicodeString(&WmiGlobalInfo->RegistryPath, RegistryPath);

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_INIT,
                    "DsmpDsmWmiInitialize (RegPath %ws): Failed to allocate memory for Registry path in WmiGlobalInfo.\n",
                    RegistryPath->Buffer));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_INIT,
                "DsmpDsmWmiInitialize (RegPath %ws): Exiting function.\n",
                RegistryPath->Buffer));

    return;
}


NTSTATUS
DsmGlobalQueryData(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN ULONG GuidIndex,
    _In_ IN ULONG InstanceIndex,
    _In_ IN ULONG InstanceCount,
    _Inout_ IN OUT PULONG InstanceLengthArray,
    _In_ IN ULONG BufferAvail,
    _Out_writes_to_(BufferAvail, *DataLength) OUT PUCHAR Buffer,
    _Out_ OUT PULONG DataLength,
    ...
    )
/*++

Routine Description:

    This is the WMI query entry point for DSM-specific GUIDs. The index into the
    GUID array is found and assuming the buffer is large enough, the data will be
    copied over.

Arguments:

    DsmContext - Global DSM Context
    DsmIds - Dsm Ids
    Irp - The WMI Irp
    GuidIndex - Index into the WMIGUIDINFO array
    InstanceIndex - Index of the data instance
    InstanceCount - Number of instances
    InstanceLengthArray - Array of ULONGs that indicate per-instance data lengths.
    BufferAvail - Size of the buffer in which data is returned.
    Buffer - Buffer in which the data is returned.
    DataLength - Storage for the actual data length written.

Return Value:

    STATUS_BUFFER_TOO_SMALL - If output buffer is not big enough to
                              to return all the available data.
    STATUS_WMI_GUID_NOT_FOUND - If GuidIndex doesn't correspond to an actual entry
                                in the reginfo array.
    STATUS_SUCCESS - On success.

--*/
{
    NTSTATUS status = STATUS_WMI_GUID_NOT_FOUND;
    UNREFERENCED_PARAMETER(DsmContext);
    UNREFERENCED_PARAMETER(InstanceLengthArray);
    UNREFERENCED_PARAMETER(InstanceCount);
    UNREFERENCED_PARAMETER(InstanceIndex);
    UNREFERENCED_PARAMETER(Irp);
    UNREFERENCED_PARAMETER(DsmIds);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmGlobalQueryData (DsmContext %p): Entering function - GuidIndex %u.\n",
                DsmContext,
                GuidIndex));

    //
    // Check the GuidIndex - the index into the DsmGuildList array - to see
    // whether this is a supported GUID or not.
    //
    switch(GuidIndex) {

        case MSDSM_SUPPORTED_DEVICES_LISTGUID_Index: {

            *DataLength = BufferAvail;

            status = DsmpQuerySupportedDevicesList(DsmContext,
                                                   BufferAvail,
                                                   DataLength,
                                                   Buffer);

            break;
        }

        case MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICYGUID_Index: {

            *DataLength = BufferAvail;

            status = DsmpQueryTargetsDefaultPolicy(DsmContext,
                                                   BufferAvail,
                                                   DataLength,
                                                   Buffer);

            break;
        }

        case MSDSM_DEFAULT_LOAD_BALANCE_POLICYGUID_Index: {

            *DataLength = BufferAvail;

            status = DsmpQueryDsmDefaultPolicy(DsmContext,
                                               BufferAvail,
                                               DataLength,
                                               Buffer);

            break;
        }

        default: {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmGlobalQueryData (DsmContext %p): Unknown GuidIndex %d.\n",
                        DsmContext,
                        GuidIndex));

            *DataLength = 0;

            break;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmGlobalQueryData (DsmContext %p): Exiting function with status 0x%x.\n",
                DsmContext,
                status));

    return status;
}


NTSTATUS
DsmGlobalSetData(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN ULONG GuidIndex,
    _In_ IN ULONG InstanceIndex,
    _In_ IN ULONG BufferAvail,
    _In_reads_bytes_(BufferAvail) IN PUCHAR Buffer,
    ...
    )
/*++

Routine Description:

    This is the WMI set entry point for DSM-specific GUIDs. The index into the
    GUID array is found and the contents of the buffer are set to the passed in
    instance index.

Arguments:

    DsmContext - Global DSM Context
    DsmIds - Dsm Ids
    Irp - The WMI Irp
    GuidIndex - Index into the WMIGUIDINFO array
    InstanceIndex - Index of the data instance
    BufferAvail - Size of the buffer in which data is returned.
    Buffer - Buffer in which the data is returned.

Return Value:

    STATUS_BUFFER_TOO_SMALL - If output buffer is not big enough to
                              to return all the available data.
    STATUS_WMI_GUID_NOT_FOUND - If GuidIndex doesn't correspond to an actual entry
                                in the reginfo array.
    STATUS_SUCCESS - On success.

--*/
{
    NTSTATUS status = STATUS_WMI_GUID_NOT_FOUND;
    ULONG dataLength;
    PDSM_CONTEXT dsmContext = (PDSM_CONTEXT)DsmContext;

    UNREFERENCED_PARAMETER(DsmIds);
    UNREFERENCED_PARAMETER(Irp);
    UNREFERENCED_PARAMETER(InstanceIndex);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmGlobalSetData (DsmContext %p): Entering function - GuidIndex %u.\n",
                DsmContext,
                GuidIndex));

    switch (GuidIndex) {

        case MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICYGUID_Index: {

            PMSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICY targetsPolicyInfo = (PMSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICY)Buffer;
            PMSDSM_TARGET_DEFAULT_POLICY_INFO targetPolicyInfo;
            PWSTR vidpidIndex;
            DSM_LOAD_BALANCE_TYPE loadBalancePolicy;
            ULONGLONG preferredPath;
            DWORD index;
            NTSTATUS errorStatus = STATUS_SUCCESS;

            //
            // Determine the correct buffer size.
            //
            dataLength = AlignOn8Bytes(FIELD_OFFSET(MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICY, TargetDefaultPolicyInfo));

            if (BufferAvail < dataLength) {

                status = STATUS_BUFFER_TOO_SMALL;

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmGlobalSetData (DsmContext %p): GuidIndex %u. Incorrect buffer size. Status %x\n",
                            DsmContext,
                            GuidIndex,
                            status));
                break;
            }

            dataLength += targetsPolicyInfo->NumberDevices * sizeof(MSDSM_TARGET_DEFAULT_POLICY_INFO);

            if (BufferAvail < dataLength) {

                status = STATUS_BUFFER_TOO_SMALL;

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmGlobalSetData (DsmContext %p): GuidIndex %u. Incorrect buffer size for %u targets. Status %x\n",
                            DsmContext,
                            GuidIndex,
                            targetsPolicyInfo->NumberDevices,
                            status));
                break;
            }

            targetPolicyInfo = targetsPolicyInfo->TargetDefaultPolicyInfo;

            for (index = 0; index < targetsPolicyInfo->NumberDevices; index++, targetPolicyInfo++) {

                size_t stringLength = 0;

                //
                // First ensure that these values make sense. The VID/PID should be
                // a string of 8+16 chars and the LB policy must be one that MSDSM
                // supports.
                //
                // The WMI string is like a unicode string with the first USHORT
                // containing the size.
                //
                vidpidIndex = targetPolicyInfo->HardwareId;
                vidpidIndex++;

                if (!NT_SUCCESS(RtlStringCchLengthW(vidpidIndex, DSM_VENDPROD_ID_LEN + 1, &stringLength)) || (stringLength != DSM_VENDPROD_ID_LEN)) {

                    errorStatus = STATUS_INVALID_PARAMETER;

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_WMI,
                                "DsmGlobalSetData (DsmContext %p): GuidIndex %u. Ignoring incorrect VID/PID %ws. Status %x\n",
                                DsmContext,
                                GuidIndex,
                                vidpidIndex,
                                errorStatus));
                    continue;
                }

                if (targetPolicyInfo->LoadBalancePolicy >= DSM_LB_VENDOR_SPECIFIC) {

                    errorStatus = STATUS_INVALID_PARAMETER;

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_WMI,
                                "DsmGlobalSetData (DsmContext %p): GuidIndex %u. Ignoring policy %u for %ws. Status %x\n",
                                DsmContext,
                                GuidIndex,
                                targetPolicyInfo->LoadBalancePolicy,
                                vidpidIndex,
                                errorStatus));
                    continue;
                }

                loadBalancePolicy = targetPolicyInfo->LoadBalancePolicy;
                preferredPath = (ULONGLONG)((ULONG_PTR)targetPolicyInfo->PreferredPath);

                //
                // Now update/create the key in the registry with the LB policy info.
                // If the LB policy is specified as 0, delete the key.
                //
                status = DsmpSetVidPidLBPolicyInRegistry(vidpidIndex, loadBalancePolicy, preferredPath);

                //
                // If above was successful, find the group that corresponds to this
                // targetId and update its LB policy as well as the states of the paths
                //
                if (NT_SUCCESS(status)) {

                    DsmpSetLBForVidPidPolicyAdjustment(dsmContext, vidpidIndex, loadBalancePolicy, preferredPath);
                } else {
                    errorStatus = status;
                }
            }

            //
            // If any error occurred, return the last error.
            //
            if (!NT_SUCCESS(errorStatus)) {
                status = errorStatus;
            }

            break;
        }

        case MSDSM_DEFAULT_LOAD_BALANCE_POLICYGUID_Index: {

            PMSDSM_DEFAULT_LOAD_BALANCE_POLICY dsmPolicyInfo = (PMSDSM_DEFAULT_LOAD_BALANCE_POLICY)Buffer;
            DSM_LOAD_BALANCE_TYPE loadBalancePolicy;
            ULONGLONG preferredPath;

            //
            // Determine the correct buffer size.
            //
            dataLength = sizeof(MSDSM_DEFAULT_LOAD_BALANCE_POLICY);

            if (BufferAvail < dataLength) {

                status = STATUS_BUFFER_TOO_SMALL;

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmGlobalSetData (DsmContext %p): GuidIndex %u. Incorrect buffer size. Status %x\n",
                            DsmContext,
                            GuidIndex,
                            status));
                break;
            }

            loadBalancePolicy = dsmPolicyInfo->LoadBalancePolicy;
            preferredPath = (ULONGLONG)((ULONG_PTR)dsmPolicyInfo->PreferredPath);

            //
            // First ensure that the values make sense.
            //
            if (loadBalancePolicy >= DSM_LB_VENDOR_SPECIFIC) {

                status = STATUS_INVALID_PARAMETER;
                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmGlobalSetData (DsmContext %p): GuidIndex %u. Invalid policy %u specified. Status %x\n",
                            DsmContext,
                            GuidIndex,
                            loadBalancePolicy,
                            status));

            } else {

                //
                // Update/create the values in the registry with the LB policy info.
                // If the LB policy is specified as 0, delete the values.
                //
                status = DsmpSetDsmLBPolicyInRegistry(loadBalancePolicy, preferredPath);

                //
                // If above is successful, find the groups that haven't had their LB policy
                // explicitly set or haven't had their policy set in accordance with target
                // hardware id. For each of these, adjust the states of the paths as well.
                //
                if (NT_SUCCESS(status)) {

                    DsmpSetLBForDsmPolicyAdjustment(dsmContext, loadBalancePolicy, preferredPath);
                }
            }

            break;
        }

        default: {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmGlobalSetData (DsmContext %p): Unknown GuidIndex %d.\n",
                        DsmContext,
                        GuidIndex));

            break;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmGlobalSetData (DsmContext %p): Exiting function with status 0x%x.\n",
                DsmContext,
                status));

    return status;
}


VOID
DsmpWmiInitialize(
    _In_ IN PDSM_WMILIB_CONTEXT WmiInfo,
    _In_ IN PUNICODE_STRING RegistryPath
    )
/*++

Routine Description:

    This routine intializes the Device-specific WmiInfo structure that is passed
    back to MPIO during DriverEntry.

Arguments:

    WmiInfo - WMI information structure to initialize.
    RegistryPath - Registry path to the service key for this driver.

Return Value:

    None

--*/
{
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_INIT,
                "DsmpWmiInitialize (RegPath %ws): Entering function.\n",
                RegistryPath->Buffer));

    RtlZeroMemory(WmiInfo, sizeof(DSM_WMILIB_CONTEXT));

    //
    // Build the mof resource name. This tells wmi via the busdriver,
    // where to find the mof data. This is found in the .rc.
    //
    RtlInitUnicodeString(&WmiInfo->MofResourceName, L"MofResourceName");

    //
    // This will jam in the entry points and guids for supported WMI
    // operations. SetDataBlock, SetDataItem, and FunctionControl are
    // currently not needed, so leave them set to zero.
    //
    WmiInfo->GuidCount = DsmGuidCount;
    WmiInfo->GuidList = DsmGuidList;

    WmiInfo->QueryWmiDataBlockEx = DsmQueryData;
    WmiInfo->ExecuteWmiMethodEx = DsmExecuteMethod;

    //
    // Allocate a buffer for the reg. path.
    //
    WmiInfo->RegistryPath.Buffer = DsmpAllocatePool(NonPagedPoolNx,
                                                    RegistryPath->MaximumLength,
                                                    DSM_TAG_REG_PATH);
    if (WmiInfo->RegistryPath.Buffer) {

        //
        // Set maximum length of the new string and copy it.
        //
        WmiInfo->RegistryPath.MaximumLength = RegistryPath->MaximumLength;

        RtlCopyUnicodeString(&WmiInfo->RegistryPath, RegistryPath);

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_INIT,
                    "DsmpWmiInitialize (RegPath %ws): Failed to allocate memory for Registry path in WMIInfo.\n",
                    RegistryPath->Buffer));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_INIT,
                "DsmpWmiInitialize (RegPath %ws): Exiting function.\n",
                RegistryPath->Buffer));

    return;
}


NTSTATUS
DsmQueryData(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN ULONG GuidIndex,
    _In_ IN ULONG InstanceIndex,
    _In_ IN ULONG InstanceCount,
    _Inout_ IN OUT PULONG InstanceLengthArray,
    _In_ IN ULONG BufferAvail,
    _When_(GuidIndex == DSM_LBOperationsGUID_Index || GuidIndex == MSDSM_WMI_METHODSGuidIndex, _Pre_notnull_ _Const_)
    _When_(!(GuidIndex == DSM_LBOperationsGUID_Index || GuidIndex == MSDSM_WMI_METHODSGuidIndex), _Out_writes_to_(BufferAvail, *DataLength))
          OUT PUCHAR Buffer,
    _Out_ OUT PULONG DataLength,
    ...
    )
/*++

Routine Description:

    This is the main WMI query entry point. The index into the GUID array is found
    and assuming the buffer is large enough, the data will be copied over.

Arguments:

    DsmContext - Global DSM Context
    DsmIds - Dsm Ids
    Irp - The WMI Irp
    GuidIndex - Index into the WMIGUIDINFO array
    InstanceIndex - Index of the data instance
    InstanceCount - Number of instances
    InstanceLengthArray - Array of ULONGs that indicate per-instance data lengths.
    BufferAvail - Size of the buffer in which data is returned.
    Buffer - Buffer in which the data is returned.
    DataLength - Storage for the actual data length written.

Return Value:

    STATUS_BUFFER_TOO_SMALL - If output buffer is not big enough to
                              to return all the available data.
    STATUS_WMI_GUID_NOT_FOUND - If GuidIndex doesn't correspond to an actual entry
                                in the reginfo array.
    STATUS_SUCCESS - On success.

--*/
{
    ULONG sizeNeeded;
    NTSTATUS status = STATUS_WMI_GUID_NOT_FOUND;

    UNREFERENCED_PARAMETER(DsmContext);
    UNREFERENCED_PARAMETER(InstanceCount);
    UNREFERENCED_PARAMETER(InstanceIndex);
    UNREFERENCED_PARAMETER(Irp);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmQueryData (DsmIds %p): Entering function - GuidIndex %u.\n",
                DsmIds,
                GuidIndex));

    //
    // Check the GuidIndex - the index into the DsmGuildList array - to see
    // whether this is a supported GUID or not.
    //
    switch(GuidIndex) {

        case DSM_LBOperationsGUID_Index: {

            //
            // Even though this class only has methods, we need to respond
            // to any queries for it since WMI expects that there is an actual
            // instance of the class on which to execute the method
            //

            sizeNeeded = sizeof(ULONG);

            *DataLength = sizeNeeded;

            if (BufferAvail >= sizeNeeded) {

                *InstanceLengthArray = sizeNeeded;
                status = STATUS_SUCCESS;

            } else {

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_WMI,
                            "DsmQueryData (DsmIds %p): Buffer too small in query data. Needed %d, Given %d.\n",
                            DsmIds,
                            sizeNeeded,
                            BufferAvail));

                status = STATUS_BUFFER_TOO_SMALL;
            }

            break;
        }

        case DSM_QueryLBPolicyGUID_Index:
        case DSM_QueryLBPolicyV2GUID_Index: {

            *DataLength = BufferAvail;

            status = DsmpQueryLoadBalancePolicy(DsmContext,
                                                DsmIds,
                                                ((GuidIndex == DSM_QueryLBPolicyGUID_Index) ? DSM_WMI_VERSION_1 : DSM_WMI_VERSION_2),
                                                BufferAvail,
                                                DataLength,
                                                Buffer);
            break;
        }

        case DSM_QuerySupportedLBPoliciesGUID_Index:
        case DSM_QuerySupportedLBPoliciesV2GUID_Index: {

            *DataLength = BufferAvail;

            status = DsmpQuerySupportedLBPolicies(DsmContext,
                                                  DsmIds,
                                                  BufferAvail,
                                                  ((GuidIndex == DSM_QuerySupportedLBPoliciesGUID_Index) ? DSM_WMI_VERSION_1 : DSM_WMI_VERSION_2),
                                                  DataLength,
                                                  Buffer);
            break;
        }

        case DSM_QueryDsmUniqueIdGUID_Index: {

            PDSM_QueryUniqueId dsmQueryUniqueId;

            *DataLength = sizeof(DSM_QueryUniqueId);

            if (BufferAvail >= sizeof(DSM_QueryUniqueId)) {

                dsmQueryUniqueId = (PDSM_QueryUniqueId) Buffer;
                dsmQueryUniqueId->DsmUniqueId = (ULONGLONG)((ULONG_PTR)DsmContext);
                status = STATUS_SUCCESS;

            } else {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmQueryData (DsmIds %p): Buffersize %d too small for Query Unique Id.\n",
                            DsmIds,
                            BufferAvail));

                status = STATUS_BUFFER_TOO_SMALL;
            }

            break;
        }

        case MSDSM_DEVICE_PERFGuidIndex: {

            *DataLength = BufferAvail;

            status = DsmpQueryDevicePerf(DsmContext,
                                         DsmIds,
                                         BufferAvail,
                                         DataLength,
                                         Buffer);

            break;
        }

        case MSDSM_WMI_METHODSGuidIndex: {

            //
            // Even though this class only has methods, we need to respond
            // to any queries for it since WMI expects that there is an actual
            // instance of the class on which to execute the method
            //

            sizeNeeded = sizeof(ULONG);

            *DataLength = sizeNeeded;

            if (BufferAvail >= sizeNeeded) {

                *InstanceLengthArray = sizeNeeded;
                status = STATUS_SUCCESS;

            } else {

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_WMI,
                            "DsmQueryData (DsmIds %p): Buffer too small in query data. Needed %d, Given %d.\n",
                            DsmIds,
                            sizeNeeded,
                            BufferAvail));

                status = STATUS_BUFFER_TOO_SMALL;
            }

            break;
        }

        default: {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmQueryData (DsmIds %p): Unknown GuidIndex %d in DsmQueryData.\n",
                        DsmIds,
                        GuidIndex));

            *DataLength = 0;

            break;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmQueryData (DsmIds %p): Exiting function with status 0x%x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmpQueryLoadBalancePolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds,
    _In_ IN ULONG        DsmWmiVersion,
    _In_ IN ULONG        InBufferSize,
    _In_ IN PULONG       OutBufferSize,
    _Out_writes_bytes_(*OutBufferSize) OUT PVOID Buffer
    )
/*+++

Routine Description:

    This routine returns the current Load Balance policy settings
    for the given device.

Arguements:

    DsmContext - Global DSM context
    DsmIds - DSM Ids for the given device
    DsmWmiVersion - version of the MPIO_DSM_Path class to use
    InBufferSize - Size of the input buffer
    OutBufferSize - Size of the output buffer
    Buffer - Buffer in which the current Load Balance policy settings
             is returned, if the buffer is big enough

Return Value:

   STATUS_SUCCESS on success
   Appropriate error code on error.

--*/
{
    PDSM_GROUP_ENTRY groupEntry;
    PDSM_DEVICE_INFO devInfo;
    PDSM_DEVICE_INFO rtpgDeviceInfo = NULL;
    ULONG inx;
    ULONG sizeNeeded;
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL irql;
    PDSM_Load_Balance_Policy_V2 supportedLBPolicies;
    PMPIO_DSM_Path_V2 dsmPath;
    PDSM_FAILOVER_GROUP foGroup;
    ULONG SpecialHandlingFlag = 0;
    
    UNREFERENCED_PARAMETER(InBufferSize);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryLoadBalancePolicy (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // At least one device should be given
    //
    if (DsmIds->Count == 0) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryLoadBalancePolicy (DsmIds %p): No DSM Ids given in DsmpQueryLoadBalancePolicy.\n",
                    DsmIds));

        *OutBufferSize = 0;
        status = STATUS_INVALID_PARAMETER;

        goto __Exit_DsmpQueryLoadBalancePolicy;
    }

    //
    // Compute the size needed for returning LoadBalance policy information
    //
    if (DsmWmiVersion == DSM_WMI_VERSION_1) {

        sizeNeeded = AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy, DSM_Paths));
        sizeNeeded += (DsmIds->Count) * sizeof(MPIO_DSM_Path);

    } else {

        sizeNeeded = AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy_V2, DSM_Paths));
        sizeNeeded += (DsmIds->Count * sizeof(MPIO_DSM_Path_V2));
    }

    if (*OutBufferSize < sizeNeeded) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryLoadBalancePolicy (DsmIds %p): Output buffer too small for QueryLBPolicy.\n",
                    DsmIds));

        *OutBufferSize = sizeNeeded;
        status = STATUS_BUFFER_TOO_SMALL;

        goto __Exit_DsmpQueryLoadBalancePolicy;
    }

    //
    // Set the size of the data returned to user
    //
    *OutBufferSize = sizeNeeded;

    //
    // Zero out the output buffer first
    //
    RtlZeroMemory(Buffer, sizeNeeded);

    devInfo = DsmIds->IdList[0];
    DSM_ASSERT(devInfo && devInfo->DeviceSig == DSM_DEVICE_SIG);
    groupEntry = devInfo->Group;

    //
    // Send down an RTPG to get the current state info if implicit transitions
    // are supported, since the states may have changed from under us.
    // Storages that support both implicit and explicit transitions that haven't
    // allowed us to turn OFF their implicit transitions, may have also changed
    // TPG states from under us. So do this for such storages also.
    //
    if (!DsmpIsSymmetricAccess(devInfo) &&
        devInfo->ALUASupport != DSM_DEVINFO_ALUA_EXPLICIT) {

        rtpgDeviceInfo = DsmpGetActivePathToBeUsed(groupEntry, FALSE, SpecialHandlingFlag);

        if (!rtpgDeviceInfo) {

            BOOLEAN sendTPG = FALSE;

            rtpgDeviceInfo = DsmpFindStandbyPathToActivateALUA(groupEntry, &sendTPG, SpecialHandlingFlag);
        }

        if (rtpgDeviceInfo) {

            status = DsmpGetDeviceALUAState(DsmContext, rtpgDeviceInfo, NULL);
        }
    }

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    //
    // If an RTPG was sent down, update all the devInfo states.
    //
    if (NT_SUCCESS(status) && rtpgDeviceInfo) {

        DsmpAdjustDeviceStatesALUA(groupEntry, NULL, SpecialHandlingFlag);
    }

    supportedLBPolicies = &(((PDSM_QueryLBPolicy_V2)Buffer)->LoadBalancePolicy);
    supportedLBPolicies->Version = DSM_WMI_VERSION;
    supportedLBPolicies->LoadBalancePolicy = groupEntry->LoadBalanceType;
    supportedLBPolicies->DSMPathCount = DsmIds->Count;
    dsmPath = supportedLBPolicies->DSM_Paths;

    //
    // Indicate which path is active and which path(s) are standby paths
    //
    inx = 0;
    while (inx < DsmIds->Count) {

        devInfo = (PDSM_DEVICE_INFO)DsmIds->IdList[inx];

        dsmPath->PathWeight = devInfo->PathWeight;
        dsmPath->Reserved = DSM_STATE_ACTIVE_OPTIMIZED_SUPPORTED;

        if (devInfo->ALUASupport == DSM_DEVINFO_ALUA_NOT_SUPPORTED) {

            if (DsmWmiVersion > DSM_WMI_VERSION_1) {

                dsmPath->TargetPortGroup_State = DSM_DEV_NOT_USED_STATE;
            }

            dsmPath->Reserved |= DSM_STATE_STANDBY_SUPPORTED;

        } else {

            if (DsmWmiVersion > DSM_WMI_VERSION_1) {

                dsmPath->TargetPortGroup_State = devInfo->TargetPortGroup->AsymmetricAccessState;
                dsmPath->TargetPortGroup_Preferred = devInfo->TargetPortGroup->Preferred;
                dsmPath->TargetPortGroup_Identifier = devInfo->TargetPortGroup->Identifier;

                if (devInfo->TargetPort) {

                    dsmPath->TargetPort_Identifier = devInfo->TargetPort->Identifier;
                }

                if (groupEntry->Symmetric) {

                    //
                    // For certain policies like FOO and RRWS, we need to be able to put
                    // path in standby.
                    //
                    dsmPath->Reserved |= DSM_STATE_STANDBY_SUPPORTED;
                }
            }

            dsmPath->Reserved |= devInfo->TargetPortGroup->ActiveUnoptimizedSupported ? DSM_STATE_ACTIVE_UNOPTIMIZED_SUPPORTED : 0;
            dsmPath->Reserved |= devInfo->TargetPortGroup->StandBySupported ? DSM_STATE_STANDBY_SUPPORTED : 0;
            dsmPath->Reserved |= devInfo->TargetPortGroup->UnavailableSupported ? DSM_STATE_UNAVAILABLE_SUPPORTED : 0;
        }

        groupEntry = devInfo->Group;

        if (DsmWmiVersion > DSM_WMI_VERSION_1) {

            dsmPath->SymmetricLUA = groupEntry->Symmetric;
            dsmPath->ALUASupport = devInfo->ALUASupport;

        }

        if (DsmpIsDeviceFailedState(devInfo->State) || !DsmpIsDeviceInitialized(devInfo)) {

            dsmPath->PrimaryPath = FALSE;
            dsmPath->DsmPathId = 0;

            if (DsmWmiVersion > DSM_WMI_VERSION_1) {

                dsmPath->OptimizedPath = dsmPath->PreferredPath = FALSE;
                dsmPath->FailedPath = TRUE;
            }

        } else {

            foGroup = devInfo->FailGroup;
            dsmPath->DsmPathId = (ULONGLONG)((ULONG_PTR)foGroup->PathId);

            if (DsmpIsDeviceStateActive(devInfo->State)) {

                dsmPath->PrimaryPath = TRUE;
            }

            if (DsmWmiVersion > DSM_WMI_VERSION_1) {

                if (devInfo->State == DSM_DEV_ACTIVE_OPTIMIZED ||
                    devInfo->State == DSM_DEV_STANDBY) {

                    dsmPath->OptimizedPath = TRUE;
                }

                if (((ULONGLONG)((ULONG_PTR)(foGroup->PathId))) == (devInfo->Group->PreferredPath)) {

                    dsmPath->PreferredPath = TRUE;
                }
            }
        }

#if DBG
        if (!dsmPath->PrimaryPath &&
            !dsmPath->FailedPath) {
            NT_ASSERT(groupEntry->LoadBalanceType != DSM_LB_ROUND_ROBIN &&
                   groupEntry->LoadBalanceType != DSM_LB_WEIGHTED_PATHS &&
                   groupEntry->LoadBalanceType != DSM_LB_DYN_LEAST_QUEUE_DEPTH &&
                   groupEntry->LoadBalanceType != DSM_LB_LEAST_BLOCKS);
        }
#endif

        dsmPath = DsmWmiVersion == DSM_WMI_VERSION_1 ?
                                   (PVOID)((PUCHAR)dsmPath + sizeof(MPIO_DSM_Path)) :
                                   (PVOID)((PUCHAR)dsmPath + sizeof(MPIO_DSM_Path_V2));

        inx++;
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

__Exit_DsmpQueryLoadBalancePolicy:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryLoadBalancePolicy (DsmIds %p): Exiting with status %x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmpQuerySupportedLBPolicies(
    _In_ IN  PDSM_CONTEXT DsmContext,
    _In_ IN  PDSM_IDS DsmIds,
    _In_ IN  ULONG BufferAvail,
    _In_ IN  ULONG DsmWmiVersion,
    _Out_ OUT PULONG OutBufferSize,
    _Out_writes_to_(BufferAvail, *OutBufferSize) OUT PUCHAR Buffer
    )
/*+++

Routine Description:

    This routine returns the load balance policies supported by this DSM for the
    given LUN (specified by the DsmIds).

Arguements:

    DsmContext - Global DSM context
    DsmIds - DSM Ids for the given device
    BufferAvail - Size of buffer available.
    DsmWmiVersion - Indicates which version of MPIO_DSMPath to use.
    OutBufferSize - Size of the output buffer.
    Buffer - Buffer in which the supported Load Balance policies are
             returned, if the buffer is big enough.

Return Value:

   STATUS_SUCCESS on success
   Appropriate error code on error.

--*/
{
    PDSM_QuerySupportedLBPolicies_V2 supportedLBPolicies;
    PDSM_Load_Balance_Policy_V2 dsmLBPolicy;
    ULONG sizeNeeded;
    ULONG policyCount;
    ULONG inx;
    NTSTATUS status = STATUS_SUCCESS;
    BOOLEAN skipRR = FALSE;
    PDSM_DEVICE_INFO devInfo = NULL;
    PUCHAR endOfBuffer;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,"DsmpQuerySupportedLBPolicies (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // At least one device should be given
    //
    if (DsmIds->Count == 0) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQuerySupportedLBPolicies (DsmIds %p): No DSM Ids given in DsmpQuerySupportedLBPolicies.\n",
                    DsmIds));

        *OutBufferSize = 0;
        status = STATUS_INVALID_PARAMETER;

        goto __Exit_DsmpQuerySupportedLBPolicies;
    }

    devInfo = DsmIds->IdList[0];
    DSM_ASSERT(devInfo && devInfo->DeviceSig == DSM_DEVICE_SIG);

    policyCount = DSM_NUMBER_OF_LB_POLICIES;

    //
    // Round Robin policy is not supported for arrays that are AAA.
    //
    if (!DsmpIsSymmetricAccess(devInfo)) {

        skipRR = TRUE;
        policyCount--;
    }

    if (DsmWmiVersion == DSM_WMI_VERSION_1) {

        sizeNeeded = AlignOn8Bytes(FIELD_OFFSET(DSM_QuerySupportedLBPolicies, Supported_LB_Policies));
        sizeNeeded += policyCount * AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy, DSM_Paths));

    } else {

        sizeNeeded = AlignOn8Bytes(FIELD_OFFSET(DSM_QuerySupportedLBPolicies_V2, Supported_LB_Policies));
        sizeNeeded += policyCount * AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy_V2, DSM_Paths));
    }

    //
    // Set the size of the data returned to user or needed but not provided.
    //
    *OutBufferSize = sizeNeeded;

    if (sizeNeeded > BufferAvail) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQuerySupportedLBPolicies (Buffer %p): Output buffer too small. Size needed = %u.\n",
                    Buffer,
                    sizeNeeded));

        status = STATUS_BUFFER_TOO_SMALL;

        goto __Exit_DsmpQuerySupportedLBPolicies;
    }

    endOfBuffer = Buffer + sizeNeeded - 1;

    //
    // Zero out the output buffer first
    //
    supportedLBPolicies = (PDSM_QuerySupportedLBPolicies_V2)Buffer;
    RtlZeroMemory(Buffer, sizeNeeded);

    supportedLBPolicies->SupportedLBPoliciesCount = policyCount;

    if (DsmWmiVersion > DSM_WMI_VERSION_1) {

        dsmLBPolicy = &(supportedLBPolicies->Supported_LB_Policies[0]);

    } else {

        dsmLBPolicy = (PVOID)&(((PDSM_QuerySupportedLBPolicies)supportedLBPolicies)->Supported_LB_Policies[0]);
    }

    //
    // All Load Balance policies are supported in Windows Server 2003
    // and above.
    //
    for (inx = 0; inx < DSM_NUMBER_OF_LB_POLICIES; inx++) {

        //
        // Skip reporting Round Robin for AAA arrays.
        //
        if (((inx + 1) == DSM_LB_ROUND_ROBIN) && skipRR) {

            continue;
        }

        if (DsmWmiVersion > DSM_WMI_VERSION_1) {

            if ((PUCHAR)dsmLBPolicy + AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy_V2, DSM_Paths)) - 1 > endOfBuffer) {

                status = STATUS_BUFFER_TOO_SMALL;
                break;
            }
        } else {

            if ((PUCHAR)dsmLBPolicy + AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy, DSM_Paths)) - 1 > endOfBuffer) {

                status = STATUS_BUFFER_TOO_SMALL;
                break;
            }
        }

        dsmLBPolicy->Version = DSM_WMI_VERSION;

        //
        // The value set for LoadBalancePolicy is based on
        // the #define for LB policies in LBPolicy.h
        //
        dsmLBPolicy->LoadBalancePolicy = inx + 1;

        //
        // Point to the next DSM_Load_Balance_Policy area
        //
        if (DsmWmiVersion > DSM_WMI_VERSION_1) {

            dsmLBPolicy = (PDSM_Load_Balance_Policy_V2)((PUCHAR)dsmLBPolicy + AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy_V2, DSM_Paths)));

        } else {

            dsmLBPolicy = (PVOID)((PUCHAR)dsmLBPolicy + AlignOn8Bytes(FIELD_OFFSET(DSM_Load_Balance_Policy, DSM_Paths)));
        }
    }

__Exit_DsmpQuerySupportedLBPolicies:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQuerySupportedLBPolicies (DsmIds %p): Exiting function with status %x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmExecuteMethod(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP  Irp,
    _In_ IN ULONG GuidIndex,
    _In_ IN ULONG InstanceIndex,
    _In_ IN ULONG MethodId,
    _In_ IN ULONG InBufferSize,
    _In_ IN PULONG OutBufferSize,
    _Inout_ IN OUT PUCHAR Buffer,
    ...
    )
/*++

Routine Description:

    This routine handles the invocation of WMI methods defined in the DSM mof.

Arguments:

    DsmContext - Global DSM context
    DsmIds - DSM Ids
    Irp - The WMI Irp
    GuidIndex - Index into the WMIGUIDINFO array
    InstanceIndex - Index value indicating for which instance data should be returned.
    MethodId - Specifies which method to invoke.
    InBufferSize - Buffer size, in bytes, of input parameter data.
    OutBufferSize - Buffer size, in bytes, of output data.
    Buffer - Buffer to which the data is read/written.

Return Value:

    Status of the method, or STATUS_WMI_ITEMID_NOT_FOUND

--*/
{
    NTSTATUS status = STATUS_WMI_GUID_NOT_FOUND;
    UNREFERENCED_PARAMETER(DsmContext);
    UNREFERENCED_PARAMETER(InstanceIndex);
    UNREFERENCED_PARAMETER(Irp);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmExecuteMethod (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // This should be the index for ExecMethod Index
    //
    if (GuidIndex == DSM_LBOperationsGUID_Index) {

        switch (MethodId) {

            case DsmSetLoadBalancePolicy:
            case DsmSetLoadBalancePolicyALUA: {

                status = DsmpSetLoadBalancePolicy(DsmContext,
                                                  DsmIds,
                                                  (MethodId == DsmSetLoadBalancePolicy) ? DSM_WMI_VERSION_1 : DSM_WMI_VERSION_2,
                                                  InBufferSize,
                                                  OutBufferSize,
                                                  Buffer);
                break;
            }

            default: {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmExecuteMethod (DsmIds %p): Unknown MethodId %d in DsmExecuteMethod.\n",
                            DsmIds,
                            MethodId));

                status = STATUS_WMI_ITEMID_NOT_FOUND;

                break;
            }
        }
    } else if (GuidIndex == MSDSM_WMI_METHODSGuidIndex) {

        if (MethodId == MSDsmClearCounters) {

            status = DsmpClearPerfCounters(DsmContext, DsmIds);

        } else {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmExecuteMethod (DsmIds %p): Unknown MethodId %d for GuidIndex %d in DsmExecuteMethod.\n",
                        DsmIds,
                        MethodId,
                        GuidIndex));
        }

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmExecuteMethod (DsmIds %p): Unknown GuidIndex %d in DsmExecuteMethod.\n",
                    DsmIds,
                    GuidIndex));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmExecuteMethod (DsmIds %p): Exiting function with status 0x%x.\n",
                DsmIds,
                status));

    return status;
}

NTSTATUS
DsmpClearLoadBalancePolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds
    )
/*++

Routine Description:

    This routine is called to clear the LUN-specific load balance policy for the given device.

    First, the routine will try to clear the "explicitly set" registry key for the device.  If
    this fails, the whole routine is aborted.

    If the registry key is successfully cleared, the following happens:
    1. Check to see if there is a target-wide load balance policy set for this device's VID/PID.
       If yes, we set the device's load balance policy accordingly and return.
    2. Check to see if there is an MSDSM-wide load balance policy set.
       If yes, we set the device's load balance policy accordingly and return.
    3. If steps 1 and 2 fall through, we set the device's load balance policy to RR, or RRWS if
       ALUA is enabled.

Arguements:

    DsmContext - Global DSM context
    DsmIds - DSM Ids for the given device

Return Value:

    Appropriate status indicating the error if the input is malformed or
    if the function was unable to clear the load balance policy.
    STATUS_SUCCESS on success

--*/

{
    NTSTATUS status = STATUS_SUCCESS;
    PDSM_DEVICE_INFO deviceInfo = NULL;
    PDSM_GROUP_ENTRY group = NULL;
    HANDLE lbSettingsKey = NULL;
    HANDLE deviceKey = NULL;
    UNICODE_STRING subKeyName;
    OBJECT_ATTRIBUTES objectAttributes;
    DSM_LOAD_BALANCE_TYPE loadBalanceType;
    ULONGLONG preferredPath = (ULONGLONG)((ULONG_PTR)MAXULONG);
    ULONG devInfoIndex;
    ULONG SpecialHandlingFlag = 0;
    
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpClearLoadBalancePolicy (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // There should be at least one device
    //
    if (DsmIds->Count == 0) {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_WMI,
                    "DsmpClearLoadBalancePolicy (DsmIds %p): No DSM Ids given.\n",
                    DsmIds));

        status = STATUS_INVALID_PARAMETER;
        goto __Exit_DsmpClearLoadBalancePolicy;
    }

    deviceInfo = (PDSM_DEVICE_INFO)DsmIds->IdList[0];
    group = deviceInfo->Group;

    //
    // First open LoadBalanceSettings key under the Services key
    //
    status = DsmpOpenLoadBalanceSettingsKey(KEY_ALL_ACCESS, &lbSettingsKey);
    if (!NT_SUCCESS(status)) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpClearLoadBalancePolicy (DevName %ws): Failed to open LB Settings key. Status %x.\n",
                    group->RegistryKeyName,
                    status));

        goto __Exit_DsmpClearLoadBalancePolicy;
    }

    //
    // Now open the key under which the LB settings for the given device is stored
    // and clear the DsmLoadBalancePolicyExplicitlySet key.
    //
    RtlInitUnicodeString(&subKeyName, group->RegistryKeyName);

    InitializeObjectAttributes(&objectAttributes,
                               &subKeyName,
                               (OBJ_CASE_INSENSITIVE | OBJ_KERNEL_HANDLE),
                               lbSettingsKey,
                               (PSECURITY_DESCRIPTOR) NULL);

    status = ZwOpenKey(&deviceKey, KEY_ALL_ACCESS, &objectAttributes);

    if (NT_SUCCESS(status)) {

        UCHAR explicitlySet = FALSE;

        status = RtlWriteRegistryValue(RTL_REGISTRY_HANDLE,
                                       deviceKey,
                                       DSM_POLICY_EXPLICITLY_SET,
                                       REG_BINARY,
                                       &explicitlySet,
                                       sizeof(UCHAR));
        if (!NT_SUCCESS(status)) {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpClearLoadBalancePolicy (DevName %ws): Failed to clear DsmLoadBalancePolicyExplicitlySet key.\n",
                        group->RegistryKeyName));

            goto __Exit_DsmpClearLoadBalancePolicy;
        }
    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpClearLoadBalancePolicy (DevName %ws): Failed to open device subkey.\n",
                    group->RegistryKeyName));

        goto __Exit_DsmpClearLoadBalancePolicy;
    }



    //
    // Set the defaults.  These will be used if no target-wide or MSDSM-wide
    // load balance policies are set.
    //
    group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_ALUA_CAPABILITY;
    loadBalanceType = DSM_LB_ROUND_ROBIN;
    preferredPath = 0;

    //
    // Check to see if target-wide (VID/PID) LB policy is set for this device.
    //
    status = DsmpQueryTargetLBPolicyFromRegistry(deviceInfo,
                                                 &loadBalanceType,
                                                 &preferredPath);
    if (NT_SUCCESS(status)) {

        group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_VID_PID;

    } else if (status == STATUS_OBJECT_NAME_NOT_FOUND) {

        //
        // Since the policy hasn't been set for this VID/PID, check if
        // overall MSDSM-wide policy has been set.
        //
        status = DsmpQueryDsmLBPolicyFromRegistry(&loadBalanceType,
                                                  &preferredPath);
        if (NT_SUCCESS(status)) {

            group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_DSM_WIDE;

        } else {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_PNP,
                        "DsmpClearLoadBalancePolicy (DevInfo %p): Failed to query Dsm overall LB policy from registry. Status %x.\n",
                        deviceInfo,
                        status));

            NT_ASSERT(status == STATUS_OBJECT_NAME_NOT_FOUND);
            status = STATUS_SUCCESS;
        }
    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_PNP,
                    "DsmpClearLoadBalancePolicy (DevInfo %p): Failed to query VID/PID LB policy from registry. Status %x.\n",
                    deviceInfo,
                    status));

        NT_ASSERT(status == STATUS_OBJECT_NAME_NOT_FOUND);
        status = STATUS_SUCCESS;
    }


    //
    // If the storage is ALUA enabled and we specified Round Robin, change
    // it to Round Robin with Subset instead.
    //
    if (!DsmpIsSymmetricAccess(deviceInfo) && loadBalanceType == DSM_LB_ROUND_ROBIN) {

        loadBalanceType = DSM_LB_ROUND_ROBIN_WITH_SUBSET;
    }

    //
    // Finally set the load balance policy and the preferred path.
    //
    group->LoadBalanceType = loadBalanceType;
    group->PreferredPath = preferredPath;

    //
    // Update the path states in accordance with the new policy.
    //
    for (devInfoIndex = 0; devInfoIndex < DSM_MAX_PATHS; devInfoIndex++) {

        DsmpSetNewDefaultLBPolicy(DsmContext,
                                  group->DeviceList[devInfoIndex],
                                  group->LoadBalanceType,
                                  SpecialHandlingFlag);
    }

__Exit_DsmpClearLoadBalancePolicy:

    if (deviceKey) {
        ZwClose(deviceKey);
    }

    if (lbSettingsKey) {
        ZwClose(lbSettingsKey);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpClearLoadBalancePolicy (DsmIds %p): Exiting function with status 0x%x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmpSetLoadBalancePolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds,
    _In_ IN ULONG        DsmWmiVersion,
    _In_ IN ULONG        InBufferSize,
    _In_ IN PULONG       OutBufferSize,
    _In_ IN PVOID        Buffer
    )
/*++

Routine Description:

    This routine is called to set the load balance policy for the given device.

    If zero is passed in as the load balance policy, the LUN-specific load balance
    policy will attempt to be cleared.  See DsmpClearLoadBalancePolicy for more details.

Arguements:

    DsmContext - Global DSM context
    DsmIds - DSM Ids for the given device
    DsmWmiVersion - version of the MPIO_DSM_Path class to use
    InBufferSize - Size of the input buffer
    OutBufferSize - Size of the output buffer
    Buffer - Buffer for input\output data

Return Value:

    STATUS_BUFFER_TOO_SMALL - If the input buffer is too small
    Appropriate status indicating the error if the input is malformed.
    STATUS_SUCCESS on success

--*/

{
    PDsmSetLoadBalancePolicyALUA_IN setLoadBalancePolicyIN = (PDsmSetLoadBalancePolicyALUA_IN) Buffer;
    PDsmSetLoadBalancePolicyALUA_OUT setLoadBalancePolicyOUT = (PDsmSetLoadBalancePolicyALUA_OUT) Buffer;
    PVOID supportedLBPolicies;
    PMPIO_DSM_Path_V2 dsmPath;
    ULONG inx = 0;
    ULONG jnx;
    NTSTATUS status = STATUS_SUCCESS;
    BOOLEAN lengthOkay = TRUE;
    PDSM_DEVICE_INFO devInfo = NULL;
    PDSM_DEVICE_INFO tempDevInfo = NULL;
    PDSM_GROUP_ENTRY groupEntry;
    PDSM_LOAD_BALANCE_POLICY_SETTINGS savedLBSettings = NULL;
    KIRQL irql;
    BOOLEAN optimized = TRUE;
    BOOLEAN preferred = FALSE;
    ULONG activePaths = 0;
    ULONG activeTPGs = 0;
    ULONG numberDevInfoChanged = 0;
    ULONG numberPreferredPaths = 0;
    DSM_LOAD_BALANCE_TYPE loadBalancePolicy;
    BOOLEAN sendSTPG = FALSE;
    ULONGLONG preferredPath = (ULONGLONG)((ULONG_PTR)MAXULONG);
    ULONG SpecialHandlingFlag = 0;
    
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetLoadBalancePolicy (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // There should be at least one device
    //
    if (DsmIds->Count == 0) {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_WMI,
                    "DsmpSetLoadBalancePolicy (DsmIds %p): No DSM Ids given.\n",
                    DsmIds));

        status = STATUS_INVALID_PARAMETER;
        goto __Exit_DsmpSetLoadBalancePolicy;
    }

    groupEntry = ((PDSM_DEVICE_INFO)DsmIds->IdList[0])->Group;

    if (DsmWmiVersion == DSM_WMI_VERSION_1) {

        if (*OutBufferSize < sizeof(DsmSetLoadBalancePolicy_OUT)) {

            *OutBufferSize = sizeof(DsmSetLoadBalancePolicy_OUT);
            lengthOkay = FALSE;
        }
    } else {

        if (*OutBufferSize < sizeof(DsmSetLoadBalancePolicyALUA_OUT)) {

            *OutBufferSize = sizeof(DsmSetLoadBalancePolicyALUA_OUT);
            lengthOkay = FALSE;
        }
    }

    if (!lengthOkay) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpSetLoadBalancePolicy (DsmIds %p): Buffer too small for SetLBPolicy.\n",
                    DsmIds));

        status = STATUS_BUFFER_TOO_SMALL;
        goto __Exit_DsmpSetLoadBalancePolicy;
    }

    *OutBufferSize = (DsmWmiVersion == DSM_WMI_VERSION_1) ? sizeof(DsmSetLoadBalancePolicy_OUT) : sizeof(DsmSetLoadBalancePolicyALUA_OUT);

    //
    // If the user specified zero as the load balance policy, we need to clear the
    // LUN-specific load balance policy.
    //
    if (setLoadBalancePolicyIN->LoadBalancePolicy.LoadBalancePolicy == 0) {
        status = DsmpClearLoadBalancePolicy(DsmContext, DsmIds);
        goto __Exit_DsmpSetLoadBalancePolicy;
    }

    status = DsmpValidateSetLBPolicyInput(DsmContext,
                                          DsmIds,
                                          DsmWmiVersion,
                                          Buffer,
                                          InBufferSize);
    if (!NT_SUCCESS(status)) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpSetLoadBalancePolicy (DsmIds %p): Failed to validate input. Status %x.\n",
                    DsmIds,
                    status));

        goto __Exit_DsmpSetLoadBalancePolicy;
    }

    //
    // At this point the Reserved field in each MPIO_DSM_Path should
    // contain the respective Device Info
    //
    supportedLBPolicies = &(setLoadBalancePolicyIN->LoadBalancePolicy);
    loadBalancePolicy = ((PDSM_Load_Balance_Policy_V2)supportedLBPolicies)->LoadBalancePolicy;

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    //
    // Cache each DeviceInfo's current state.
    // This will be used to rollback in case of errors.
    //
    DsmpSaveDeviceState(supportedLBPolicies, DsmWmiVersion);

    while (inx < ((PDSM_Load_Balance_Policy_V2)supportedLBPolicies)->DSMPathCount) {

        if (DsmWmiVersion == DSM_WMI_VERSION_1) {

            dsmPath = (PVOID)&(((PDSM_Load_Balance_Policy)supportedLBPolicies)->DSM_Paths[inx]);

            optimized = TRUE;
            preferred = FALSE;

        } else {

            dsmPath = &(((PDSM_Load_Balance_Policy_V2)supportedLBPolicies)->DSM_Paths[inx]);

            optimized = dsmPath->OptimizedPath ? TRUE : FALSE;
            preferred = dsmPath->PreferredPath ? TRUE : FALSE;

            if (preferred && loadBalancePolicy == DSM_LB_FAILOVER) {

                preferredPath = dsmPath->DsmPathId;

                if (preferredPath != 0) {

                    numberPreferredPaths++;
                }

                if (numberPreferredPaths > 1) {

                    DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
                    status = STATUS_INVALID_PARAMETER;
                    break;
                }
            }
        }

        //
        // Reserved field in MPIO_DSM_Path is set to DeviceInfo in
        // DsmpValidateSetLBPolicyInput routine.
        //
        devInfo = (PDSM_DEVICE_INFO)dsmPath->Reserved;

        if (!devInfo) {

            inx++;
            continue;

        } else {

            if (!tempDevInfo) {

                tempDevInfo = devInfo;

                if (loadBalancePolicy == DSM_LB_ROUND_ROBIN ||
                    loadBalancePolicy == DSM_LB_ROUND_ROBIN_WITH_SUBSET) {

                    InterlockedExchangePointer(&(groupEntry->PathToBeUsed), NULL);
                }
            }
        }

        if (!DsmpIsDeviceFailedState(devInfo->State)) {

            if (devInfo->ALUAState == DSM_DEV_ACTIVE_OPTIMIZED) {

                activeTPGs++;
            }

            if (dsmPath->PrimaryPath) {

                //
                // Optimized flag decides between AO and AU
                //
                if (optimized) {

                    //
                    // For implicit-only ALUA, state cannot be explicitly changed to A/O
                    //
                    if (!DsmpIsSymmetricAccess(devInfo) && devInfo->ALUASupport == DSM_DEVINFO_ALUA_IMPLICIT) {

                        //
                        // While we can mask off acutal A/O to be A/U, there is no
                        // way to explicitly make non-A/O state A/O
                        //
                        if (devInfo->ALUAState != DSM_DEV_ACTIVE_OPTIMIZED) {

                            TracePrint((TRACE_LEVEL_ERROR,
                                        TRACE_FLAG_WMI,
                                        "DsmpSetLoadBalancePolicy (DsmIds %p): Can't make non-AO path A/O for Implicit-only transitions.\n",
                                        DsmIds));

                            DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
                            status = STATUS_INVALID_PARAMETER;
                            break;
                        }
                    }

                    numberDevInfoChanged++;

                    devInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;
                    activePaths++;

                    //
                    // Check to see if the actual making of this path state A/O
                    // will require an STPG to be sent down.
                    //
                    if (devInfo->TargetPortGroup &&
                        devInfo->ALUAState != DSM_DEV_ACTIVE_OPTIMIZED) {

                        sendSTPG = TRUE;
                    }

                    if (loadBalancePolicy == DSM_LB_FAILOVER) {

                        //
                        // Only ONE path can be specified as AO for FailOverOnly policy.
                        //
                        if (activePaths > 1) {

                            TracePrint((TRACE_LEVEL_ERROR,
                                        TRACE_FLAG_WMI,
                                        "DsmpSetLoadBalancePolicy (DsmIds %p): More than one AO node given for FO Only.\n",
                                        DsmIds));

                            DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
                            status = STATUS_INVALID_PARAMETER;
                            break;
                        }
                    }

                    if (loadBalancePolicy == DSM_LB_ROUND_ROBIN ||
                        loadBalancePolicy == DSM_LB_ROUND_ROBIN_WITH_SUBSET) {

                        if (!groupEntry->PathToBeUsed) {
                            InterlockedExchangePointer(&(groupEntry->PathToBeUsed), (PVOID)devInfo->FailGroup);
                        }
                    }
                } else {

                    //
                    // This is an ActiveUnoptimized path
                    //
                    devInfo->State = DSM_DEV_ACTIVE_UNOPTIMIZED;

                    //
                    // For LB policy RR, WP, LB and LQD, all paths must be in A/O
                    // state. However, this is not possible for ALUA storages.
                    // For these storages, A/U is allowable only if that is the
                    // access state that the TPG is in.
                    //
                    if (loadBalancePolicy == DSM_LB_ROUND_ROBIN ||
                        loadBalancePolicy == DSM_LB_WEIGHTED_PATHS ||
                        loadBalancePolicy == DSM_LB_DYN_LEAST_QUEUE_DEPTH ||
                        loadBalancePolicy == DSM_LB_LEAST_BLOCKS) {

                        if (devInfo->TargetPortGroup && devInfo->ALUAState != DSM_DEV_ACTIVE_UNOPTIMIZED) {

                            TracePrint((TRACE_LEVEL_ERROR,
                                        TRACE_FLAG_WMI,
                                        "DsmpSetLoadBalancePolicy (DsmIds %p): Path (%u) specified in A/U state when TPG is in %u state (for LB %u).\n",
                                        DsmIds,
                                        inx,
                                        devInfo->ALUAState,
                                        loadBalancePolicy));

                            DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
                            status = STATUS_INVALID_PARAMETER;
                            break;
                        }
                    }
                }
            } else {

                if (optimized) {

                    //
                    // This is a standby path
                    //
                    devInfo->State = DSM_DEV_STANDBY;

                } else {

                    //
                    // This is unavailable path
                    //
                    devInfo->State = DSM_DEV_UNAVAILABLE;
                }

                //
                // For RR, LQD, LB and WP, all paths must be in A/O state for non-ALUA
                // storage. For ALUA storage, the only time path states can be in
                // S/B or U/A is if the TPG itself is in that state.
                //
                if (loadBalancePolicy == DSM_LB_ROUND_ROBIN ||
                    loadBalancePolicy == DSM_LB_WEIGHTED_PATHS ||
                    loadBalancePolicy == DSM_LB_DYN_LEAST_QUEUE_DEPTH ||
                    loadBalancePolicy == DSM_LB_LEAST_BLOCKS) {

                    if ((!devInfo->TargetPortGroup) ||
                        (devInfo->TargetPortGroup && devInfo->State != devInfo->ALUAState)) {

                        //
                        // No paths can be in SB or UA unless its TPG is in that state.
                        //
                        TracePrint((TRACE_LEVEL_ERROR,
                                    TRACE_FLAG_WMI,
                                    "DsmpSetLoadBalancePolicy (DsmIds %p): Path (%u) specified in non-active state for LB %u.\n",
                                    DsmIds,
                                    inx,
                                    loadBalancePolicy));

                        DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
                        status = STATUS_INVALID_PARAMETER;
                        break;
                    }
                } else if (loadBalancePolicy == DSM_LB_ROUND_ROBIN_WITH_SUBSET) {

                    //
                    // It is okay to set a path to be in S/B or U/A state in RRWS
                    // if either the storage is non-ALUA, or if the storage is
                    // ALUA but the TPG is in A/O (where it can be masked) or the
                    // TPG is in the state that the path is being set to.
                    //
                    if ((devInfo->TargetPortGroup) &&
                        (devInfo->ALUAState != DSM_DEV_ACTIVE_OPTIMIZED && devInfo->State != devInfo->ALUAState)) {

                        //
                        // No paths can be in SB or UA unless its TPG is in that state.
                        //
                        TracePrint((TRACE_LEVEL_ERROR,
                                    TRACE_FLAG_WMI,
                                    "DsmpSetLoadBalancePolicy (DsmIds %p): Path (%u) (in TPG state %u) can't be specified in non-active state for LB %u.\n",
                                    DsmIds,
                                    inx,
                                    devInfo->ALUAState,
                                    loadBalancePolicy));

                        DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
                        status = STATUS_INVALID_PARAMETER;
                        break;
                    }
                }
            }
        }

        inx++;
    }

    if (NT_SUCCESS(status)) {


        //
        // If we arrive here, that means DsmpValidateSetLBPolicyInput already returned success.
        // The device info is found.
        //
        _Analysis_assume_(tempDevInfo != NULL);

        //
        // There must be at least one AO path. Unless there are no A/O TPGs.
        // eg. During a controller failover, it is possible that the TPG through
        // the TPG through other controller is still in non-A/O state and the
        // storage supports implicit transitions and is still in the midst of
        // making the transition of the non-A/O TPG to A/O. During such windows
        // the states for all paths will be non-A/O and there's nothing that can
        // be done about it. This is not an error condition.
        //
        if (!activePaths) {

            if ((tempDevInfo->ALUASupport == DSM_DEVINFO_ALUA_NOT_SUPPORTED) ||
                (tempDevInfo->ALUASupport != DSM_DEVINFO_ALUA_NOT_SUPPORTED && activeTPGs)) {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpSetLoadBalancePolicy (DsmIds %p): No active node given for LB %u.\n",
                            DsmIds,
                            loadBalancePolicy));

                //
                // Roll back to DeviceState to the state it was before
                // processing this SetLB policy request
                //
                DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);

                status = STATUS_INVALID_PARAMETER;
            }
        }
    }

    if (NT_SUCCESS(status)) {

        //
        // If we arrive here, that means DsmpValidateSetLBPolicyInput already returned success.
        // The device info is found.
        //
        _Analysis_assume_(tempDevInfo != NULL);

        //
        // If device supports explicit transitions, we need to send down an
        // STPG to enforce A/O path selection if we need to make a path in a
        // non-A/O TPG active/optimized.
        //
        if (tempDevInfo->ALUASupport >= DSM_DEVINFO_ALUA_EXPLICIT && sendSTPG) {

            PUCHAR targetPortGroupsInfo = NULL;
            ULONG targetPortGroupsInfoLength = 0;
            PSPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR tpgDescriptor = NULL;

            //
            // Build the target port groups info to set the new states.
            // Send down an STPG for TPG descriptors for those devInfos' TPGs
            // that need to be in AO state. If this causes side-effects in
            // state transitions (these can't be considered implicit according
            // to the spec), fake the devInfo states to what was selected.
            //
            targetPortGroupsInfoLength = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE +
                                         activePaths * sizeof(SPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR);

            targetPortGroupsInfo = DsmpAllocatePool(NonPagedPoolNx,
                                                    targetPortGroupsInfoLength,
                                                    DSM_TAG_TARGET_PORT_GROUPS);

            if (targetPortGroupsInfo) {

                PDSM_DEVICE_INFO devInfoToUse = NULL;

                //
                // Set the new asymmetric access states for the the devices' target port groups
                //
                tpgDescriptor = (PSPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR)(targetPortGroupsInfo + SPC3_TARGET_PORT_GROUPS_HEADER_SIZE);

                for (inx = 0, jnx = 0;
                     inx < ((PDSM_Load_Balance_Policy_V2)supportedLBPolicies)->DSMPathCount;
                     inx++) {

                    if (DsmWmiVersion == DSM_WMI_VERSION_1) {

                        dsmPath = (PVOID)&(((PDSM_Load_Balance_Policy)supportedLBPolicies)->DSM_Paths[inx]);

                    } else {

                        dsmPath = &(((PDSM_Load_Balance_Policy_V2)supportedLBPolicies)->DSM_Paths[inx]);
                    }

                    devInfo = (PDSM_DEVICE_INFO)dsmPath->Reserved;

                    if (!devInfo) {

                        continue;
                    }

                    if (devInfo->State == DSM_DEV_ACTIVE_OPTIMIZED) {

                        tpgDescriptor->AsymmetricAccessState = devInfo->State;
                        REVERSE_BYTES_SHORT(&tpgDescriptor->TPG_Identifier, &devInfo->TargetPortGroup->Identifier);

                        tpgDescriptor = (PSPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR)((PUCHAR)tpgDescriptor + sizeof(SPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR));

                        jnx++;
                    }

                    if (devInfo->TempPreviousStateForLB == DSM_DEV_ACTIVE_OPTIMIZED) {

                        devInfoToUse = devInfo;
                    }
                }

                NT_ASSERT(jnx == numberDevInfoChanged);
                NT_ASSERT(devInfoToUse);

                if (devInfoToUse) {

                    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                    status = DsmpSetTargetPortGroups(devInfoToUse->TargetObject,
                                                     targetPortGroupsInfo,
                                                     targetPortGroupsInfoLength);

                    if (NT_SUCCESS(status)) {

                        DsmpFreePool(targetPortGroupsInfo);
                        targetPortGroupsInfo = NULL;
                        targetPortGroupsInfoLength = 0;
                        status = DsmpReportTargetPortGroups(devInfoToUse->TargetObject,
                                                            &targetPortGroupsInfo,
                                                            &targetPortGroupsInfoLength);
                    } else {

                        TracePrint((TRACE_LEVEL_ERROR,
                                    TRACE_FLAG_WMI,
                                    "DsmpSetLoadBalancePolicy (DsmIds %p): STPG failed with status %x.\n",
                                    DsmIds,
                                    status));

                        DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
                    }

                    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
                }

                if (NT_SUCCESS(status)) {

                    ULONG index;
                    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroup;

                    status = DsmpParseTargetPortGroupsInformation(DsmContext,
                                                                  groupEntry,
                                                                  targetPortGroupsInfo,
                                                                  targetPortGroupsInfoLength);

                    NT_ASSERT(NT_SUCCESS(status));

                    for (index = 0; index < DSM_MAX_PATHS; index++) {

                        targetPortGroup = groupEntry->TargetPortGroupList[index];

                        if (targetPortGroup) {

                            DsmpUpdateTargetPortGroupDevicesStates(targetPortGroup, targetPortGroup->AsymmetricAccessState);
                        }
                    }

                    //
                    // Update TPGs with new state
                    //
                    for (inx = 0;
                         inx < ((PDSM_Load_Balance_Policy_V2)supportedLBPolicies)->DSMPathCount;
                         inx++) {

                        if (DsmWmiVersion == DSM_WMI_VERSION_1) {

                            dsmPath = (PVOID)&(((PDSM_Load_Balance_Policy)supportedLBPolicies)->DSM_Paths[inx]);

                        } else {

                            dsmPath = &(((PDSM_Load_Balance_Policy_V2)supportedLBPolicies)->DSM_Paths[inx]);
                        }

                        devInfo = (PDSM_DEVICE_INFO)dsmPath->Reserved;

                        if (devInfo) {

                            //
                            // An explicit state transition can cause TPGs that were not specified
                            // in the parameter list to also change (this is not considered to be
                            // an implicit transition. It is SPC3 behavior and we must take
                            // this into consideration and update the devInfo states.
                            // This is an unfortunate side-effect in that the Admin may not get
                            // the paths to be in the exact states that he has set.
                            //
                            if (devInfo->State == DSM_DEV_ACTIVE_OPTIMIZED) {

                                if (devInfo->ALUAState == DSM_DEV_ACTIVE_UNOPTIMIZED ||
                                    devInfo->ALUAState == DSM_DEV_STANDBY ||
                                    devInfo->ALUAState == DSM_DEV_UNAVAILABLE) {

                                    //
                                    // An A/O TPG's devInfos can be masked as A/U.
                                    // However, the reverse the is not true (ie. we can't
                                    // mark a non-A/O TPG's devInfo(s) to be in A/O state.
                                    //
                                    devInfo->State = devInfo->ALUAState;
                                }
                            }

                            //
                            // The devInfo->State has already been set. Update its previous state.
                            //
                            devInfo->PreviousState = devInfo->TempPreviousStateForLB;
                        }
                    }

                    NT_ASSERT(jnx == numberDevInfoChanged);
                }

            } else {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpSetLoadBalancePolicy (DsmIds %p): Failed to allocate targetPortGroupsInfo.\n",
                            DsmIds));

                status = STATUS_INSUFFICIENT_RESOURCES;
            }
        }

        if (NT_SUCCESS(status)) {

            groupEntry->LoadBalanceType = loadBalancePolicy;

            if (loadBalancePolicy == DSM_LB_FAILOVER) {

                groupEntry->PreferredPath = preferredPath;
            }

            savedLBSettings = DsmpCopyLoadBalancePolicies(groupEntry,
                                                          DsmWmiVersion,
                                                          supportedLBPolicies);

        } else {

            //
            // Roll back to DeviceState to the state it was before
            // processing this SetLB policy request
            //
            DsmpRestorePreviousDeviceState(supportedLBPolicies, DsmWmiVersion);
        }
    }

    if (NT_SUCCESS(status)) {

        //
        // LUN's LB policy has been explicitly set by Admin
        //
        groupEntry->LBPolicySelection = DSM_DEFAULT_LB_POLICY_LUN_EXPLICIT;

        //
        // Update the states and if appropriate, the path weight
        //
        DsmpUpdateDesiredStateAndWeight(groupEntry,
                                        DsmWmiVersion,
                                        supportedLBPolicies);

        //
        // Update the next path to be used for the group
        //
        devInfo = DsmpGetActivePathToBeUsed(groupEntry,
                                            DsmpIsSymmetricAccess(tempDevInfo),
                                            SpecialHandlingFlag);
        if (devInfo != NULL) {

            InterlockedExchangePointer(&(groupEntry->PathToBeUsed), (PVOID)devInfo->FailGroup);
        } else {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpSetLoadBalancePolicy (DsmIds %p): After setting LB policy No FOG available for group %p\n",
                        DsmIds,
                        groupEntry));

            InterlockedExchangePointer(&(groupEntry->PathToBeUsed), NULL);
        }
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

    if (NT_SUCCESS(status) && savedLBSettings) {

        DsmpPersistLBSettings(savedLBSettings);

        DsmpFreePool(savedLBSettings);
    }

__Exit_DsmpSetLoadBalancePolicy:

    if (DsmWmiVersion == DSM_WMI_VERSION_1) {

        ((PDsmSetLoadBalancePolicy_OUT)setLoadBalancePolicyOUT)->Status = status;

    } else {

        setLoadBalancePolicyOUT->Status = status;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetLoadBalancePolicy (DsmIds %p): Exiting function with status 0x%x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmpValidateSetLBPolicyInput(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds,
    _In_ IN ULONG        DsmWmiVersion,
    _In_ IN PVOID        SetLoadBalancePolicyIN,
    _In_ IN ULONG        InBufferSize
    )
/*++

Routine Description:

    This routine validates the input buffer given for setting
    Load Balance policy

Arguements:

    DsmContext - DSM Global Context
    DsmIds - DSM Ids for the given device
    DsmWmiVersion - version of the MPIO_DSM_Path class to use
    SetLoadBalancePolicyIN - Describes the load balance policy to be set
    InBufferSize - Number of bytes in SetLoadBalancePolicyIN

Return Value:

    STATUS_SUCCESS - if the input buffer is well formed
    Appropriate error status if the input buffer is malformed.

--*/
{
    PDSM_Load_Balance_Policy_V2 supportedLBPolicies;
    PMPIO_DSM_Path_V2 dsmPath0;
    PMPIO_DSM_Path_V2 dsmPath1;
    NTSTATUS status = STATUS_SUCCESS;
    ULONG inx;
    ULONG jnx;
    ULONG sizeNeeded;
    KIRQL irql;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpValidateSetLBPolicyInput (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // Validate the input buffer for setting Load Balance policy
    //
    if (DsmWmiVersion > DSM_WMI_VERSION_1) {

        sizeNeeded = FIELD_OFFSET(DSM_Load_Balance_Policy_V2, DSM_Paths);

    } else {

        sizeNeeded = FIELD_OFFSET(DSM_Load_Balance_Policy, DSM_Paths);
    }

    if (InBufferSize < sizeNeeded) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpValidateSetLBPolicyInput (DsmIds %p): Insufficient buffer in SetLB. Expected %d, Given %d.\n",
                    DsmIds,
                    sizeNeeded,
                    InBufferSize));

        status = STATUS_BUFFER_TOO_SMALL;
        goto __Exit_DsmpValidateSetLBPolicyInput;
    }

    if (DsmWmiVersion == DSM_WMI_VERSION_1) {

        supportedLBPolicies = (PVOID)&(((PDsmSetLoadBalancePolicy_IN)SetLoadBalancePolicyIN)->LoadBalancePolicy);

        sizeNeeded += supportedLBPolicies->DSMPathCount * sizeof(MPIO_DSM_Path);

    } else {

        supportedLBPolicies = &(((PDsmSetLoadBalancePolicyALUA_IN)SetLoadBalancePolicyIN)->LoadBalancePolicy);

        sizeNeeded += supportedLBPolicies->DSMPathCount * sizeof(MPIO_DSM_Path_V2);
    }

    if (InBufferSize < sizeNeeded) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpValidateSetLBPolicyInput (DsmIds %p): Insufficient buffer in SetLB. Expected %d, Given %d.\n",
                    DsmIds,
                    sizeNeeded,
                    InBufferSize));

        status = STATUS_BUFFER_TOO_SMALL;
        goto __Exit_DsmpValidateSetLBPolicyInput;
    }

    if (supportedLBPolicies->Version > DSM_WMI_VERSION) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpValidateSetLBPolicyInput (DsmIds %p): WMI Version mismatch. Expected %d, Given %d.\n",
                    DsmIds,
                    DSM_WMI_VERSION,
                    supportedLBPolicies->Version));

        status = DSM_UNSUPPORTED_VERSION;
        goto __Exit_DsmpValidateSetLBPolicyInput;

    } else if (supportedLBPolicies->Version < DSM_WMI_VERSION) {

        ULONG dsmWmiVersion = DSM_WMI_VERSION;
        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_WMI,
                    "DsmpValidateSetLBPolicyInput (DsmIds %p): Use of older management app (WMI-Version %x) with newer DSM (WMI-Version %x).\n",
                    DsmIds,
                    supportedLBPolicies->Version,
                    dsmWmiVersion));

        NT_ASSERT(supportedLBPolicies->Version == DSM_WMI_VERSION);
    }

    if ((supportedLBPolicies->LoadBalancePolicy < DSM_LB_FAILOVER) ||
        (supportedLBPolicies->LoadBalancePolicy > DSM_LB_LEAST_BLOCKS)) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpValidateSetLBPolicyInput (DsmIds %p): Invalid LB Policy %d.\n",
                    DsmIds,
                    supportedLBPolicies->LoadBalancePolicy));

        status = DSM_INVALID_LOAD_BALANCE_POLICY;
        goto __Exit_DsmpValidateSetLBPolicyInput;
    }

    //
    // It is expected that the user provide LB policy settings
    // for all the paths and not just a subset of the paths.
    //
    if (supportedLBPolicies->DSMPathCount != DsmIds->Count) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpValidateSetLBPolicyInput (DsmIds %p): Path Count %d not equal to DSM IDs count %d.\n",
                    DsmIds,
                    supportedLBPolicies->DSMPathCount,
                    DsmIds->Count));

        status = STATUS_INVALID_PARAMETER;
        goto __Exit_DsmpValidateSetLBPolicyInput;
    }

    //
    // Make sure user did not provide duplicate path ids
    //
    for (inx = 0; inx < supportedLBPolicies->DSMPathCount && NT_SUCCESS(status); inx++) {

        if (DsmWmiVersion == DSM_WMI_VERSION_1) {

            dsmPath0 = (PVOID)&(((PDSM_Load_Balance_Policy)supportedLBPolicies)->DSM_Paths[inx]);

        } else {

            dsmPath0 = &(supportedLBPolicies->DSM_Paths[inx]);
        }

        dsmPath0->Reserved = 0;

        for (jnx = 0; jnx < supportedLBPolicies->DSMPathCount; jnx++) {

            if (DsmWmiVersion == DSM_WMI_VERSION_1) {

                dsmPath1 = (PVOID)&(((PDSM_Load_Balance_Policy)supportedLBPolicies)->DSM_Paths[jnx]);

            } else {

                dsmPath1 = &(supportedLBPolicies->DSM_Paths[jnx]);
            }

            if ((inx != jnx) &&
                ((dsmPath0->DsmPathId == dsmPath1->DsmPathId) && (dsmPath1->DsmPathId != 0))) {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpValidateSetLBPolicyInput (DsmIds %p): Duplicate path id %I64x at %d and %d.\n",
                            DsmIds,
                            dsmPath0->DsmPathId,
                            inx,
                            jnx));

                status = STATUS_INVALID_PARAMETER;

                break;
            }
        }
    }

    if (NT_SUCCESS(status)) {

        PDSM_DEVICE_INFO devInfo;
        PDSM_FAILOVER_GROUP foGroup;
        PVOID pathId;
        BOOLEAN foundPath;

        irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

        //
        // Make sure the user has provided path id corresponding
        // to all the DSM IDs given to us.
        //
        for (inx = 0; inx < DsmIds->Count; inx++) {

            devInfo = DsmIds->IdList[inx];

            if (!DsmpIsDeviceInitialized(devInfo)) {

                continue;
            }

            foGroup = devInfo->FailGroup;
            if (!foGroup) {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpValidateSetLBPolicyInput (DsmIds %p): FO Group NULL for %p at index %d.\n",
                            DsmIds,
                            devInfo,
                            inx));

                status = STATUS_INVALID_PARAMETER;

                break;
            }

            foundPath = FALSE;

            for (jnx = 0; jnx < supportedLBPolicies->DSMPathCount; jnx++) {

                if (DsmWmiVersion == DSM_WMI_VERSION_1) {

                    dsmPath0 = (PVOID)&(((PDSM_Load_Balance_Policy)supportedLBPolicies)->DSM_Paths[jnx]);

                } else {

                    dsmPath0 = &(supportedLBPolicies->DSM_Paths[jnx]);
                }

                pathId = (PVOID) dsmPath0->DsmPathId;
                if (foGroup->PathId == pathId) {

                    //
                    // Found the device info corresponding to the given path.
                    // Use the reserved field in MPIO_DSM_Path to store
                    // the pointer to the device info. Device Info is used
                    // later on to set the load balance policy for the device.
                    //
                    foundPath = TRUE;

                    dsmPath0->Reserved = (ULONG_PTR) devInfo;

                    //
                    // If ALUA, RoundRobin is not an allowed LB policy since not all paths can
                    // be in A/O state. RRWS must be used instead.
                    //
                    if (supportedLBPolicies->LoadBalancePolicy == DSM_LB_ROUND_ROBIN && !DsmpIsSymmetricAccess(devInfo)) {

                        status = DSM_INVALID_LOAD_BALANCE_POLICY;

                        TracePrint((TRACE_LEVEL_ERROR,
                                    TRACE_FLAG_WMI,
                                    "DsmpValidateSetLBPolicyInput (DsmIds %p): Invalid LB policy for ALUA. Status %x.\n",
                                    DsmIds,
                                    status));
                    }

                    break;
                }
            }

            if (!foundPath) {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpValidateSetLBPolicyInput (DsmIds %p): Failed to find path %p for %p at index %d.\n",
                            DsmIds,
                            foGroup->PathId,
                            devInfo,
                            inx));

                status = STATUS_INVALID_PARAMETER;

                break;
            }
        }

        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
    }

__Exit_DsmpValidateSetLBPolicyInput:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpValidateSetLBPolicyInput (DsmIds %p): Exiting function with status %x.\n",
                DsmIds,
                status));

    return status;
}


VOID
DsmpSaveDeviceState(
    _In_ IN PVOID SupportedLBPolicies,
    _In_ IN ULONG DsmWmiVersion
    )
/*+++

Routine Description:

    This routine saves the current Load Balance policy settings.
    If there is any error while setting the new policy given
    by the user, the saved values will be used to restore
    the old state.

    Note: This routine MUST be called with DsmContextLock held in Exclusive mode.

Arguements:

    SupportedLBPolicies - New Load Balance policy values
    DsmWmiVersion - version of the MPIO_DSM_Path class to use

Return Value:

    None
--*/
{
    PDSM_DEVICE_INFO devInfo;
    PMPIO_DSM_Path_V2 dsmPath;
    ULONG inx;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSaveDeviceState (LBP %p): Entering function.\n",
                SupportedLBPolicies));

    inx = 0;

    while (inx < ((PDSM_Load_Balance_Policy_V2)SupportedLBPolicies)->DSMPathCount) {

        if (DsmWmiVersion == DSM_WMI_VERSION_1) {

            dsmPath = (PVOID)&(((PDSM_Load_Balance_Policy)SupportedLBPolicies)->DSM_Paths[inx]);

        } else {

            dsmPath = &(((PDSM_Load_Balance_Policy_V2)SupportedLBPolicies)->DSM_Paths[inx]);
        }

        devInfo = (PDSM_DEVICE_INFO)dsmPath->Reserved;

        if (devInfo) {

            devInfo->TempPreviousStateForLB = devInfo->State;
        }

        inx++;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSaveDeviceState (LBP %p): Exiting function.\n",
                SupportedLBPolicies));

    return;
}


VOID
DsmpRestorePreviousDeviceState(
    _In_ IN PVOID SupportedLBPolicies,
    _In_ IN ULONG DsmWmiVersion
    )
/*++

Routine Description:

    This routine restores the old Load Balance policy settings.
    If there is any error while setting the new policy given
    by the user, the old state is restored from the saved state.

    Note: This routine MUST be called with DsmContextLock held in Exclusive mode.

Arguements:

    SupportedLBPolicies - New Load Balance policy values
    DsmWmiVersion - version of the MPIO_DSM_Path class to use

Return Value:

    None
--*/
{
    PDSM_DEVICE_INFO devInfo;
    PMPIO_DSM_Path_V2 dsmPath;
    ULONG inx;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpRestorePreviousDeviceState (LBP %p): Entering function.\n",
                SupportedLBPolicies));

    inx = 0;

    while (inx < ((PDSM_Load_Balance_Policy_V2)SupportedLBPolicies)->DSMPathCount) {

        if (DsmWmiVersion == DSM_WMI_VERSION_1) {

            dsmPath = (PVOID)&(((PDSM_Load_Balance_Policy)SupportedLBPolicies)->DSM_Paths[inx]);

        } else {

            dsmPath = &(((PDSM_Load_Balance_Policy_V2)SupportedLBPolicies)->DSM_Paths[inx]);
        }

        devInfo = (PDSM_DEVICE_INFO)dsmPath->Reserved;

        if (devInfo) {

            devInfo->State = devInfo->TempPreviousStateForLB;
        }

        inx++;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpRestorePreviousDeviceState (LBP %p): Exiting function.\n",
                SupportedLBPolicies));

    return;
}


VOID
DsmpUpdateDesiredStateAndWeight(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG DsmWmiVersion,
    _In_ IN PVOID SupportedLBPolicies
    )
/*++

Routine Description:

    This routine updates the desired state and path weights
    based on admin's LB selection.

    Note: This routine MUST be called with DsmContextLock held in Exclusive mode.

Arguements:

    Group - The group entry correponding to the pseudo-LUN.
    SupportedLBPolicies - New Load Balance policy values
    DsmWmiVersion - version of the MPIO_DSM_Path class to use

Return Value:

    None
--*/
{
    PMPIO_DSM_Path_V2 dsmPath;
    PDSM_DEVICE_INFO devInfo;
    ULONG inx;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpUpdatedDesiredState (Group %p): Entering function.\n",
                Group));

    inx = 0;
    while (inx < ((PDSM_Load_Balance_Policy_V2)SupportedLBPolicies)->DSMPathCount) {

        if (DsmWmiVersion == DSM_WMI_VERSION_1) {

            dsmPath = (PVOID)&(((PDSM_Load_Balance_Policy)SupportedLBPolicies)->DSM_Paths[inx]);

        } else {

            dsmPath = &(((PDSM_Load_Balance_Policy_V2)SupportedLBPolicies)->DSM_Paths[inx]);
        }

        devInfo = (PDSM_DEVICE_INFO) dsmPath->Reserved;

        if (!devInfo) {

            inx++;
            continue;
        }

        DSM_ASSERT(devInfo->DeviceSig == DSM_DEVICE_SIG);
        NT_ASSERT(devInfo->Group == Group);

        //
        // We'll honor the chosen path for FOO for ALUA storage
        // since we know for a fact that the Admin has chosen the path.
        // We'll also honor path state in RRWS if it is different from TPG state
        // as that too is an indication that it was explicitly selected.
        //
        if ((DsmpIsSymmetricAccess(devInfo)) ||
            (Group->LoadBalanceType == DSM_LB_FAILOVER) ||
            (!DsmpIsSymmetricAccess(devInfo) && Group->LoadBalanceType == DSM_LB_ROUND_ROBIN_WITH_SUBSET && devInfo->State != devInfo->ALUAState)) {

            //
            // Check if this is the primary path or a standby path
            //
            if (dsmPath->PrimaryPath) {

                devInfo->DesiredState = DSM_DEV_ACTIVE_OPTIMIZED;

                if (DsmWmiVersion > DSM_WMI_VERSION_1) {

                    if (!dsmPath->OptimizedPath) {

                        devInfo->DesiredState = DSM_DEV_ACTIVE_UNOPTIMIZED;
                    }
                }

            } else {

                devInfo->DesiredState = DSM_DEV_STANDBY;

                if (DsmWmiVersion > DSM_WMI_VERSION_1) {

                    if (!dsmPath->OptimizedPath) {

                        devInfo->DesiredState = DSM_DEV_UNAVAILABLE;
                    }
                }
            }
        } else {

            devInfo->DesiredState = DSM_DEV_UNDETERMINED;
        }

        if (Group->LoadBalanceType == DSM_LB_WEIGHTED_PATHS) {

            devInfo->PathWeight = dsmPath->PathWeight;
        }

        inx++;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpUpdatedDesiredState (Group %p): Exiting function.\n",
                Group));

    return;
}


NTSTATUS
DsmpQueryDevicePerf(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ PDSM_IDS DsmIds,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    )
/*++

Routine Description:

    This routine returns the perf counters for each path for the
    device that corresponds to the passed in DsmIds.

Arguements:

    DsmContext - Global DSM context
    DsmIds - DSM Ids for the given device
    InBufferSize - Size of the input buffer
    OutBufferSize - Size of the output buffer
    Buffer - Buffer in which the current Load Balance policy settings
             is returned, if the buffer is big enough

Return Value:

   STATUS_SUCCESS on success
   Appropriate error code on error.

--*/
{
    NTSTATUS status = STATUS_SUCCESS;
    PDSM_DEVICE_INFO devInfo;
    ULONG sizeNeeded;
    PMSDSM_DEVICE_PERF devicePerf;
    ULONG i;
    PMSDSM_DEVICEPATH_PERF pathPerf;
    KIRQL irql;

    UNREFERENCED_PARAMETER(InBufferSize);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryDevicePerf (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // At least one device should be given
    //
    if (DsmIds->Count == 0) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryDevicePerf (DsmIds %p): No DSM Ids given.\n",
                    DsmIds));

        *OutBufferSize = 0;
        status = STATUS_INVALID_PARAMETER;

        goto __Exit_DsmpQueryDevicePerf;
    }

    sizeNeeded = AlignOn8Bytes(FIELD_OFFSET(MSDSM_DEVICE_PERF, PerfInfo));
    sizeNeeded += (DsmIds->Count * sizeof(MSDSM_DEVICEPATH_PERF));

    if (*OutBufferSize < sizeNeeded) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryDevicePerf (DsmIds %p): Output buffer too small for QueryLBPolicy.\n",
                    DsmIds));

        *OutBufferSize = sizeNeeded;
        status = STATUS_BUFFER_TOO_SMALL;

        goto __Exit_DsmpQueryDevicePerf;
    }

    //
    // Zero out the output buffer first
    //
    RtlZeroMemory(Buffer, sizeNeeded);

#if DBG
    devInfo = DsmIds->IdList[0];
    DSM_ASSERT(devInfo);
    DSM_ASSERT(devInfo->DeviceSig == DSM_DEVICE_SIG);
#endif

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    devicePerf = (PMSDSM_DEVICE_PERF)Buffer;
    devicePerf->NumberPaths = DsmIds->Count;

    //
    // For each path, get the stats info
    //
    for (i = 0; i < DsmIds->Count; i++) {

        pathPerf = &devicePerf->PerfInfo[i];
        devInfo = DsmIds->IdList[i];

        if (DsmpIsDeviceInitialized(devInfo)) {

            pathPerf->PathId = (ULONGLONG)((ULONG_PTR)((devInfo->FailGroup)->PathId));
            pathPerf->NumberReads = (devInfo->DeviceStats).NumberReads;
            pathPerf->NumberWrites = (devInfo->DeviceStats).NumberWrites;
            pathPerf->BytesRead = (devInfo->DeviceStats).BytesRead;
            pathPerf->BytesWritten = (devInfo->DeviceStats).BytesWritten;
        }
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

    *OutBufferSize = sizeNeeded;

__Exit_DsmpQueryDevicePerf:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryDevicePerf (DsmIds %p): Exiting function with status %x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmpClearPerfCounters(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmIds
    )
/*++

Routine Description:

    This routine clears the perf counters for each path for the
    device that corresponds to the passed in DsmIds.

Arguements:

    DsmContext - Global DSM context
    DsmIds - DSM Ids for the given device

Return Value:

   STATUS_SUCCESS on success
   Appropriate error code on error.

--*/
{
    NTSTATUS status = STATUS_SUCCESS;
    PDSM_DEVICE_INFO devInfo;
    KIRQL irql;
    ULONG i;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpClearPerfCounters (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // At least one device should be given
    //
    if (DsmIds->Count == 0) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpClearPerfCounters (DsmIds %p): No DSM Ids given.\n",
                    DsmIds));

        status = STATUS_INVALID_PARAMETER;

        goto __Exit_DsmpClearPerfCounters;
    }

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    for (i = 0; i < DsmIds->Count; i++) {

        devInfo = DsmIds->IdList[i];
        DSM_ASSERT(devInfo);
        DSM_ASSERT(devInfo->DeviceSig == DSM_DEVICE_SIG);

        if (devInfo) {
            (devInfo->DeviceStats).BytesRead = 0;
            (devInfo->DeviceStats).BytesWritten = 0;
            (devInfo->DeviceStats).NumberReads = 0;
            (devInfo->DeviceStats).NumberWrites = 0;
        }
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

__Exit_DsmpClearPerfCounters:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpClearPerfCounters (DsmIds %p): Exiting function with status %x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmpQuerySupportedDevicesList(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    )
/*++

Routine Description:

    This routine returns the list of devices that are supported by MSDSM.

Arguements:

    DsmContext - Global DSM context
    InBufferSize - Size of the input buffer
    OutBufferSize - Size of the output buffer
    Buffer - Buffer in which the current Load Balance policy settings
             is returned, if the buffer is big enough

Return Value:

   STATUS_SUCCESS on success
   Appropriate error code on error.

--*/
{
    NTSTATUS status;
    ULONG sizeNeeded;
    PMSDSM_SUPPORTED_DEVICES_LIST supportedDeviceIds;
    PWSTR szIndex;
    PWSTR deviceIdIndex;
    ULONG numberDeviceIds = 0;
    ULONG index = 0;
    KIRQL oldIrql;
    PWSTR tempBuffer = NULL;

    UNREFERENCED_PARAMETER(InBufferSize);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQuerySupportedDevicesList (DsmContext %p): Entering function.\n",
                DsmContext));

    //
    // It is possible that manually changes to the registry weren't yet picked up,
    // so query for the list in its current state. Failure to get this list is not
    // fatal, so ignore errors.
    //
#if DBG
    status = DsmpGetDeviceList(DsmContext);
    NT_ASSERT(NT_SUCCESS(status));
#else
    DsmpGetDeviceList(DsmContext);
#endif

    //
    // Since it is possible that this list may change if a new device arrival
    // gets processed at the same time as this query being processed, we need
    // to protect it.
    //
    KeAcquireSpinLock(&DsmContext->SupportedDevicesListLock, &oldIrql);

    tempBuffer = DsmpAllocatePool(NonPagedPoolNx, DsmContext->SupportedDevices.MaximumLength, DSM_TAG_REG_VALUE_RELATED);

    if (tempBuffer) {

        RtlCopyMemory(tempBuffer, DsmContext->SupportedDevices.Buffer, DsmContext->SupportedDevices.Length);

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQuerySupportedDevicesList (DsmContext %p): Failed to allocate temporary list.\n",
                    DsmContext));

        status = STATUS_INSUFFICIENT_RESOURCES;
        KeReleaseSpinLock(&DsmContext->SupportedDevicesListLock, oldIrql);

        goto __Exit_DsmpQuerySupportedDevicesList;
    }

    KeReleaseSpinLock(&DsmContext->SupportedDevicesListLock, oldIrql);

    status = STATUS_SUCCESS;
    szIndex = tempBuffer;

    sizeNeeded = AlignOn8Bytes(FIELD_OFFSET(MSDSM_SUPPORTED_DEVICES_LIST, DeviceId));

    if (szIndex) {

        while (*szIndex) {

            szIndex += wcslen(szIndex) + 1;
            numberDeviceIds++;
        }

        sizeNeeded += numberDeviceIds * (MSDSM_MAX_DEVICE_ID_SIZE + sizeof(WNULL));
    }

    if (*OutBufferSize < sizeNeeded) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQuerySupportedDevicesList (DsmContext %p): Output buffer too small for QuerySupportedDevicesList.\n",
                    DsmContext));

        *OutBufferSize = sizeNeeded;
        status = STATUS_BUFFER_TOO_SMALL;

        goto __Exit_DsmpQuerySupportedDevicesList;
    }

    //
    // Zero out the output buffer first
    //
    RtlZeroMemory(Buffer, sizeNeeded);

    *OutBufferSize = sizeNeeded;

    supportedDeviceIds = (PMSDSM_SUPPORTED_DEVICES_LIST)Buffer;
    supportedDeviceIds->NumberDevices = numberDeviceIds;

    for (index = 0, szIndex = tempBuffer, deviceIdIndex = supportedDeviceIds->DeviceId;
         index < numberDeviceIds;
         index++, szIndex += wcslen(szIndex) + 1, deviceIdIndex += MSDSM_MAX_DEVICE_ID_LENGTH) {

        *((PUSHORT)deviceIdIndex) = MSDSM_MAX_DEVICE_ID_SIZE;
        deviceIdIndex++;

        RtlStringCchCopyW(deviceIdIndex,
                          MSDSM_MAX_DEVICE_ID_LENGTH - 1,
                          szIndex);
    }

__Exit_DsmpQuerySupportedDevicesList:

    if (tempBuffer) {
        DsmpFreePool(tempBuffer);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQuerySupportedDevicesList (DsmContext %p): Exiting function with status %x.\n",
                DsmContext,
                status));

    return status;
}


NTSTATUS
DsmpQueryTargetsDefaultPolicy(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    )
/*++

Routine Description:

    This routine is used to build the target list (for which the override default LB policy
    was explicitly set), by querying the services key for the subkeys under
    "msdsm\Parameters\DsmTargetsLoadBalanceSetting"

Arguements:

    Context - The DSM Context value. It contains storage for the target hardware ids and their
              default policy info.
    InBufferSize - Size of the input buffer
    OutBufferSize - Size of the output buffer
    Buffer - Buffer in which the current targets whose default policy settings is returned, if the buffer is big enough

Return Value:

   STATUS_SUCCESS on success
   Appropriate error code on error.

--*/
{
    ULONG sizeNeeded;
    PMSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICY targetsPolicyInfo = (PMSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICY)Buffer;
    PMSDSM_TARGET_DEFAULT_POLICY_INFO targetPolicyInfo;
    HANDLE targetsLBSettingKey = NULL;
    NTSTATUS status;
    PKEY_FULL_INFORMATION keyFullInfo = NULL;
    ULONG length = sizeof(KEY_FULL_INFORMATION);
    ULONG numSubKeys = 0;
    WCHAR vidPid[25] = {0};
    PKEY_BASIC_INFORMATION keyBasicInfo = NULL;
    OBJECT_ATTRIBUTES objectAttributes;
    HANDLE targetKey = NULL;
    ULONG index = 0;
    RTL_QUERY_REGISTRY_TABLE queryTable[2];
    DSM_LOAD_BALANCE_TYPE loadBalanceType;
    ULONGLONG preferredPath = (ULONGLONG)((ULONG_PTR)MAXULONG);
    PWCHAR policyInfoIndex;
    UNICODE_STRING keyValueName;
    PKEY_VALUE_PARTIAL_INFORMATION keyValueInfo = NULL;

    UNREFERENCED_PARAMETER(InBufferSize);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryTargetsDefaultPolicy (Context %p): Entering function.\n",
                DsmContext));

    status = DsmpOpenTargetsLoadBalanceSettingKey(KEY_ALL_ACCESS, &targetsLBSettingKey);

    if (!NT_SUCCESS(status)) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to open Targets LB Setting key. Status %x.\n",
                    DsmContext,
                    status));

        goto __Exit_DsmpQueryTargetsDefaultPolicy;
    }

    //
    // Query for number of subkeys
    //
    do {
        if (keyFullInfo) {

            DsmpFreePool(keyFullInfo);
        }

        keyFullInfo = DsmpAllocatePool(NonPagedPoolNxCacheAligned, length, DSM_TAG_REG_KEY_RELATED);

        if (!keyFullInfo) {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to allocate resources for key full info.\n",
                        DsmContext));

            status = STATUS_INSUFFICIENT_RESOURCES;
            goto __Exit_DsmpQueryTargetsDefaultPolicy;
        }

        status = ZwQueryKey(targetsLBSettingKey,
                            KeyFullInformation,
                            keyFullInfo,
                            length,
                            &length);

    } while (status == STATUS_BUFFER_TOO_SMALL || status == STATUS_BUFFER_OVERFLOW);

    if (!NT_SUCCESS(status)) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to query key. Status %x.\n",
                    DsmContext,
                    status));

        goto __Exit_DsmpQueryTargetsDefaultPolicy;
    }

    //
    // Calculate total buffer size required
    //
    numSubKeys = keyFullInfo->SubKeys;

    sizeNeeded = AlignOn8Bytes(FIELD_OFFSET(MSDSM_TARGETS_DEFAULT_LOAD_BALANCE_POLICY, TargetDefaultPolicyInfo));
    sizeNeeded += numSubKeys * sizeof(MSDSM_TARGET_DEFAULT_POLICY_INFO);

    if (*OutBufferSize < sizeNeeded) {

        *OutBufferSize = sizeNeeded;
        status = STATUS_BUFFER_TOO_SMALL;

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryTargetsDefaultPolicy (Context %p): Buffer insufficient. Status %x.\n",
                    DsmContext,
                    status));

        goto __Exit_DsmpQueryTargetsDefaultPolicy;
    }

    *OutBufferSize = sizeNeeded;
    RtlZeroMemory(Buffer, *OutBufferSize);

    targetsPolicyInfo->NumberDevices = numSubKeys;
    targetPolicyInfo = targetsPolicyInfo->TargetDefaultPolicyInfo;

    //
    // Now Enumerate all of the subkeys
    //
    for(index = 0; index < numSubKeys && NT_SUCCESS(status); index++) {

        UNICODE_STRING targetName;

        if (targetKey) {
            ZwClose(targetKey);
            targetKey = NULL;
        }

        length = sizeof(KEY_BASIC_INFORMATION);

        do {
            if (keyBasicInfo) {

                DsmpFreePool(keyBasicInfo);
            }

            keyBasicInfo = DsmpAllocatePool(NonPagedPoolNxCacheAligned,
                                            length,
                                            DSM_TAG_REG_KEY_RELATED);

            if (!keyBasicInfo) {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to allocate resources for key basic info.\n",
                            DsmContext));

                status = STATUS_INSUFFICIENT_RESOURCES;
                goto __Exit_DsmpQueryTargetsDefaultPolicy;
            }

            //
            // Enumerate the index'th subkey
            //
            status = ZwEnumerateKey(targetsLBSettingKey,
                                    index,
                                    KeyBasicInformation,
                                    keyBasicInfo,
                                    length,
                                    &length);

        } while (status == STATUS_BUFFER_TOO_SMALL || status == STATUS_BUFFER_OVERFLOW);

        //
        // Ignore errors - this is a best case effort.
        //
        if (!NT_SUCCESS(status)) {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to enumerate sub key's info. Status %x.\n",
                        DsmContext,
                        status));

            status = STATUS_SUCCESS;
            continue;
        }

        RtlZeroMemory(vidPid, sizeof(vidPid));
        RtlStringCbCopyNW(vidPid, sizeof(vidPid), keyBasicInfo->Name, keyBasicInfo->NameLength);
        RtlInitUnicodeString(&targetName, vidPid);

        //
        // Open a handle to the the target subkey.
        //
        InitializeObjectAttributes(&objectAttributes,
                                   &targetName,
                                   (OBJ_CASE_INSENSITIVE | OBJ_KERNEL_HANDLE),
                                   targetsLBSettingKey,
                                   (PSECURITY_DESCRIPTOR) NULL);

        status = ZwOpenKey(&targetKey,
                           KEY_ALL_ACCESS,
                           &objectAttributes);

        if (!NT_SUCCESS(status)) {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to open reg key %ws. Status %x.\n",
                        DsmContext,
                        vidPid,
                        status));

            goto __Exit_DsmpQueryTargetsDefaultPolicy;
        }

        RtlZeroMemory(queryTable, sizeof(queryTable));

        queryTable[0].Flags = RTL_QUERY_REGISTRY_DIRECT | RTL_QUERY_REGISTRY_REQUIRED | RTL_QUERY_REGISTRY_TYPECHECK;
        queryTable[0].Name = DSM_LOAD_BALANCE_POLICY;
        queryTable[0].EntryContext = &loadBalanceType;
        queryTable[0].DefaultType  = (REG_DWORD << RTL_QUERY_REGISTRY_TYPECHECK_SHIFT) | REG_NONE;

        status = RtlQueryRegistryValues(RTL_REGISTRY_HANDLE,
                                        targetKey,
                                        queryTable,
                                        targetKey,
                                        NULL);
        if (!NT_SUCCESS(status)) {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to query LB Policy for %ws - error %x.\n",
                        DsmContext,
                        vidPid,
                        status));
        } else {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpQueryTargetsDefaultPolicy (Context %p): LB Policy for %ws is %d.\n",
                        DsmContext,
                        vidPid,
                        loadBalanceType));

            RtlInitUnicodeString(&keyValueName, DSM_PREFERRED_PATH);

            length = sizeof(KEY_VALUE_PARTIAL_INFORMATION);

            do {
                DsmpFreePool(keyValueInfo);
                keyValueInfo = DsmpAllocatePool(NonPagedPoolNxCacheAligned, length, DSM_TAG_REG_KEY_RELATED);
                if (!keyValueInfo) {

                    status = STATUS_INSUFFICIENT_RESOURCES;

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_WMI,
                                "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to allocate resources for keyValueInfo (PP). Status %x.\n",
                                DsmContext,
                                status));

                    goto __Exit_DsmpQueryTargetsDefaultPolicy;
                }

                status = ZwQueryValueKey(targetKey,
                                         &keyValueName,
                                         KeyValuePartialInformation,
                                         keyValueInfo,
                                         length,
                                         &length);

            } while (status == STATUS_BUFFER_TOO_SMALL || status == STATUS_BUFFER_OVERFLOW);

            if (NT_SUCCESS(status)) {

                NT_ASSERT(keyValueInfo->DataLength == sizeof(ULONGLONG));

                preferredPath = *((ULONGLONG UNALIGNED *)keyValueInfo->Data);

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpQueryTargetsDefaultPolicy (Context %p): PreferredPath for %ws is %I64x.\n",
                            DsmContext,
                            vidPid,
                            preferredPath));

            } else {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_WMI,
                            "DsmpQueryTargetsDefaultPolicy (Context %p): Failed to query PreferredPath for %ws. Status %x.\n",
                            DsmContext,
                            vidPid,
                            status));
            }

            //
            // Copy over this target's policy info.
            //
            policyInfoIndex = targetPolicyInfo->HardwareId;
            *((PUSHORT)policyInfoIndex) = MSDSM_MAX_DEVICE_ID_SIZE;
            policyInfoIndex++;
            RtlStringCchCopyW((PWSTR)policyInfoIndex, MSDSM_MAX_DEVICE_ID_LENGTH - 1, vidPid);
            targetPolicyInfo->LoadBalancePolicy = loadBalanceType;
            targetPolicyInfo->PreferredPath = preferredPath;

            targetPolicyInfo++;
        }
    }

__Exit_DsmpQueryTargetsDefaultPolicy:

    if (targetKey) {
        ZwClose(targetKey);
    }

    if (targetsLBSettingKey) {
        ZwClose(targetsLBSettingKey);
    }

    if (keyBasicInfo) {
        DsmpFreePool(keyBasicInfo);
    }

    if (keyValueInfo) {
        DsmpFreePool(keyValueInfo);
    }

    if (keyFullInfo) {
        DsmpFreePool(keyFullInfo);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryTargetsDefaultPolicy (Context %p): Exiting function with status %x.\n",
                DsmContext,
                status));

    return status;
}


NTSTATUS
DsmpQueryDsmDefaultPolicy(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    )
/*++

Routine Description:

    This routine is used to return the override MSDSM-wide default LB policy
    if it was explicitly set, by querying the services key at "msdsm\Parameters"

Arguements:

    Context - The DSM Context value. It contains storage for the target hardware ids and their
              default policy info.
    InBufferSize - Size of the input buffer
    OutBufferSize - Size of the output buffer
    Buffer - Buffer in which the current MSDSM-wide default policy is returned, if the buffer
             is big enough

Return Value:

   STATUS_SUCCESS on success
   Appropriate error code on error.

--*/
{
    PMSDSM_DEFAULT_LOAD_BALANCE_POLICY dsmPolicyInfo = (PMSDSM_DEFAULT_LOAD_BALANCE_POLICY)Buffer;
    NTSTATUS status;
    DSM_LOAD_BALANCE_TYPE loadBalanceType;
    ULONGLONG preferredPath = (ULONGLONG)((ULONG_PTR)MAXULONG);

    UNREFERENCED_PARAMETER(InBufferSize);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryDsmDefaultPolicy (Context %p): Entering function.\n",
                DsmContext));

    if (*OutBufferSize < sizeof(MSDSM_DEFAULT_LOAD_BALANCE_POLICY)) {

        *OutBufferSize = sizeof(MSDSM_DEFAULT_LOAD_BALANCE_POLICY);
        status = STATUS_BUFFER_TOO_SMALL;

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryDsmDefaultPolicy (Context %p): Buffer insufficient. Status %x.\n",
                    DsmContext,
                    status));

        goto __Exit_DsmpQueryDsmDefaultPolicy;
    }

    *OutBufferSize = sizeof(MSDSM_DEFAULT_LOAD_BALANCE_POLICY);
    RtlZeroMemory(Buffer, *OutBufferSize);

    status = DsmpQueryDsmLBPolicyFromRegistry(&loadBalanceType, &preferredPath);

    if (NT_SUCCESS(status)) {

        dsmPolicyInfo->LoadBalancePolicy = loadBalanceType;
        dsmPolicyInfo->PreferredPath = (ULONGLONG)((ULONG_PTR)preferredPath);

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryDsmDefaultPolicy (Context %p): LB policy = %u, Preferred path = %I64x.\n",
                    DsmContext,
                    dsmPolicyInfo->LoadBalancePolicy,
                    dsmPolicyInfo->PreferredPath));
    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_WMI,
                    "DsmpQueryDsmDefaultPolicy (Context %p): Query for MSDSM-wide policy, status %x.\n",
                    DsmContext,
                    status));
    }

__Exit_DsmpQueryDsmDefaultPolicy:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpQueryDsmDefaultPolicy (Context %p): Exiting function with status %x.\n",
                DsmContext,
                status));

    return status;
}

