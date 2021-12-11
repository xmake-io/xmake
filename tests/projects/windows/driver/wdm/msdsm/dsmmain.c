/*++

Copyright (C) 2004-2010  Microsoft Corporation

Module Name:

    dsmmain.c

Abstract:

    This driver is the Microsoft Device Specific Module (DSM).
    It exports behaviours that mpio.sys will use to determine how to
    multipath SPC-3 conforming devices.

    This file contains routines that are internal to MSDSM.

Environment:

    kernel mode only

Notes:

--*/

#include "precomp.h"

#ifdef DEBUG_USE_WPP
#include "dsmmain.tmh"
#endif

#pragma warning (disable:4305)

extern BOOLEAN DoAssert;

#ifdef ALLOC_PRAGMA
    #pragma alloc_text(PAGE, DsmpRegisterPersistentReservationKeys)
#endif

VOID
DsmpFreeDSMResources(
    _In_ IN PDSM_CONTEXT DsmContext
    )
/*++

Routine Description:

    This routine will free the resources allocated by the DSM. This routine
    should be called when the DSM is being unloaded.

Arguements:

    DsmContext - DSM context given to MPIO during initialization

Return Value:

    None
--*/
{
    PDSM_WMILIB_CONTEXT wmiInfo;
    PVOID tempAddress = (PVOID)DsmContext;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_INIT,
                "DsmpFreeDSMResources (DsmCtxt %p): Entering function.\n",
                DsmContext));

    //
    // First free the buffer allocated for storing the registry path.
    //
    wmiInfo = &gDsmInitData.DsmWmiInfo;

    if (wmiInfo->RegistryPath.Buffer) {

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_INIT,
                    "DsmpFreeDSMResources (DsmCtxt %p): Freeing wmiInfo's registry buffer.\n",
                    DsmContext));

        DsmpFreePool(wmiInfo->RegistryPath.Buffer);
    }

    if (DsmContext) {
        PLIST_ENTRY entry;
        PDSM_DEVICE_INFO deviceInfo;
        PDSM_GROUP_ENTRY groupEntry;
        PDSM_FAILOVER_GROUP failGroup;
        PDSM_CONTROLLER_LIST_ENTRY controllerEntry;

        ExDeleteNPagedLookasideList(&(DsmContext->CompletionContextList));

        //
        // Free up the devices (DeviceInfo) list.
        //
        while (!IsListEmpty(&DsmContext->DeviceList)) {

             entry = DsmContext->DeviceList.Flink;

             NT_ASSERT(entry);

             deviceInfo = CONTAINING_RECORD(entry, DSM_DEVICE_INFO, ListEntry);

             if (deviceInfo) {

                 DsmpRemoveDeviceFailGroup(DsmContext, deviceInfo->FailGroup, deviceInfo, TRUE);
                 DsmpRemoveDeviceEntry(DsmContext, deviceInfo->Group, deviceInfo);
             }
        }

        NT_ASSERT(!DsmContext->NumberDevices &&
                  !DsmContext->NumberFOGroups &&
                  !DsmContext->NumberGroups);

        //
        // By now, there should be no group entries left but play it safe and
        // free up the GROUP list.
        //
        while (!IsListEmpty(&DsmContext->GroupList)) {

             entry = DsmContext->GroupList.Flink;

             NT_ASSERT(entry);

             groupEntry = CONTAINING_RECORD(entry, DSM_GROUP_ENTRY, ListEntry);

             if (groupEntry) {

                 DsmpRemoveGroupEntry(DsmContext, groupEntry, TRUE);

                 DsmpFreePool(groupEntry);
             }
        }

        //
        // By now there should be no FOG entries left but we play it safe and
        // free up the FOG list.
        //
        while (!IsListEmpty(&DsmContext->FailGroupList)) {

             entry = RemoveHeadList(&DsmContext->FailGroupList);

             if (entry) {

                 failGroup = CONTAINING_RECORD(entry, DSM_FAILOVER_GROUP, ListEntry);

                 if (failGroup) {

                     PDSM_FOG_DEVICELIST_ENTRY fogDeviceListEntry = NULL;
                     PLIST_ENTRY deviceEntry = NULL;

                     while (!IsListEmpty(&failGroup->FOG_DeviceList)) {

                         deviceEntry = RemoveHeadList(&failGroup->FOG_DeviceList);

                         if (deviceEntry) {

                             fogDeviceListEntry = CONTAINING_RECORD(deviceEntry, DSM_FOG_DEVICELIST_ENTRY, ListEntry);

                             if (!fogDeviceListEntry) {
                                 continue;
                             }

                             (fogDeviceListEntry->DeviceInfo)->FailGroup = NULL;

                             DsmpFreePool(fogDeviceListEntry);
                             InterlockedDecrement((LONG volatile*)&failGroup->Count);
                         }
                     }

                     DsmpFreeZombieGroupList(failGroup);
                     DsmpFreePool(failGroup);
                     InterlockedDecrement((LONG volatile*)&DsmContext->NumberFOGroups);
                 }
             }
        }

        //
        // Free up the controller list.
        //
        while (!IsListEmpty(&DsmContext->ControllerList)) {

             entry = RemoveHeadList(&DsmContext->ControllerList);

             if (entry) {

                 controllerEntry = CONTAINING_RECORD(entry, DSM_CONTROLLER_LIST_ENTRY, ListEntry);

                 if (controllerEntry) {

                     DsmpFreeControllerEntry(DsmContext, controllerEntry);

                     InterlockedDecrement((LONG volatile*)&DsmContext->NumberControllers);
                 }
             }
        }

        NT_ASSERT(!DsmContext->NumberControllers);

        //
        // Free up the stale FOG list.
        //
        while (!IsListEmpty(&DsmContext->StaleFailGroupList)) {

             entry = RemoveHeadList(&DsmContext->StaleFailGroupList);

             if (entry) {

                 failGroup = CONTAINING_RECORD(entry, DSM_FAILOVER_GROUP, ListEntry);

                 if (failGroup) {

                     InterlockedDecrement((LONG volatile*)&DsmContext->NumberStaleFOGroups);
                     NT_ASSERT(IsListEmpty(&failGroup->FOG_DeviceList));
                     DsmpFreeZombieGroupList(failGroup);
                     DsmpFreePool(failGroup);
                 }
             }
        }

        //
        // Free up the supported devices list buffer.
        //
        DsmpFreePool(DsmContext->SupportedDevices.Buffer);

        //
        // It's the responsibility of the mpio bus driver to have already
        // destroyed all devices and paths. As those functions free allocations
        // for the objects, the only thing needed here is to free the DsmContext.
        //
        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_INIT,
                    "DsmpFreeDSMResources (DsmCtxt %p): Freeing the DsmContext.\n",
                    DsmContext));

        DsmpFreePool(DsmContext);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_INIT,
                "DsmpFreeDSMResources (DsmCtxt %p): Exiting function.\n",
                tempAddress));

    return;
}


PDSM_GROUP_ENTRY
DsmpFindDevice(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN BOOLEAN AcquireDSMLockExclusive
    )
/*++

Routine Description:

    This routine searches for a serial number match between DeviceInfo and
    the rest of the devices currently being driven by this DSM.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    DeviceInfo - The deviceInfo containing serial number for which to search.
    AcquireDSMLockExclusive - If TRUE this routine should acquire DsmContextLock Exclusively

Return Value:

    The multi-path group entry in which the device resides.

--*/
{
    PDSM_DEVICE_INFO deviceInfo;
    PLIST_ENTRY entry;
    PDSM_GROUP_ENTRY groupEntry = NULL;
    ULONG i;
    KIRQL irql = PASSIVE_LEVEL; // Initialize variable to prevent C4701 error

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpFindDevice (DevInfo %p): Entering function.\n",
                DeviceInfo));

    if (AcquireDSMLockExclusive) {
        irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
    }

    //
    // Run through the DeviceInfo List
    //
    entry = DsmContext->DeviceList.Flink;
    for (i = 0; i < DsmContext->NumberDevices; i++, entry = entry->Flink) {

        //
        // Extract the deviceInfo structure.
        //
        deviceInfo = CONTAINING_RECORD(entry, DSM_DEVICE_INFO, ListEntry);
        DSM_ASSERT(deviceInfo);

        if (deviceInfo) {

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpFindDevice (DevInfo %p): Comparing with %p.\n",
                        DeviceInfo,
                        deviceInfo));

            //
            // Call the Serial Number compare routine.
            //
            if (DsmCompareDevices(DsmContext,
                                  DeviceInfo,
                                  deviceInfo)) {

                groupEntry = deviceInfo->Group;

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_PNP,
                            "DsmpFindDevice (DevInfo %p): Found matching multi-path group %p.\n",
                            DeviceInfo,
                            groupEntry));

                break;
            }
        }
    }

    if (AcquireDSMLockExclusive) {
        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpFindDevice (DevInfo %p): Exiting function with groupEntry %p.\n",
                DeviceInfo,
                groupEntry));

    return groupEntry;
}


PDSM_GROUP_ENTRY
DsmpBuildGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    )
/*++

Routine Description:

    This will allocate and partially initialise a multi-path group entry.

    N.B: This routine must be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    DeviceInfo - The first device to be added to the group.

Return Value:

    The new group entry.

--*/
{
    PDSM_GROUP_ENTRY group;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpBuildGroupEntry (DevInfo %p): Entering function.\n",
                DeviceInfo));

    //
    // Allocate the memory for the multi-path group.
    //
    group = DsmpAllocatePool(NonPagedPoolNx,
                             sizeof(DSM_GROUP_ENTRY),
                             DSM_TAG_GROUP_ENTRY);

    if (group) {

        InitializeListHead(&group->FailingDevInfoList);
        group->GroupNumber = InterlockedIncrement((LONG volatile*)&DsmContext->NumberGroups);
        group->GroupSig = DSM_GROUP_SIG;
        group->State = DSM_GP_NORMAL;

        //
        // Add it to the list of multi-path groups.
        //
        InsertTailList(&DsmContext->GroupList, &group->ListEntry);

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_PNP,
                    "DsmpBuildGroupEntry (DevInfo %p): Failed to allocate memory for the group.\n",
                    DeviceInfo));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpBuildGroupEntry (DevInfo %p): Exiting function with group %p.\n",
                DeviceInfo,
                group));

    return group;
}


NTSTATUS
DsmpParseTargetPortGroupsInformation(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_reads_bytes_(TargetPortGroupsInfoLength) IN PUCHAR TargetPortGroupsInfo,
    _In_ IN ULONG TargetPortGroupsInfoLength
    )
/*++

Routine Description:

    This will parse the information returned back from a previously
    made call to ReportTargetPortGroups and build new TPG entries or
    update old ones.

    N.B: This routine must be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DsmContext
    Group - group entry
    TargetPortGroupsInfo - Pointer to the ReportTPG returned buffer.
    TargetPortGroupsInfoLength - length of the buffer.

Return Value:

    STATUS_SUCCESS or appropriate error code.

--*/
{
    PUCHAR targetPortGroupsInfoIndex;
    ULONG bytes = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE;
    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroupEntry = NULL;
    ULONG descriptorSize = 0;
    NTSTATUS status = STATUS_SUCCESS;
    ULONG index;
    DSM_DEVICE_STATE tpgState = DSM_DEV_NOT_USED_STATE;
    ULONG bytesLeft;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpParseTargetPortGroupsInformation (Group %p): Entering function.\n",
                Group));

    targetPortGroupsInfoIndex = TargetPortGroupsInfo + bytes;
    bytesLeft = TargetPortGroupsInfoLength - bytes;

    while (bytes < TargetPortGroupsInfoLength && NT_SUCCESS(status)) {

        targetPortGroupEntry = DsmpFindTargetPortGroupEntry(DsmContext,
                                                            Group,
                                                            targetPortGroupsInfoIndex,
                                                            bytesLeft);

        if (targetPortGroupEntry) {

            targetPortGroupEntry = DsmpUpdateTargetPortGroupEntry(DsmContext,
                                                                  targetPortGroupEntry,
                                                                  targetPortGroupsInfoIndex,
                                                                  bytesLeft,
                                                                  &descriptorSize);
        } else {

            targetPortGroupEntry = DsmpBuildTargetPortGroupEntry(DsmContext,
                                                                 Group,
                                                                 targetPortGroupsInfoIndex,
                                                                 bytesLeft,
                                                                 &descriptorSize);

            if (targetPortGroupEntry) {

                //
                // Insert this TPG entry into array
                //
                for (index = 0; index < DSM_MAX_PATHS; index++) {

                    if (!Group->TargetPortGroupList[index]) {

                        Group->TargetPortGroupList[index] = targetPortGroupEntry;
                        InterlockedIncrement((LONG volatile*)&Group->NumberTargetPortGroups);
                        targetPortGroupEntry->Group = Group;
                        break;
                    }
                }

                if (index == DSM_MAX_PATHS) {

                    NT_ASSERT(index < DSM_MAX_PATHS);

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_GENERAL,
                                "DsmpParseTargetPortGroupsInformation (Group %p): Number of paths exceeded max supported.\n",
                                Group));

                    status = STATUS_UNSUCCESSFUL;
                    goto __Exit_DsmpParseTargetPortGroupsInformation;
                }

            } else {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_GENERAL,
                            "DsmpParseTargetPortGroupsInformation (Group %p): Insufficient resources to build TPG.\n",
                            Group));

                status = STATUS_INSUFFICIENT_RESOURCES;
            }
        }

        if (NT_SUCCESS(status)) {

            //
            // If this is the first TPG being parsed, save off its AA state.
            //
            if (tpgState == DSM_DEV_NOT_USED_STATE) {

                tpgState = targetPortGroupEntry->AsymmetricAccessState;

            } else {

                //
                // Check if this TPG's AA state differs from the previous one's.
                // Symmetric LU access means that TPG access states must be the
                // same for TPGs. If this one is different, we know that the
                // device supports Asymmetric LU access.
                //
                if (tpgState != targetPortGroupEntry->AsymmetricAccessState) {

                    Group->Symmetric = FALSE;
                }
            }
        }

        if (targetPortGroupEntry) {

            //
            // Set the flag to indicate that we've encountered this TPG in the RTPG information.
            //
            targetPortGroupEntry->Traversed = TRUE;
        }

        bytes += descriptorSize;
        targetPortGroupsInfoIndex += descriptorSize;
        bytesLeft -= descriptorSize;
    }

    //
    // Since we've gone through the entire information reported by back RTPG, it
    // is now time to delete the stale entries.
    //
    for (index = 0; index < DSM_MAX_PATHS; index++) {

        targetPortGroupEntry = Group->TargetPortGroupList[index];

        if (targetPortGroupEntry) {

            if (targetPortGroupEntry->Traversed) {

                //
                // Entry needs to continue to exist. Reset the flag and continue.
                //
                targetPortGroupEntry->Traversed = FALSE;
                continue;

            } else {

                PLIST_ENTRY entry;
                PLIST_ENTRY tempEntry;
                PDSM_TARGET_PORT_LIST_ENTRY targetPort;

                //
                // For this target port group, clean up all its target ports if
                // the port doesn't expose any instance of this device.
                //
                for (entry = targetPortGroupEntry->TargetPortList.Flink;
                     entry != NULL && entry != &targetPortGroupEntry->TargetPortList;
                     entry = entry->Flink) {

                        targetPort = CONTAINING_RECORD(entry, DSM_TARGET_PORT_LIST_ENTRY, ListEntry);

                        if (targetPort) {

                            //
                            // If the TP doesn't expose this device, it is safe
                            // to delete it.
                            //
                            if (IsListEmpty(&targetPort->TP_DeviceList)) {

                                tempEntry = entry;
                                entry = entry->Blink;

                                RemoveEntryList(tempEntry);

                                TracePrint((TRACE_LEVEL_INFORMATION,
                                            TRACE_FLAG_PNP,
                                            "DsmpParseTargetPortGroupsInformation (Group %p): Deleting empty target port %p from TPG %p list.\n",
                                            Group,
                                            targetPort,
                                            targetPortGroupEntry));

                                DsmpFreePool(targetPort);

                                InterlockedDecrement((LONG volatile*)&targetPortGroupEntry->NumberTargetPorts);
                            }
                        }
                    }

                //
                // If the TPG doesn't have any TPs, it is safe to delete it.
                //
                if (!targetPortGroupEntry->NumberTargetPorts) {

                    TracePrint((TRACE_LEVEL_INFORMATION,
                                TRACE_FLAG_PNP,
                                "DsmpParseTargetPortGroupsInformation (Group %p): Deleting target port group %p.\n",
                                Group,
                                targetPortGroupEntry));

                    DsmpFreePool(targetPortGroupEntry);

                    InterlockedDecrement((LONG volatile*)&Group->NumberTargetPortGroups);

                    Group->TargetPortGroupList[index] = NULL;
                }
            }
        }
    }

__Exit_DsmpParseTargetPortGroupsInformation:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpParseTargetPortGroupsInformation (Group %p): Exiting function with status %x\n",
                Group,
                status));

    return status;
}


PDSM_TARGET_PORT_GROUP_ENTRY
DsmpFindTargetPortGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_reads_bytes_(TPGs_BufferLength) IN PUCHAR TargetPortGroupsDescriptor,
    _In_ IN ULONG TPGs_BufferLength
    )
/*++

Routine Description:

    This will search the group's TPG array to look for an identifier match.

    N.B: This routine must be called with DsmContextLock held in either Shared
    or Exclusive mode.

Arguments:

    DsmContext - DsmContext
    Group - group entry
    TargetPortGroupsDescriptor - Pointer to the TPG descriptor.
    TPGs_BufferLength - Length of the passed in TargetPortGroupsDescriptor buffer.

Return Value:

    Pointer to the array element that matches, else NULL.

--*/
{
    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroup = NULL;
    PSPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR descriptor = (PSPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR)TargetPortGroupsDescriptor;
    ULONG index;
    BOOLEAN found = FALSE;
    USHORT identifier = ((descriptor->TPG_Identifier & 0x00FF) << 8) | ((descriptor->TPG_Identifier & 0xFF00) >> 8);

    UNREFERENCED_PARAMETER(TPGs_BufferLength);
    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPortGroupEntry (Group %p): Entering function.\n",
                Group));

    for (index = 0; index < DSM_MAX_PATHS && !found; index++) {

        targetPortGroup = Group->TargetPortGroupList[index];

        if (targetPortGroup) {

            if (targetPortGroup->Identifier == identifier) {

                found = TRUE;
            }
        }
    }

    if (!found) {
        targetPortGroup = NULL;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPortGroupEntry (Group %p): Exiting function with targetPortGroup %p.\n",
                Group,
                targetPortGroup));

    return targetPortGroup;
}

_Success_(return!=0)
PDSM_TARGET_PORT_GROUP_ENTRY
DsmpUpdateTargetPortGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_reads_bytes_(TPGs_BufferLength) IN PUCHAR TargetPortGroupsDescriptor,
    _In_ IN ULONG TPGs_BufferLength,
    _Out_ OUT PULONG DescriptorSize
    )
/*++

Routine Description:

    This routine will update the target port group with information contained
    in the passed in descriptor.

    N.B: This routine must be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DsmContext
    TargetPortGroup - Pointer to the TPG entry to update.
    TargetPortGroupsDescriptor - Pointer to the TPG descriptor.
    TPGs_BufferLength - Length of the passed in TargetPortGroupsDescriptor buffer.
    DescriptorSize - return value of the size of the descriptor.

Return Value:

    The updated target port group entry on success, NULL in case of failure.

--*/
{
    PLIST_ENTRY entry;
    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroup = TargetPortGroup;
    PSPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR descriptor = (PSPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR)TargetPortGroupsDescriptor;
    ULONG numberTargetPorts = 0;
    PULONG descriptorIndex;
    ULONG index;
    PDSM_TARGET_PORT_LIST_ENTRY listEntry;
    NTSTATUS status = STATUS_SUCCESS;
    ULONG identifier;
    PLIST_ENTRY tempEntry = NULL;
    ULONG delCount;
    PUCHAR endOfBuffer = TargetPortGroupsDescriptor + TPGs_BufferLength - 1;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpUpdateTargetPortGroupEntry (TPG %p): Entering function.\n",
                TargetPortGroup));

    if (DescriptorSize == NULL) {
        status = STATUS_INVALID_PARAMETER;

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_GENERAL,
                    "DsmpUpdateTargetPortGroupEntry (TPG %p): Status %x due to null passed in DescriptorSize pointer\n",
                    TargetPortGroup,
                    status));

        goto __Exit_DsmpUpdateTargetPortGroupEntry;
    }

    *DescriptorSize = sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) +
                      (targetPortGroup->NumberTargetPorts * sizeof(ULONG));

    if (((PUCHAR)descriptor + sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) - 1) > endOfBuffer) {

        status = STATUS_INVALID_PARAMETER;

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_GENERAL,
                    "DsmpUpdateTargetPortGroupEntry (TPG %p): Status %x due to incorrect passed in TPG buffer size (%u).\n",
                    TargetPortGroup,
                    status,
                    TPGs_BufferLength));

        goto __Exit_DsmpUpdateTargetPortGroupEntry;
    }

    identifier = ((descriptor->TPG_Identifier & 0x00FF) << 8) | ((descriptor->TPG_Identifier & 0xFF00) >> 8);
    NT_ASSERT(targetPortGroup->Identifier == (USHORT)identifier);
    NT_ASSERT(targetPortGroup->ActiveOptimizedSupported == (descriptor->ActiveOptimizedSupported) ? TRUE : FALSE);
    NT_ASSERT(targetPortGroup->ActiveUnoptimizedSupported == (descriptor->ActiveUnoptimizedSupported) ? TRUE : FALSE);
    NT_ASSERT(targetPortGroup->StandBySupported == (descriptor->StandbySupported) ? TRUE : FALSE);
    NT_ASSERT(targetPortGroup->UnavailableSupported == (descriptor->UnavailableSupported) ? TRUE : FALSE);
    NT_ASSERT(targetPortGroup->TransitioningSupported == (descriptor->TransitioningSupported) ? TRUE : FALSE);
    DSM_ASSERT(targetPortGroup->VendorUnique == descriptor->VendorUnique);

    //
    // It is possible that the asymmetric access state, status code and number of port
    // may have changed
    //
    if ((targetPortGroup->AsymmetricAccessState) != (descriptor->AsymmetricAccessState & 0xF))
    {
        TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_GENERAL,
                        "DsmpUpdateTargetPortGroupEntry (TPG %p): Asymmetric access state has changed.\n",
                        TargetPortGroup));


        targetPortGroup->AsymmetricAccessState = descriptor->AsymmetricAccessState & 0xF;
    }

    targetPortGroup->Preferred = (descriptor->Preferred) ? TRUE : FALSE;

    targetPortGroup->StatusCode = descriptor->StatusCode;

    numberTargetPorts = descriptor->NumberTargetPorts;

    NT_ASSERT(numberTargetPorts > 0);

    //
    // Point to first target port identifier
    //
    descriptorIndex = descriptor->TargetPortIds;

    for (index = 0; index < numberTargetPorts && NT_SUCCESS(status); index++) {

        if (((PUCHAR)descriptorIndex + ((index + 1) * sizeof(ULONG)) - 1) > endOfBuffer) {

            status = STATUS_INVALID_PARAMETER;

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_GENERAL,
                        "DsmpUpdateTargetPortGroupEntry (TPG %p): Status %x due to incorrect TPG buffer size (%u) passed in.\n",
                        TargetPortGroup,
                        status,
                        TPGs_BufferLength));

            goto __Exit_DsmpUpdateTargetPortGroupEntry;
        }

        GetUlongFrom4ByteArray((PUCHAR)(&descriptorIndex[index]), identifier);

        listEntry = DsmpFindTargetPortListEntry(DsmContext,
                                                targetPortGroup,
                                                identifier);

        if (listEntry) {

            RemoveEntryList(&listEntry->ListEntry);
            InsertHeadList(&targetPortGroup->TargetPortList, &listEntry->ListEntry);

        } else {

            listEntry = DsmpBuildTargetPortListEntry(DsmContext,
                                                     targetPortGroup,
                                                     identifier);

            if (listEntry) {

                InsertHeadList(&targetPortGroup->TargetPortList, &listEntry->ListEntry);
                InterlockedIncrement((LONG volatile*)&targetPortGroup->NumberTargetPorts);

            } else {

                status = STATUS_INSUFFICIENT_RESOURCES;

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_GENERAL,
                            "DsmpUpdateTargetPortGroupEntry (TPG %p): Failed to allocate TargetPort (identifier %x).\n",
                            TargetPortGroup,
                            identifier));
            }
        }
    }

    //
    // Ignore the status & carry on. Even if we weren't able to build TP entries
    // for the new target ports, we are no worse off than before.
    //
    DSM_ASSERT(NT_SUCCESS(status));

    *DescriptorSize = sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) +
                      (numberTargetPorts * sizeof(ULONG));

    for (index = 0, entry = targetPortGroup->TargetPortList.Flink;
         index < numberTargetPorts;
         index++, entry = entry->Flink);

    delCount = targetPortGroup->NumberTargetPorts - numberTargetPorts;

    for (index = 0; index < delCount; index++) {

        tempEntry = entry;
        entry = entry->Flink;

        RemoveEntryList(tempEntry);
        InterlockedDecrement((LONG volatile*)&targetPortGroup->NumberTargetPorts);

        listEntry = CONTAINING_RECORD(tempEntry, DSM_TARGET_PORT_LIST_ENTRY, ListEntry);
        NT_ASSERT(listEntry);

        if (listEntry) {

            PLIST_ENTRY deviceEntry;
            PDSM_TARGET_PORT_DEVICELIST_ENTRY tp_device;

            while (!IsListEmpty(&listEntry->TP_DeviceList)) {

                deviceEntry = RemoveHeadList(&listEntry->TP_DeviceList);
                InterlockedDecrement((LONG volatile*)&listEntry->Count);

                if (deviceEntry) {

                    tp_device = CONTAINING_RECORD(deviceEntry, DSM_TARGET_PORT_DEVICELIST_ENTRY, ListEntry);

                    if (tp_device) {

                        if (tp_device->DeviceInfo) {

                            tp_device->DeviceInfo->TargetPort = NULL;
                        }

                        DsmpFreePool(tp_device);
                    }
                }
            }

            DsmpFreePool(listEntry);
        }
    }

__Exit_DsmpUpdateTargetPortGroupEntry:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpUpdateTargetPortGroupEntry (TPG %p): Exiting function.\n",
                targetPortGroup));

    return targetPortGroup;
}


PDSM_TARGET_PORT_GROUP_ENTRY
DsmpBuildTargetPortGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_reads_bytes_(TPGs_BufferLength) IN PUCHAR TargetPortGroupsDescriptor,
    _In_ IN ULONG TPGs_BufferLength,
    _Out_ OUT PULONG DescriptorSize
    )
/*++

Routine Description:

    This will allocate and partially initialise a target port group entry.

    N.B: This routine must be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DsmContext
    Group - The group that this newly going to be built TPG belongs to.
    TargetPortGroupsDescriptor - Pointer to the TPG descriptor.
    TPGs_BufferLength - Length of the passed in TargetPortGroupsDescriptor buffer.
    DescriptorSize - return value of the size of the descriptor.

Return Value:

    The new target port group entry.

--*/
{
    PDSM_TARGET_PORT_GROUP_ENTRY entry = NULL;
    PSPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR descriptor = (PSPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR)TargetPortGroupsDescriptor;
    ULONG numberTargetPorts = 0;
    PULONG descriptorIndex;
    ULONG index = 0;
    PDSM_TARGET_PORT_LIST_ENTRY listEntry;
    NTSTATUS status = STATUS_SUCCESS;
    ULONG identifier;
    PUCHAR endOfBuffer = TargetPortGroupsDescriptor + TPGs_BufferLength - 1;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpBuildTargetPortGroupEntry (Group %p): Entering function.\n",
                Group));

    if (DescriptorSize == NULL) {

        status = STATUS_INVALID_PARAMETER;

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_GENERAL,
                    "DsmpBuildTargetPortGroupEntry (Group %p): Status %x due to null passed in DescriptorSize pointer\n",
                    Group,
                    status));

        goto __Exit_DsmpBuildTargetPortGroupEntry;
    }

    *DescriptorSize = 0;

    if (((PUCHAR)descriptor + sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) - 1) > endOfBuffer) {

        status = STATUS_INVALID_PARAMETER;

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_GENERAL,
                    "DsmpBuildTargetPortGroupEntry (Group %p): Status %x due to incorrect passed in TPG buffer size (%u).\n",
                    Group,
                    status,
                    TPGs_BufferLength));

        goto __Exit_DsmpBuildTargetPortGroupEntry;
    }

    //
    // Allocate the memory for the multi-path group.
    //
    entry = DsmpAllocatePool(NonPagedPoolNx,
                             sizeof(DSM_TARGET_PORT_GROUP_ENTRY),
                             DSM_TAG_TARGET_PORT_GROUP_ENTRY);

    if (entry) {

        entry->TargetPortGroupSig = DSM_TARGET_PORT_GROUP_SIG;

        //
        // Target Port Group's access state
        //
        entry->AsymmetricAccessState = descriptor->AsymmetricAccessState & 0xF;

        //
        // Target Port Group's supported states
        //
        entry->ActiveOptimizedSupported = (descriptor->ActiveOptimizedSupported) ? TRUE : FALSE;
        entry->ActiveUnoptimizedSupported = (descriptor->ActiveUnoptimizedSupported) ? TRUE : FALSE;
        entry->StandBySupported = (descriptor->StandbySupported) ? TRUE : FALSE;
        entry->UnavailableSupported = (descriptor->UnavailableSupported) ? TRUE : FALSE;

        //
        // Target Port Group's Preference and support for reporting transitioning
        //
        entry->Preferred = (descriptor->Preferred) ? TRUE : FALSE;
        entry->TransitioningSupported = (descriptor->TransitioningSupported) ? TRUE : FALSE;

        //
        // Target Port Group's identifier
        //
        entry->Identifier = ((descriptor->TPG_Identifier & 0x00FF) << 8) | ((descriptor->TPG_Identifier & 0xFF00) >> 8);

        //
        // Target Port Group's status code
        //
        entry->StatusCode = descriptor->StatusCode;

        //
        // Vendor unique
        //
        entry->VendorUnique = descriptor->VendorUnique;

        //
        // Number of target ports
        //
        numberTargetPorts = descriptor->NumberTargetPorts;

        NT_ASSERT(numberTargetPorts > 0);

        //
        // Point to first target port identifier
        //
        descriptorIndex = descriptor->TargetPortIds;

        InitializeListHead(&entry->TargetPortList);

        for (index = 0; index < numberTargetPorts && NT_SUCCESS(status); index++) {

            if (((PUCHAR)descriptorIndex + ((index + 1) * sizeof(ULONG)) - 1) > endOfBuffer) {

                status = STATUS_INVALID_PARAMETER;

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_GENERAL,
                            "DsmpBuildTargetPortGroupEntry (Group %p): Status %x due to incorrect TPG buffer size (%u) passed in.\n",
                            Group,
                            status,
                            TPGs_BufferLength));

                break;
            }

            GetUlongFrom4ByteArray((PUCHAR)(&descriptorIndex[index]), identifier);

            listEntry = DsmpBuildTargetPortListEntry(DsmContext,
                                                     entry,
                                                     identifier);

            if (listEntry) {

                InsertTailList(&entry->TargetPortList, &listEntry->ListEntry);
                InterlockedIncrement((LONG volatile*)&entry->NumberTargetPorts);

            } else {

                status = STATUS_INSUFFICIENT_RESOURCES;
                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_GENERAL,
                            "DsmpBuildTargetPortGroupEntry (Group %p): Failed to allocate memory for TP (identifier %x) of TPG %p.\n",
                            Group,
                            identifier,
                            entry));
            }
        }

        if (NT_SUCCESS(status)) {
            *DescriptorSize = sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) +
                              (numberTargetPorts * sizeof(ULONG));
        }

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_GENERAL,
                    "DsmpBuildTargetPortGroupEntry (Group %p): Failed to allocate memory for the TPG.\n",
                    Group));

        status = STATUS_INSUFFICIENT_RESOURCES;
    }

    if (!NT_SUCCESS(status)) {

        //
        // Delete the target port list and the target port group entry
        //
        numberTargetPorts = index - 1;

        if (entry) {

            PLIST_ENTRY delEntry;

            for (index = 0; index < numberTargetPorts; index++) {

                delEntry = RemoveHeadList(&entry->TargetPortList);
                listEntry = CONTAINING_RECORD(delEntry, DSM_TARGET_PORT_LIST_ENTRY, ListEntry);

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_GENERAL,
                            "DsmpBuildTargetPortGroupEntry (Group %p): Cleaning up TPG %p's TP %x.\n",
                            Group,
                            entry,
                            listEntry->Identifier));

                DsmpFreePool(listEntry);
            }

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_GENERAL,
                        "DsmpBuildTargetPortGroupEntry (Group %p): Cleaning up TPG %p.\n",
                        Group,
                        entry));

            DsmpFreePool(entry);
            entry = NULL;
        }
    }

__Exit_DsmpBuildTargetPortGroupEntry:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpBuildTargetPortGroupEntry (Group %p): Exiting function with entry %p.\n",
                Group,
                entry));

    return entry;
}


PDSM_TARGET_PORT_LIST_ENTRY
DsmpFindTargetPortListEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN ULONG RelativeTargetPortId
    )
/*++

Routine Description:

    This will search the passed in TPG's target port list for an identifier match.

    N.B: This routine must be called with DsmContextLock held in either Shared or
    Exclusive mode.

Arguments:

    DsmContext - DsmContext
    TargetPortGroup - The Target Port Group whose target ports need to be searched.
    RelativeTargetPortId - Identifier of the target port entry being matched.

Return Value:

    The target port list entry if match found, else NULL.

--*/
{
    PLIST_ENTRY entry = NULL;
    PDSM_TARGET_PORT_LIST_ENTRY targetPort = NULL;
    BOOLEAN found = FALSE;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPortListEntry (TPG %p): Entering function.\n",
                TargetPortGroup));

    for (entry = TargetPortGroup->TargetPortList.Flink;
         entry != &TargetPortGroup->TargetPortList && !found;
         entry = entry->Flink) {

        targetPort = CONTAINING_RECORD(entry, DSM_TARGET_PORT_LIST_ENTRY, ListEntry);
        NT_ASSERT(targetPort);

        if (targetPort) {

            if (targetPort->Identifier == RelativeTargetPortId) {

                NT_ASSERT(targetPort->TargetPortGroup == TargetPortGroup);

                found = TRUE;
            }
        }
    }

    if (!found) {
        targetPort = NULL;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPortListEntry (TPG %p): Exiting function with target port %p.\n",
                TargetPortGroup,
                targetPort));

    return targetPort;
}


PDSM_TARGET_PORT_LIST_ENTRY
DsmpBuildTargetPortListEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN ULONG RelativeTargetPortId
    )
/*++

Routine Description:

    This will allocate and partially initialize a target port list entry.

    N.B: This routine must be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DsmContext
    TargetPortGroup - The Target Port Group that this target port belongs to.
    RelativeTargetPortId - Identifier of the target port entry being added.

Return Value:

    The new target port list entry.

--*/
{
    PDSM_TARGET_PORT_LIST_ENTRY entry;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpBuildTargetPortListEntry (TPG %p): Entering function.\n",
                TargetPortGroup));

    entry = DsmpAllocatePool(NonPagedPoolNx,
                             sizeof(DSM_TARGET_PORT_LIST_ENTRY),
                             DSM_TAG_TARGET_PORT_LIST_ENTRY);

    if (entry) {

        InitializeListHead(&entry->TP_DeviceList);

        entry->Identifier = RelativeTargetPortId;
        entry->TargetPortGroup = TargetPortGroup;
        entry->TargetPortSig = DSM_TARGET_PORT_SIG;

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_GENERAL,
                    "DsmpBuildTargetPortListEntry (TPG %p): Failed to allocate memory for target port (identifier %x).\n",
                    TargetPortGroup,
                    RelativeTargetPortId));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpBuildTargetPortListEntry (TPG %p): Exiting function with entry %p.\n",
                TargetPortGroup,
                entry));

    return entry;
}


PDSM_TARGET_PORT_GROUP_ENTRY
DsmpFindTargetPortGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PUSHORT TargetPortGroupId
    )
/*++

Routine Description:

    This routine searches the list of TargetPortGroups of a Group to
    find a match for the passed in TargetPortGroupId.

    N.B: This routine must be called with DsmContextLock held in either Shared or
    Exclusive mode.

Arguments:

    DsmContext - DSM context.
    Group - The group whose target port groups to search for a match.
    TargetPortGroupId - Identifier of the target port group entry being searched.

Return Value:

    The target port group entry which matches the passed in identifier.

--*/
{
    ULONG index;
    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroupEntry = NULL;
    BOOLEAN found = FALSE;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPortGroup (Group %p): Entering function.\n",
                Group));

    //
    // Run through the target port group array
    //
    for (index = 0; index < DSM_MAX_PATHS && !found; index++) {

        targetPortGroupEntry = Group->TargetPortGroupList[index];

        if (targetPortGroupEntry) {

            if (targetPortGroupEntry->Identifier == *TargetPortGroupId) {

                found = TRUE;
            }
        }
    }

    if (!found) {

        targetPortGroupEntry = NULL;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPortGroup (Group %p): Exiting function with targetPortGroupEntry %p.\n",
                Group,
                targetPortGroupEntry));

    return targetPortGroupEntry;
}


PDSM_TARGET_PORT_LIST_ENTRY
DsmpFindTargetPort(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN PULONG TargetPortGroupId
    )
/*++

Routine Description:

    This routine searches the list of TargetPorts to
    find a match for the passed in TargetPortGroup and RelativeTargetPortId.

    N.B. Spin lock must be held by caller.

Arguments:

    DsmContext - DSM context.
    TargetPortGroup - the Target Port Group of which this target port is a member.
    RelativeTargetPortId - Identifier of the target port entry being searched.

Return Value:

    The target port entry which matches the passed in identifier.

--*/
{
    PLIST_ENTRY entry;
    PDSM_TARGET_PORT_LIST_ENTRY targetPortListEntry = NULL;
    BOOLEAN found = FALSE;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPort (TPG %p): Entering function.\n",
                TargetPortGroup));

    //
    // Run through the Target Port List
    //
    for (entry = TargetPortGroup->TargetPortList.Flink;
         entry != &TargetPortGroup->TargetPortList && !found;
         entry = entry->Flink) {

        //
        // Extract the target port group structure.
        //
        targetPortListEntry = CONTAINING_RECORD(entry,
                                                DSM_TARGET_PORT_LIST_ENTRY,
                                                ListEntry);
        NT_ASSERT(targetPortListEntry);

        if (targetPortListEntry) {

            NT_ASSERT(TargetPortGroup == targetPortListEntry->TargetPortGroup);

            //
            // Compare with passed in identifier.
            //
            if (targetPortListEntry->Identifier == *TargetPortGroupId) {

                found = TRUE;
            }
        }
    }

    if (!found) {

        targetPortListEntry = NULL;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindTargetPort (TPG %p): Exiting function with targetPortListEntry %p.\n",
                TargetPortGroup,
                targetPortListEntry));

    return targetPortListEntry;
}


NTSTATUS
DsmpAddDeviceEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    )
/*++

Routine Description:

    This routine adds DeviceInfo to an existing multi-path group.

    N.B: This routine MUST be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    Group - The multi-path group to which DeviceInfo should be added.
    DeviceInfo - The new device.
    DeviceState - The initial device state (active, passive,...)

Return Value:

    UNSUCCESSFUL - If there are too many paths already.
    SUCCESS

--*/
{
    ULONG numberDevices;
    NTSTATUS status = STATUS_SUCCESS;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpAddDeviceEntry (DevInfo %p): Entering function.\n",
                DeviceInfo));

    //
    // Ensure that this is a valid config - namely, it hasn't
    // exceeded the number of paths supported.
    //
    numberDevices = * (volatile ULONG *) &Group->NumberDevices;
    if (numberDevices < DSM_MAX_PATHS) {

#if DBG
        ULONG i;

        //
        // Ensure that this isn't a second copy of the same pdo.
        //
        for (i = 0; i < numberDevices; i++) {
            if (Group->DeviceList[i]->PortPdo == DeviceInfo->PortPdo) {
                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_PNP,
                            "DsmpAddDeviceEntry (DevInfo %p): Received same PDO %p twice.\n",
                            DeviceInfo,
                            DeviceInfo->PortPdo));
            }
        }
#endif

        //
        // Indicate one more device is present in this group.
        //
        Group->DeviceList[numberDevices] = DeviceInfo;

        //
        // Indicate one more in the list.
        //
        InterlockedIncrement((LONG volatile*)&Group->NumberDevices);

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpAddDeviceEntry (DevInfo %p): Adding Device to Group %p\n",
                    DeviceInfo,
                    Group));

        //
        // Set-up this device's group id.
        //
        DeviceInfo->Group = Group;

        //
        // One more deviceInfo entry.
        //
        InterlockedIncrement((LONG volatile*)&DsmContext->NumberDevices);

        //
        // Finally, add it to the global list of devices.
        //
        InsertTailList(&DsmContext->DeviceList,
                       &DeviceInfo->ListEntry);

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_PNP,
                    "DsmpAddDeviceEntry (DevInfo %p): Max Paths already added for Group %p.\n",
                    DeviceInfo,
                    Group));

        status = STATUS_UNSUCCESSFUL;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpAddDeviceEntry (DevInfo %p): Exiting function with status %x.\n",
                DeviceInfo,
                status));

    return status;
}


PDSM_CONTROLLER_LIST_ENTRY
DsmpFindControllerEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDEVICE_OBJECT PortObject,
    _In_ IN PSCSI_ADDRESS ScsiAddress,
    _In_reads_(ControllerSerialNumberLength) IN PSTR ControllerSerialNumber,
    _In_ IN SIZE_T ControllerSerialNumberLength,
    _In_ IN STORAGE_IDENTIFIER_CODE_SET CodeSet,
    _In_ IN BOOLEAN AcquireLock
    )
/*++

Routine Description:

    This routine compares the passed in serial number and SCSI address with the
    entries in the list of controller objects.

Arguments:

    DsmContext - DSM context given to MPIO during initialization.
    PortObject - Port FDO exposing the controller.
    ScsiAddress - The scsi address to match.
    ControllerSerialNumber - The serial number for which to find a match.
    ControllerSerialNumberLength - Length of the passed in serial number, in bytes.
    CodeSet - Code set used when building the passed in serial number.
    AcquireLock - FALSE indicates that the caller has already acquired the spin lock.

Return Value:

    Controller list entry if a match is found, else NULL

--*/
{
    KIRQL oldIrql = PASSIVE_LEVEL; // Initialize variable to prevent C4701 error
    PLIST_ENTRY entry;
    PDSM_CONTROLLER_LIST_ENTRY controllerEntry = NULL;
    BOOLEAN found = FALSE;
    PDSM_CONTROLLER_LIST_ENTRY candidate = NULL;

    UNREFERENCED_PARAMETER(CodeSet);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpFindControllerEntry (SN %s): Entering function.\n",
                ControllerSerialNumber));

    if (AcquireLock) {

        oldIrql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
    }

    for (entry = DsmContext->ControllerList.Flink;
         entry != &DsmContext->ControllerList && !found;
         entry = entry->Flink) {

        controllerEntry = CONTAINING_RECORD(entry, DSM_CONTROLLER_LIST_ENTRY, ListEntry);
        NT_ASSERT(controllerEntry);

        if (!controllerEntry) {

            continue;
        }

        //
        // Serial numbers and Portal, Bus, and Target of the SCSI address must match.
        //
        if (!strncmp((const char*)controllerEntry->Identifier,
                    ControllerSerialNumber,
                    ControllerSerialNumberLength) &&
            (controllerEntry->ScsiAddress->PortNumber == ScsiAddress->PortNumber &&
             controllerEntry->ScsiAddress->PathId == ScsiAddress->PathId &&
             controllerEntry->ScsiAddress->TargetId == ScsiAddress->TargetId)) {

            if (controllerEntry->IdLength == ControllerSerialNumberLength) {

                found = TRUE;

            } else {

                if ((!candidate) ||
                    (controllerEntry->IdLength > ControllerSerialNumberLength && ControllerSerialNumberLength == 32)) {

                    candidate = controllerEntry;
                }
            }
        }
    }

    if (!found) {

        if (candidate) {

            controllerEntry = candidate;

        } else {

            controllerEntry = NULL;
        }
    }

    //
    // If we found a matching controller entry, we need to make sure the Port
    // Object (FDO) is updated.  We also don't care about the LUN part of the
    // SCSI address so we just set it to zero.
    //
    if (controllerEntry) {
        controllerEntry->PortObject = PortObject;
        controllerEntry->ScsiAddress->Lun = 0;
    }

    if (AcquireLock) {

        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), oldIrql);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpFindControllerEntry (SN %s): Exiting function with controllerEntry %p\n",
                ControllerSerialNumber,
                controllerEntry));

    return controllerEntry;
}


_Ret_maybenull_
_Must_inspect_result_
_When_(return != NULL, __drv_allocatesMem(Mem))
PDSM_CONTROLLER_LIST_ENTRY
DsmpBuildControllerEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_opt_ IN PDEVICE_OBJECT DeviceObject,
    _In_ IN PDEVICE_OBJECT PortObject,
    _In_ IN PSCSI_ADDRESS ScsiAddress,
    _In_ IN PSTR ControllerSerialNumber,
    _In_ IN STORAGE_IDENTIFIER_CODE_SET CodeSet,
    _In_ IN BOOLEAN AcquireLock
    )
/*++

Routine Description:

    This routine builds a new controller list entry with the passed in serial number info.

Arguments:

    DsmContext - DSM context given to MPIO during initialization.
    DeviceObject - Controller's PDO.
    PortObject - Port FDO exposing the controller.
    ScsiAddress - scsi address of the controller.
    ControllerSerialNumber - The serial number to associate with new entry.
    CodeSet - Code set of the identifier that was used to build the serial number.
    AcquireLock - TRUE indicates that the function must grab the spinlock. FALSE indicates
                  that caller has the spin lock held.

Return Value:

    New controller list entry if we successfully built one, else NULL

--*/
{
    KIRQL oldIrql = PASSIVE_LEVEL; // Initialize variable to prevent C4701 error
    PDSM_CONTROLLER_LIST_ENTRY controllerEntry = NULL;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpBuildControllerEntry (SN %s): Entering function - Controller %p seen through PortFDO %p.\n",
                ControllerSerialNumber,
                DeviceObject,
                PortObject));

    if (AcquireLock) {

        oldIrql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
    }

    controllerEntry = DsmpAllocatePool(NonPagedPoolNx,
                                       sizeof(DSM_CONTROLLER_LIST_ENTRY),
                                       DSM_TAG_CONTROLLER_LIST_ENTRY);

    if (controllerEntry) {

        //
        // Note:
        // ControllerSerialNumber's length fits in a 32-bit value.
        // See implementation in DsmpParseDeviceID()
        //
        ULONG length = (ULONG)strlen(ControllerSerialNumber);

        controllerEntry->Identifier = DsmpAllocatePool(NonPagedPoolNx,
                                                       length + 1,
                                                       DSM_TAG_SERIAL_NUM);

        if (controllerEntry->Identifier) {

            controllerEntry->ScsiAddress = DsmpAllocatePool(NonPagedPoolNx,
                                                            sizeof(SCSI_ADDRESS),
                                                            DSM_TAG_SCSI_ADDRESS);
            if (controllerEntry->ScsiAddress) {

                RtlCopyMemory(controllerEntry->ScsiAddress, ScsiAddress, sizeof(SCSI_ADDRESS));

                controllerEntry->DeviceObject = DeviceObject;
                controllerEntry->PortObject = PortObject;
                controllerEntry->ControllerSig = DSM_CONTROLLER_SIG;
                controllerEntry->IdLength = length;
                controllerEntry->IdCodeSet = CodeSet;

                RtlCopyMemory(controllerEntry->Identifier,
                              ControllerSerialNumber,
                              length);

                controllerEntry->RefCount = 0;

            } else {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_PNP,
                            "DsmpBuildControllerEntry (SN %s): Failed to allocate resources for scsiaddress (controllerEntry %p).\n",
                            ControllerSerialNumber,
                            controllerEntry));

                DsmpFreePool(controllerEntry->Identifier);
                controllerEntry->Identifier = NULL;
                DsmpFreePool(controllerEntry);
                controllerEntry = NULL;
            }

        } else {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_PNP,
                        "DsmpBuildControllerEntry (SN %s): Failed to allocate resources for identifier (controllerEntry %p).\n",
                        ControllerSerialNumber,
                        controllerEntry));

            DsmpFreePool(controllerEntry);
            controllerEntry = NULL;
        }

    } else {
        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_PNP,
                    "DsmpBuildControllerEntry (SN %s): Failed to allocate memory for ControllerEntry.\n",
                    ControllerSerialNumber));
    }

    if (AcquireLock) {

        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), oldIrql);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpBuildControllerEntry (SN %s): Exiting function with controllerEntry %p\n",
                ControllerSerialNumber,
                controllerEntry));

    return controllerEntry;
}


VOID
DsmpFreeControllerEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ __drv_freesMem(Mem) IN PDSM_CONTROLLER_LIST_ENTRY ControllerEntry
    )
/*++

Routine Description:

    This routine frees the allocations of the passed in controller list entry.

Arguments:

    DsmContext - DSM context given to MPIO during initialization.
    ControllerEntry - Controller list entry.

Return Value:

    Nothing

--*/
{
    PVOID tempAddress = (PVOID)ControllerEntry;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpFreeControllerEntry (Entry %p): Entering function.\n",
                ControllerEntry));

    if (ControllerEntry->Identifier) {
        DsmpFreePool(ControllerEntry->Identifier);
    }

    if (ControllerEntry->ScsiAddress) {
        DsmpFreePool(ControllerEntry->ScsiAddress);
    }

    DsmpFreePool(ControllerEntry);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpFreeControllerEntry (Entry %p): Exiting function.\n",
                tempAddress));

    return;
}


BOOLEAN
DsmpIsDeviceBelongsToController(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN PDSM_CONTROLLER_LIST_ENTRY ControllerEntry
    )
/*++

Routine Description:

    This routine determines if the device passed in was exposed via the passed
    in controller.
    The match is to be based on VID and SCSI Address (using the Port, Bus
    and Target comparison).

Arguments:

    DsmContext - DSM context given to MPIO during initialization.
    DeviceInfo - The device instance to match.
    ControllerEntry - The controller object which we need to determine whether
                      DeviceInfo is exposed from.

Return Value:

    TRUE - if the controller's VID and scsi address match
    FALSE - not matched

--*/
{
    BOOLEAN saMatch = FALSE;
    BOOLEAN vMatch = FALSE;
    BOOLEAN match = FALSE;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpIsDeviceBelongsToController (DevInfo %p): Entering function - ControllerEntry is %p.\n",
                DeviceInfo,
                ControllerEntry));

    if (DeviceInfo->ScsiAddress && ControllerEntry->ScsiAddress) {

        saMatch = (DeviceInfo->ScsiAddress->PathId == ControllerEntry->ScsiAddress->PathId &&
                   DeviceInfo->ScsiAddress->PortNumber == ControllerEntry->ScsiAddress->PortNumber &&
                   DeviceInfo->ScsiAddress->TargetId == ControllerEntry->ScsiAddress->TargetId);
    }

    if (saMatch) {

        INQUIRYDATA inquiryData = {0};
        UCHAR controllerVID[9] = {0};
        UCHAR deviceVID[9] = {0};

        if (NT_SUCCESS(DsmpGetStandardInquiryData(ControllerEntry->DeviceObject, &inquiryData))) {

            RtlStringCchCopyA((PSTR)controllerVID,
                              ARRAYSIZE(controllerVID),
                              (PCSTR)(&inquiryData.VendorId));

            RtlStringCchCopyA((PSTR)deviceVID,
                              ARRAYSIZE(deviceVID),
                              (PCSTR)(&DeviceInfo->Descriptor) + DeviceInfo->Descriptor.VendorIdOffset);


            if (!strcmp((const char*)controllerVID, (const char*)deviceVID)) {

                vMatch = TRUE;
            }
        }
    }

    match = saMatch & vMatch;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpIsDeviceBelongsToController (DevInfo %p): ControllerEntry %p. Exiting function with match = %x.\n",
                DeviceInfo,
                ControllerEntry,
                match));

    return match;
}


PDSM_DEVICE_INFO
DsmpFindDevInfoFromGroupAndFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_FAILOVER_GROUP FOGroup
    )
/*++

Routine Description:

    This routine will find the deviceInfo that is part of both the passed in Group
    as well as passed in Fail-Over group.

    N.B: This routine MUST be called with DsmContextLock held in either Shared or
    Exclusive mode.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    Group - The group that represents the device.
    FOGroup - The FOG that the device is part of.

Return Value:

    The deviceInfo that is part of both.
    NULL - if not found.

--*/
{
    ULONG i;
    PDSM_DEVICE_INFO deviceInfo = NULL;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpFindDevInfoFromGroupAndFOGroup (Group %p FOG %p): Entering function.\n",
                Group,
                FOGroup));

    if (Group && FOGroup) {

        //
        // Run through the list of devInfos in passed in Group
        //
        for (i = 0; i < DSM_MAX_PATHS; i++) {

            deviceInfo = Group->DeviceList[i];

            if (deviceInfo) {

                if (deviceInfo->FailGroup == FOGroup) {

                    break;

                } else {

                    deviceInfo = NULL;
                }
            }
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpFindFOGroup (Group %p FOG %p): Exiting function with deviceInfo %p.\n",
                Group,
                FOGroup,
                deviceInfo));

    return deviceInfo;
}


PDSM_FAILOVER_GROUP
DsmpFindFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PVOID PathId
    )
/*++

Routine Description:

    This routine will find the Fail-Over group that corresponds to PathId.

    N.B: This routine MUST be called with DsmContextLock held in either Shared or
    Exclusive mode.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    PathId - The Path Identifier that corresponds to
             an adapter/adapter-controller

Return Value:

    The fail-over group.
    NULL - if not found.

--*/
{
    PDSM_FAILOVER_GROUP failOverGroup = NULL;
    PDSM_FAILOVER_GROUP retFOGroup = NULL;
    PLIST_ENTRY entry;
    ULONG i;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindFOGroup (PathId %p): Entering function.\n",
                PathId));

    //
    // Run through the list of Fail-Over Groups
    //
    entry = DsmContext->FailGroupList.Flink;
    for (i = 0; i < DsmContext->NumberFOGroups; i++, entry = entry->Flink) {

        //
        // Extract the fail-over group structure.
        //
        failOverGroup = CONTAINING_RECORD(entry, DSM_FAILOVER_GROUP, ListEntry);
        NT_ASSERT(failOverGroup);

        if (!failOverGroup) {
            continue;
        }

        //
        // Check for a match of the PathId.
        //
        if (failOverGroup->PathId == PathId) {

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_GENERAL,
                        "DsmpFindFOGroup (PathId %p): Found a FO group %p.\n",
                        PathId,
                        failOverGroup));

            retFOGroup = failOverGroup;

            break;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindFOGroup (PathId %p): Exiting function with retFOGroup %p.\n",
                PathId,
                retFOGroup));

    return retFOGroup;
}


PDSM_FAILOVER_GROUP
DsmpBuildFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN PVOID *PathId
    )
/*++

Routine Description:

    This routine will build and partially initialise a fail-over group entry.
    The FOG corresponds to the device list which will fail as a group.

    N.B: This routine MUST be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    DeviceInfo - The first device to add to the group.
    PathId - An identifier that is returned to mpio that id's the path.

Return Value:

    The fail-over group entry.
    NULL - on failed allocation.

--*/
{
    PDSM_FAILOVER_GROUP failOverGroup;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpBuildFOGroup (PathId %p): Entering function.\n", PathId));

    //
    // Allocate a new Fail Over Group
    //
    failOverGroup = DsmpAllocatePool(NonPagedPoolNx,
                                     sizeof(DSM_FAILOVER_GROUP),
                                     DSM_TAG_FO_GROUP);
    if (failOverGroup) {

        InitializeListHead(&failOverGroup->FOG_DeviceList);
        InitializeListHead(&failOverGroup->ZombieGroupList);

        //
        // Get the current number of groups, and add the one that's being created.
        //
        InterlockedIncrement((LONG volatile*)&DsmContext->NumberFOGroups);

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpBuildFOGroup (PathId %p): Path that will be used for %p is %p.\n",
                    PathId,
                    DeviceInfo,
                    *PathId));

        failOverGroup->PathId = *PathId;

        //
        // Set the initial state to NORMAL.
        //
        failOverGroup->State = DSM_FG_NORMAL;

        failOverGroup->FailOverSig = DSM_FOG_SIG;

        //
        // Add it to the global list.
        //
        InsertTailList(&DsmContext->FailGroupList,
                       &failOverGroup->ListEntry);

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpBuildFOGroup (PathId %p): Added new FOGroup %p with path %p. Count of FO Group %d.\n",
                    PathId,
                    failOverGroup,
                    *PathId,
                    DsmContext->NumberFOGroups));

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_PNP,
                    "DsmpBuildFOGroup (PathId %p): Failed to allocate memory for FailOverGroup.\n",
                    PathId));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpBuildFOGroup (PathId %p): Exiting function with failOverGroup %p.\n",
                PathId,
                failOverGroup));

    return failOverGroup;
}


NTSTATUS
DsmpUpdateFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_FAILOVER_GROUP FailGroup,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    )
/*++

Routine Description:

    This routine will add DeviceInfo to an existing FOG.

    N.B: This routine MUST be called with DsmContextLock held in Exclusive mode.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    FailGroup - The fail-over group entry.
    DeviceInfo - The new device.

Return Value:

    STATUS_SUCCESS or appropriate error code.

--*/
{
    NTSTATUS status = STATUS_SUCCESS;
    PDSM_FOG_DEVICELIST_ENTRY fogDeviceListEntry;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpUpdateFOGroup (FOG %p): Entering function. DeviceInfo %p.\n",
                FailGroup,
                DeviceInfo));

    if (DeviceInfo && FailGroup) {

        fogDeviceListEntry = DsmpAllocatePool(NonPagedPoolNx,
                                              sizeof(DSM_FOG_DEVICELIST_ENTRY),
                                              DSM_TAG_FOG_DEV_ENTRY);

        if (fogDeviceListEntry) {

            //
            // Add the device to the list of devices that are on this path.
            //
            fogDeviceListEntry->DeviceInfo = DeviceInfo;
            InterlockedIncrement((LONG volatile*)&FailGroup->Count);
            InsertTailList(&FailGroup->FOG_DeviceList, &fogDeviceListEntry->ListEntry);

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpUpdateFOGroup (FOG %p): DevInfo %p added (current count: %d)\n",
                        FailGroup,
                        DeviceInfo,
                        FailGroup->Count));

            //
            // Set the device's F.O. Group.
            //
            DeviceInfo->FailGroup = FailGroup;

        } else {

            status = STATUS_INSUFFICIENT_RESOURCES;
            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_PNP,
                        "DsmpUpdateFOGroup (FOG %p): Failed to allocate memory for FOG devlist entry.\n",
                        FailGroup));
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpUpdateFOGroup (FOG %p): Exiting function with status %x.\n",
                FailGroup,
                status));

    return status;
}


VOID
DsmpRemoveDeviceFailGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_FAILOVER_GROUP FailGroup,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN BOOLEAN AcquireDSMLockExclusive
    )
/*++

Routine Description:

    This routine will remove DeviceInfo from the FOG.
    This routine is called in response to a removal of the device.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    FailGroup - The FOG from which DeviceInfo should be removed.
    DeviceInfo - The now missing device.
    AcquireDSMLockExclusive - If TRUE this routine should acquire DsmContextLock Exclusively

Return Value:

    NOTHING

--*/
{
    KIRQL irql = PASSIVE_LEVEL; // Initialize variable to prevent C4701 warnings
    PLIST_ENTRY entry;
    PDSM_FOG_DEVICELIST_ENTRY fogDeviceListEntry;
    PLIST_ENTRY zombieEntry;
    PDSM_ZOMBIEGROUP_ENTRY zombieGroup;
    PDSM_ZOMBIEGROUP_ENTRY newZombieGroup;
    BOOLEAN groupInZombieList = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpRemoveDeviceFailGroup (FOG %p): Entering function. DeviceInfo %p.\n",
                FailGroup,
                DeviceInfo));

    if (FailGroup && DeviceInfo) {

        if (AcquireDSMLockExclusive) {
            irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
        }

        for (entry = FailGroup->FOG_DeviceList.Flink;
             entry != &FailGroup->FOG_DeviceList;
             entry = entry->Flink) {

            fogDeviceListEntry = CONTAINING_RECORD(entry,
                                                   DSM_FOG_DEVICELIST_ENTRY,
                                                   ListEntry);
            DSM_ASSERT(fogDeviceListEntry);

            if (!fogDeviceListEntry) {
                continue;
            }

            if (fogDeviceListEntry->DeviceInfo == DeviceInfo) {

                DeviceInfo->FailGroup = NULL;
                RemoveEntryList(entry);
                DsmpFreePool(fogDeviceListEntry);

                InterlockedDecrement((LONG volatile*)&FailGroup->Count);

                //
                // If a DeviceInfo is removed, we need to keep its group in a
                // "zombie" list so that we can still access a fail-over group's
                // associated groups even when all its devices are gone.
                //
                for (zombieEntry = FailGroup->ZombieGroupList.Flink;
                     zombieEntry != &(FailGroup->ZombieGroupList);
                     zombieEntry = zombieEntry->Flink) {

                    zombieGroup = CONTAINING_RECORD(zombieEntry, DSM_ZOMBIEGROUP_ENTRY, ListEntry);
                    if (zombieGroup != NULL &&
                        zombieGroup->Group != NULL &&
                        zombieGroup->Group == DeviceInfo->Group) {

                        groupInZombieList = TRUE;
                        break;
                    }
                }

                //
                // Create a new entry if the group does not exist in the zombie group list.
                //
                if (groupInZombieList == FALSE) {
                    newZombieGroup = (PDSM_ZOMBIEGROUP_ENTRY)DsmpAllocatePool(NonPagedPoolNx,
                                                                              sizeof(DSM_ZOMBIEGROUP_ENTRY),
                                                                              DSM_TAG_ZOMBIEGROUP_ENTRY);
                    if (newZombieGroup != NULL) {
                        newZombieGroup->Group = DeviceInfo->Group;
                        InsertTailList(&FailGroup->ZombieGroupList, &newZombieGroup->ListEntry);
                    } else {
                        TracePrint((TRACE_LEVEL_ERROR,
                                    TRACE_FLAG_PNP,
                                    "DsmpRemoveDeviceFailGroup (DevInfo %p): Failed to allocate memory for the zombie group.\n",
                                    DeviceInfo));
                    }
                }

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_PNP,
                            "DsmpRemoveDeviceFailGroup (FOG %p): DevInfo %p removed from FOG (current count: %d)\n",
                            FailGroup,
                            DeviceInfo,
                            FailGroup->Count));

                break;
            }
        }

        if (AcquireDSMLockExclusive) {
            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpRemoveDeviceFailGroup (FOG %p): Exiting function.\n",
                FailGroup));

    return;
}


ULONG
DsmpRemoveDeviceEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    )
/*++

Routine Description:

    This routine will remove DeviceInfo from Group. If it is the last DeviceInfo
    in the Group, it has the added side-effect of cleaning up the Group entry
    also.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    Group - The multi-path group from which DeviceInfo should be removed.
    DeviceInfo - The device to remove.

Return Value:

    Number of devices left in group.

--*/
{
    KIRQL irql;
    ULONG i;
    ULONG j;
    ULONG numberDevices;
    BOOLEAN freeGroup = FALSE;
    PVOID tempAddress = (PVOID)Group;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpRemoveDeviceEntry (Group %p): Entering function. DeviceInfo %p.\n",
                Group,
                DeviceInfo));

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    //
    // Find it's offset in the array of devices.
    //
    for (i = 0; i < Group->NumberDevices; i++) {

        if (Group->DeviceList[i] == DeviceInfo) {

            //
            // Zero out it's entry.
            //
            Group->DeviceList[i] = NULL;

            //
            // Reduce the number in the group.
            //
            InterlockedDecrement((LONG volatile*)&Group->NumberDevices);


            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpRemoveDeviceEntry (Group %p): Removing Device %p (desiredState %u) from Group\n",
                        Group,
                        DeviceInfo,
                        DeviceInfo->DesiredState));

            //
            // Collapse the array.
            // Holding the spinlock, so that the state is consistent in other
            // routines.
            //
            for (j = i; j < Group->NumberDevices; j++) {

                //
                // Shuffle all entries down to fill the hole.
                //
                Group->DeviceList[j] = Group->DeviceList[j + 1];
            }

            //
            // Zero out the last one.
            //
            Group->DeviceList[j] = NULL;
            break;
        }
    }

    //
    // Remove this devInfo from the TargetPort deviceList
    //
    DsmpRemoveDeviceFromTargetPortList(DeviceInfo);

    numberDevices = Group->NumberDevices;

    //
    // See if anything is left in the Group.
    //
    if (Group->NumberDevices == 0) {

        Group->State = DSM_GP_FAILED;

        //
        // Yank it from the Group list.
        //
        DsmpRemoveGroupEntry(DsmContext, Group, FALSE);

        freeGroup = TRUE;
    }

    //
    // Yank the device out of the Global list.
    //
    RemoveEntryList(&DeviceInfo->ListEntry);
    InterlockedDecrement((LONG volatile*)&DsmContext->NumberDevices);

    //
    // If the serial number buffer was allocated, need to free it.
    //
    if (DeviceInfo->SerialNumberAllocated) {
        DsmpFreePool(DeviceInfo->SerialNumber);
    }

    if (DeviceInfo->ScsiAddress) {
        DsmpFreePool(DeviceInfo->ScsiAddress);
    }

    //
    // Fix up the Reservation List, if needed.
    //
    if (!freeGroup && Group->ReservationList) {
        ULONG oldList;

        //
        // Capture the list for debugging.
        //
        oldList = Group->ReservationList;
        Group->ReservationList = 0;

        //
        // Go through all devices in this group and find the one(s) registered.
        //
        for (i = 0; i < Group->NumberDevices; i++) {

            if (Group->DeviceList[i]->RegisterServiced) {
                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_PNP,
                            "DsmRemoveDeviceEntry (Group %p): Device %p at %d registered.\n",
                            Group,
                            Group->DeviceList[i],
                            i));

                //
                // Indicate its place.
                //
                Group->ReservationList |= (1 << i);
            }
        }

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmRemoveDeviceEntry (Group %p): Reservations Old (%x) New (%x).\n",
                    Group,
                    oldList,
                    Group->ReservationList));
    }


    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

    //
    // Free the allocation.
    //
    DsmpFreePool(DeviceInfo);

    if (freeGroup) {

        //
        // Free the allocations.
        //
        if (Group->RegistryKeyName) {
            DsmpFreePool(Group->RegistryKeyName);
        }

        if (Group->HardwareId) {
            DsmpFreePool(Group->HardwareId);
        }

        DsmpFreePool(Group);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpRemoveDeviceEntry (Group %p): Exiting function - numberDevices = %x.\n",
                tempAddress,
                numberDevices));

    return numberDevices;
}


VOID
DsmpRemoveDeviceFromTargetPortList(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    )
/*++

Routine Description:

    This will remove a DeviceInfo from its target port device list.

    The caller should ensure that the DsmContext->SpinLock is held before
    calling this function.

Arguments:

    DeviceInfo - The DeviceInfo to be removed.

Return Value:

    None

--*/
{
    if (DeviceInfo->TargetPort) {

        PLIST_ENTRY entry;
        PDSM_TARGET_PORT_DEVICELIST_ENTRY listEntry;

        for (entry = DeviceInfo->TargetPort->TP_DeviceList.Flink;
             entry != NULL && entry != &DeviceInfo->TargetPort->TP_DeviceList;
             entry = entry->Flink) {

                listEntry = CONTAINING_RECORD(entry, DSM_TARGET_PORT_DEVICELIST_ENTRY, ListEntry);

                if (listEntry) {

                    if (listEntry->DeviceInfo == DeviceInfo) {

                        TracePrint((TRACE_LEVEL_INFORMATION,
                                    TRACE_FLAG_PNP,
                                    "DsmpRemoveDeviceFromTargetPortList: Removing device %p from target port entry %p.\n",
                                    DeviceInfo,
                                    listEntry));

                        RemoveEntryList(entry);
                        InterlockedDecrement((LONG volatile*)&DeviceInfo->TargetPort->Count);
                        DsmpFreePool(listEntry);

                        DeviceInfo->TargetPort = NULL;
                        DeviceInfo->TargetPortGroup = NULL;

                        break;
                    }
                }
            }
        }
}


VOID
DsmpRemoveZombieGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY ZombieGroup
    )
/* ++

Routine Description:

    This will scan through all the Failover Groups and remove the given Group
    from each Failover Group's zombie group list.

    The DSM lock should be aquired by the caller.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    ZombieGroup - Group entry that should be removed from FOGs' ZombieGroupList

Return Value:

    None

-- */
{
    //
    // Run through the list of Fail-Over Groups
    //
    ULONG i;
    PDSM_FAILOVER_GROUP failOverGroup = NULL;
    PLIST_ENTRY fogEntry;
    PLIST_ENTRY groupEntry;
    PDSM_ZOMBIEGROUP_ENTRY zombieGroupEntry;

    TracePrint((TRACE_LEVEL_VERBOSE,
            TRACE_FLAG_PNP,
            "DsmpRemoveZombieGroupEntry (Group %p): Entering function.\n",
            ZombieGroup));

    fogEntry = DsmContext->FailGroupList.Flink;
    for (i = 0; fogEntry != NULL && i < DsmContext->NumberFOGroups; i++, fogEntry = fogEntry->Flink) {

            failOverGroup = CONTAINING_RECORD(fogEntry, DSM_FAILOVER_GROUP, ListEntry);
            if (failOverGroup != NULL) {

                for (groupEntry = failOverGroup->ZombieGroupList.Flink;
                     groupEntry != &(failOverGroup->ZombieGroupList);
                     groupEntry = groupEntry->Flink) {

                    zombieGroupEntry = CONTAINING_RECORD(groupEntry, DSM_ZOMBIEGROUP_ENTRY, ListEntry);
                    if (zombieGroupEntry != NULL &&
                        zombieGroupEntry->Group != NULL &&
                        zombieGroupEntry->Group == ZombieGroup) {

                        RemoveEntryList(groupEntry);
                        DsmpFreePool(zombieGroupEntry);

                        TracePrint((TRACE_LEVEL_VERBOSE,
                            TRACE_FLAG_PNP,
                            "DsmpRemoveZombieGroupEntry (Group %p): Found and removed a zombie group in (FOG %p)\n",
                            ZombieGroup,
                            failOverGroup));

                        //
                        // We removed the zombie group entry from this fail-over
                        // group, so we can move on to the next fail-over group.
                        //
                        break;
                    }
                }
            }
        }

    TracePrint((TRACE_LEVEL_VERBOSE,
            TRACE_FLAG_PNP,
            "DsmpRemoveZombieGroupEntry (Group %p): Exiting function.\n",
            ZombieGroup));
}


VOID
DsmpRemoveGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY GroupEntry,
    _In_ IN BOOLEAN AcquireDSMLockExclusive
    )
/*++

Routine Description:

    This will remove a group entry from the DSM's list.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    GroupEntry - Group entry that should be removed from DSM's list
    AcquireDSMLockExclusive - If TRUE this routine should acquire DsmContextLock Exclusively

Return Value:

    None

--*/
{
    KIRQL irql = PASSIVE_LEVEL; // Initialize variable to prevent C4701 warnings
    ULONG index;
    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroup;
    PLIST_ENTRY entry;
    PDSM_TARGET_PORT_LIST_ENTRY targetPort;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpRemoveGroupEntry (Group %p): Entering function.\n",
                GroupEntry));

    if (AcquireDSMLockExclusive) {
        irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
    }

    NT_ASSERT(GroupEntry && GroupEntry->ListEntry.Flink && GroupEntry->ListEntry.Blink);

    //
    // Since this group is being removed, we need to make sure it is also
    // removed from all fail-over groups' zombie group lists.
    //
    DsmpRemoveZombieGroupEntry(DsmContext, GroupEntry);

    //
    // Add it to the list of multi-path groups.
    //
    RemoveEntryList(&GroupEntry->ListEntry);

    GroupEntry->ListEntry.Flink = GroupEntry->ListEntry.Blink = NULL;

    InterlockedDecrement((LONG volatile*)&DsmContext->NumberGroups);

    for (index = 0; index < DSM_MAX_PATHS; index++) {

        //
        // Clean up all its Target Port Groups
        //
        targetPortGroup = GroupEntry->TargetPortGroupList[index];

        if (targetPortGroup) {

            GroupEntry->TargetPortGroupList[index] = NULL;

            //
            // For each target port group, clean up all its target ports
            //
            while (!IsListEmpty(&targetPortGroup->TargetPortList)) {

                entry = RemoveHeadList(&targetPortGroup->TargetPortList);

                if (entry) {

                    targetPort = CONTAINING_RECORD(entry, DSM_TARGET_PORT_LIST_ENTRY, ListEntry);

                    if (targetPort) {

                        PLIST_ENTRY deviceEntry;
                        PDSM_TARGET_PORT_DEVICELIST_ENTRY listEntry;

                        while (!IsListEmpty(&targetPort->TP_DeviceList)) {

                            deviceEntry = RemoveHeadList(&targetPort->TP_DeviceList);

                            if (deviceEntry) {

                                listEntry = CONTAINING_RECORD(deviceEntry,
                                                              DSM_TARGET_PORT_DEVICELIST_ENTRY,
                                                              ListEntry);

                                if (listEntry) {

                                    TracePrint((TRACE_LEVEL_INFORMATION,
                                                TRACE_FLAG_PNP,
                                                "DsmpRemoveGroupEntry (Group %p): Deleting device %p from TP %p list (TPG %p).\n",
                                                GroupEntry,
                                                listEntry->DeviceInfo,
                                                targetPort,
                                                targetPortGroup));

                                    DsmpFreePool(listEntry);

                                    InterlockedDecrement((LONG volatile*)&targetPort->Count);
                                }
                            }
                        }

                        TracePrint((TRACE_LEVEL_INFORMATION,
                                    TRACE_FLAG_PNP,
                                    "DsmpRemoveGroupEntry (Group %p): Deleting target port %p from TPG %p list.\n",
                                    GroupEntry,
                                    targetPort,
                                    targetPortGroup));

                        DsmpFreePool(targetPort);

                        InterlockedDecrement((LONG volatile*)&targetPortGroup->NumberTargetPorts);
                    }
                }
            }

            NT_ASSERT(targetPortGroup->NumberTargetPorts == 0);

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpRemoveGroupEntry (Group %p): Deleting target port group %p.\n",
                        GroupEntry,
                        targetPortGroup));

            DsmpFreePool(targetPortGroup);

            InterlockedDecrement((LONG volatile*)&GroupEntry->NumberTargetPortGroups);
        }
    }

    NT_ASSERT(GroupEntry->NumberTargetPortGroups == 0);

    if (AcquireDSMLockExclusive) {
        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpRemoveGroupEntry (Group %p): Exiting function.\n",
                GroupEntry));

    return;
}


PDSM_FAILOVER_GROUP
DsmpSetNewPath(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDevice
    )
/*++

Routine Description:

    This routine will assign a new path to the multi-path group in
    which FailingDevice resides.

    Caller must NOT hold spin lock.

Arguments:

    DsmContext    - DSM context given to MPIO during initialization

    FailingDevice - The device-path that is being moved
                    (due to failure, or admin. request)

Return Value:

    The FOG containing the new path.

--*/
{
    ULONG SpecialHandlingFlag = 0;
    
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpSetNewPath (DevInfo %p): Entering function.\n",
                FailingDevice));

    if (DsmpIsSymmetricAccess(FailingDevice)) {

        DsmpSetLBForPathRemoval(DsmContext, FailingDevice, NULL, SpecialHandlingFlag);

    } else {

        DsmpSetLBForPathRemovalALUA(DsmContext, FailingDevice, NULL, SpecialHandlingFlag);
    }

  
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpSetNewPath (DevInfo %p): Exiting function with path (failGroup) %p.\n",
                FailingDevice,
                FailingDevice->Group->PathToBeUsed));

    return FailingDevice->Group->PathToBeUsed;
}


PDSM_FAILOVER_GROUP
DsmpSetNewPathUsingGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group
    )
/*++

Routine Description:

       This routine will try to assign a new path using the given multi-path group.
       This function should only be called during failover in the event that there
       is no DeviceInfo with which to call DsmpSetNewPath().

       Typically this will be called with one of a fail-over group's zombie groups.

       Caller must NOT hold spin lock.

Arguments:

       DsmContext - DSM context given to MPIO during initialization.

       Group - The multi-path group which to assign a new path.

Return Value:

       The FOG containing the new path or NULL if no path was found.

--*/

{
    ULONG               i;
    PDSM_DEVICE_INFO    pDevInfo = NULL;
    ULONG SpecialHandlingFlag = 0;

    TracePrint((TRACE_LEVEL_ERROR,
                TRACE_FLAG_GENERAL,
                "DsmpSetNewPathUsingGroup (Group %p): Entering function.\n",
                Group));

    //
    // Get the first available DeviceInfo.
    //
    for (i = 0; i < DSM_MAX_PATHS; i ++) {
        if (Group->DeviceList[i] != NULL) {
            pDevInfo = Group->DeviceList[i];
            break;
        }
    }

    if (pDevInfo == NULL) {
        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_GENERAL,
                    "DsmpSetNewPathForZombieGroup (ZombieGroup %p): No failover group can be found.\n",
                    Group));
        return NULL;
    }


    if (DsmpIsSymmetricAccess(pDevInfo)) {

        DsmpSetLBForPathRemoval(DsmContext, pDevInfo, Group, SpecialHandlingFlag);

    } else {

        DsmpSetLBForPathRemovalALUA(DsmContext, pDevInfo, Group, SpecialHandlingFlag);
    }


    TracePrint((TRACE_LEVEL_ERROR,
                TRACE_FLAG_GENERAL,
                "DsmpSetNewPathForZombieGroup (ZombieGroup %p): Exiting function with path (failGroup) %p.\n",
                Group,
                Group->PathToBeUsed));

    return Group->PathToBeUsed;

}


NTSTATUS
DsmpUpdateTargetPortGroupDevicesStates(
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN DSM_DEVICE_STATE NewState
    )
/*++

Routine Description:

    This routine will update the target port group and all its appropriate
    devInfos (ones not in remove pending, removed, or invalidated) with the
    new state. The ALUAState will only be updated, NOT the real State.
    Caller needs to update the real State based on the current LB policy.

    Note: This should be called with DsmContext Lock held and should only be
    called after a SetTargetPortGroups request was sent down.

Arguments:

    TargetPortGroup - TargetPortGroup whose state and deviceInfos need to be
                      updated

    NewState        - The new state

Return Value:

    STATUS_SUCCESS or appropriate failure code.

--*/
{
    NTSTATUS status = STATUS_SUCCESS;
    PLIST_ENTRY entry = NULL;
    PDSM_TARGET_PORT_LIST_ENTRY targetPort = NULL;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpUpdateTargetPortGroupDevicesStates (TPG %p): Entering function.\n",
                TargetPortGroup));

    if (!TargetPortGroup) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_GENERAL,
                    "DsmpUpdateTargetPortGroupDevicesStates (TPG %p): Invalid TPG passed in.\n",
                    TargetPortGroup));

        status = STATUS_INVALID_PARAMETER;
        goto __Exit_DsmpUpdateTargetPortGroupDevicesStates;
    }

    //
    // First update TPG's asymmetric access state.
    //
    TargetPortGroup->AsymmetricAccessState = NewState;

    //
    // Now update state of each of the devices belonging to this TPG.
    //
    for (entry = TargetPortGroup->TargetPortList.Flink;
         entry != &TargetPortGroup->TargetPortList;
         entry = entry->Flink) {

        targetPort = CONTAINING_RECORD(entry, DSM_TARGET_PORT_LIST_ENTRY, ListEntry);
        NT_ASSERT(targetPort);

        if (targetPort) {

            PLIST_ENTRY deviceEntry;
            PDSM_TARGET_PORT_DEVICELIST_ENTRY tp_device;

            for (deviceEntry = targetPort->TP_DeviceList.Flink;
                 deviceEntry != &targetPort->TP_DeviceList;
                 deviceEntry = deviceEntry->Flink) {

                tp_device = CONTAINING_RECORD(deviceEntry,
                                              DSM_TARGET_PORT_DEVICELIST_ENTRY,
                                              ListEntry);

                if (tp_device) {

                    tp_device->DeviceInfo->ALUAState = NewState;

                    TracePrint((TRACE_LEVEL_INFORMATION,
                                TRACE_FLAG_GENERAL,
                                "DsmpUpdateTargetPortGroupDevicesStates (TPG %p): Updated device %p alua state to %x.\n",
                                TargetPortGroup,
                                tp_device->DeviceInfo,
                                tp_device->DeviceInfo->ALUAState));
                }
            }
        }
    }

__Exit_DsmpUpdateTargetPortGroupDevicesStates:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpUpdateTargetPortGroupDevicesStates (TPG %p): Exiting function with status %x.\n",
                TargetPortGroup,
                status));

    return status;
}


VOID
DsmpIncrementCounters(
    _In_ PDSM_FAILOVER_GROUP FailGroup,
    _In_ PSCSI_REQUEST_BLOCK Srb
    )
{
    ULONG bytes = 0;
    PCDB cdb = NULL;
    ULONG cdbLength = 0;
    BOOLEAN isReadWrite = FALSE;
    ULONGLONG lastLba = 0;
    ULONG numBlocks = 0;
    ULONGLONG startLba = 0;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpIncrementCounters (FOG %p): Entering function.\n",
                FailGroup));

    if (Srb) {

        cdb = SrbGetCdb(Srb);

        if (cdb && DsmIsReadWrite(cdb->AsByte[0])) {

            isReadWrite = TRUE;
        }
    }

    InterlockedIncrement(&FailGroup->NumberOfRequestsInFlight);

    //
    // Update counters that apply to read/write requests
    //
    if (isReadWrite) {

        bytes = SrbGetDataTransferLength(Srb);

        InterlockedExchangeAdd64((LONGLONG volatile*)&FailGroup->OutstandingBytesOfIO, bytes);

        cdbLength = SrbGetCdbLength(Srb);

        if (cdbLength == 16) {

            REVERSE_BYTES_QUAD(&startLba, &cdb->CDB16.LogicalBlock);
            REVERSE_BYTES(&numBlocks, &cdb->CDB16.TransferLength);

        } else {

            REVERSE_BYTES(&startLba, &cdb->CDB10.LogicalBlockByte0);
            REVERSE_BYTES_SHORT(&numBlocks, &cdb->CDB10.TransferBlocksMsb);
        }

        lastLba = startLba + numBlocks - 1;

        InterlockedExchange64((LONGLONG volatile*)&FailGroup->LastLba, lastLba);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpIncrementCounters (FOG %p): Exiting function.\n",
                FailGroup));

    return;
}


BOOLEAN
DsmpDecrementCounters(
    _In_ PDSM_FAILOVER_GROUP FailGroup,
    _In_ PSCSI_REQUEST_BLOCK Srb
    )
{
    ULONG bytes = 0;
    PCDB cdb = NULL;
    BOOLEAN isReadWrite = FALSE;
    BOOLEAN isDeletionEligible = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpDecrementCounters (FOG %p): Entering function.\n",
                FailGroup));

    if (Srb) {

        cdb = SrbGetCdb(Srb);

        if (cdb && DsmIsReadWrite(cdb->AsByte[0])) {

            isReadWrite = TRUE;
        }
    }

    //
    // Update counters that apply to read/write requests
    //
    if (isReadWrite) {

        bytes = SrbGetDataTransferLength(Srb);

        InterlockedExchangeAdd64((LONGLONG volatile*)&FailGroup->OutstandingBytesOfIO, -(LONGLONG)bytes);
    }

    NT_ASSERT(FailGroup->NumberOfRequestsInFlight > 0);
    if (InterlockedCompareExchange(&FailGroup->NumberOfRequestsInFlight, 0, 0) > 0) {

        if(InterlockedDecrement(&FailGroup->NumberOfRequestsInFlight) == 0){
                
            //
            // If the inflight requests on the path is zero, if needed path can be removed.
            //
            isDeletionEligible = TRUE;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpDecrementCounters (FOG %p): Exiting function.\n",
                FailGroup));

    return isDeletionEligible;
}


PDSM_FAILOVER_GROUP
DsmpGetPath(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmList,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine will pick a path, for processing a request, based
    on the current LoadBalance policy that is set.

    N.B: This routine must be called with DSM Context Lock held in Shared mode.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    DsmList    - List of DSM Ids sent by MPIO
    Srb        - The read/write/verify request
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    FailOver Group that should be used for processing the request
--*/
{
    //
    // Algorithm:
    // ==========
    // Failover-only:
    // --------------
    //      If symmetric LUA (ie. ALUA not supported, or symmetric LUA using ALUA semantics (viz. storage reports
    //                                                              implicit-only transitions and all TPGs in A/O):
    //          One path AO,            <- this will be the only path used for I/O
    //          M paths in SB,          <- one of these will be made active on failure of the above active path
    //          Rest of the paths Failed (Invalidated/PendingRemove/Removed)
    //
    //      If ALUA:
    //          One path AO,            <- this will be the only path used for I/O
    //          M paths in AU, SB or UA <- one of these made active on failover. Pref: AU > SB > UA. Also, controller affinity.
    //          Rest of the paths Failed
    //
    //      Automatic failback will happen only if Preferred path has been set.
    //      This is the only policy that will support failback.
    //
    // Round-Robin:
    // ------------
    //      If symmetric LUA:
    //          N paths AO,             <- round robin among these
    //          Rest of the paths Failed
    //
    //      If ALUA:
    //          Round Robin policy not supported since all paths can't be in A/O state.
    //
    // Round-Robin With Subset:
    // ------------------------
    //      If symmetric LUA:
    //          N paths AO,             <- round robin among these
    //          M paths SB,             <- if no active paths left, make one of these active
    //          Rest of the paths Failed
    //
    //      If ALUA:
    //          N paths AO,             <- round robin among these (NOTE: paths in AU not considered)
    //          M paths AU, SB or UA    <- if no active paths, make subset of these active (based on TPG states after transition)
    //          Rest of the paths Failed
    //
    // Least-Queue Depth:
    // ------------------
    //      If symmetric LUA:
    //          N paths AO,             <- one with least outstanding I/O is chosen
    //          Rest of the paths Failed
    //
    //      If ALUA:
    //          N paths AO,             <- one with least outstanding I/O is chosen
    //          M paths AU, SB or UA    <- if no AO paths available, subset of these become active (based on TPG
    //                                        states after transition) - one with least outstanding I/O is chosen.
    //          Rest of the paths Failed
    //
    // Least-Weighted:
    // ---------------
    //      If symmetric LUA:
    //          N paths AO,             <- every path has an associated weight, path with least weight is used.
    //          Rest of the paths Failed
    //
    //      If ALUA:
    //          N paths AO,
    //          M paths AU, SB or UA    <- if no AO paths available, subset of these become active (based on TPG
    //                                        states after transition) - path with least weight used.
    //          Rest of the paths Failed
    //
    // Least-Blocks:
    // -------------
    //      If symmetric LUA:
    //          N paths AO,             <- one with least cumulative outstanding IO is chosen
    //          Rest of the paths Failed
    //
    //      If ALUA:
    //          N paths AO,             <- one with least cumulative outstanding IO is chosen
    //          M paths AU, SB or UA    <- if no AO paths available, subset of these become active (based on TPG
    //                                        states after transition) - one with least cumulative outstanding is chosen.
    //
    // Actual implementation of algorithm happens in the following routines: DsmpGetAnyActivePath,
    //          DsmpGetActivePathToBeUsed, flavors of DsmpSetLBForPathXXX.
    //

    PDSM_FAILOVER_GROUP failGroup = NULL;
    PDSM_DEVICE_INFO deviceInfo = DsmList->IdList[0];
    PDSM_GROUP_ENTRY groupEntry;
    ULONG inx = 0;

    UNREFERENCED_PARAMETER(DsmContext);
    UNREFERENCED_PARAMETER(SpecialHandlingFlag);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpGetPath (DsmIds %p): Entering function.\n",
                DsmList));

    if (!(DsmList->Count && deviceInfo)) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_RW,
                    "DsmpGetPath (DsmIds %p): Called with no available paths.\n",
                    DsmList));

        goto __Exit_DsmpGetPath;
    }

    groupEntry = deviceInfo->Group;
    DSM_ASSERT(groupEntry->GroupSig == DSM_GROUP_SIG);

    switch (groupEntry->LoadBalanceType) {

        case DSM_LB_FAILOVER:
        case DSM_LB_WEIGHTED_PATHS: {

            //
            // For FailOverOnly there is only one active path so we can
            // just grab it from the cached location and go with it.
            // For LeastWeightPath we always choose the lowest weighted
            // one so we grab that and go
            //
            failGroup = groupEntry->PathToBeUsed;

            break;
        }

        case DSM_LB_ROUND_ROBIN:
        case DSM_LB_ROUND_ROBIN_WITH_SUBSET: {

            PDSM_DEVICE_INFO candidateDevice = NULL;
            PDSM_GROUP_ENTRY newGroup = NULL;
            ULONG newPath;
            BOOLEAN foundPath = FALSE;
            ULONG jnx = 0;
            ULONG counter = 0;
            BOOLEAN reset = FALSE;

            for (inx = 0; inx < DsmList->Count; inx++) {

                deviceInfo = DsmList->IdList[inx];

                if (!(deviceInfo && DsmpIsDeviceInitialized(deviceInfo) && DsmpIsDeviceUsable(deviceInfo) && DsmpIsDeviceUsablePR(deviceInfo))) {

                    continue;
                }


                if (deviceInfo->FailGroup == groupEntry->PathToBeUsed) {

                    //
                    // We've reached the devInfo that corresponds to the path
                    // that we should be using. If this devInfo is not in the
                    // right state to be used, we need to find the first candidate
                    // starting from this one to satisfy the request.
                    // To play it safe, we may have already considered a previous
                    // devInfo to be a candidate, that now needs to be reset to
                    // the one that we now find.
                    //
                    reset = TRUE;
                }

#if DBG
                if (deviceInfo->TargetPortGroup && !DsmpIsDeviceFailedState(deviceInfo->State)) {

                    if (deviceInfo->State != deviceInfo->ALUAState) {

                        DSM_ASSERT(groupEntry->LoadBalanceType == DSM_LB_ROUND_ROBIN_WITH_SUBSET &&
                                   deviceInfo->State == DSM_DEV_ACTIVE_UNOPTIMIZED &&
                                   deviceInfo->DesiredState != DSM_DEV_ACTIVE_OPTIMIZED);
                    }
                }
#endif

                if (deviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED) {

                    if (!candidateDevice || reset) {

                        candidateDevice = deviceInfo;
                        TracePrint((TRACE_LEVEL_WARNING,
                                    TRACE_FLAG_RW,
                                    "DsmpGetPath (DsmIds %p): Candidate device %p.\n",
                                    DsmList,
                                    candidateDevice));

                        jnx = inx;
                    }

                    if (!groupEntry->PathToBeUsed || deviceInfo->FailGroup == groupEntry->PathToBeUsed) {

                        //
                        // The devInfo that corresponds to the path that we were
                        // supposed to use, is in a state that makes it usable.
                        // So we've found our devInfo.
                        //
                        InterlockedExchangePointer(&(groupEntry->PathToBeUsed), (PVOID)deviceInfo->FailGroup);
                        foundPath = TRUE;
                        candidateDevice = NULL;

                        break;
                    }
                }
            }

            if (!foundPath) {

                if (candidateDevice) {

                    InterlockedExchangePointer(&(groupEntry->PathToBeUsed), (PVOID)candidateDevice->FailGroup);
                    inx = jnx;
                    candidateDevice = NULL;

                } else {

                    inx = 0;
                }
            }

            failGroup = groupEntry->PathToBeUsed;

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_RW,
                        "DsmpGetPath (DsmIds %p): Path to be used is %p.\n",
                        DsmList,
                        groupEntry->PathToBeUsed));

            //
            // The current chosen path is given by failGroup. Find the next path
            // that should be chosen in the RoundRobin policy. Start with the
            // device at index inx + 1, and look for the one with Active state.
            //
            for (counter = 0, jnx = inx + 1;
                 counter < DsmList->Count && !newGroup;
                 counter++, jnx++) {

                newPath = jnx % DsmList->Count;

                deviceInfo = DsmList->IdList[newPath];

                if (!(deviceInfo && DsmpIsDeviceInitialized(deviceInfo) && DsmpIsDeviceUsable(deviceInfo) && DsmpIsDeviceUsablePR(deviceInfo))) {

                    continue;
                }


                if (deviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED) {

                    newGroup = deviceInfo->Group;
                    DSM_ASSERT(newGroup == groupEntry);

                    InterlockedExchangePointer(&(newGroup->PathToBeUsed), (PVOID)deviceInfo->FailGroup);

                    TracePrint((TRACE_LEVEL_WARNING,
                                TRACE_FLAG_RW,
                                "DsmpGetPath (DsmIds %p): New Path is %p.\n",
                                DsmList,
                                newGroup->PathToBeUsed));

                     break;
                }
            }

            break;
        }

        case DSM_LB_DYN_LEAST_QUEUE_DEPTH: {

            LONG leastQueueDepth = 0x7FFFFFFF;

            for (inx = 0; inx < DsmList->Count; inx++) {

                deviceInfo = DsmList->IdList[inx];

                if (!(deviceInfo && DsmpIsDeviceInitialized(deviceInfo) && DsmpIsDeviceUsable(deviceInfo) && DsmpIsDeviceUsablePR(deviceInfo))) {

                    continue;
                }


                if (deviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED &&
                    deviceInfo->FailGroup->NumberOfRequestsInFlight < leastQueueDepth) {

                    leastQueueDepth = deviceInfo->FailGroup->NumberOfRequestsInFlight;
                    failGroup = deviceInfo->FailGroup;
                }
            }

            if (failGroup) {

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_RW,
                            "DsmpGetPath (DsmIds %p): Path to be used for LQD is %p.\n",
                            DsmList,
                            failGroup));

            } else {

                //
                // For ALUA storage there are two cases where we are left with no
                // TPG in the A/O state:
                // 1) On storage that supports implicit transitions, a transition
                //    was initiated that left no TPG in the A/O state.
                // 2) On storage that has explicit only transitions enabled, we tried
                //    making at least one path as A/O and failed. This can happen,
                //    for example, when STPG fails because this initiator is not
                //    registered or does not hold exclusive reservation over the
                //    target.
                //
                // For such storages, we should return some path instead of just
                // failing the I/O. The path will likely be an A/U path until the
                // storage does a transition to make a TPG A/O.
                //
                if (!DsmpIsSymmetricAccess((PDSM_DEVICE_INFO)DsmList->IdList[0])) {

                    //
                    // Use the same path as the one used for the previous request.
                    //
                    failGroup = groupEntry->PathToBeUsed;

                    TracePrint((TRACE_LEVEL_WARNING,
                                TRACE_FLAG_PNP,
                                "DsmpGetPath (DsmIds %p): Using same path (FOG %p) as previous request for LQD.\n",
                                DsmList,
                                failGroup));
                } else {

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_RW,
                                "DsmpGetPath (DsmIds %p): Failed to find a path for LQD.\n",
                                DsmList));
                }
            }

            break;
        }

        case DSM_LB_LEAST_BLOCKS: {

            ULONG bytes = 0;
            PCDB cdb = NULL;
            ULONG cdbLength = 0;
            BOOLEAN isRead = FALSE;
            BOOLEAN isWrite = FALSE;
            PDSM_FAILOVER_GROUP lastPathUsed = groupEntry->PathToBeUsed;
            ULONGLONG leastOutstandingIO = MAXULONGLONG;
            ULONGLONG startLba = 0;

            //
            // Use the last path under the following conditions:
            //
            // 1. This is not a read/write request or
            // 2. This is a read/write request and
            //   a. The request is sequential and
            //   b. The cache is not exhausted
            //

            if (Srb) {

                cdb = SrbGetCdb(Srb);

                if (cdb && DsmIsReadRequest(cdb->AsByte[0])) {

                    isRead = TRUE;
                }

                if (cdb && DsmIsWriteRequest(cdb->AsByte[0])) {

                    isWrite = TRUE;
                }
            }

            if (isRead || isWrite) {
                
                if (groupEntry->UseCacheForLeastBlocks) {

                    bytes = SrbGetDataTransferLength(Srb);

                    cdbLength = SrbGetCdbLength(Srb);

                    if (cdbLength == 16) {

                        REVERSE_BYTES_QUAD(&startLba, &cdb->CDB16.LogicalBlock);

                    } else {

                        REVERSE_BYTES(&startLba, &cdb->CDB10.LogicalBlockByte0);
                    }

                    //
                    // Check if:
                    // 1. The IO is sequential, AND
                    // 2. It is either:
                    //    a. read request, OR
                    //    b. write request and outstanding bytes will be within the cache limit
                    //
                    if ((lastPathUsed != NULL) &&
                        (startLba >= lastPathUsed->LastLba) &&
                        ((isRead) ||
                         (isWrite && lastPathUsed->OutstandingBytesOfIO + bytes <= groupEntry->CacheSizeForLeastBlocks))) {

                        failGroup = groupEntry->PathToBeUsed;

                        TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_RW,
                            "DsmpGetPath (DsmIds %p): Sequential IO, so using same path %p for LeastBlocks.\n",
                            DsmList,
                            failGroup));
                    } 
                }

            } else {
                //
                // The request is neither a read nor a write so use the same path.
                //
                failGroup = groupEntry->PathToBeUsed;
            }

            if (!failGroup) {

                //
                // Choose whichever Active/Optimized path has the least outstanding bytes.
                //
                for (inx = 0; inx < DsmList->Count; inx++) {

                    deviceInfo = DsmList->IdList[inx];

                    if (!(deviceInfo && DsmpIsDeviceInitialized(deviceInfo) && DsmpIsDeviceUsable(deviceInfo) && DsmpIsDeviceUsablePR(deviceInfo))) {

                        continue;
                    }


                    if (deviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED &&
                        deviceInfo->FailGroup->OutstandingBytesOfIO < leastOutstandingIO) {

                        leastOutstandingIO = deviceInfo->FailGroup->OutstandingBytesOfIO;
                        failGroup = deviceInfo->FailGroup;
                    }
                }
            }

            if (failGroup) {

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_RW,
                            "DsmpGetPath (DsmIds %p): Path to be used for LeastBlocks is %p.\n",
                            DsmList,
                            failGroup));

            } else {

                //
                // For ALUA storage there are two cases where we are left with no
                // TPG in the A/O state:
                // 1) On storage that supports implicit transitions, a transition
                //    was initiated that left no TPG in the A/O state.
                // 2) On storage that has explicit only transitions enabled, we tried
                //    making at least one path as A/O and failed. This can happen,
                //    for example, when STPG fails because this initiator is not
                //    registered or does not hold exclusive reservation over the
                //    target.
                //
                // For such storages, we should return some path instead of just
                // failing the I/O. The path will likely be an A/U path until the
                // storage does a transition to make a TPG A/O.
                //
                if (!DsmpIsSymmetricAccess((PDSM_DEVICE_INFO)DsmList->IdList[0])) {

                    //
                    // Use the same path as the one used for the previous request.
                    //
                    failGroup = groupEntry->PathToBeUsed;

                    TracePrint((TRACE_LEVEL_WARNING,
                                TRACE_FLAG_PNP,
                                "DsmpGetPath (DsmIds %p): Using same path (FOG %p) as previous request for LeastBlocks.\n",
                                DsmList,
                                failGroup));
                } else {

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_RW,
                                "DsmpGetPath (DsmIds %p): Failed to find a path for LeastBlocks.\n",
                                DsmList));
                }
            }

            break;
        }

        default: {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_RW,
                        "DsmpGetPath (DsmIds %p): Invalid LB Type %d set for group %p.\n",
                        DsmList,
                        groupEntry->LoadBalanceType,
                        groupEntry));

            DSM_ASSERT(FALSE);

            break;
        }
    }

__Exit_DsmpGetPath:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpGetPath (DsmIds %p): Exiting function with failGroup %p.\n",
                DsmList,
                failGroup));

    return failGroup;
}


PVOID
DsmpGetPathIdFromPassThroughPath(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmList,
    _In_ PIRP Irp,
    _Inout_ IN OUT NTSTATUS *Status
    )
/*++

Routine Description:

    This routine will pick the path that corresponds to the PathId
    in the mpio pass through structure.

    NOTE: Caller must ensure that the IRP is either MPTP or MPTPD.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    DsmList    - List of DSM Ids sent by MPIO
    Irp        - The MPTP or MPTPD request
    Status     - Returned status

Return Value:

    The PathId to which the request should be sent
--*/
{
    PDSM_FAILOVER_GROUP failGroup = NULL;
    PDSM_GROUP_ENTRY groupEntry;
    PDSM_DEVICE_INFO deviceInfo;
    ULONG inx = 0;
    NTSTATUS status = STATUS_INVALID_PARAMETER;
    KIRQL irql;
    PVOID newPath = NULL;
    BOOLEAN found = FALSE;
    BOOLEAN useScsiAddress = FALSE;
    PIO_STACK_LOCATION irpStack = IoGetCurrentIrpStackLocation(Irp);
    ULONG controlCode = irpStack->Parameters.DeviceIoControl.IoControlCode;
    UCHAR pathId = 0;
    UCHAR targetId = 0;
    UCHAR portNumber = 0;
    ULONGLONG mpioPathId = 0;

#if DBG
    BOOLEAN useMpioPathId = FALSE;
#endif

    //
    // Extract the parameters from the passthrough based on the bitness of the
    // process (32 or 64) and the type of passthrough (legacy or extended).
    //
#if defined (_WIN64)
    if (IoIs32bitProcess(Irp)) {

        if (DsmpIsMPIOPassThroughEx(controlCode)) {
            PMPIO_PASS_THROUGH_PATH32_EX mpioPassThroughPath32 = (PMPIO_PASS_THROUGH_PATH32_EX)(Irp->AssociatedIrp.SystemBuffer);
            PSCSI_PASS_THROUGH32_EX passThrough32 = (PSCSI_PASS_THROUGH32_EX)((PUCHAR)mpioPassThroughPath32 + mpioPassThroughPath32->PassThroughOffset);

            useScsiAddress = mpioPassThroughPath32->Flags & MPIO_IOCTL_FLAG_USE_SCSIADDRESS;
            #if DBG
            useMpioPathId = mpioPassThroughPath32->Flags & MPIO_IOCTL_FLAG_USE_PATHID;
            #endif

            if (useScsiAddress) {
                PSTOR_ADDRESS address;
                if (passThrough32->StorAddressOffset < sizeof(SCSI_PASS_THROUGH_EX) ||
                    passThrough32->StorAddressLength < sizeof(STOR_ADDRESS)) {
                    *Status = STATUS_INVALID_PARAMETER;
                    return NULL;
                }
                address = (PSTOR_ADDRESS)((PUCHAR)passThrough32 + passThrough32->StorAddressOffset);
                if (address->Type != STOR_ADDRESS_TYPE_BTL8 ||
                    address->AddressLength < STOR_ADDR_BTL8_ADDRESS_LENGTH) {
                    *Status = STATUS_INVALID_PARAMETER;
                    return NULL;
                }
                pathId = ((PSTOR_ADDR_BTL8)address)->Path;
                targetId = ((PSTOR_ADDR_BTL8)address)->Target;
                portNumber = mpioPassThroughPath32->PortNumber;
            } else {
                mpioPathId = mpioPassThroughPath32->MpioPathId;
            }

        } else {
            PMPIO_PASS_THROUGH_PATH32 mpioPassThroughPath32 = (PMPIO_PASS_THROUGH_PATH32)(Irp->AssociatedIrp.SystemBuffer);

            useScsiAddress = mpioPassThroughPath32->Flags & MPIO_IOCTL_FLAG_USE_SCSIADDRESS;
            #if DBG
            useMpioPathId = mpioPassThroughPath32->Flags & MPIO_IOCTL_FLAG_USE_PATHID;
            #endif

            if (useScsiAddress) {
                pathId = mpioPassThroughPath32->PassThrough.PathId;
                targetId = mpioPassThroughPath32->PassThrough.TargetId;
                portNumber = mpioPassThroughPath32->PortNumber;
            } else {
                mpioPathId = mpioPassThroughPath32->MpioPathId;
            }
        }
    } else
#endif
    if (DsmpIsMPIOPassThroughEx(controlCode)) {
        PMPIO_PASS_THROUGH_PATH_EX mpioPassThroughPath = (PMPIO_PASS_THROUGH_PATH_EX)(Irp->AssociatedIrp.SystemBuffer);
        PSCSI_PASS_THROUGH_EX passThrough = (PSCSI_PASS_THROUGH_EX)((PUCHAR)mpioPassThroughPath + mpioPassThroughPath->PassThroughOffset);

        useScsiAddress = mpioPassThroughPath->Flags & MPIO_IOCTL_FLAG_USE_SCSIADDRESS;
        #if DBG
        useMpioPathId = mpioPassThroughPath->Flags & MPIO_IOCTL_FLAG_USE_PATHID;
        #endif

        if (useScsiAddress) {
            PSTOR_ADDRESS address;
            if (passThrough->StorAddressOffset < sizeof(SCSI_PASS_THROUGH_EX) ||
                passThrough->StorAddressLength < sizeof(STOR_ADDRESS)) {
                *Status = STATUS_INVALID_PARAMETER;
                return NULL;
            }
            address = (PSTOR_ADDRESS)((PUCHAR)passThrough + passThrough->StorAddressOffset);
            if (address->Type != STOR_ADDRESS_TYPE_BTL8 ||
                address->AddressLength < STOR_ADDR_BTL8_ADDRESS_LENGTH) {
                *Status = STATUS_INVALID_PARAMETER;
                return NULL;
            }
            pathId = ((PSTOR_ADDR_BTL8)address)->Path;
            targetId = ((PSTOR_ADDR_BTL8)address)->Target;
            portNumber = mpioPassThroughPath->PortNumber;
        } else {
            mpioPathId = mpioPassThroughPath->MpioPathId;
        }
    } else {
        PMPIO_PASS_THROUGH_PATH mpioPassThroughPath = (PMPIO_PASS_THROUGH_PATH)(Irp->AssociatedIrp.SystemBuffer);

        useScsiAddress = mpioPassThroughPath->Flags & MPIO_IOCTL_FLAG_USE_SCSIADDRESS;
        #if DBG
        useMpioPathId = mpioPassThroughPath->Flags & MPIO_IOCTL_FLAG_USE_PATHID;
        #endif

        if (useScsiAddress) {
            pathId = mpioPassThroughPath->PassThrough.PathId;
            targetId = mpioPassThroughPath->PassThrough.TargetId;
            portNumber = mpioPassThroughPath->PortNumber;
        } else {
            mpioPathId = mpioPassThroughPath->MpioPathId;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpGetPathIdFromPassThroughPath (DsmIds %p): Entering function.\n",
                DsmList));

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    deviceInfo = DsmList->IdList[0];
    groupEntry = deviceInfo->Group;
    DSM_ASSERT(groupEntry->GroupSig == DSM_GROUP_SIG);
    //
    // useMpioPathId is BOOLEAN (0 or 1) since MPIO_IOCTL_FLAG_USE_PATHID = 1
    // But since MPIO_IOCTL_FLAG_USE_SCSIADDRESS = 0x2, 
    // useScsiAddress could have a value of 2 if set. Use logical NOT to make boolean before comparing below
    //
    DSM_ASSERT(useMpioPathId == !useScsiAddress);

    for (inx = 0; inx < DSM_MAX_PATHS; inx++) {

        deviceInfo = groupEntry->DeviceList[inx];

        if (deviceInfo) {

            failGroup = deviceInfo->FailGroup;

            if (failGroup) {

                if (useScsiAddress) {

                    if (portNumber == deviceInfo->ScsiAddress->PortNumber &&
                        pathId == deviceInfo->ScsiAddress->PathId &&
                        targetId == deviceInfo->ScsiAddress->TargetId) {

                        found = TRUE;
                        break;
                    }
                } else {

                    NT_ASSERT(useMpioPathId);

                    if ((ULONGLONG)((ULONG_PTR)(failGroup->PathId)) == mpioPathId) {

                        found = TRUE;
                        break;
                    }
                }
            }
        }
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

    if (found) {

        newPath = failGroup->PathId;
        status = STATUS_SUCCESS;

        //
        // This should not affect the next path chosen based on the
        // current LB policy, so do NOT update groupEntry->PathToBeUsed
        //

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_RW,
                    "DsmpGetPathIdFromPassThroughPath (DsmIds %p): Failed to get corresponding path.\n",
                    DsmList));
    }

    if (Status) {

        *Status = status;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpGetPathIdFromPassThroughPath (DsmIds %p): Exiting function with path %p and status %x.\n",
                DsmList,
                newPath,
                status));

    return newPath;
}


BOOLEAN
DsmpShouldRetryTPGRequest(
    _In_ IN PVOID SenseData,
    _In_ IN UCHAR SenseDataSize
    )
/*++

Routine Description:

    This routine determines if a Report/Set TargetPortGroup request (sent either
    as a passThrough or as an IRP_MJ_SCSI) needs to be retried.

Arguments:

    SenseData - Pointer to Sense Data information buffer.
    SenseDataSize - Size of the passed in sense data buffer.

Return Value:

    TRUE if sense information indicates a retry-able error, else FALSE.

--*/
{
    BOOLEAN retry = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpShouldRetryTPGRequest (SenseData %p): Entering function.\n",
                SenseData));

    //
    // Two types of conditions need to be retried:
    // 1. Asymmetric Access State Changed
    // 2. Asymmetric Access State Transition
    //

    //
    // Check if asymmetric access state changed
    //
    retry = DsmpShouldRetryPassThroughRequest(SenseData, SenseDataSize);
    if (!retry) {

        BOOLEAN validSense = FALSE;
        UCHAR senseKey = 0;
        UCHAR addSenseCode = 0;
        UCHAR addSenseCodeQualifier = 0;

        validSense = ScsiGetSenseKeyAndCodes(SenseData,
                                             SenseDataSize,
                                             SCSI_SENSE_OPTIONS_FIXED_FORMAT_IF_UNKNOWN_FORMAT_INDICATED,
                                             &senseKey,
                                             &addSenseCode,
                                             &addSenseCodeQualifier);
        if (validSense) {

            if (senseKey == SCSI_SENSE_NOT_READY) {

                switch (addSenseCode) {
                    case SCSI_ADSENSE_LUN_NOT_READY: {

                        //
                        // Check if asymmetric access state transitioning
                        //
                        if (addSenseCodeQualifier == SPC3_SCSI_SENSEQ_ASYMMETRIC_ACCESS_STATE_TRANSITION) {

                            retry = TRUE;
                        }
                        break;
                    }

                    case SCSI_ADSENSE_OPERATING_CONDITIONS_CHANGED: {

                        if (addSenseCodeQualifier == SCSI_SENSEQ_REPORTED_LUNS_DATA_CHANGED) {

                            retry = TRUE;
                        }
                        break;
                    }

                    default: {
                        TracePrint((TRACE_LEVEL_ERROR,
                                    TRACE_FLAG_GENERAL,
                                    "DsmpShouldRetryTPGRequest (SenseData %p): AddSenseCode %x. Not retrying.\n",
                                    SenseData,
                                    addSenseCode));

                        retry = FALSE;
                        break;
                    }
                }
            }
        } else {
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_GENERAL,
                        "DsmpShouldRetryTPGRequest (SenseData %p): Sense data size %d not big enough.\n",
                        SenseData,
                        SenseDataSize));
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpShouldRetryTPGRequest (SenseData %p): Exiting function with retry %x.\n",
                SenseData,
                retry));

    return retry;
}


BOOLEAN
DsmpIsDeviceRemoved(
    _In_ IN PVOID   SenseData,
    _In_ IN UCHAR   SenseDataSize
    )
/*++

Routine Description:

    This routine evaluate Sense Data and determine if LUN is available or not.

Arguments:

    SenseData - Pointer to Sense Data information buffer.
    SenseDataSize - Size of the passed in sense data buffer.

Return Value:

    TRUE if device is no longer available, else FALSE.

--*/
{
    BOOLEAN validSense = FALSE;
    UCHAR senseKey = 0;
    UCHAR addSenseCode = 0;
    UCHAR addSenseCodeQualifier = 0;
    BOOLEAN bRemoved = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpIsDeviceRemoved (SenseData %p): Entering function.\n",
                SenseData));

    validSense = ScsiGetSenseKeyAndCodes(SenseData,
                                         SenseDataSize,
                                         SCSI_SENSE_OPTIONS_FIXED_FORMAT_IF_UNKNOWN_FORMAT_INDICATED,
                                         &senseKey,
                                         &addSenseCode,
                                         &addSenseCodeQualifier);

    if (validSense) {
        //
        // SPC 3 6.25 suggests response should follow Test Unit Ready responses
        // For now, we accept Ileegal Request as an indication of device not in available
        // state.
        //
        if (senseKey == SCSI_SENSE_ILLEGAL_REQUEST) {

            ASSERT(addSenseCodeQualifier == 0); //LOGICAL UNIT NOT SUPPORTED

            bRemoved = TRUE;
        }

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_GENERAL,
                    "DsmpIsDeviceRemoved (SenseData %p): SenseKey %x AddSenseCode %x. Remove %x\n",
                    SenseData,
                    senseKey,
                    addSenseCode,
                    bRemoved));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpIsDeviceRemoved (SenseData %p): Exiting function. Removed %x.\n",
                SenseData,
                bRemoved));

    return bRemoved;
}


BOOLEAN
DsmpReservationCommand(
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb
    )
/*++

Routine Description:

    This routine examines the DeviceIoControlCode and Srb OpCode to determine
    if this is PR request.

Arguments:

    Irp - The Irp containing Srb.
    Srb - The current non-read/write Srb.

Return Value:

    TRUE - If it's a special-case command (some reservation-handling request).

--*/
{
    PIO_STACK_LOCATION irpStack = IoGetCurrentIrpStackLocation(Irp);
    UCHAR opCode = 0;
    BOOLEAN isReservationCommand = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpReservationCommand (Irp %p): Entering function.\n",
                Irp));

    //
    // Ensure it's a scsi request before checking the opcode.
    //
    if (irpStack->MajorFunction == IRP_MJ_SCSI) {

        PCDB cdb = SrbGetCdb(Srb);
        if (cdb != NULL) {
            opCode = cdb->AsByte[0];

            if (opCode == SCSIOP_PERSISTENT_RESERVE_IN || opCode == SCSIOP_PERSISTENT_RESERVE_OUT) {

                //
                // Set or release a reservation.
                //
                isReservationCommand = TRUE;
            }
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpReservationCommand (Irp %p): Exiting function - IsReservationCmd %x.\n",
                Irp,
                isReservationCommand));

    return isReservationCommand;
}


BOOLEAN
DsmpMpioPassThroughPathCommand(
    _In_ IN PIRP Irp
    )
/*++

Routine Description:

    This routine examines the DeviceIoControlCode to determine whether this is
    either a mpio pass through or a mpio pass through direct. If so, it needs
    to be handled via a specific path indicated by the caller.

Arguments:

    Irp - The Irp.

Return Value:

    TRUE  - If it is either MPTP or MPTPD.
    FALSE - Otherwise.

--*/
{
    PIO_STACK_LOCATION irpStack = IoGetCurrentIrpStackLocation(Irp);
    ULONG ioctlCode;
    BOOLEAN isMPTPCommand = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpMpioPassThroughPathCommand (Irp %p): Entering function.\n",
                Irp));

    if (irpStack->MajorFunction == IRP_MJ_DEVICE_CONTROL) {

        //
        // Check whether this is a MPTP, MPTPD, or an extended flavor.
        //
        ioctlCode = irpStack->Parameters.DeviceIoControl.IoControlCode;

        if (ioctlCode == IOCTL_MPIO_PASS_THROUGH_PATH ||
            ioctlCode == IOCTL_MPIO_PASS_THROUGH_PATH_DIRECT ||
            ioctlCode == IOCTL_MPIO_PASS_THROUGH_PATH_EX ||
            ioctlCode == IOCTL_MPIO_PASS_THROUGH_PATH_DIRECT_EX) {

            isMPTPCommand = TRUE;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpMpioPassThroughPathCommand (Irp %p): Exiting function - IsMpioPassThruPathCmd %!bool!.\n",
                Irp,
                isMPTPCommand));

    return isMPTPCommand;
}


VOID
DsmpRequestComplete(
    _In_ IN PVOID DsmId,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PVOID DsmContext
    )
/*++

Routine Description:

    This routine is called from mpio's completion routine when the Irp
    has been completed by the port driver. Currently, it updates some counters
    and free's the context back to the look-aside list.

Arguments:

    DsmIds - The collection of DSM IDs that pertain to the MPDISK.
    Irp - Irp containing SRB.
    Srb - Scsi request block
    DsmContext - DSM context given to MPIO during initialization

Return Value:

    NONE

--*/

{
    PDSM_DEVICE_INFO deviceInfo = DsmId;
    PDSM_CONTEXT dsmContext = (PDSM_CONTEXT)DsmContext;
    UCHAR opCode = 0xFF;
    ULONG dataTransferLength = 0;
    PIO_STACK_LOCATION irpStack = IoGetCurrentIrpStackLocation(Irp);
    PDSM_FAILOVER_GROUP failGroup = irpStack->Parameters.Others.Argument3;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpRequestComplete (DevInfo %p): Entering function.\n",
                DsmId));

    DSM_ASSERT(DsmContext);

    if (Srb) {
        PCDB cdb = SrbGetCdb(Srb);
        if (cdb) {
            opCode = cdb->AsByte[0];
        }
        dataTransferLength = SrbGetDataTransferLength(Srb);
    }

    //
    // Extract the interesting bits from the context struct.
    //

    if (failGroup) {

        if (DsmpDecrementCounters(failGroup, Srb)) {

            //
            // If there are no requests on a path that is supposed to be removed, remove it now.
            //
            if (failGroup->State == DSM_FG_PENDING_REMOVE) {

                KIRQL oldIrql;

                NT_ASSERT(failGroup->Count == 0);

                oldIrql = ExAcquireSpinLockExclusive(&(dsmContext->DsmContextLock));
                RemoveEntryList(&failGroup->ListEntry);
                InterlockedDecrement((LONG volatile*)&dsmContext->NumberStaleFOGroups);

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_PNP,
                            "DsmpRequestComplete (DevInfo %p): Removing FOGroup %p with path %p.\n",
                            DsmId,
                            failGroup,
                            failGroup->PathId));

                DsmpFreePool(failGroup);
                ExReleaseSpinLockExclusive(&(dsmContext->DsmContextLock), oldIrql);
            }
        }
    }

    //
    // Note: We use the deviceInfo passed in since the one saved off in the
    // context may be stale in the case of a retried I/O
    //
    if (deviceInfo) {

        //
        // If statistics gathering is enabled update the inflight request count
        // for this device-path pairing.
        //
        if (!dsmContext->DisableStatsGathering) {

            //
            // Indicate one less request on this device.
            // Update the path that on which the increment was done.
            //
            if (InterlockedCompareExchange((LONG volatile*)&deviceInfo->NumberOfRequestsInProgress, 0, 0) > 0) {
                InterlockedDecrement(&(deviceInfo->NumberOfRequestsInProgress));
            }
        }

        //
        // If statistics gathering is enabled, we are interested in read/write requests
        //
        if (!dsmContext->DisableStatsGathering) {

            //
            // If it's a read or a write, update the stats.
            // Use the path that was cached during dispatch.
            //
            if (DsmIsReadRequest(opCode)) {

                if (deviceInfo->DeviceStats.NumberReads <= MAXULONG) {

                    InterlockedIncrement((LONG volatile*)&deviceInfo->DeviceStats.NumberReads);
                }

                if ((MAXULONGLONG - dataTransferLength) > deviceInfo->DeviceStats.BytesRead) {

                    deviceInfo->DeviceStats.BytesRead += dataTransferLength;

                } else {

                    deviceInfo->DeviceStats.BytesRead = MAXULONGLONG;
                }

            } else if (DsmIsWriteRequest(opCode)) {

                if (deviceInfo->DeviceStats.NumberWrites <= MAXULONG) {

                    InterlockedIncrement((LONG volatile*)&deviceInfo->DeviceStats.NumberWrites);
                }

                if ((MAXULONGLONG - dataTransferLength) > deviceInfo->DeviceStats.BytesWritten) {

                    deviceInfo->DeviceStats.BytesWritten += dataTransferLength;

                } else {

                    deviceInfo->DeviceStats.BytesWritten = MAXULONGLONG;
                }
            }
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpRequestComplete (DevInfo %p): Exiting function.\n",
                DsmId));

    return;
}


NTSTATUS
DsmpRegisterPersistentReservationKeys(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN BOOLEAN      Register
    )
/*++

Routine Description:

    This routine is used to build and send down the request to register
    or unregister the persistent reservation keys to the device down
    the path given by DeviceInfo.

Arguments:

    DeviceInfo - Device-path pair to use for sending down the request
    Register - Flag to indicate whether to register or unregister the keys.

Return Value:

    STATUS_SUCCESS on success, else appropriate failure code.

--*/
{
    PSCSI_PASS_THROUGH_WITH_BUFFERS passThrough = NULL;
    PCDB cdb;
    PPRO_PARAMETER_LIST parameters;
    IO_STATUS_BLOCK ioStatus;
    NTSTATUS status = STATUS_SUCCESS;
    ULONG length;
    PDSM_DEVICE_INFO deviceInfo = DeviceInfo;
    PDSM_GROUP_ENTRY group;
    ULONGLONG saKey;

    PAGED_CODE();

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpRegisterPersistentReservationKeys (DevInfo %p): Entering function - Register = %x.\n",
                deviceInfo,
                Register));

    group = DeviceInfo->Group;

    NT_ASSERT(group && group->PRKeyValid);

    if (DeviceInfo->State >= DSM_DEV_FAILED) {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_IOCTL,
                    "DsmpRegisterPersistentReservationKeys (DevInfo %p): Unusable - state %d.\n",
                    deviceInfo,
                    deviceInfo->State));

        status = STATUS_UNSUCCESSFUL;
        goto __Exit_DsmpRegisterPersistentReservationKeys;
    }

    //
    // Build a pass through command to process Persistent Reserve Out
    // for registering the device.
    //
    length = sizeof(SCSI_PASS_THROUGH_WITH_BUFFERS);

    passThrough = DsmpAllocatePool(NonPagedPoolNx,
                                   length,
                                   DSM_TAG_PASS_THRU);
    if (!passThrough) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_IOCTL,
                    "DsmpRegisterPersistentReservationKeys (DevInfo %p): Failed to allocate memory for persistent reserve.\n",
                    deviceInfo));

        status = STATUS_INSUFFICIENT_RESOURCES;
        goto __Exit_DsmpRegisterPersistentReservationKeys;
    }

    REVERSE_BYTES_QUAD(&saKey, &group->PersistentReservationRegisteredKey);
    TracePrint((TRACE_LEVEL_INFORMATION,
                TRACE_FLAG_IOCTL,
                "DsmpRegisterPersistentReservationKeys (DevInfo %p): Attempting PR-Out SA %u, Type %u, Scope %u, PR-Key %I64x.\n",
                deviceInfo,
                group->PRServiceAction,
                group->PRType,
                group->PRScope,
                saKey));

__RetryRequest:

    //
    // Build the cdb to reserve the device (Logical Unit). The type of reservation
    // scope and service action is whatever cluster service provided at the time of
    // sending down registration to this device before this particular path was available.
    //
    cdb = (PCDB) passThrough->ScsiPassThrough.Cdb;
    cdb->PERSISTENT_RESERVE_OUT.OperationCode = SCSIOP_PERSISTENT_RESERVE_OUT;
    cdb->PERSISTENT_RESERVE_OUT.ServiceAction = group->PRServiceAction;
    cdb->PERSISTENT_RESERVE_OUT.Scope = group->PRScope;
    cdb->PERSISTENT_RESERVE_OUT.Type = group->PRType;
    cdb->PERSISTENT_RESERVE_OUT.ParameterListLength[1] = sizeof(PRO_PARAMETER_LIST);

    passThrough->ScsiPassThrough.Length = sizeof(SCSI_PASS_THROUGH);
    passThrough->ScsiPassThrough.CdbLength = 10;
    passThrough->ScsiPassThrough.SenseInfoLength = SPTWB_SENSE_LENGTH;
    passThrough->ScsiPassThrough.DataIn = 0;
    passThrough->ScsiPassThrough.DataTransferLength = sizeof(PRO_PARAMETER_LIST);
    passThrough->ScsiPassThrough.TimeOutValue = 20;
    passThrough->ScsiPassThrough.SenseInfoOffset = FIELD_OFFSET(SCSI_PASS_THROUGH_WITH_BUFFERS, SenseInfoBuffer);
    passThrough->ScsiPassThrough.DataBufferOffset = FIELD_OFFSET(SCSI_PASS_THROUGH_WITH_BUFFERS, DataBuffer);

    parameters = (PPRO_PARAMETER_LIST)(passThrough->DataBuffer);

    //
    // Copy the persistent reservation key given by cluster service to
    // Service Action Reservation Key. This key will be registered
    // with the device.
    //
    // Set ServiceActionReservationKey to the well-known key if we are registering.
    // Note that to unregister ServiceActionReservationKey needs to be set to 0.
    //
    if (Register) {

        RtlCopyMemory(parameters->ServiceActionReservationKey, group->PersistentReservationRegisteredKey, 8);

    } else {

        RtlCopyMemory(parameters->ReservationKey, group->PersistentReservationRegisteredKey, 8);
        RtlZeroMemory(parameters->ServiceActionReservationKey, 8);
    }

    DsmSendDeviceIoControlSynchronous(IOCTL_SCSI_PASS_THROUGH,
                                      DeviceInfo->TargetObject,
                                      passThrough,
                                      passThrough,
                                      length,
                                      length,
                                      FALSE,
                                      &ioStatus);

    status = ioStatus.Status;

    if ((passThrough->ScsiPassThrough.ScsiStatus == SCSISTAT_GOOD) && (NT_SUCCESS(ioStatus.Status))) {

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_IOCTL,
                    "DsmpRegisterPersistentReservationKeys (DevInfo %p): Persistent Reserve (Register Key) succeeded using %p.\n",
                    deviceInfo,
                    DeviceInfo));

    } else {

        PUCHAR senseData;
        UCHAR senseInfoLength;

        senseData = (PUCHAR)(passThrough->SenseInfoBuffer);
        senseInfoLength = passThrough->ScsiPassThrough.SenseInfoLength;

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_IOCTL,
                    "DsmpRegisterPersistentReservationKeys (DevInfo %p): DevInfo %p, Register keys (%d): NTStatus %x, ScsiStatus %x.\n",
                    deviceInfo,
                    DeviceInfo,
                    Register,
                    ioStatus.Status,
                    passThrough->ScsiPassThrough.ScsiStatus));

        if (DsmpShouldRetryPassThroughRequest((PVOID)senseData, senseInfoLength)) {

            length = sizeof(SCSI_PASS_THROUGH_WITH_BUFFERS);

            RtlZeroMemory(passThrough, length);

            goto __RetryRequest;

        } else if (NT_SUCCESS(status)) {

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_IOCTL,
                        "DsmpRegisterPersistentReservationKeys (DevInfo %p): Will change success to error status for register\n",
                        deviceInfo));

            status = STATUS_INVALID_DEVICE_REQUEST;
        }
    }

    //
    // Free the passthrough + data buffer.
    //
    DsmpFreePool(passThrough);

__Exit_DsmpRegisterPersistentReservationKeys:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpRegisterPersistentReservationKeys (DevInfo %p): Exiting function with status %x.\n",
                DeviceInfo,
                status));

    return status;
}



BOOLEAN
DsmpShouldRetryPassThroughRequest(
    _In_ IN PVOID SenseData,
    _In_ IN UCHAR SenseDataSize
    )
/*++

Routine Description:

    This routine determines if a passthrough request needs to be retried based on the
    information in the passed in sense data.

Arguments:

    SenseData - Pointer to Sense Data information buffer.
    SenseDataSize - Size of the passed in sense data buffer.

Return Value:

    TRUE if sense information indicates a retry-able error, else FALSE.

--*/
{
    BOOLEAN validSense = FALSE;
    UCHAR senseKey = 0;
    UCHAR addSenseCode = 0;
    BOOLEAN retry = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpShouldRetryPassThroughRequest (SenseData %p): Entering function.\n",
                SenseData));

#if DBG
    if (SenseDataSize > 0) {

        ULONG inx;
        PUCHAR senseInfo;


        senseInfo = (PUCHAR) SenseData;

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_GENERAL,
                    "DsmpShouldRetryPassThroughRequest (SenseData %p): Sense info length %d. Sense Info : ",
                    SenseData,
                    SenseDataSize));

        for (inx = 0; inx < SenseDataSize; inx++) {
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_GENERAL,
                        "%x ",
                        senseInfo[inx]));
        }

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_GENERAL,
                    "\n"));
    }
#endif

    validSense = ScsiGetSenseKeyAndCodes(SenseData,
                                         SenseDataSize,
                                         SCSI_SENSE_OPTIONS_FIXED_FORMAT_IF_UNKNOWN_FORMAT_INDICATED,
                                         &senseKey,
                                         &addSenseCode,
                                         NULL);
    if (validSense) {
        if (senseKey == SCSI_SENSE_UNIT_ATTENTION) {

            switch (addSenseCode) {
                case SCSI_ADSENSE_OPERATING_CONDITIONS_CHANGED:
                case SCSI_ADSENSE_BUS_RESET:
                case SCSI_ADSENSE_PARAMETERS_CHANGED: {
                    retry = TRUE;
                    break;
                }

                default: {
                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_GENERAL,
                                "DsmpShouldRetryPassThroughRequest (SenseData %p): AddSenseCode %x. Not retrying.\n",
                                SenseData,
                                addSenseCode));

                    retry = FALSE;
                    break;
                }
            }
        }
    } else {
        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_GENERAL,
                    "DsmpShouldRetryPassThroughRequest (SenseData %p): Sense data size %d not big enough.\n",
                    SenseData,
                    SenseDataSize));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpShouldRetryPassThroughRequest (SenseData %p): Exiting function with retry %x.\n",
                SenseData,
                retry));

    return retry;
}


BOOLEAN
DsmpShouldRetryPersistentReserveCommand(
    _In_ IN PVOID SenseData,
    _In_ IN UCHAR SenseDataSize
    )
/*++

Routine Description:

    This routine determines if a a PR request needs to be retried based on the
    information in the passed in sense data.

Arguments:

    SenseData - Pointer to Sense Data information buffer.
    SenseDataSize - Size of the passed in sense data buffer.

Return Value:

    TRUE if sense information indicates a retry-able error, else FALSE.

--*/
{
    BOOLEAN retry = FALSE;
    BOOLEAN validSense = FALSE;
    UCHAR senseKey = 0;
    UCHAR addSenseCode = 0;
    UCHAR addSenseCodeQualifier = 0;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpShouldRetryPersistentReserveCommand (SenseData %p): Entering function.\n",
                SenseData));

    retry = DsmpShouldRetryPassThroughRequest(SenseData, SenseDataSize);

    if (!retry) {
        validSense = ScsiGetSenseKeyAndCodes(SenseData,
                                             SenseDataSize,
                                             SCSI_SENSE_OPTIONS_FIXED_FORMAT_IF_UNKNOWN_FORMAT_INDICATED,
                                             &senseKey,
                                             &addSenseCode,
                                             &addSenseCodeQualifier);
        if (validSense) {

            //
            // If the TPG is in transitioning state, retry the request
            //
            if ((senseKey == SCSI_SENSE_UNIT_ATTENTION || senseKey == SCSI_SENSE_NOT_READY) &&
                (addSenseCode == SCSI_ADSENSE_LUN_NOT_READY &&
                 addSenseCodeQualifier == SPC3_SCSI_SENSEQ_ASYMMETRIC_ACCESS_STATE_TRANSITION)) {

                retry = TRUE;
            }
        } else {
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_GENERAL,
                        "DsmpShouldRetryPersistentReserveCommand (SenseData %p): Sense data size %d not big enough.\n",
                        SenseData,
                        SenseDataSize));
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpShouldRetryPersistentReserveCommand (SenseData %p): Exiting function with retry %x.\n",
                SenseData,
                retry));

    return retry;
}


VOID
DsmpAllowStandbyPathsToRest(
    _In_ PDSM_GROUP_ENTRY Group
    )
/*++

Routine Description:

    This routine is called when a new path is available for a device
    and has a desired state of ACTIVE_O. Since this will be an ACTIVE_O
    path we see if there are any paths with a desired state of Standby
    but that are currently active. These paths can be safely moved by
    to standby.

    This routine assumes that the lock is held

Arguements:

    Group is the multipath group

Return Value:

    None
--*/
{
    PDSM_DEVICE_INFO existingDeviceInfo;
    ULONG inx;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpAllowStandbyPathsToRest (Group %p): Entering function.\n",
                Group));

    for (inx = 0; inx < Group->NumberDevices; inx++) {

        existingDeviceInfo = Group->DeviceList[inx];

        if ((existingDeviceInfo->DesiredState == DSM_DEV_STANDBY) &&
            (existingDeviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED)) {

            existingDeviceInfo->State = DSM_DEV_STANDBY;

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpAllowStandbyPathsToRest (Group %p): DevInfo %p changed to state %d at %d\n",
                        Group,
                        existingDeviceInfo,
                        existingDeviceInfo->State,
                        __LINE__));
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpAllowStandbyPathsToRest (Group %p): Exiting function.\n",
                Group));
    return;
}


PDSM_DEVICE_INFO
DsmpGetAnyActivePath(
    _In_ PDSM_GROUP_ENTRY Group,
    _In_ BOOLEAN Exception,
    _In_opt_ PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine will return an active path from the list

    This routine assumes that the DSM lock is held

Arguements:

    Group is the multipath group
    Exception - if TRUE, indicates that the returned devInfo must not be the same
                as the one passed in.
    DeviceInfo - the must-not-match devInfo. Valid parameter only if Exception is
                 TRUE.
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    active path or NULL

--*/
{
    PDSM_DEVICE_INFO existingDeviceInfo;
    PDSM_DEVICE_INFO candidateDevInfo = NULL;
    ULONG inx;

    UNREFERENCED_PARAMETER(SpecialHandlingFlag);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpGetAnyActivePath (Group %p): Entering function.\n",
                Group));

    for (inx = 0; inx < DSM_MAX_PATHS; inx++) {

        existingDeviceInfo = Group->DeviceList[inx];

        if (existingDeviceInfo &&
            existingDeviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED &&
            DsmpIsDeviceInitialized(existingDeviceInfo) &&
            DsmpIsDeviceUsable(existingDeviceInfo) &&
            DsmpIsDeviceUsablePR(existingDeviceInfo)) {


            if (Exception && existingDeviceInfo == DeviceInfo) {
                continue;
            }

            candidateDevInfo = existingDeviceInfo;
            break;
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpGetAnyActivePath (Group %p): Exiting function with DevInfo %p\n",
                Group,
                candidateDevInfo));
                
    return candidateDevInfo;
}


PDSM_DEVICE_INFO
DsmpGetActivePathToBeUsed(
    _In_ PDSM_GROUP_ENTRY Group,
    _In_ BOOLEAN Symmetric,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine will return an active path from the list that should
    be the next one used by the DSM

    This routine assumes that the DSM lock is held

Arguements:

    Group is the multipath group
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    active path or NULL

--*/
{
    PDSM_DEVICE_INFO deviceInfo;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpGetActivePathToBeUsed (Group %p): Entering function.\n",
                Group));

    deviceInfo = NULL;

    switch (Group->LoadBalanceType) {

        case DSM_LB_LEAST_BLOCKS:
        case DSM_LB_DYN_LEAST_QUEUE_DEPTH: {

            //
            // Since we choose the path with the smallest queue or cumulative size in
            // DsmpGetPath, we just pick any path now
            //

            // fall through
        }

        case DSM_LB_ROUND_ROBIN_WITH_SUBSET:
        case DSM_LB_ROUND_ROBIN: {

            //
            // For RR and RRS we just pick any active path to start with
            // and the DsmpGetPath will do the round robining
            //
        }

        case DSM_LB_FAILOVER: {

            deviceInfo = DsmpGetAnyActivePath(Group, FALSE, NULL, SpecialHandlingFlag);

            break;
        }

        case DSM_LB_WEIGHTED_PATHS: {

            PDSM_DEVICE_INFO workDeviceInfo;
            ULONG weight = (ULONG) -1;
            ULONG inx;

            for (inx = 0; inx < Group->NumberDevices; inx++) {

                workDeviceInfo = Group->DeviceList[inx];

                if ((workDeviceInfo) &&
                    (DsmpIsDeviceInitialized(workDeviceInfo)) &&
                    (DsmpIsDeviceUsable(workDeviceInfo)) &&
                    (DsmpIsDeviceUsablePR(workDeviceInfo)) &&
                    (workDeviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED) &&
                    (workDeviceInfo->PathWeight < weight)) {

                    //
                    // We found a path that is active and is at
                    // the lowest weight. Remember it.
                    //
                    weight = workDeviceInfo->PathWeight;

                    deviceInfo = workDeviceInfo;
                }
            }

            break;
        }

        default: {

            break;
        }
    }

    if (!deviceInfo && !Symmetric) {

        //
        // In the case of implicit transitions, it is possible that a TPG hasn't yet
        // been made A/O. So instead of not setting any path, fall back to using some
        // other path. IO sent down this path may fail, but will be retried in
        // InterpretError(). Hopefully by then, at least one TPG will have transitioned
        // to A/O state.
        //
        // The same argument holds true if the storage supports both implicit and
        // explicit transitions, since it is possible that after we explicitly changed
        // the TPG states, an implicit transition left us with no path in A/O state.
        //
        // In the case of explicit only transitions, we tried making at least one path
        // as A/O and failed. This can happen, for example, when STPG fails because
        // this initiator is not registered or does not hold exclusive reservation over
        // the target. Instead of not using any path, we can consider a path in A/U state,
        // A/U being just a functional path state.
        //
        BOOLEAN sendTPG = FALSE;

        deviceInfo = DsmpFindStandbyPathToActivateALUA(Group, &sendTPG, SpecialHandlingFlag);

        if ((deviceInfo != NULL) &&
            ((deviceInfo->ALUASupport != DSM_DEVINFO_ALUA_EXPLICIT) ||
             ((deviceInfo->ALUASupport == DSM_DEVINFO_ALUA_EXPLICIT) &&
              (deviceInfo->State <= DSM_DEV_ACTIVE_UNOPTIMIZED)))) {

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_PNP,
                        "DsmpGetActivePathToBeUsed (Group %p): Using best alternative candidate device %p\n",
                        Group,
                        deviceInfo));
        } else {

            deviceInfo = NULL;

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_PNP,
                        "DsmpGetActivePathToBeUsed (Group %p): No active/alternative path available for group\n",
                        Group));
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpGetActivePathToBeUsed (Group %p): Exiting function with devInfo %p.\n",
                Group,
                deviceInfo));

    return deviceInfo;
}


PDSM_DEVICE_INFO
DsmpFindStandbyPathToActivate(
    _In_ PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine will find another path in the group that is active

    This routine assumes that the DSM lock is held

    This is used by devices that support symmetric LUA.

Arguements:

    Group is the multipath group
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Standby path or NULL if no standby path is available

--*/
{
    PDSM_DEVICE_INFO existingDeviceInfo;
    ULONG inx;
    PDSM_DEVICE_INFO candidateDevInfo = NULL;

    UNREFERENCED_PARAMETER(SpecialHandlingFlag);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindStandbyPathToActivate(Group %p): Entering function.\n",
                Group));

    for (inx = 0; inx < Group->NumberDevices; inx++) {

        existingDeviceInfo = Group->DeviceList[inx];

        if (existingDeviceInfo &&
            existingDeviceInfo->State == DSM_DEV_STANDBY &&
            DsmpIsDeviceInitialized(existingDeviceInfo) &&
            DsmpIsDeviceUsable(existingDeviceInfo) &&
            DsmpIsDeviceUsablePR(existingDeviceInfo)) {

            //
            // If we don't as yet have a candidate, pick the first available one.
            // However, our preference is one that is through the preferred TPG.
            //
            if (!candidateDevInfo ||
                existingDeviceInfo->TargetPortGroup && existingDeviceInfo->TargetPortGroup->Preferred) {

                candidateDevInfo = existingDeviceInfo;
            }
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindStandbyPathToActivate (Group %p): Exiting function with devInfo %p.\n",
                Group,
                candidateDevInfo));
                
    return candidateDevInfo;
}


PDSM_DEVICE_INFO
DsmpFindStandbyPathToActivateALUA(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PBOOLEAN SendTPG,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine will find another path in the group that is active

    This is used by devices that don't support symmetric LUA.

    N.B: This routine MUST be called with DsmContextLock held in either Shared or
    Exclusive mode.

Arguements:

    Group is the multipath group
    SendTPG - output parameter that indicates if TPG command need to be sent down.
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Standby path or NULL if no standby path is available

--*/
{
    PDSM_DEVICE_INFO existingDeviceInfo;
    ULONG inx;
    PDSM_DEVICE_INFO candidateDevInfo = NULL;

    UNREFERENCED_PARAMETER(SpecialHandlingFlag);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindStandbyPathToActivateALUA (Group %p): Entering function.\n",
                Group));

    for (inx = 0; inx < Group->NumberDevices; inx++) {

        existingDeviceInfo = Group->DeviceList[inx];

        //
        // The candidate for making A/O obviously mustn't be in a failed state
        // and should have a path assigned.
        //
        if (existingDeviceInfo &&
            !DsmpIsDeviceFailedState(existingDeviceInfo->State) &&
            DsmpIsDeviceInitialized(existingDeviceInfo) &&
            DsmpIsDeviceUsable(existingDeviceInfo) &&
            DsmpIsDeviceUsablePR(existingDeviceInfo)) {

            //
            // If we don't have any candidate currently, choose the very first
            // one that is in a non-failure state, regardless of what state it
            // may be in.
            //
            if (!candidateDevInfo) {

                candidateDevInfo = existingDeviceInfo;
                *SendTPG = TRUE;
            }

            //
            // Might as well use one that the Admin desires for to be in A/O
            //
            if (existingDeviceInfo->DesiredState == DSM_DEV_ACTIVE_OPTIMIZED) {

                //
                // However, such a devInfo is not a better candidate if our candidate
                // devInfo is also one that the Admin desires be in A/O, and it is
                // through a preferred TPG.
                //
                if (!(existingDeviceInfo->DesiredState == candidateDevInfo->DesiredState &&
                      candidateDevInfo->TargetPortGroup->Preferred)) {

                    candidateDevInfo = existingDeviceInfo;
                    *SendTPG = TRUE;
                }
            }

            //
            // Check if the current one is at least better than the candidate.
            //
            if (DsmpIsBetterDeviceState(candidateDevInfo->State, existingDeviceInfo->State)) {

                candidateDevInfo = existingDeviceInfo;
                *SendTPG = TRUE;
            }

            //
            // We found one that we may have just masked as non-A/O. This is the
            // best option as we don't have to send down an STPG.
            //
            if (existingDeviceInfo->ALUAState == DSM_DEV_ACTIVE_OPTIMIZED) {

                candidateDevInfo = existingDeviceInfo;
                *SendTPG = FALSE;
                break;
            }
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindStandbyPathToActivateALUA (Group %p): Exiting function with devInfo %p.\n",
                Group,
                candidateDevInfo));
                
    return candidateDevInfo;
}


PDSM_DEVICE_INFO
DsmpFindStandbyPathInAlternateTpgALUA(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine will find another path in the group that is not in the same
    TPG as the passed in DeviceInfo.

    This routine assumes that the DSM lock is held

    This is used by devices that support ALUA.

Arguements:

    Group is the multipath group
    DeviceInfo is the devInfo whose TPG must not be matched
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Standby path not in same TPG as passed in DeviceInfo
    or NULL if no standby path is available

--*/
{
    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroup = DeviceInfo->TargetPortGroup;
    PDSM_DEVICE_INFO existingDeviceInfo;
    ULONG inx;
    PDSM_DEVICE_INFO candidateDevInfo = NULL;

    UNREFERENCED_PARAMETER(SpecialHandlingFlag);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindStandbyPathInAlternateTpgALUA (DevInfo %p): Entering function.\n",
                DeviceInfo));

    for (inx = 0; inx < Group->NumberDevices; inx++) {

        existingDeviceInfo = Group->DeviceList[inx];

        //
        // We only care about deviceInfo if TPG is different
        //
        if (existingDeviceInfo && existingDeviceInfo->TargetPortGroup != targetPortGroup) {

            //
            // The candidate for making A/O obviously mustn't be in a failed state
            // and must be initialized
            //
            if (!DsmpIsDeviceFailedState(existingDeviceInfo->State) &&
                DsmpIsDeviceInitialized(existingDeviceInfo) &&
                DsmpIsDeviceUsable(existingDeviceInfo) &&
                DsmpIsDeviceUsablePR(existingDeviceInfo)) {

                //
                // If we don't have any candidate currently, choose the very first
                // one that is in a non-failure state, regardless of what state it
                // may be in.
                //
                if (!candidateDevInfo) {

                    candidateDevInfo = existingDeviceInfo;
                    continue;
                }

                //
                // Check if the current one is at least better than the candidate.
                //
                if (DsmpIsBetterDeviceState(candidateDevInfo->State, existingDeviceInfo->State)) {

                    candidateDevInfo = existingDeviceInfo;
                }
            }
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_GENERAL,
                "DsmpFindStandbyPathInAlternateTpgALUA (DevInfo %p): Exiting function with devInfo %p.\n",
                DeviceInfo,
                candidateDevInfo));

    return candidateDevInfo;
}


NTSTATUS
DsmpSetLBForDsmPolicyAdjustment(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONGLONG PreferredPath
    )

/*++

Routine Description:

    This routine is called when a change is made to the DSM-wide default
    load balance policy. It goes through each LUN representation (ie. Group
    entry) and updates the appropriate ones (ie. ones for which the policy
    was not chosen based on VID/PID or because of an explicit settings on
    the LUN). It also then updates the path states in accordance with the
    new LB policy.

Arguements:

    DsmContext is the DSM context
    LoadBalanceType is the new load balance policy to be applied
    PreferredPath is the preferred failback path to be used (applicable only
                  if LB policy is Failover)

Return Value:

    Success

--*/

{
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL oldIrql;
    PLIST_ENTRY entry;
    ULONG groupIndex = 0;
    ULONG devInfoIndex;
    PDSM_GROUP_ENTRY group;
    PDSM_DEVICE_INFO devInfo;
    DSM_LOAD_BALANCE_TYPE newLoadBalancePolicy;
    ULONG SpecialHandlingFlag = 0;
    
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetLBForDsmPolicyAdjustment (DsmContext %p): Entering function.\n",
                DsmContext));

    oldIrql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    for (entry = DsmContext->GroupList.Flink; entry != &(DsmContext->GroupList); entry = entry->Flink, groupIndex++) {

        group = CONTAINING_RECORD(entry, DSM_GROUP_ENTRY, ListEntry);

        newLoadBalancePolicy = LoadBalanceType;

        //
        // Only LUNs that don't have their policy explicitly set
        // and ones that don't have it set based on VID/PID are
        // of interest to us here.
        //
        if (group->LBPolicySelection == DSM_DEFAULT_LB_POLICY_ALUA_CAPABILITY ||
            group->LBPolicySelection == DSM_DEFAULT_LB_POLICY_DSM_WIDE) {

            //
            // Also, if the caller is trying to clear the DSM-wide
            // default policy, then we don't even care about those
            // LUNs whose policies were not set using this value.
            //
            if (newLoadBalancePolicy < DSM_LB_FAILOVER &&
                group->LBPolicySelection != DSM_DEFAULT_LB_POLICY_DSM_WIDE) {

                continue;
            }

            //
            // If the DSM-wide setting is being cleared, we need to fall back
            // to using the default based on the array's ALUA capabilities.
            //
            if (newLoadBalancePolicy < DSM_LB_FAILOVER) {

                newLoadBalancePolicy = DSM_LB_ROUND_ROBIN;
                group->PreferredPath = (ULONGLONG)((ULONG_PTR)MAXULONG);
                group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_ALUA_CAPABILITY;


            } else {

                //
                // Since a new policy has been selected for the DSM-wide
                // one, it needs to be applied to this LUN.
                //
                group->PreferredPath = (ULONGLONG)((ULONG_PTR)PreferredPath);
                group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_DSM_WIDE;
            }

            //
            // If Round Robin is set and ALUA is enabled, we need to change the
            // policy to Round Robin with Subset.
            //
            if (!DsmpIsSymmetricAccess(group->DeviceList[0]) && newLoadBalancePolicy == DSM_LB_ROUND_ROBIN) {

                newLoadBalancePolicy = DSM_LB_ROUND_ROBIN_WITH_SUBSET;
            }

            //
            // Finally set the new load balance policy.
            //
            group->LoadBalanceType = newLoadBalancePolicy;

            //
            // Path states need to be updated in accordance with the new policy.
            //
            for (devInfoIndex = 0; devInfoIndex < DSM_MAX_PATHS; devInfoIndex++) {

                devInfo = group->DeviceList[devInfoIndex];
                DsmpSetNewDefaultLBPolicy(DsmContext, devInfo, group->LoadBalanceType, SpecialHandlingFlag);
            }
        }
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), oldIrql);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetLBForDsmPolicyAdjustment (DsmContext %p): Exiting function with status %x\n",
                DsmContext,
                status));

    return status;
}


NTSTATUS
DsmpSetLBForVidPidPolicyAdjustment(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PWSTR TargetHardwareId,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONGLONG PreferredPath
    )

/*++

Routine Description:

    This routine is called when a change is made to the default load balance
    policy for a VID/PID. It goes through each LUN representation (ie. Group
    entry) and updates the appropriate ones (ie. ones for which the policy
    was not because of an explicit settings on the LUN). It also then updates
    the path states in accordance with the new LB policy.

Arguements:

    DsmContext is the DSM context
    TargetHardwareId is the VID/PID whose matching LUNs policy need to be updated
    LoadBalanceType is the new load balance policy to be applied
    PreferredPath is the preferred failback path to be used (applicable only
                  if LB policy is Failover)

Return Value:

    Success

--*/

{
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL oldIrql;
    PLIST_ENTRY entry;
    ULONG groupIndex = 0;
    ULONG devInfoIndex;
    PDSM_GROUP_ENTRY group;
    PDSM_DEVICE_INFO devInfo;
    DSM_LOAD_BALANCE_TYPE dsmLoadBalanceType;
    ULONGLONG dsmPreferredPath;
    BOOLEAN useDsmLBSettings = FALSE;
    ULONG SpecialHandlingFlag = 0;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetLBForVidPidPolicyAdjustment (%ws): Entering function.\n",
                TargetHardwareId));

    status = DsmpQueryDsmLBPolicyFromRegistry(&dsmLoadBalanceType, &dsmPreferredPath);

    if (NT_SUCCESS(status)) {

        useDsmLBSettings = TRUE;

    } else {

        if (status == STATUS_OBJECT_NAME_NOT_FOUND) {

            status = STATUS_SUCCESS;
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_WMI,
                        "DsmpSetLBForVidPidPolicyAdjustment (%ws): MSDSM-wide default LB policy not set.\n",
                        TargetHardwareId));

        } else {

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_WMI,
                        "DsmpSetLBForVidPidPolicyAdjustment (%ws): Failed to query MSDMS-wide default LB setting. Status %x.\n",
                        TargetHardwareId,
                        status));
        }
    }

    oldIrql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    for (entry = DsmContext->GroupList.Flink; entry != &(DsmContext->GroupList); entry = entry->Flink, groupIndex++) {

        group = CONTAINING_RECORD(entry, DSM_GROUP_ENTRY, ListEntry);

        //
        // Only LUNs that don't have their policy explicitly set
        // are of interest to us here.
        //
        if (group->LBPolicySelection < DSM_DEFAULT_LB_POLICY_LUN_EXPLICIT) {

            //
            // Figure out if this LUN matches the VID/PID of interest
            // Device not of interest if it doesn't match the passed in target ID
            //
            if (wcscmp(group->HardwareId, TargetHardwareId) != 0) {

                continue;
            }

            //
            // Also, if the caller is trying to clear the VID/PID
            // default policy, then we don't even care about those
            // LUNs whose policies were not set using this value.
            //
            if (LoadBalanceType < DSM_LB_FAILOVER &&
                group->LBPolicySelection != DSM_DEFAULT_LB_POLICY_VID_PID) {

                continue;
            }

            //
            // If the VID/PID setting is being cleared, we need to fall back
            // to using the DSM-wide default policy if it has been set, else
            // we need to use the default based on the array's ALUA capabilities.
            //
            if (LoadBalanceType < DSM_LB_FAILOVER) {

                if (useDsmLBSettings) {

                    //
                    // Even if the MSDSM-wide policy is specified as RR, if the storage
                    // is ALUA, we can't have the policy as RR, so we'll change it to
                    // RRWS instead.
                    //
                    if (!DsmpIsSymmetricAccess(group->DeviceList[0]) && dsmLoadBalanceType == DSM_LB_ROUND_ROBIN) {

                        group->LoadBalanceType = DSM_LB_ROUND_ROBIN_WITH_SUBSET;

                    } else {

                        group->LoadBalanceType = dsmLoadBalanceType;
                    }

                    group->PreferredPath = (ULONGLONG)((ULONG_PTR)dsmPreferredPath);
                    group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_DSM_WIDE;

                } else {

                    //
                    // Default LB type:                    
                    // is Round Robin if ALUA is not supported, or if ALUA support is implicit but access is symmetric,
                    // else Round Robin With Subset (since in ALUA, all paths aren't in A/O).
                    //
                    if (DsmpIsSymmetricAccess(group->DeviceList[0])) {

                        group->LoadBalanceType = DSM_LB_ROUND_ROBIN;

                    } else {

                        group->LoadBalanceType = DSM_LB_ROUND_ROBIN_WITH_SUBSET;
                    }


                    group->PreferredPath = (ULONGLONG)((ULONG_PTR)MAXULONG);
                    group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_ALUA_CAPABILITY;
                }

            } else {

                //
                // Since a new policy has been selected for the DSM-wide
                // one, it needs to be applied to this LUN.
                //
                // However, if the VID/PID policy is specified as RR but the storage
                // is ALUA, we can't have the policy as RR, so we'll change it to
                // RRWS instead.
                //
                if (!DsmpIsSymmetricAccess(group->DeviceList[0]) && LoadBalanceType == DSM_LB_ROUND_ROBIN) {

                    group->LoadBalanceType = DSM_LB_ROUND_ROBIN_WITH_SUBSET;

                } else {

                    group->LoadBalanceType = LoadBalanceType;
                }

                group->PreferredPath = (ULONGLONG)((ULONG_PTR)PreferredPath);
                group->LBPolicySelection = DSM_DEFAULT_LB_POLICY_VID_PID;
            }

            //
            // Path states need to be updated in accordance with the new policy.
            //
            for (devInfoIndex = 0; devInfoIndex < DSM_MAX_PATHS; devInfoIndex++) {

                devInfo = group->DeviceList[devInfoIndex];
                DsmpSetNewDefaultLBPolicy(DsmContext, devInfo, group->LoadBalanceType, SpecialHandlingFlag);
            }
        }
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), oldIrql);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetLBForVidPidPolicyAdjustment (%ws): Exiting function with status %x\n",
                TargetHardwareId,
                status));

    return status;
}


NTSTATUS
DsmpSetNewDefaultLBPolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_opt_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine is called to adjust the path state of an instance of a
    LUN for which a new default load balance policy was applied
    following an admin request for such a change.

    This routine must be called with spinlock held.

Arguements:

    DsmContext is the DSM context
    DeviceInfo is the device info on which the new path state needs to be set
    LoadBalanceType is the load balance policy in accordance with which the path state needs to be adjusted
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Status

--*/
{
    PDSM_GROUP_ENTRY group;
    NTSTATUS status = STATUS_SUCCESS;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetNewDefaultLBPolicy (DevInfo %p): Entering function\n",
                DeviceInfo));

    if (!DeviceInfo) {
        status = STATUS_INVALID_PARAMETER;
        goto __Exit_DsmpSetNewDefaultLBPolicy;
    }

    if (!(DsmpIsDeviceInitialized(DeviceInfo) && DsmpIsDeviceUsable(DeviceInfo) && DsmpIsDeviceUsablePR(DeviceInfo)) ||
        DsmpIsDeviceFailedState(DeviceInfo->State)) {

        status = STATUS_UNSUCCESSFUL;
        goto __Exit_DsmpSetNewDefaultLBPolicy;
    }


    group = DeviceInfo->Group;

    if (!DsmpIsSymmetricAccess(DeviceInfo)) {

        DsmpAdjustDeviceStatesALUA(group, NULL, SpecialHandlingFlag);

    } else {

        switch (LoadBalanceType) {

            //
            // For failover, it is important the right path is
            // chosen, ie. preferred path needs to be taken into
            // consideration.
            //
            case DSM_LB_FAILOVER: {

                DsmpSetLBForPathArrival(DsmContext, DeviceInfo, SpecialHandlingFlag);

                break;
            }

            //
            // For all other policies, the state must be A/O.
            //
            default: {

                DeviceInfo->PreviousState = DeviceInfo->State;
                DeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;

                break;
            }
        }
    }

__Exit_DsmpSetNewDefaultLBPolicy:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_WMI,
                "DsmpSetNewDefaultLBPolicy (DevInfo %p): Exiting function with status %x\n",
                DeviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpSetLBForPathArrival(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO NewDeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine is called when a new path arrives for a multipath
    group that doesn't support ALUA. The routine will set the path
    to the appropriate state and fix up the other paths state if
    they need to change.

    This is used by devices NOT supporting ALUA.

    This routine must be called with spinlock held.

Arguements:

    DsmContext is the DSM context
    NewDeviceInfo is the device info for the newly arrived path
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Status

--*/
{
    PDSM_GROUP_ENTRY group;
    PDSM_DEVICE_INFO deviceInfo;
    NTSTATUS status = STATUS_SUCCESS;

    UNREFERENCED_PARAMETER(DsmContext);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathArrival (DevInfo %p): Entering function.\n",
                NewDeviceInfo));

    group = NewDeviceInfo->Group;

    if (!(DsmpIsDeviceInitialized(NewDeviceInfo) && DsmpIsDeviceUsable(NewDeviceInfo) && DsmpIsDeviceUsablePR(NewDeviceInfo))) {

        //
        // Bad device instance. Nothing can be done about it.
        //
        NewDeviceInfo->PreviousState = NewDeviceInfo->State;
        NewDeviceInfo->State = DSM_DEV_UNDETERMINED;

        NT_ASSERT(NewDeviceInfo->FailGroup == NULL);

        goto __Exit_DsmpSetLBForPathArrival;
    }


    if (group->NumberDevices == 1) {

        //
        // if this is the only device for the group then we will always
        // be active as every group must have at least one active path
        //
        if (NewDeviceInfo->State == DSM_DEV_ACTIVE_OPTIMIZED) {

            //
            // All's good
            //
            goto __Exit_DsmpSetLBForPathArrival;

        } else {

            NewDeviceInfo->PreviousState = NewDeviceInfo->State;
            NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;
        }

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathArrival (DevInfo %p): State changed to %d at %d\n",
                    NewDeviceInfo,
                    NewDeviceInfo->State,
                    __LINE__));

        goto __Exit_DsmpSetLBForPathArrival;
    }

    switch(group->LoadBalanceType) {
        case DSM_LB_FAILOVER: {

            //
            // Get the current active path.
            //
            deviceInfo = DsmpGetAnyActivePath(group, FALSE, NULL, SpecialHandlingFlag);

            //
            // If the newly arriving path is the preferred path, this now should
            // become our active path.
            //
            if (group->PreferredPath == ((ULONGLONG)((ULONG_PTR)(NewDeviceInfo->FailGroup->PathId)))) {

                //
                // If current active path is not the preferred path, change its
                // path state to standby.
                //
                if (deviceInfo && deviceInfo != NewDeviceInfo) {

                    deviceInfo->PreviousState = deviceInfo->State;
                    deviceInfo->State = DSM_DEV_STANDBY;

                    TracePrint((TRACE_LEVEL_INFORMATION,
                                TRACE_FLAG_PNP,
                                "DsmpSetLBForPathArrival (Group %p): Preferred path back online. DevInfo %p changed to state %d\n",
                                group,
                                deviceInfo,
                                deviceInfo->State));
                }

                NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;

            } else {

                //
                // In the case of failover, we must have only a single
                // active path. If this newly added path is configured as
                // the one that is desired to be active then we make this
                // active and set the standby path that was active back to
                // standby unless the preferred path is the currently active
                // path. If the newly added path is supposed to be
                // standby then we leave it as standby.
                //
                if (NewDeviceInfo->DesiredState == DSM_DEV_ACTIVE_OPTIMIZED) {

                    if (deviceInfo) {

                        //
                        // If the preferred path is currently active, don't change
                        // it regardless of this path wanting to be in active state.
                        //
                        if (group->PreferredPath == ((ULONGLONG)((ULONG_PTR)(deviceInfo->FailGroup->PathId)))) {

                            if (NewDeviceInfo != deviceInfo) {

                                NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                                NewDeviceInfo->State = DSM_DEV_STANDBY;
                            }

                        } else {

                            //
                            // Since the preferred path is not active, make this
                            // path active since it wants to be so. This means
                            // changing the current active path to standby.
                            //
                            deviceInfo->PreviousState = deviceInfo->State;
                            deviceInfo->State = DSM_DEV_STANDBY;

                            NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                            NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;
                        }
                    } else {

                        NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                        NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;
                    }

                } else {

                    if (deviceInfo) {

                        if (deviceInfo != NewDeviceInfo) {

                            //
                            // This newly arrived device doesn't want to be in
                            // A/O, and we already have an active path, so make
                            // it standby.
                            //
                            NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                            NewDeviceInfo->State = DSM_DEV_STANDBY;
                        }
                    } else {

                        //
                        // Since we currently don't have an active path, this one
                        // needs to be made active, regardless of its path it wishes
                        // to be in.
                        //
                        NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                        NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;
                    }
                }
            }

            break;
        }

        case DSM_LB_ROUND_ROBIN_WITH_SUBSET: {

            //
            // In RRWS, a set of paths can be active and another set of
            // paths can be standby. We set the new path to the desired
            // state unless the desired state is standby, but there are
            // no active paths. Also if the desired state is Active we
            // need to check if there are any existing paths that are
            // also active but have a desired state of standby. For
            // those we can move them back to standby.
            //
            if (NewDeviceInfo->DesiredState == DSM_DEV_ACTIVE_OPTIMIZED) {

                //
                // We are the active path coming back. Find out who has
                // been the active one and place him back to standby
                //
                DsmpAllowStandbyPathsToRest(group);
                NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_PNP,
                            "DsmpSetLBForPathArrival (DevInfo %p): Changed to state %d at %d\n",
                            NewDeviceInfo,
                            NewDeviceInfo->State,
                            __LINE__));

            } else {

                //
                // if there are no paths already active then we've got
                // to make this one AO, otherwise we can be non-AO
                //
                deviceInfo = DsmpGetAnyActivePath(group, FALSE, NULL, SpecialHandlingFlag);

                if (!deviceInfo || deviceInfo == NewDeviceInfo) {

                    NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                    NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;

                } else {

                    NewDeviceInfo->State = DSM_DEV_STANDBY;
                }

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_PNP,
                            "DsmpSetLBForPathArrival (%p): Changed to state %d at %d. Status %x\n",
                            NewDeviceInfo,
                            NewDeviceInfo->State,
                            __LINE__,
                            status));
            }

            status = STATUS_SUCCESS;

            break;
        }

        case DSM_LB_LEAST_BLOCKS:
        case DSM_LB_ROUND_ROBIN:
        case DSM_LB_DYN_LEAST_QUEUE_DEPTH:
        case DSM_LB_WEIGHTED_PATHS: {

            //
            // In RR, LWP, LB and LQD all paths are active so the new device
            // becomes AO or AU.
            //
            if (NewDeviceInfo->State != DSM_DEV_ACTIVE_OPTIMIZED) {

                NewDeviceInfo->PreviousState = NewDeviceInfo->State;
                NewDeviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;
            }

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpSetLBForPathArrival (DevInfo %p): Changed to state %d at %d. Status %x\n",
                        NewDeviceInfo,
                        NewDeviceInfo->State,
                        __LINE__,
                        status));

            status = STATUS_SUCCESS;

            break;
        }

        default: {
            status = STATUS_INVALID_PARAMETER;
            break;
        }
    }

__Exit_DsmpSetLBForPathArrival:

    //
    // Update the next path to be used for the group
    //
    deviceInfo = DsmpGetActivePathToBeUsed(group,
                                           DsmpIsSymmetricAccess(NewDeviceInfo),
                                           SpecialHandlingFlag);
    if (deviceInfo != NULL) {

        InterlockedExchangePointer(&(group->PathToBeUsed), (PVOID)deviceInfo->FailGroup);

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathArrival (DevInfo %p): Updating PathToBeUsed in %p to %p\n",
                    NewDeviceInfo,
                    group,
                    group->PathToBeUsed));
    } else {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathArrival (DevInfo %p): No FOG available for group %p\n",
                    NewDeviceInfo,
                    group));

        InterlockedExchangePointer(&(group->PathToBeUsed), NULL);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathArrival (DevInfo %p): Exiting function with status %x\n",
                NewDeviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpSetLBForPathArrivalALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO NewDeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine is called when a new path arrives for a multipath
    group. The routine will set the path to the appropriate state and
    fix up the other paths state if they need to change.

    Spin lock must NOT be held by caller

Arguements:

    DsmContext is the DSM context
    NewDeviceInfo is the device info for the newly arrived path
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Status

--*/
{
    PDSM_GROUP_ENTRY group;
    PDSM_DEVICE_INFO deviceInfo = NULL;
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL irql = PASSIVE_LEVEL; // Initialize variable to prevent C4701 warnings;
    BOOLEAN lockHeld = FALSE;
    PDSM_DEVICE_INFO preferredActiveDeviceInfo = NULL;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathArrivalALUA (DevInfo %p): Entering function.\n",
                NewDeviceInfo));

    group = NewDeviceInfo->Group;

    if (!(DsmpIsDeviceInitialized(NewDeviceInfo) && DsmpIsDeviceUsable(NewDeviceInfo) && DsmpIsDeviceUsablePR(NewDeviceInfo))) {

        //
        // Bad device instance. Nothing can be done about it.
        //
        NewDeviceInfo->PreviousState = NewDeviceInfo->State;
        NewDeviceInfo->State = DSM_DEV_UNDETERMINED;

        NT_ASSERT(NewDeviceInfo->FailGroup == NULL);

        goto __Exit_DsmpSetLBForPathArrivalALUA;
    }


    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
    lockHeld = TRUE;

    if (group->NumberDevices == 1) {

        //
        // If this is the only device for the group then it should be the
        // active instance as every group must have at least one active path.
        //
        if (NewDeviceInfo->State != DSM_DEV_ACTIVE_OPTIMIZED) {

            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
            lockHeld = FALSE;

            if (NewDeviceInfo->ALUASupport >= DSM_DEVINFO_ALUA_EXPLICIT) {

                //
                // If the device supports explicit transitions, set its state to A/O
                //
                status = DsmpSetDeviceALUAState(DsmContext, NewDeviceInfo, DSM_DEV_ACTIVE_OPTIMIZED);

            } else {

                //
                // Since the device supports only implicit transitions, send down
                // RTPG and hope that the controller has made this one the A/O path.
                //
                status = DsmpGetDeviceALUAState(DsmContext, NewDeviceInfo, NULL);

                if (NT_SUCCESS(status)) {

                    //
                    // Remember that at this point it is possible that this path
                    // is still non-A/O. We'll need to handle this in DsmGetPath
                    // as a special case where we don't find an A/O path but the
                    // storage supports implicit-only transitions. At that time,
                    // we mustn't blindly return a NULL path back.
                    //
                    TracePrint((TRACE_LEVEL_INFORMATION,
                                TRACE_FLAG_PNP,
                                "DsmpSetLBForPathArrivalALUA (DevInfo %p): RTPG returned state = %x, ALUA state = %x.\n",
                                NewDeviceInfo,
                                NewDeviceInfo->State,
                                NewDeviceInfo->ALUAState));
                }
            }
        }

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathArrivalALUA (DevInfo %p): State changed to %d at %d\n",
                    NewDeviceInfo,
                    NewDeviceInfo->State,
                    __LINE__));

    } else {

        deviceInfo = DsmpGetAnyActivePath(group, FALSE, NULL, SpecialHandlingFlag);

        //
        // Irrespecitve of the policy, we must have at least one A/O path.
        //
        // For RRWS and FOO, this path is of interest if it is desired to be in A/O.
        //
        // Also, for failover-only, this new path is of interest if it is
        // the preferred path.
        //
        // This path is also of interest if it is not A/O and desired state has not
        // explicitly been set to non-A/O and it has been exposed through the
        // preferred TPG.
        //
        if ((!deviceInfo) ||
            ((NewDeviceInfo->DesiredState == DSM_DEV_ACTIVE_OPTIMIZED) &&
             (group->LoadBalanceType == DSM_LB_FAILOVER ||
              group->LoadBalanceType == DSM_LB_ROUND_ROBIN_WITH_SUBSET)) ||
            (group->PreferredPath == (ULONGLONG)((ULONG_PTR)(NewDeviceInfo->FailGroup->PathId)) &&
             group->LoadBalanceType == DSM_LB_FAILOVER) ||
            (NewDeviceInfo->State != DSM_DEV_ACTIVE_OPTIMIZED &&
             NewDeviceInfo->DesiredState == DSM_DEV_UNDETERMINED &&
             NewDeviceInfo->TargetPortGroup->Preferred)) {

            //
            // Since this path is supposed to be active, we make it
            // active and then allow any paths that are supposed to
            // be standby go back to being standby
            //
            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
            lockHeld = FALSE;

            //
            // If explicit ALUA is supported, we need to send down STPG to make the change.
            //
            if (NewDeviceInfo->ALUASupport >= DSM_DEVINFO_ALUA_EXPLICIT) {

                status = DsmpSetDeviceALUAState(DsmContext, NewDeviceInfo, DSM_DEV_ACTIVE_OPTIMIZED);

            } else {

                //
                // If implicit ALUA, the controller may have made some
                // changes to the TPG states. We just need to query it.
                // We'll try and honor the Admin's request but can't
                // guarantee it.
                //
                status = DsmpGetDeviceALUAState(DsmContext, NewDeviceInfo, NULL);
            }

            //
            // We prefer this newly arrived devInfo to be A/O
            //
            preferredActiveDeviceInfo = NewDeviceInfo;
        }
    }

    if (!lockHeld) {

        irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
        lockHeld = TRUE;
    }

    if (NT_SUCCESS(status)) {

        DsmpAdjustDeviceStatesALUA(group, preferredActiveDeviceInfo, SpecialHandlingFlag);

    } else {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathArrivalALUA (DevInfo %p): Trying to query ALUA state failed with %x\n",
                    NewDeviceInfo,
                    status));
    }

    status = STATUS_SUCCESS;

__Exit_DsmpSetLBForPathArrivalALUA:

    //
    // Update the next path to be used for the group
    //
    deviceInfo = DsmpGetActivePathToBeUsed(group,
                                           DsmpIsSymmetricAccess(NewDeviceInfo),
                                           SpecialHandlingFlag);
    if (deviceInfo != NULL) {

        InterlockedExchangePointer(&(group->PathToBeUsed), (PVOID)deviceInfo->FailGroup);

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathArrivalALUA (DevInfo %p): Updating PathToBeUsed in %p to %p\n",
                    NewDeviceInfo,
                    group,
                    group->PathToBeUsed));
    } else {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathArrivalALUA (DevInfo %p): No active/alternative path available for group %p\n",
                    NewDeviceInfo,
                    group));

        InterlockedExchangePointer(&(group->PathToBeUsed), NULL);
    }

    if (lockHeld) {
        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathArrivalALUA (DevInfo %p): Exiting function with status %x\n",
                NewDeviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpSetLBForPathRemoval(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO RemovedDeviceInfo,
    _In_opt_ IN OPTIONAL PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine is called when a path is removed from a multipath
    group. The routine will set the path to the appropriate state and
    fix up the other paths state if they need to change.

    Note: This is used by devices NOT supporting ALUA.

Arguements:

    DsmContext is the DSM context

    RemovedDeviceInfo is the device info for failing/going-away path

    Group is an optional group override.  That is, if Group is not NULL, this
        function will run the load balance policy on the given Group and not
        the Group from the RemovedDeviceInfo.  This should only be used when
        it's impossible to get a pointer to the RemovedDeviceInfo.
        
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Status

--*/
{
    PDSM_GROUP_ENTRY group;
    PDSM_DEVICE_INFO deviceInfo;
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL irql;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathRemoval (DevInfo %p, Group %p): Entering function.\n",
                RemovedDeviceInfo,
                Group));

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

    if (Group == NULL) {

        if (!(DsmpIsDeviceFailedState(RemovedDeviceInfo->State))) {

            RemovedDeviceInfo->LastKnownGoodState = RemovedDeviceInfo->State;
        }

        RemovedDeviceInfo->PreviousState = RemovedDeviceInfo->State;
        RemovedDeviceInfo->State = DSM_DEV_FAILED;

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathRemoval (DevInfo %p): changed to state %d at %d\n",
                    RemovedDeviceInfo,
                    RemovedDeviceInfo->State,
                    __LINE__));

        group = RemovedDeviceInfo->Group;

    } else {
        //
        // The caller has chosen to override the RemovedDeviceInfo->Group.
        //
        group = Group;
    }

    switch(group->LoadBalanceType) {
        case DSM_LB_FAILOVER:
        case DSM_LB_ROUND_ROBIN_WITH_SUBSET: {

            //
            // In the case of failover, we must have only a single
            // active path. If the removed path was the active path we
            // need to find another path to become active
            //
            // In RRWS, a set of paths can be active and another set of
            // paths can be standby. If the removed path is an active
            // path then we need to make sure there is another active
            // path. If there is already another active path then there
            // is nothing to do. If not then a path needs to be made
            // active.
            //
            if (!DsmpGetAnyActivePath(group, FALSE, NULL, SpecialHandlingFlag)) {

                deviceInfo = DsmpFindStandbyPathToActivate(group, SpecialHandlingFlag);
                if (deviceInfo) {

                    deviceInfo->PreviousState = deviceInfo->State;
                    deviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;

                    TracePrint((TRACE_LEVEL_INFORMATION,
                                TRACE_FLAG_PNP,
                                "DsmpSetLBForPathRemoval (DevInfo %p): DevInfo %p changed to state %d at %d\n",
                                RemovedDeviceInfo,
                                deviceInfo,
                                deviceInfo->State,
                                __LINE__));
                }
            } else {
                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_PNP,
                            "DsmpSetLBForPathRemoval (DevInfo %p): LB Policy FO/RRWS and other paths active, no path made active at %d\n",
                            RemovedDeviceInfo,
                            __LINE__));
            }

            break;
        }

        case DSM_LB_LEAST_BLOCKS:
        case DSM_LB_ROUND_ROBIN:
        case DSM_LB_WEIGHTED_PATHS:
        case DSM_LB_DYN_LEAST_QUEUE_DEPTH: {

            //
            // In RR, LQD, LB and LWP, all paths are active so we don't
            // need to worry about activating a new path
            //
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpSetLBForPathRemoval (DevInfo %p): LB Policy RR, LWP or LQD, no path made active at %d\n",
                        RemovedDeviceInfo,
                        __LINE__));
            break;
        }

        default: {
            status = STATUS_INVALID_PARAMETER;
            break;
        }
    }

    //
    // Update the next path to be used for the group
    //
    deviceInfo = DsmpGetActivePathToBeUsed(group,
                                           DsmpIsSymmetricAccess(RemovedDeviceInfo),
                                           SpecialHandlingFlag);
    if (deviceInfo != NULL) {

        InterlockedExchangePointer(&(group->PathToBeUsed), deviceInfo->FailGroup);

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathRemoval (DevInfo %p): Removal: Updating PathToBeUsed in %p to %p\n",
                    RemovedDeviceInfo,
                    group,
                    group->PathToBeUsed));
    } else {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathRemoval (DevInfo %p): After remove No FOG available for group %p\n",
                    RemovedDeviceInfo,
                    group));

        InterlockedExchangePointer(&(group->PathToBeUsed), NULL);
    }

    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathRemoval (DevInfo %p): Exiting function with status %x\n",
                RemovedDeviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpSetLBForPathRemovalALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO RemovedDeviceInfo,
    _In_opt_ IN OPTIONAL PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine is called when a path is removed from a multipath
    group. The routine will set the path to the appropriate state and
    fix up the other paths state if they need to change.

    Note: This should NOT be called with DsmContext Lock held
          This is used for devices supporting ALUA.

Arguements:

    DsmContext is the DSM context

    RemovedDeviceInfo is the device info for the failing/going-away path

    Group is an optional group override.  That is, if Group is not NULL, this
        function will run the load balance policy on the given Group and not
        the Group from the RemovedDeviceInfo.  This should only be used when
        it's impossible to get a pointer to the RemovedDeviceInfo.
        
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Status

--*/
{
    PDSM_GROUP_ENTRY group;
    PDSM_DEVICE_INFO deviceInfo = NULL;
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL irql;
    BOOLEAN lockHeld = FALSE;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathRemovalALUA (DevInfo %p, Group %p): Entering function.\n",
                RemovedDeviceInfo,
                Group));

    irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
    lockHeld = TRUE;

    if (Group == NULL) {

        if (!(DsmpIsDeviceFailedState(RemovedDeviceInfo->State))) {

            RemovedDeviceInfo->LastKnownGoodState = RemovedDeviceInfo->State;
        }

        RemovedDeviceInfo->PreviousState = RemovedDeviceInfo->State;
        RemovedDeviceInfo->State = DSM_DEV_FAILED;

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathRemovalALUA (DevInfo %p): changed to state %d at %d\n",
                    RemovedDeviceInfo,
                    RemovedDeviceInfo->State,
                    __LINE__));

        group = RemovedDeviceInfo->Group;

    } else {
        //
        // The caller has chosen to override the RemovedDeviceInfo->Group.
        //
        group = Group;
    }

    if (group->LoadBalanceType < DSM_LB_FAILOVER ||
        group->LoadBalanceType > DSM_LB_LEAST_BLOCKS) {

        status = STATUS_INVALID_PARAMETER;

    } else {

        //
        // In the case of failover, we must have only a single
        // active path. If the removed path was the active path we
        // need to find another path to become active
        //
        // In rest of policies, set of paths can be active and another set of
        // paths can be standby. If the removed path is an active
        // path then we need to make sure there is another active
        // path. If there is already another active path then there
        // is nothing to do. If not then a path needs to be made
        // active.
        //
        if (!DsmpGetAnyActivePath(group, FALSE, NULL, SpecialHandlingFlag)) {

            BOOLEAN sendTPG = TRUE;

            deviceInfo = DsmpFindStandbyPathToActivateALUA(group, &sendTPG, SpecialHandlingFlag);

            if (deviceInfo) {

                if (sendTPG) {

                    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
                    lockHeld = FALSE;

                    //
                    // If explicit transition supported, we need to send down STPG to make the change.
                    //
                    if (deviceInfo->ALUASupport >= DSM_DEVINFO_ALUA_EXPLICIT) {

                        status = DsmpSetDeviceALUAState(DsmContext, deviceInfo, DSM_DEV_ACTIVE_OPTIMIZED);

                    } else {

                        //
                        // If implicit ALUA, the controller may have made necessary
                        // changes to the TPG states. We just need to query it.
                        //
                        status = DsmpGetDeviceALUAState(DsmContext, deviceInfo, NULL);
                    }

                    if (!lockHeld) {
                        irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));
                        lockHeld = TRUE;
                    }

                    if (NT_SUCCESS(status)) {

                        DsmpAdjustDeviceStatesALUA(group, deviceInfo, SpecialHandlingFlag);

                    } else {

                        TracePrint((TRACE_LEVEL_WARNING,
                                    TRACE_FLAG_PNP,
                                    "DsmpSetLBForPathRemovalALUA (DevInfo %p): Trying to query for ALUA state failed with status %x\n",
                                    RemovedDeviceInfo,
                                    status));
                    }
                } else {

                    deviceInfo->PreviousState = deviceInfo->State;
                    deviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;
                }

                if (NT_SUCCESS(status)) {

                    TracePrint((TRACE_LEVEL_INFORMATION,
                                TRACE_FLAG_PNP,
                                "DsmpSetLBForPathRemovalALUA (DevInfo %p): Device %p changed to state %d at %d\n",
                                RemovedDeviceInfo,
                                deviceInfo,
                                deviceInfo->State,
                                __LINE__));
                }
            }
        } else {
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_PNP,
                        "DsmpSetLBForPathRemovalALUA (DevInfo %p): Other paths active, no path made active at %d\n",
                        RemovedDeviceInfo,
                        __LINE__));
        }

        status = STATUS_SUCCESS;
    }

    //
    // Update the next path to be used for the group
    //
    deviceInfo = DsmpGetActivePathToBeUsed(group,
                                           DsmpIsSymmetricAccess(RemovedDeviceInfo),
                                           SpecialHandlingFlag);
    if (deviceInfo != NULL) {

        InterlockedExchangePointer(&(group->PathToBeUsed), deviceInfo->FailGroup);

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathRemovalALUA (DevInfo %p): Removal: Updating PathToBeUsed in %p to %p\n",
                    RemovedDeviceInfo,
                    group,
                    group->PathToBeUsed));
    } else {

        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_PNP,
                    "DsmpSetLBForPathRemovalALUA (DevInfo %p): No active/alternative path available for group %p\n",
                    RemovedDeviceInfo,
                    group));

        InterlockedExchangePointer(&(group->PathToBeUsed), NULL);
    }

    if (lockHeld) {

        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_PNP,
                "DsmpSetLBForPathRemovalALUA (DevInfo %p): Exiting function with status %x.\n",
                RemovedDeviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpSetLBForPathFailing(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDeviceInfo,
    _In_ IN BOOLEAN MarkDevInfoFailed,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine is called when an IO that was sent using this path fails with
    a fatal error. The routine will set the path to the appropriate state and
    fix up the other paths state if they need to change.

    Note: This is used by devices NOT supporting ALUA.

Arguements:

    DsmContext is the DSM context

    FailingDeviceInfo is the device info for the path on which IO failed
    
    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Status

--*/
{
    NTSTATUS status;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpSetLBForPathFailing (DevInfo %p): Entering function.\n",
                FailingDeviceInfo));

    //
    // We need to do exactly what DsmpSetLBForPathRemoval() does, except
    // that the devInfo may not really go away (may come back before a
    // Pnp remove comes down for the real LUN)
    //
    if (MarkDevInfoFailed) {
        status = DsmpSetLBForPathRemoval(DsmContext, FailingDeviceInfo, NULL, SpecialHandlingFlag);
    } else {
        status = DsmpSetLBForPathRemoval(DsmContext, FailingDeviceInfo, FailingDeviceInfo->Group, SpecialHandlingFlag);
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpSetLBForPathFailing (DevInfo %p): Exiting function with status %x\n",
                FailingDeviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpSetLBForPathFailingALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDeviceInfo,
    _In_ IN BOOLEAN MarkDevInfoFailed,
    _In_ IN ULONG SpecialHandlingFlag
    )
/*++

Routine Description:

    This routine is called when an IO that was sent using this path fails with
    a fatal error. The routine will set the path to the appropriate state and
    send down a Set Target Port Groups command asynchronously to fix up the
    other paths state if they need to change (actual work done in the completion
    routine).

    Note: This should NOT be called with DsmContext Lock held
          This is used for devices supporting ALUA.

Arguements:

    DsmContext is the DSM context

    FailingDeviceInfo is the device info for the failing/going-away path

    SpecialHandlingFlag - Flags to indicate any special handling requirement

Return Value:

    Status

--*/
{
    PDSM_GROUP_ENTRY group;
    PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY failDevInfoListEntry = NULL;
    PDSM_DEVICE_INFO deviceInfo = NULL;
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL irql;
    PUCHAR targetPortGroupsInfo = NULL;
    ULONG targetPortGroupsInfoLength;
    PSPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR tpgDescriptor = NULL;
    PDSM_COMPLETION_CONTEXT completionContext = NULL;
    PVOID senseInfo = NULL;
    PSCSI_REQUEST_BLOCK srb = NULL;
    PDSM_TPG_COMPLETION_CONTEXT tpgCompletionContext = NULL;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpSetLBForPathFailingALUA (DevInfo %p): Entering function.\n",
                FailingDeviceInfo));
                
    if (MarkDevInfoFailed) {
        if (!(DsmpIsDeviceFailedState(FailingDeviceInfo->State))) {

            FailingDeviceInfo->LastKnownGoodState = FailingDeviceInfo->State;
        }

        FailingDeviceInfo->PreviousState = FailingDeviceInfo->State;
        FailingDeviceInfo->State = DSM_DEV_FAILED;

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_RW,
                    "DsmpSetLBForPathFailingALUA (DevInfo %p): changed to state %d at %d\n",
                    FailingDeviceInfo,
                    FailingDeviceInfo->State,
                    __LINE__));
    }
    
    group = FailingDeviceInfo->Group;

    if (group->LoadBalanceType < DSM_LB_FAILOVER ||
        group->LoadBalanceType > DSM_LB_LEAST_BLOCKS) {

        status = STATUS_INVALID_PARAMETER;

    } else {

        irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

        //
        // Check if there are any active paths that can be used.
        //
        deviceInfo = DsmpGetAnyActivePath(group, FALSE, NULL, SpecialHandlingFlag);
        if (!deviceInfo) {

            //
            // Check if an Set/Report TPG has already been sent for this failing devInfo
            //
            failDevInfoListEntry = DsmpFindFailPathDevInfoEntry(DsmContext, group, FailingDeviceInfo);

            if (!failDevInfoListEntry) {

                BOOLEAN sendTPG = TRUE;

                deviceInfo = DsmpFindStandbyPathToActivateALUA(group, &sendTPG, SpecialHandlingFlag);

                if (deviceInfo) {

                    if (sendTPG) {

                        tpgCompletionContext = DsmpAllocatePool(NonPagedPoolNx,
                                                                sizeof(DSM_TPG_COMPLETION_CONTEXT),
                                                                DSM_TAG_TPG_COMPLETION_CONTEXT);

                        if (tpgCompletionContext) {
                            UCHAR senseInfoLength = SENSE_BUFFER_SIZE_EX;

                            senseInfo = DsmpAllocatePool(NonPagedPoolNx,
                                                         senseInfoLength,
                                                         DSM_TAG_SCSI_SENSE_INFO);

                            if (senseInfo) {

                                srb = DsmpAllocatePool(NonPagedPoolNx,
                                                       sizeof(SCSI_REQUEST_BLOCK),
                                                       DSM_TAG_SCSI_REQUEST_BLOCK);

                                if (srb) {

                                    srb->Length = SCSI_REQUEST_BLOCK_SIZE;
                                    srb->Function = SRB_FUNCTION_EXECUTE_SCSI;

                                    completionContext = ExAllocateFromNPagedLookasideList(&DsmContext->CompletionContextList);
                                    if (completionContext) {

                                        //
                                        // Update the target port group that needs to be made
                                        // active/optimized. We will send down an STPG for
                                        // storages that support both implicit and explicit.
                                        // If the storage does NOT like our choice of A/O TPG,
                                        // it will make an implicit transition. This is still
                                        // a better option than solely relying on the storage's
                                        // implicit transitions at this stage and ending up with
                                        // no path in A/O state.
                                        //
                                        if (deviceInfo->ALUASupport >= DSM_DEVINFO_ALUA_EXPLICIT) {

                                            targetPortGroupsInfoLength = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE +
                                                                         sizeof(SPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR);

                                        } else {

                                            //
                                            // Find an active/optimized target port group that should
                                            // have been set by the controller
                                            //
                                            // Take care of worst case scenario, which is:
                                            // 1. 4-byte header (for allocation length)
                                            // 2. 32 8-byte descriptors (for TPGs)
                                            // 3. Each descriptor containing 32 4-byte identifiers (for TPs in each TPG)
                                            //
                                            targetPortGroupsInfoLength = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE +
                                                                         (DSM_MAX_PATHS * (sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) +
                                                                                           DSM_MAX_PATHS * sizeof(ULONG)));
                                        }

                                        targetPortGroupsInfo = DsmpAllocatePool(NonPagedPoolNx,
                                                                                targetPortGroupsInfoLength,
                                                                                DSM_TAG_TARGET_PORT_GROUPS);

                                        if (targetPortGroupsInfo) {

                                            failDevInfoListEntry = DsmpBuildFailPathDevInfoEntry(DsmContext,
                                                                                                 group,
                                                                                                 FailingDeviceInfo,
                                                                                                 deviceInfo);

                                            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                                            if (failDevInfoListEntry) {

                                                tpgDescriptor = (PSPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR)(targetPortGroupsInfo + SPC3_TARGET_PORT_GROUPS_HEADER_SIZE);
                                                tpgDescriptor->AsymmetricAccessState = DSM_DEV_ACTIVE_OPTIMIZED;
                                                REVERSE_BYTES_SHORT(&tpgDescriptor->TPG_Identifier, &deviceInfo->TargetPortGroup->Identifier);

                                                //
                                                // Prevent the device info from being removed when a TPG is in-flight.
                                                //
                                                InterlockedIncrement(&FailingDeviceInfo->BlockRemove);

                                                completionContext->DeviceInfo = FailingDeviceInfo;
                                                completionContext->DsmContext = DsmContext;
                                                completionContext->RequestUnique1 = deviceInfo;
                                                completionContext->RequestUnique2 = FALSE;

                                                tpgCompletionContext->CompletionContext = completionContext;
                                                tpgCompletionContext->Srb = srb;
                                                tpgCompletionContext->SenseInfoBuffer = senseInfo;
                                                tpgCompletionContext->SenseInfoBufferLength = senseInfoLength;

                                                TracePrint((TRACE_LEVEL_INFORMATION,
                                                            TRACE_FLAG_RW,
                                                            "DsmpSetLBForPathFailingALUA (DevInfo %p): Sending down TPG asynchronously for %p using devInfo %p (path %p).\n",
                                                            FailingDeviceInfo,
                                                            FailingDeviceInfo->FailGroup->PathId,
                                                            deviceInfo,
                                                            deviceInfo->FailGroup->PathId));

                                                if (deviceInfo->ALUASupport >= DSM_DEVINFO_ALUA_EXPLICIT) {

                                                    status = DsmpSetTargetPortGroupsAsync(deviceInfo,
                                                                                          DsmpPhase1ProcessPathFailingALUA,
                                                                                          tpgCompletionContext,
                                                                                          targetPortGroupsInfoLength,
                                                                                          targetPortGroupsInfo);
                                                } else {

                                                    status = DsmpReportTargetPortGroupsAsync(deviceInfo,
                                                                                             DsmpPhase2ProcessPathFailingALUA,
                                                                                             tpgCompletionContext,
                                                                                             targetPortGroupsInfoLength,
                                                                                             targetPortGroupsInfo);
                                                }

                                                if (status != STATUS_PENDING) {

                                                    //
                                                    // Request not sent down successfully. Free the allocations.
                                                    //
                                                    DsmpFreePool(targetPortGroupsInfo);
                                                    ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);
                                                    DsmpFreePool(srb);
                                                    DsmpFreePool(senseInfo);
                                                    DsmpFreePool(tpgCompletionContext);

                                                    //
                                                    // Allow the failing device to be removed.
                                                    //
                                                    InterlockedDecrement(&FailingDeviceInfo->BlockRemove);
                                                }
                                            } else {

                                                //
                                                // Fail to build DevInfo entry. Free the allocations.
                                                //
                                                DsmpFreePool(targetPortGroupsInfo);
                                                ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);
                                                DsmpFreePool(srb);
                                                DsmpFreePool(senseInfo);
                                                DsmpFreePool(tpgCompletionContext);

                                            }
                                        } else {
                                            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                                            ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);
                                            DsmpFreePool(srb);
                                            DsmpFreePool(senseInfo);
                                            DsmpFreePool(tpgCompletionContext);
                                        }
                                    } else {
                                        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                                        NT_ASSERT(completionContext != NULL);

                                        TracePrint((TRACE_LEVEL_ERROR,
                                                    TRACE_FLAG_RW,
                                                    "DsmpSetLBForPathFailingALUA (DevInfo %p): Failed to allocate completion context. Failing path %p.\n",
                                                    FailingDeviceInfo,
                                                    FailingDeviceInfo->FailGroup->PathId));

                                        DsmpFreePool(srb);
                                        DsmpFreePool(senseInfo);
                                        DsmpFreePool(tpgCompletionContext);
                                    }
                                } else {
                                    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                                    NT_ASSERT(srb != NULL);

                                    TracePrint((TRACE_LEVEL_ERROR,
                                                TRACE_FLAG_RW,
                                                "DsmpSetLBForPathFailingALUA (DevInfo %p): Failed to allocate SRB. Failing path %p.\n",
                                                FailingDeviceInfo,
                                                FailingDeviceInfo->FailGroup->PathId));

                                    DsmpFreePool(senseInfo);
                                    DsmpFreePool(tpgCompletionContext);
                                }
                            } else {
                                ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                                NT_ASSERT(senseInfo != NULL);

                                TracePrint((TRACE_LEVEL_ERROR,
                                            TRACE_FLAG_RW,
                                            "DsmpSetLBForPathFailingALUA (DevInfo %p): Failed to allocate senseInfo. Failing path %p.\n",
                                            FailingDeviceInfo,
                                            FailingDeviceInfo->FailGroup->PathId));

                                DsmpFreePool(tpgCompletionContext);
                            }
                        } else {
                            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                            NT_ASSERT(tpgCompletionContext != NULL);

                            TracePrint((TRACE_LEVEL_ERROR,
                                        TRACE_FLAG_RW,
                                        "DsmpSetLBForPathFailingALUA (DevInfo %p): Failed to allocate TPG completion context. Failing path %p.\n",
                                        FailingDeviceInfo,
                                        FailingDeviceInfo->FailGroup->PathId));
                        }
                    } else {
                        ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                        deviceInfo->PreviousState = deviceInfo->State;
                        deviceInfo->State = DSM_DEV_ACTIVE_OPTIMIZED;

                        TracePrint((TRACE_LEVEL_INFORMATION,
                                    TRACE_FLAG_RW,
                                    "DsmpSetLBForPathFailingALUA (DevInfo %p): Found alternative devInfo %p for failing path %p without need for TPG\n",
                                    FailingDeviceInfo,
                                    deviceInfo,
                                    FailingDeviceInfo->FailGroup->PathId));
                    }
                } else {
                    ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_RW,
                                "DsmpSetLBForPathFailingALUA (DevInfo %p): Couldn't find a standby path to activate for failing path %p.\n",
                                FailingDeviceInfo,
                                FailingDeviceInfo->FailGroup->PathId));
                }
            } else {
                ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

                deviceInfo = failDevInfoListEntry->TempDeviceInfo;

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_RW,
                            "DsmpSetLBForPathFailingALUA (DevInfo %p): There is an RTPG/STPG already in progress for this path %p. Returning alternative %p.\n",
                            FailingDeviceInfo,
                            FailingDeviceInfo->FailGroup->PathId,
                            deviceInfo));
            }
        } else {
            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_RW,
                        "DsmpSetLBForPathFailingALUA (DevInfo %p): Other paths active, no path made active at %d\n",
                        FailingDeviceInfo,
                        __LINE__));
        }

        status = STATUS_SUCCESS;
    }

    if (deviceInfo) {

        //
        // Update temporarily the next path to be used for the group as this devInfo
        //
        InterlockedExchangePointer(&(group->PathToBeUsed), deviceInfo->FailGroup);
        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_RW,
                    "DsmpSetLBForPathFailingALUA (DevInfo %p): Updating PathToBeUsed in %p to %p\n",
                    FailingDeviceInfo,
                    group,
                    group->PathToBeUsed));

    } else {
    
        InterlockedExchangePointer(&(group->PathToBeUsed), NULL);
        TracePrint((TRACE_LEVEL_WARNING,
                    TRACE_FLAG_RW,
                    "DsmpSetLBForPathRemovalALUA (DevInfo %p): No FOG available for group %p\n",
                    FailingDeviceInfo,
                    group));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpSetLBForPathFailingALUA (DevInfo %p): Exiting function with status %x.\n",
                FailingDeviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpSetPathForIoRetryALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDeviceInfo,
    _In_ IN BOOLEAN TPGException,
    _In_ IN BOOLEAN DeviceInfoException
    )
/*++

Routine Description:

    This routine is called when an IO that was sent using this path fails with
    a retry-able "ALUA" error. What this basically means is that most likely an
    implicit transition has taken place and we need an RTPG to get the updated
    path states. The routine will send down a Report Target Port Groups command
    asynchronously to get the paths states (actual work done in the completion
    routine).

    Note: This should NOT be called with DsmContext Lock held
          This is used for devices supporting ALUA.

Arguements:

    DsmContext is the DSM context

    FailingDeviceInfo is the device info for the failing/going-away path

    TPGException is a flag used to indicate if the selected path must be from a
                      TPG that is different from FailingDeviceInfo's. This is
                      special handling for UA with sense "TPG in SB/UA state"

    DeviceInfoException is a flag used to indicate that the current FailindDeviceInfo
                      itself needs to be used again. This is special handling for
                      UA with sense "Asymmetric Access State Changed"

    (NOTE: TPGException and DeviceInfoException are mutually exclusive, although
           it is okay for both to be FALSE)

Return Value:

    Status

--*/
{
    PDSM_GROUP_ENTRY group;
    PDSM_DEVICE_INFO deviceInfo = NULL;
    NTSTATUS status = STATUS_SUCCESS;
    KIRQL irql;
    PUCHAR targetPortGroupsInfo = NULL;
    ULONG targetPortGroupsInfoLength;
    PDSM_COMPLETION_CONTEXT completionContext = NULL;
    PVOID senseInfo = NULL;
    PSCSI_REQUEST_BLOCK srb = NULL;
    PDSM_TPG_COMPLETION_CONTEXT tpgCompletionContext = NULL;
    NTSTATUS throttleStatus = STATUS_UNSUCCESSFUL;
    ULONG inflightRTPG;
    ULONG SpecialHandlingFlag = 0;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpSetPathForIoRetryALUA (DevInfo %p): Entering function.\n",
                FailingDeviceInfo));

    group = FailingDeviceInfo->Group;


    if (group->LoadBalanceType < DSM_LB_FAILOVER ||
        group->LoadBalanceType > DSM_LB_LEAST_BLOCKS) {

        status = STATUS_INVALID_PARAMETER;

    } else {

        //
        // First check to see if we need to find a candidate from a different TPG.
        //
        if (TPGException) {

            irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

            //
            // Find a candidate in a TPG that is different from this one
            //
            deviceInfo = DsmpFindStandbyPathInAlternateTpgALUA(group, FailingDeviceInfo, SpecialHandlingFlag);

            ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_RW,
                        "DsmpSetPathForIoRetryALUA (DevInfo %p): Need to try a different TPG deviceInfo %p.\n",
                        FailingDeviceInfo,
                        deviceInfo));

        } else if (DeviceInfoException) {

            //
            // Retry on the same path
            //
            deviceInfo = FailingDeviceInfo;

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_RW,
                        "DsmpSetPathForIoRetryALUA (DevInfo %p): Will retry using same deviceInfo %p.\n",
                        FailingDeviceInfo,
                        deviceInfo));
        }

        //
        // Check if an Report TPG has already been sent for this group
        //
        inflightRTPG = InterlockedCompareExchange((LONG volatile*)&group->InFlightRTPG, 0, 0);

        //
        // If there is no RTPG currently in flight, use the best candidate found
        // above to send down the RTPG. If there is already an RTPG inflight,
        // we're done. The result of the RTPG should fix the path states.
        //
        if (!inflightRTPG) {

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_RW,
                        "DsmpSetPathForIoRetryALUA (DevInfo %p): No RTPG in flight. Try sending one down.\n",
                        FailingDeviceInfo));

            //
            // If we need a candidate device, first get the currently active one.
            // If we can't find one that way, resort to finding the best alternative.
            // Basic idea is find SOME path instead of failing IOs back to the application.
            //
            if (!deviceInfo) {

                irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

                //
                // Find the best candidate - ie. either a currently A/O path or
                // the best alternative path to be made A/O.
                //
                deviceInfo = DsmpGetAnyActivePath(group, TRUE, deviceInfo, SpecialHandlingFlag);
                if (!deviceInfo) {

                    BOOLEAN sendTPG = TRUE;

                    deviceInfo = DsmpFindStandbyPathToActivateALUA(group, &sendTPG, SpecialHandlingFlag);

                    TracePrint((TRACE_LEVEL_WARNING,
                                TRACE_FLAG_RW,
                                "DsmpSetPathForIoRetryALUA (DevInfo %p): No active path. Best alternative %p.\n",
                                FailingDeviceInfo,
                                deviceInfo));
                }
                ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
            }

            if (deviceInfo) {

                tpgCompletionContext = DsmpAllocatePool(NonPagedPoolNx,
                                                        sizeof(DSM_TPG_COMPLETION_CONTEXT),
                                                        DSM_TAG_TPG_COMPLETION_CONTEXT);

                if (tpgCompletionContext) {
                    UCHAR senseInfoLength = SENSE_BUFFER_SIZE_EX;

                    senseInfo = DsmpAllocatePool(NonPagedPoolNx,
                                                 senseInfoLength,
                                                 DSM_TAG_SCSI_SENSE_INFO);

                    if (senseInfo) {

                        srb = DsmpAllocatePool(NonPagedPoolNx,
                                               sizeof(SCSI_REQUEST_BLOCK),
                                               DSM_TAG_SCSI_REQUEST_BLOCK);

                        if (srb) {

                            srb->Length = SCSI_REQUEST_BLOCK_SIZE;
                            srb->Function = SRB_FUNCTION_EXECUTE_SCSI;

                            completionContext = ExAllocateFromNPagedLookasideList(&DsmContext->CompletionContextList);

                            if (completionContext) {

                                //
                                // Find an active/optimized target port group that should
                                // have been set by the controller
                                //
                                // Take care of worst case scenario, which is:
                                // 1. 4-byte header (for allocation length)
                                // 2. 32 8-byte descriptors (for TPGs)
                                // 3. Each descriptor containing 32 4-byte identifiers (for TPs in each TPG)
                                //
                                targetPortGroupsInfoLength = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE +
                                                             (DSM_MAX_PATHS * (sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) +
                                                                               DSM_MAX_PATHS * sizeof(ULONG)));

                                targetPortGroupsInfo = DsmpAllocatePool(NonPagedPoolNx,
                                                                        targetPortGroupsInfoLength,
                                                                        DSM_TAG_TARGET_PORT_GROUPS);

                                if (targetPortGroupsInfo) {

                                    completionContext->DeviceInfo = FailingDeviceInfo;
                                    completionContext->DsmContext = DsmContext;
                                    completionContext->RequestUnique1 = deviceInfo;
                                    completionContext->RequestUnique2 = TRUE;

                                    tpgCompletionContext->CompletionContext = completionContext;
                                    tpgCompletionContext->Srb = srb;
                                    tpgCompletionContext->SenseInfoBuffer = senseInfo;
                                    tpgCompletionContext->SenseInfoBufferLength = senseInfoLength;

                                    //
                                    // Now we are all set to send the RTPG request.
                                    // check and set InFlightRTPG to make sure this thread is the only one with
                                    // the RTPG active for this group, since it is possible to have more than one
                                    // threads reaching up to this point in parallel
                                    //
                                    inflightRTPG = InterlockedCompareExchange((LONG volatile*)&group->InFlightRTPG, 1, 0);
                                    if (inflightRTPG) {
                                    
                                        DsmpFreePool(targetPortGroupsInfo);
                                        ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);
                                        DsmpFreePool(srb);
                                        DsmpFreePool(senseInfo);
                                        DsmpFreePool(tpgCompletionContext);
                                    } else {

                                        //
                                        // Prevent the device info from being removed when a TPG is in-flight.
                                        //
                                        InterlockedIncrement(&FailingDeviceInfo->BlockRemove);

                                        //
                                        // First try and throttle the IO. The completion routine will
                                        // take care of resuming the IO.
                                        //
                                        if (!InterlockedCompareExchange((LONG volatile*)&group->Throttled, 1, 0)) {

                                            DsmNotification(((PDSM_CONTEXT)DsmContext)->MPIOContext,
                                                            ThrottleIO_V2,
                                                            deviceInfo,
                                                            FALSE,
                                                            &throttleStatus,
                                                            0);

                                            if (NT_SUCCESS(throttleStatus)) {

                                                TracePrint((TRACE_LEVEL_INFORMATION,
                                                            TRACE_FLAG_RW,
                                                            "DsmpSetPathForIoRetryALUA (DevInfo %p): Successfully throttled IO. About to send RTPG. Failing path %p.\n",
                                                            FailingDeviceInfo,
                                                            FailingDeviceInfo->FailGroup->PathId));

                                            } else {

                                                //
                                                // Throttle can fail when the MPDisk is
                                                // 1. Being removed. (or)
                                                // 2. In any other state other than Normal or Degraded.
                                                //

                                                TracePrint((TRACE_LEVEL_WARNING,
                                                            TRACE_FLAG_RW,
                                                            "DsmpSetPathForIoRetryALUA (DevInfo %p): Throttle before RTPG failed. Failing path %p.\n",
                                                            FailingDeviceInfo,
                                                            FailingDeviceInfo->FailGroup->PathId));
                                                
                                                InterlockedDecrement((LONG volatile*)&FailingDeviceInfo->Group->Throttled);
                                            }
                                        } else {
                                        
                                            //
                                            // Currently we don't expect this to happen
                                            //
                                            NT_ASSERT(FALSE);                                        
                                        }


                                        TracePrint((TRACE_LEVEL_INFORMATION,
                                                    TRACE_FLAG_RW,
                                                    "DsmpSetPathForIoRetryALUA (DevInfo %p): Sending RTPG asynchronously. Failing path %p.\n",
                                                    FailingDeviceInfo,
                                                    FailingDeviceInfo->FailGroup->PathId));

                                        if (STATUS_PENDING != DsmpReportTargetPortGroupsAsync(deviceInfo,
                                                                                              DsmpPhase2ProcessPathFailingALUA,
                                                                                              tpgCompletionContext,
                                                                                              targetPortGroupsInfoLength,
                                                                                              targetPortGroupsInfo)) {



                                            //
                                            // Request not sent down successfully. Free the allocations.
                                            //
                                            DsmpFreePool(targetPortGroupsInfo);
                                            ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);
                                            DsmpFreePool(srb);
                                            DsmpFreePool(senseInfo);
                                            DsmpFreePool(tpgCompletionContext);

                                            //
                                            // Allow the failing device to be removed.
                                            //
                                            InterlockedDecrement(&FailingDeviceInfo->BlockRemove);

                                            //
                                            // Resume IO if we throttled requests before calling DsmpReportTargetPortGroupsAsync
                                            //
                                            if (InterlockedCompareExchange((LONG volatile*)&group->Throttled, 0, 1)) {

                                                NTSTATUS resumeStatus = STATUS_UNSUCCESSFUL;

                                                DsmNotification(((PDSM_CONTEXT)deviceInfo->DsmContext)->MPIOContext,
                                                                ResumeIO_V2,
                                                                deviceInfo,
                                                                TRUE,
                                                                &resumeStatus,
                                                                0);

                                                if (!NT_SUCCESS(resumeStatus)) {

                                                    //
                                                    // Resume can fail when
                                                    // 1. The MPDisk is being removed (or)
                                                    // 2. The MPDisk is any other state other than throttled (or)
                                                    // 3. There is a problem dispatching throttled requests.
                                                    //

                                                    TracePrint((TRACE_LEVEL_WARNING,
                                                                TRACE_FLAG_RW,
                                                                "DsmpSetPathForIoRetryALUA (DevInfo %p): Resume IO failed.\n",
                                                                deviceInfo));
                                                }

                                            } 
                                            
                                            InterlockedDecrement((LONG volatile*)&group->InFlightRTPG);
                                        }
                                    }
                                } else {

                                    NT_ASSERT(targetPortGroupsInfo != NULL);

                                    TracePrint((TRACE_LEVEL_ERROR,
                                                TRACE_FLAG_RW,
                                                "DsmpSetPathForIoRetryALUA (DevInfo %p): Couldn't allocate TPG info buffer. Failing path %p.\n",
                                                FailingDeviceInfo,
                                                FailingDeviceInfo->FailGroup->PathId));

                                    ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);
                                    ExFreePool(srb);
                                    ExFreePool(senseInfo);
                                    ExFreePool(tpgCompletionContext);
                                }
                            } else {

                                NT_ASSERT(completionContext != NULL);

                                TracePrint((TRACE_LEVEL_ERROR,
                                            TRACE_FLAG_RW,
                                            "DsmpSetPathForIoRetryALUA (DevInfo %p): Couldn't allocate completion context. Failing path %p.\n",
                                            FailingDeviceInfo,
                                            FailingDeviceInfo->FailGroup->PathId));

                                ExFreePool(srb);
                                ExFreePool(senseInfo);
                                ExFreePool(tpgCompletionContext);
                            }
                        } else {

                            NT_ASSERT(srb != NULL);

                            TracePrint((TRACE_LEVEL_ERROR,
                                        TRACE_FLAG_RW,
                                        "DsmpSetPathForIoRetryALUA (DevInfo %p): Couldn't allocate SRB. Failing path %p.\n",
                                        FailingDeviceInfo,
                                        FailingDeviceInfo->FailGroup->PathId));

                            ExFreePool(senseInfo);
                            ExFreePool(tpgCompletionContext);
                        }
                    } else {

                        NT_ASSERT(senseInfo != NULL);

                        TracePrint((TRACE_LEVEL_ERROR,
                                    TRACE_FLAG_RW,
                                    "DsmpSetPathForIoRetryALUA (DevInfo %p): Couldn't allocate senseInfo. Failing path %p.\n",
                                    FailingDeviceInfo,
                                    FailingDeviceInfo->FailGroup->PathId));

                        ExFreePool(tpgCompletionContext);
                    }
                } else {

                    NT_ASSERT(tpgCompletionContext != NULL);

                    TracePrint((TRACE_LEVEL_ERROR,
                                TRACE_FLAG_RW,
                                "DsmpSetPathForIoRetryALUA (DevInfo %p): Couldn't allocate TPG completion context. Failing path %p.\n",
                                FailingDeviceInfo,
                                FailingDeviceInfo->FailGroup->PathId));
                }
            } else {
                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_RW,
                            "DsmpSetPathForIoRetryALUA (DevInfo %p): Couldn't find a path for RTPG. Failing path %p.\n",
                            FailingDeviceInfo,
                            FailingDeviceInfo->FailGroup->PathId));
            }
        } else {
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_RW,
                        "DsmpSetPathForIoRetryALUA (DevInfo %p): Other paths active, no path made active at %d\n",
                        FailingDeviceInfo,
                        __LINE__));
        }

        if(!deviceInfo) {

            //
            // It is possible that there are only two TPGs with one of them in U/A
            // state and the other in transitioning state. In such a case, we would
            // not find an alternative TPG deviceInfo. In addition, if there is an
            // RTPG in flight, we won't go down the path of forcibly picking any
            // deviceInfo. This is to cover that scenario, else we're left with no
            // deviceInfo to do the retry and we'll end up setting the group's PTBU
            // to NULL thus failing the retried request (if for eg. the LB is RRWS).
            // Need to ensure that we handle this exception case.
            //
            if (inflightRTPG) {

                irql = ExAcquireSpinLockExclusive(&(DsmContext->DsmContextLock));

                //
                // Find the best candidate - ie. either a currently A/O path or
                // the best alternative path to be made A/O.
                //
                deviceInfo = DsmpGetAnyActivePath(group, TRUE, deviceInfo, SpecialHandlingFlag);
                if (!deviceInfo) {

                    BOOLEAN sendTPG = TRUE;

                    deviceInfo = DsmpFindStandbyPathToActivateALUA(group, &sendTPG, SpecialHandlingFlag);
                }

                ExReleaseSpinLockExclusive(&(DsmContext->DsmContextLock), irql);
            }
        }

        if(deviceInfo) {

            //
            // Update temporarily the next path to be used for the group as this devInfo
            //
            InterlockedExchangePointer(&(group->PathToBeUsed), deviceInfo->FailGroup);
            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_RW,
                        "DsmpSetPathForIoRetryALUA (DevInfo %p): Updating PathToBeUsed in %p to %p\n",
                        FailingDeviceInfo,
                        group,
                        group->PathToBeUsed));

        } else {
            InterlockedExchangePointer(&(group->PathToBeUsed), NULL);

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_RW,
                        "DsmpSetPathForIoRetryALUA (DevInfo %p): No FOG available for group %p\n",
                        FailingDeviceInfo,
                        group));
        }

        status = STATUS_SUCCESS;
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpSetPathForIoRetryALUA (DevInfo %p): Exiting function with status %x.\n",
                FailingDeviceInfo,
                status));

    return status;
}


PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY
DsmpFindFailPathDevInfoEntry(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO FailingDevInfo
    )
/*++

Routine Description:

    This routine finds the entry that contains the alternate devInfo to use for
    a failing one for the passed in devInfo.

    N.B: This routine MUST be called with DsmContextLock held in either Shared or
    Exclusive mode.

Arguments:

    Context is the DSM's context info.

    Group is the group entry representing the device.

    FailingDevInfo is the device info whose entry needs to be found.

Return Value:

    Pointer to the entry. NULL if it doesn't exist.

--*/
{
    PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY failDevInfoListEntry = NULL;
    PLIST_ENTRY entry = NULL;

    UNREFERENCED_PARAMETER(Context);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpFindFailPathDevInfoEntry (DevInfo %p): Entering function.\n",
                FailingDevInfo));

    for (entry = Group->FailingDevInfoList.Flink;
         entry != &Group->FailingDevInfoList;
         entry = entry->Flink) {

        failDevInfoListEntry = CONTAINING_RECORD(entry, DSM_FAIL_PATH_PROCESSING_LIST_ENTRY, ListEntry);
        NT_ASSERT(failDevInfoListEntry);

        if (failDevInfoListEntry) {

            if (failDevInfoListEntry->FailingDeviceInfo == FailingDevInfo) {

                break;

            } else {

                failDevInfoListEntry = NULL;
            }
        }
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpFindFailPathDevInfoEntry (DevInfo %p): Exiting function returning entry %p.\n",
                FailingDevInfo,
                failDevInfoListEntry));

    return failDevInfoListEntry;
}


PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY
DsmpBuildFailPathDevInfoEntry(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO FailingDevInfo,
    _In_ IN PDSM_DEVICE_INFO AlternateDevInfo
    )
/*++

Routine Description:

    When InterpretError() is called with an IRP that has failed with a fatal error,
    if the device is ALUA it is possible that STPG needs to be sent to update a new
    devInfo as being Active/Optimized. However, for in-flight IOs that weren't
    queued by MPIO, we still need to return a path that can be used.

    This routine is builds an entry that contains the alternate devInfo to use for
    a failing one.

    NOTE: Calling function should be holding the spin lock.

Arguments:

    Context is the DSM's context info.

    Group is the group entry representing the device.

    FailingDevInfo is the device info that was used when the IRP failed.

    AlternateDevInfo is the new one to temporarily use until its state can be properly set.

Return Value:

    Pointer to the newly built entry.
    NULL if there were any errors building it.

--*/
{
    PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY failDevInfoListEntry = NULL;

    UNREFERENCED_PARAMETER(Context);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpBuildFailPathDevInfoEntry (DevInfo %p): Entering function.\n",
                FailingDevInfo));

    failDevInfoListEntry = DsmpAllocatePool(NonPagedPoolNx,
                                            sizeof(DSM_FAIL_PATH_PROCESSING_LIST_ENTRY),
                                            DSM_TAG_FAIL_DEVINFO_LIST_ENTRY);

    if (failDevInfoListEntry) {

        failDevInfoListEntry->FailingDeviceInfo = FailingDevInfo;
        failDevInfoListEntry->TempDeviceInfo = AlternateDevInfo;
        InsertTailList(&Group->FailingDevInfoList, &failDevInfoListEntry->ListEntry);
        InterlockedIncrement((LONG volatile*)&Group->NumberFailingDevInfos);

    } else {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_RW,
                    "DsmpBuildFailPathDevInfoEntry (DevInfo %p): Failed to allocate memory for entry.\n",
                    FailingDevInfo));
    }

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpBuildFailPathDevInfoEntry (DevInfo %p): Exiting function returning entry %p.\n",
                FailingDevInfo,
                failDevInfoListEntry));

    return failDevInfoListEntry;
}


NTSTATUS
DsmpPhase1ProcessPathFailingALUA(
    IN PDEVICE_OBJECT DeviceObject,
    IN PIRP Irp,
    IN PVOID Context
    )
/*++

Routine Description:

    This is the completion routine that is called when the STPG is sent down by
    DsmpSetLBForPathFailingALUA.

    The caller SHOULD NOT acquire the DSM Context lock before calling this routine.

Arguements:

    DeviceObject is the target device object to which Irp was sent

    Irp is the scsi pass through request for STPG

    Context is the completion context.

Return Value:

    Status

--*/
{
    PIO_STACK_LOCATION nextIrpStack = IoGetNextIrpStackLocation(Irp);
    PDSM_TPG_COMPLETION_CONTEXT context = (PDSM_TPG_COMPLETION_CONTEXT)Context;
    PSCSI_REQUEST_BLOCK srb = context->Srb;
    PVOID senseData = context->SenseInfoBuffer;
    UCHAR senseDataLength = context->SenseInfoBufferLength;
    NTSTATUS status = Irp->IoStatus.Status;
    ULONG targetPortGroupsInfoLength = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE + sizeof(SPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR);
    PUCHAR targetPortGroupsInfo;
    PDSM_DEVICE_INFO deviceInfo = (PDSM_DEVICE_INFO)(context->CompletionContext->RequestUnique1);
    PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY failDevInfoListEntry = NULL;
    BOOLEAN releaseCompletionContextResources = TRUE;
    KIRQL irql;
    UCHAR scsiStatus = SrbGetScsiStatus(srb);

    UNREFERENCED_PARAMETER(DeviceObject);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpPhase1ProcessPathFailingALUA (DevInfo %p): Entering function.\n",
                deviceInfo));

#if DBG
    KeQuerySystemTime(&context->CompletionContext->TickCount);
#endif

    if ((scsiStatus == SCSISTAT_GOOD) &&
        (NT_SUCCESS(status))) {

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_RW,
                    "DsmpPhase1ProcessPathFailingALUA (DevInfo %p): STPG succeeded.\n",
                    deviceInfo));

    } else if (NT_SUCCESS(status) &&
               scsiStatus == SCSISTAT_CHECK_CONDITION &&
               DsmpShouldRetryTPGRequest(senseData, senseDataLength)) {

        if ((context->NumberRetries)--) {

            //
            // Retry the request
            //

            NT_ASSERT(SrbGetDataBuffer(srb) == MmGetMdlVirtualAddress(Irp->MdlAddress));

            //
            // Reset byte count of transfer in SRB Extension.
            //
            SrbSetDataTransferLength(srb, Irp->MdlAddress->ByteCount);

            //
            // Zero SRB statuses.
            //
            srb->SrbStatus = 0;
            SrbSetScsiStatus(srb, 0);

            nextIrpStack->MajorFunction = IRP_MJ_INTERNAL_DEVICE_CONTROL;
            nextIrpStack->MinorFunction = IRP_MN_SCSI_CLASS;

            //
            // Save SRB address in next stack for port driver.
            //
            nextIrpStack->Parameters.Scsi.Srb = srb;
            IoSetCompletionRoutine(Irp, DsmpPhase1ProcessPathFailingALUA, Context, TRUE, TRUE, TRUE);

            IoMarkIrpPending(Irp);

            //
            // Send the IRP asynchronously
            //
            DsmSendRequestEx(context->CompletionContext->DsmContext->MPIOContext,
                             deviceInfo->TargetObject,
                             Irp,
                             deviceInfo,
                             DSM_CALL_COMPLETION_ON_MPIO_ERROR);

            //
            // We know that the completion routine will always be called.
            //
            status = STATUS_PENDING;
            goto __Exit_DsmpPhase1ProcessPathFailingALUA;
        }
    } else {

        irql = ExAcquireSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock));

        failDevInfoListEntry = DsmpFindFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                                            context->CompletionContext->DeviceInfo->Group,
                                                            context->CompletionContext->DeviceInfo);

        if (failDevInfoListEntry) {

            DsmpRemoveFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                           context->CompletionContext->DeviceInfo->Group,
                                           failDevInfoListEntry);
        }

        ExReleaseSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock), irql);

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_RW,
                    "DsmpPhase1ProcessPathFailingALUA (DevInfo %p): NTStatus 0%x, ScsiStatus 0x%x.\n",
                    deviceInfo,
                    status,
                    scsiStatus));
    }

    if (NT_SUCCESS(status)) {

        //
        // An explicit transition may cause changes to some other TPGs.
        // So we need to query for the states of all the TPGs and update
        // our internal list and its elements.
        //

        //
        // Take care of worst case scenario, which is:
        // 1. 4-byte header (for allocation length)
        // 2. 32 8-byte descriptors (for TPGs)
        // 3. Each descriptor containing 32 4-byte identifiers (for TPs in each TPG)
        //
        targetPortGroupsInfoLength = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE +
                                     (DSM_MAX_PATHS * (sizeof(SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR) +
                                                       DSM_MAX_PATHS * sizeof(ULONG)));

        targetPortGroupsInfo = DsmpAllocatePool(NonPagedPoolNx,
                                                targetPortGroupsInfoLength,
                                                DSM_TAG_TARGET_PORT_GROUPS);

        if (targetPortGroupsInfo) {

            if (STATUS_PENDING == DsmpReportTargetPortGroupsAsync(deviceInfo,
                                                                  DsmpPhase2ProcessPathFailingALUA,
                                                                  Context,
                                                                  targetPortGroupsInfoLength,
                                                                  targetPortGroupsInfo)) {

                releaseCompletionContextResources = FALSE;

            } else {

                DsmpFreePool(targetPortGroupsInfo);
            }
        } else {

            irql = ExAcquireSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock));

            failDevInfoListEntry = DsmpFindFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                                                context->CompletionContext->DeviceInfo->Group,
                                                                context->CompletionContext->DeviceInfo);

            if (failDevInfoListEntry) {

                DsmpRemoveFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                               context->CompletionContext->DeviceInfo->Group,
                                               failDevInfoListEntry);
            }

            ExReleaseSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock), irql);
        }
    }

    //
    // Free the allocations.
    //
    IoFreeMdl(Irp->MdlAddress);
    Irp->MdlAddress = NULL;

    DsmpFreePool(Irp->UserBuffer);

    IoFreeIrp(Irp);
    Irp = (PIRP) NULL;

    if (releaseCompletionContextResources) {

        //
        // Release our hold on the device info so that it can be removed.
        //
        InterlockedDecrement(&context->CompletionContext->DeviceInfo->BlockRemove);

        ExFreeToNPagedLookasideList(&(context->CompletionContext->DsmContext)->CompletionContextList, context->CompletionContext);
        DsmpFreePool(context->Srb);
        DsmpFreePool(context->SenseInfoBuffer);
#pragma warning(suppress:6001) // DevDiv 818965
        DsmpFreePool(context);
    }

__Exit_DsmpPhase1ProcessPathFailingALUA:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpPhase1ProcessPathFailingALUA (DevInfo %p): Exiting function.\n",
                deviceInfo));

    return STATUS_MORE_PROCESSING_REQUIRED;
}


NTSTATUS
DsmpRemoveFailPathDevInfoEntry(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY FailPathDevInfoEntry
    )
/*++

Routine Description:

    This routine removes the entry pointed to from the passed in Group's list.

    NOTE: Calling function should be holding the spin lock.

Arguments:

    Context is the DSM's context info.

    Group is the group entry representing the device.

    FailingPathDevInfoEntry is the entry that needs to be removed.

Return Value:

    STATUS_SUCCESS if successful, else appropriate NT error code.

--*/
{
    PLIST_ENTRY entry = &FailPathDevInfoEntry->ListEntry;
    PDSM_DEVICE_INFO deviceInfo = FailPathDevInfoEntry->FailingDeviceInfo;
    NTSTATUS status = STATUS_SUCCESS;

    UNREFERENCED_PARAMETER(Context);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpRemoveFailPathDevInfoEntry (DevInfo %p): Entering function.\n",
                deviceInfo));

    RemoveEntryList(entry);
    DsmpFreePool(FailPathDevInfoEntry);
    InterlockedDecrement((LONG volatile*)&Group->NumberFailingDevInfos);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpRemoveFailPathDevInfoEntry (DevInfo %p): Exiting function with status %x.\n",
                deviceInfo,
                status));

    return status;
}


NTSTATUS
DsmpPhase2ProcessPathFailingALUA(
    IN PDEVICE_OBJECT DeviceObject,
    IN PIRP Irp,
    IN PVOID Context
    )
/*++

Routine Description:

    This is the completion routine that is called when the RTPG is sent down by
    DsmpPhase1ProcessPathFailingALUA.

    The caller SHOULD NOT acquire the DSM Context lock before calling this routine.

Arguements:

    DeviceObject is the target device object to which Irp was sent

    Irp is the scsi pass through request for RTPG

    Context is the completion context.

Return Value:

    Status

--*/
{
    PIO_STACK_LOCATION nextIrpStack = IoGetNextIrpStackLocation(Irp);
    PDSM_TPG_COMPLETION_CONTEXT context = (PDSM_TPG_COMPLETION_CONTEXT)Context;
    PSCSI_REQUEST_BLOCK srb = context->Srb;
    PVOID senseData = context->SenseInfoBuffer;
    UCHAR senseDataLength = context->SenseInfoBufferLength;
    NTSTATUS status = Irp->IoStatus.Status;
    PUCHAR header;
    ULONG returnedDataLength = 0;
    PUCHAR targetPortGroupsInfo = NULL;
    ULONG targetPortGroupsInfoLength = 0;
    PDSM_DEVICE_INFO deviceInfo = (PDSM_DEVICE_INFO)(context->CompletionContext->RequestUnique1);
    BOOLEAN decrementRTPGcount = (BOOLEAN)(context->CompletionContext->RequestUnique2);
    KIRQL irql;
    ULONG index;
    PDSM_DEVICE_INFO devInfo;
    PDSM_TARGET_PORT_GROUP_ENTRY targetPortGroup = NULL;
    PDSM_GROUP_ENTRY group = deviceInfo->Group;
    PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY failDevInfoListEntry = NULL;
    UCHAR scsiStatus = SrbGetScsiStatus(srb);

    UNREFERENCED_PARAMETER(DeviceObject);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpPhase2ProcessPathFailingALUA (DevInfo %p): Entering function.\n",
                deviceInfo));

#if DBG
    KeQuerySystemTime(&(context->CompletionContext)->TickCount);
#endif

    if ((status == STATUS_BUFFER_OVERFLOW) ||
        (NT_SUCCESS(status) &&
        (scsiStatus == SCSISTAT_GOOD))) {

        header = (PUCHAR)((PUCHAR)SrbGetDataBuffer(srb));
        GetUlongFrom4ByteArray(header, returnedDataLength);

        status = STATUS_SUCCESS;
        if (returnedDataLength > SrbGetDataTransferLength(srb)) {

            status = STATUS_BUFFER_OVERFLOW;
        }
    }

    if ((scsiStatus == SCSISTAT_GOOD) &&
        (NT_SUCCESS(status))) {

        TracePrint((TRACE_LEVEL_INFORMATION,
                    TRACE_FLAG_RW,
                    "DsmpPhase2ProcessPathFailingALUA (DevInfo %p): RTPG using path %p succeeded.\n",
                    deviceInfo,
                    deviceInfo->FailGroup->PathId));

        header = (PUCHAR)((PUCHAR)SrbGetDataBuffer(srb));
        GetUlongFrom4ByteArray(header, returnedDataLength);

        //
        // Allocate a buffer to hold the TPG info.
        //
        targetPortGroupsInfo = DsmpAllocatePool(NonPagedPoolNx,
                                                SPC3_TARGET_PORT_GROUPS_HEADER_SIZE + returnedDataLength,
                                                DSM_TAG_TARGET_PORT_GROUPS);

        if (targetPortGroupsInfo) {

            targetPortGroupsInfoLength = SPC3_TARGET_PORT_GROUPS_HEADER_SIZE + returnedDataLength;

            //
            // Copy it over.
            //
            RtlCopyMemory(targetPortGroupsInfo,
                          header,
                          targetPortGroupsInfoLength);

        } else {

            irql = ExAcquireSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock));

            failDevInfoListEntry = DsmpFindFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                                                context->CompletionContext->DeviceInfo->Group,
                                                                context->CompletionContext->DeviceInfo);

            if (failDevInfoListEntry) {

                DsmpRemoveFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                               context->CompletionContext->DeviceInfo->Group,
                                               failDevInfoListEntry);
            }

            ExReleaseSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock), irql);

            TracePrint((TRACE_LEVEL_ERROR,
                        TRACE_FLAG_RW,
                        "DsmpPhase2ProcessPathFailingALUA (DevInfo %p): Failed to allocate mem for TPG.\n",
                        deviceInfo));

            status = STATUS_INSUFFICIENT_RESOURCES;
        }

    } else if (NT_SUCCESS(status) &&
               scsiStatus == SCSISTAT_CHECK_CONDITION &&
               DsmpShouldRetryTPGRequest(senseData, senseDataLength)) {

        if ((context->NumberRetries)--) {

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_RW,
                        "DsmpPhase2ProcessPathFailingALUA (DevInfo %p): Retrying check condition using path %p. Retries remaining %u.\n",
                        deviceInfo,
                        deviceInfo->FailGroup->PathId,
                        context->NumberRetries));

            //
            // Retry the request
            //

            NT_ASSERT(SrbGetDataBuffer(srb) == MmGetMdlVirtualAddress(Irp->MdlAddress));

            //
            // Reset byte count of transfer in SRB Extension to true length.
            //
            SrbSetDataTransferLength(srb, targetPortGroupsInfoLength);

            //
            // Zero SRB statuses.
            //
            srb->SrbStatus = 0;
            SrbSetScsiStatus(srb, 0);

            nextIrpStack->MajorFunction = IRP_MJ_INTERNAL_DEVICE_CONTROL;
            nextIrpStack->MinorFunction = IRP_MN_SCSI_CLASS;

            //
            // Save SRB address in next stack for port driver.
            //
            nextIrpStack->Parameters.Scsi.Srb = srb;
            IoSetCompletionRoutine(Irp, DsmpPhase2ProcessPathFailingALUA, Context, TRUE, TRUE, TRUE);

            IoMarkIrpPending(Irp);

            //
            // Send the IRP asynchronously
            //
            DsmSendRequestEx(context->CompletionContext->DsmContext->MPIOContext,
                             deviceInfo->TargetObject,
                             Irp,
                             deviceInfo,
                             DSM_CALL_COMPLETION_ON_MPIO_ERROR);

            //
            // We know that the completion routine will always be called.
            //
            status = STATUS_PENDING;
            goto __Exit_DsmpPhase2ProcessPathFailingALUA;
        }
    } else {

        irql = ExAcquireSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock));

        failDevInfoListEntry = DsmpFindFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                                            context->CompletionContext->DeviceInfo->Group,
                                                            context->CompletionContext->DeviceInfo);

        if (failDevInfoListEntry) {

            DsmpRemoveFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                           context->CompletionContext->DeviceInfo->Group,
                                           failDevInfoListEntry);
        }

        ExReleaseSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock), irql);

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_RW,
                    "DsmpPhase2ProcessPathFailingALUA (DevInfo %p): NTStatus 0%x, ScsiStatus 0x%x.\n",
                    deviceInfo,
                    status,
                    SrbGetScsiStatus(srb)));

        // Failed to get TPG Info.
        // Here it is possible status is success, but scsiStatus is not.
        // If so, set status to unsuccessful.

        if (NT_SUCCESS(status)) {
            status = STATUS_UNSUCCESSFUL;
        }
    }

    if (NT_SUCCESS(status)) {

        irql = ExAcquireSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock));

        //
        // Parse the TPG information and update the device path states
        //
        status = DsmpParseTargetPortGroupsInformation(context->CompletionContext->DsmContext,
                                                      deviceInfo->Group,
                                                      targetPortGroupsInfo,
                                                      targetPortGroupsInfoLength);

        for (index = 0; index < DSM_MAX_PATHS; index++) {

            targetPortGroup = deviceInfo->Group->TargetPortGroupList[index];

            if (targetPortGroup) {

                DsmpUpdateTargetPortGroupDevicesStates(targetPortGroup, targetPortGroup->AsymmetricAccessState);
            }
        }

        if (NT_SUCCESS(status)) {

            PDSM_DEVICE_INFO tempDevice = NULL;

            //
            // Update all the devInfo states. If the device is AO but
            // not this device, make it fake AU.
            // If device not in AO, make sure that it matches the TPG
            // state.
            // Ensure that:
            // 1. All devices match their ALUA state.
            // 2. For RRWS, if a device's desired state is non-A/O, but ALUA state is A/O, mask it.
            // 3. For FOO there must be only one A/O device. Preferably the preferred path.
            //
            for (index = 0; index < DSM_MAX_PATHS; index++) {

                devInfo = group->DeviceList[index];

                if (devInfo) {

                    if (devInfo->ALUAState == DSM_DEV_ACTIVE_OPTIMIZED) {

                        //
                        // In implicit transitions, there is no guarantee that
                        // the TPG of chosen "deviceInfo" is in A/O state. So
                        // to play it safe, we hang on to the very first devInfo
                        // whose TPG is in A/O state.
                        //
                        if (!tempDevice &&
                            !DsmpIsDeviceFailedState(devInfo->State)) {

                            devInfo->PreviousState = devInfo->State;
                            devInfo->State = devInfo->ALUAState;

                            tempDevice = devInfo;
                        }

                        if (devInfo != deviceInfo) {

                            if (!DsmpIsDeviceFailedState(devInfo->State)) {

                                //
                                // For FOO, only one path can be in A/O.
                                // For RRWS, mask an A/O path if that isn't the desired state.
                                //
                                if ((group->LoadBalanceType == DSM_LB_FAILOVER) ||
                                    (group->LoadBalanceType == DSM_LB_ROUND_ROBIN_WITH_SUBSET &&
                                     devInfo->DesiredState != DSM_DEV_ACTIVE_OPTIMIZED &&
                                     devInfo->DesiredState != DSM_DEV_UNDETERMINED)) {

                                    //
                                    // For implicit transitions, we may have saved off an A/O path.
                                    // Don't undo that.
                                    //
                                    if (tempDevice != devInfo) {

                                        devInfo->PreviousState = devInfo->State;
                                        devInfo->State = DSM_DEV_ACTIVE_UNOPTIMIZED;
                                    }

                                } else {

                                    devInfo->PreviousState = devInfo->State;
                                    devInfo->State = devInfo->ALUAState;
                                }
                            }
                        } else {

                            devInfo->PreviousState = devInfo->State;

                            //
                            // For FOO, only one path can be in A/O state.
                            // The TPG of the selected "deviceInfo" is in A/O, so this
                            // can now very well be made the candidate. However, since
                            // it is possible that we saved off another candidate, we
                            // now need to replace that with this.
                            //
                            if (!DsmpIsDeviceFailedState(devInfo->State) &&
                                devInfo->Group->LoadBalanceType == DSM_LB_FAILOVER &&
                                tempDevice) {

                                tempDevice->State = DSM_DEV_ACTIVE_UNOPTIMIZED;
                            }

                            devInfo->State = devInfo->ALUAState;

                            tempDevice = devInfo;
                        }
                    } else {

                        if (!DsmpIsDeviceFailedState(devInfo->State)) {

                            devInfo->PreviousState = devInfo->State;
                            devInfo->State = devInfo->ALUAState;
                        }
                    }
                }
            }
        }

        failDevInfoListEntry = DsmpFindFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                                            context->CompletionContext->DeviceInfo->Group,
                                                            context->CompletionContext->DeviceInfo);

        if (failDevInfoListEntry) {

            DsmpRemoveFailPathDevInfoEntry(context->CompletionContext->DsmContext,
                                           context->CompletionContext->DeviceInfo->Group,
                                           failDevInfoListEntry);
        }

        ExReleaseSpinLockExclusive(&(context->CompletionContext->DsmContext->DsmContextLock), irql);
    }

    
    //
    // Resume IO if we throttled requests.
    //
    if (InterlockedCompareExchange((LONG volatile*)&group->Throttled, 0, 1)) {

        NTSTATUS resumeStatus = STATUS_UNSUCCESSFUL;

        DsmNotification(((PDSM_CONTEXT)deviceInfo->DsmContext)->MPIOContext,
                        ResumeIO_V2,
                        deviceInfo,
                        TRUE,
                        &resumeStatus,
                        0);

        if (!NT_SUCCESS(resumeStatus)) {

            //
            // Resume can fail when
            // 1. The MPDisk is being removed (or)
            // 2. The MPDisk is any other state other than throttled (or)
            // 3. There is a problem dispatching throttled requests.
            //

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_RW,
                        "DsmpPhase2ProcessPathFailingALUA (DevObj %p): Resume IO failed.\n",
                        DeviceObject));
        }

    } 

    if (decrementRTPGcount) {
        
        //
        // Resetting InFlightRTPG after resume so that we don't get into situation where 
        // new DsmpSetPathForIoRetryALUA caller thread finds that InFlightRTPG is not set but Throttled is set
        //
        ULONG count = InterlockedCompareExchange((LONG volatile*)&group->InFlightRTPG, 0, 1);

        //
        // If decrementRTPGCount flag is set, there must be atleast one RTPG in flight.
        //
        NT_ASSERT(count);

        UNREFERENCED_PARAMETER(count);
        
    }
    
    //
    // Free the allocations.
    //
    if (targetPortGroupsInfo) {

        DsmpFreePool(targetPortGroupsInfo);
    }

    //
    // Release our hold on the device info so that it can be removed.
    //
    InterlockedDecrement(&context->CompletionContext->DeviceInfo->BlockRemove);

    IoFreeMdl(Irp->MdlAddress);
    Irp->MdlAddress = NULL;

    DsmpFreePool(Irp->UserBuffer);

    IoFreeIrp(Irp);
    Irp = (PIRP) NULL;

    ExFreeToNPagedLookasideList(&(context->CompletionContext->DsmContext)->CompletionContextList, context->CompletionContext);
    DsmpFreePool(srb);
    DsmpFreePool(senseData);
#pragma warning(suppress:6001) // DevDiv 818965
    DsmpFreePool(context);

__Exit_DsmpPhase2ProcessPathFailingALUA:

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_RW,
                "DsmpPhase2ProcessPathFailingALUA (DevInfo %p): Exiting function.\n",
                deviceInfo));

    return STATUS_MORE_PROCESSING_REQUIRED;
}


NTSTATUS
DsmpPersistentReserveOut(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PKEVENT Event
    )
/*++

Routine Description:

    This routine will handle determine which devices to send the request to based
    on the service action of the PR-out command.
    On REGISTER/REGISTER_AND_IGNORE_EXISTING, it will send the command down all
    paths. If any path succeeds, the PR key will be stored. If failure down any
    path, return failure.
    On REGISTER/REGISTER_AND_IGNORE_EXISTING with key == 0 (ie. UNREGISTER),
    the request is sent down every path. Failure is returned if request fails down
    any path (but error is ignored if path happens to be one where prior
    REGISTER/REGISTER_AND_IGNORE_EXISTING had failed in the first place). The
    stored PR key is cleared irrespective of success/failure being returned.
    On RESERVE/RELEASE, the command is sent down one path. If it fails, another
    path is tried. Failure is returned only if none succeed.
    On CLEAR, command is sent down one path. If it fails, another path is tried.
    Failure is returned only if none succeed. The stored PR key is cleared
    irrespective of success/failure being returned.
    On PREEMPT, command is sent down one path. If it fails, another path is
    tried. Failure is returned only if none succeed.
    On PREEMPT_AND_ABORT, command is sent down one path. Failed request is not
    retried.

    NOTE: If a path shows up later, REGISTER_AND_IGNORE_EXISTING request is
    built by the IsPathActive routine using the saved PR key and sent down new path.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    DsmIds - The collection of DSM IDs that pertain to the MPDISK.
    Irp - Irp containing SRB.
    Srb - Scsi request block
    Event - The event to

Return Value:

    NTSTATUS of the operation.

--*/
{
    PDSM_DEVICE_INFO deviceInfo;
    PDSM_DEVICE_INFO servicingDeviceInfo = NULL;
    PDSM_GROUP_ENTRY group;
    LONG i;
    ULONG count;
    NTSTATUS status = STATUS_UNSUCCESSFUL;
    PDSM_COMPLETION_CONTEXT completionContext;
    PCDB cdb = SrbGetCdb(Srb);
    UCHAR serviceAction;
    NTSTATUS returnStatus = STATUS_SUCCESS;
    BOOLEAN sendDownAll = FALSE;
    BOOLEAN savePRKeyIfAnySucceed = FALSE;
    BOOLEAN retryOnAnother = FALSE;
    BOOLEAN passOnlyIfAllSucceed = FALSE;
    BOOLEAN ignoreIfPreviousFailed = FALSE;
    BOOLEAN clearPRKey = FALSE;
    KEVENT event;
    PPRO_PARAMETER_LIST prOutParam = Irp->AssociatedIrp.SystemBuffer;
    PUCHAR index = NULL;
    UCHAR prKey[8] = {0};
    PSTORAGE_REQUEST_BLOCK_HEADER srbCopy = NULL;
    PIO_STACK_LOCATION irpStack;
    PIO_STACK_LOCATION currentIrpStack = IoGetCurrentIrpStackLocation(Irp);
    BOOLEAN statusUpdated = FALSE;
    ULONGLONG currentTickCount;
    ULONGLONG finalTickCount;
    ULONG tickLength = KeQueryTimeIncrement();
    PVOID senseInfoBuffer = NULL;
    UCHAR senseInfoBufferLength = 0;
    BOOLEAN srbCopySucceeded = FALSE;
    UCHAR prType;
    UCHAR prScope;
    ULONGLONG saKey;
    ULONGLONG resKey;
    ULONG SpecialHandlingFlag = 0;
    
    UNREFERENCED_PARAMETER(Event);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveOut (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // Cache away a copy of the SRB
    //
    srbCopy = SrbAllocateCopy(Srb, NonPagedPoolNx, DSM_TAG_SCSI_REQUEST_BLOCK);
    if (srbCopy == NULL) {
        returnStatus = STATUS_INSUFFICIENT_RESOURCES;
        goto __Exit_DsmpPersistentReserveOut;
    }

    deviceInfo = DsmIds->IdList[0];
    group = deviceInfo->Group;

    prType = cdb->PERSISTENT_RESERVE_OUT.Type;
    prScope = cdb->PERSISTENT_RESERVE_OUT.Scope;
    serviceAction = cdb->PERSISTENT_RESERVE_OUT.ServiceAction;

    NT_ASSERT(serviceAction >= RESERVATION_ACTION_REGISTER && serviceAction <= RESERVATION_ACTION_REGISTER_IGNORE_EXISTING);

    index = prOutParam->ServiceActionReservationKey;
    RtlCopyMemory(&prKey, index, 8);
    REVERSE_BYTES_QUAD(&saKey, &prOutParam->ServiceActionReservationKey);

    REVERSE_BYTES_QUAD(&resKey, &prOutParam->ReservationKey);

    switch (serviceAction) {
        case RESERVATION_ACTION_REGISTER:
        case RESERVATION_ACTION_REGISTER_IGNORE_EXISTING: {

            //
            // The command must be sent down all paths.
            //
            sendDownAll = TRUE;

            //
            // Return failure if it fails down even one of the paths.
            //
            passOnlyIfAllSucceed = TRUE;

            if (DsmpIsPersistentReservationKeyZeroKey(ARRAY_SIZE(prKey), prKey)) {

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveOut (DsmIds %p): NULL PR key, service action %u\n",
                            DsmIds,
                            serviceAction));

                //
                // If unregister fails, don't report it back as error if the
                // previous register/register_and_ignore_existing down that
                // path had failed too.
                //
                ignoreIfPreviousFailed = TRUE;

                //
                // Clear the group PR key irrespective of the status that is
                // going to be returned to clusdisk.
                //
                clearPRKey = TRUE;

            } else {

                //
                // If register/register_and_ignore_existing succeed down any of
                // the paths, save off the PR key for the group entry.
                //
                savePRKeyIfAnySucceed = TRUE;
            }

            break;
        }

        case RESERVATION_ACTION_RESERVE:
        case RESERVATION_ACTION_RELEASE:
        case RESERVATION_ACTION_PREEMPT:
        case RESERVATION_ACTION_PREEMPT_ABORT:
        case RESERVATION_ACTION_CLEAR: {

            if (serviceAction != RESERVATION_ACTION_PREEMPT_ABORT) {

                //
                // Apart from preempt_abort, all the others must be retried
                // (down another path) if they fail down the chosen path.
                //
                retryOnAnother = TRUE;
            }

            if (serviceAction == RESERVATION_ACTION_CLEAR) {

                //
                // Clear the stored PR key for the group entry irrespective of
                // the status that is going to be returned back.
                //
                clearPRKey = TRUE;
            }

            break;
        }

        default: {

            returnStatus = STATUS_INVALID_PARAMETER;

            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_IOCTL,
                        "DsmpPersistentReserveOut (DsmIds %p): Invalid service action %u.\n",
                        DsmIds,
                        serviceAction));

            goto __Exit_DsmpPersistentReserveOut;
        }
    }

    TracePrint((TRACE_LEVEL_INFORMATION,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveOut (DsmIds %p): Srb %p, Service Action %u, Type %u, Scope %u, \
                \n\t\t\t\tservice action reservation key %I64x, reservation key %I64x.\n",
                DsmIds,
                Srb,
                serviceAction,
                prType,
                prScope,
                saKey,
                resKey));

    //
    // Allocate a context for the completion routine.
    //
    completionContext = ExAllocateFromNPagedLookasideList(&DsmContext->CompletionContextList);
    if (!completionContext) {

        returnStatus = STATUS_INSUFFICIENT_RESOURCES;

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_IOCTL,
                    "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u - Failed to allocate completion context.\n",
                    DsmIds,
                    serviceAction));

        goto __Exit_DsmpPersistentReserveOut;
    }

    KeInitializeEvent(&event, NotificationEvent, FALSE);

    //
    // Indicate the target for this request.
    //
    completionContext->DsmContext = DsmContext;
    completionContext->RequestUnique1 = (PVOID)&event;
    completionContext->RequestUnique2 = cdb->PERSISTENT_RESERVE_OUT.OperationCode;

    count = group->NumberDevices;

    for (i = count - 1; i >= 0; i--) {

        //
        // A PR command may fail with a "retry-able" UA when reservation is
        // released or preempted (on every I_T_L nexus except the one on which
        // it was released/preempted). In such a case we should retry the PR
        // command on the same path.
        //
        KeQueryTickCount((PLARGE_INTEGER)&currentTickCount);
        finalTickCount = currentTickCount + (DSM_SECONDS_TO_TICKS(group->MaxPRRetryTimeDuringStateTransition) / tickLength);

        if (!sendDownAll && !retryOnAnother) {

            //
            // If the request doesn't need to be retried (down another path) on
            // failure, better choose the path that has maximum chances of
            // success.
            //
            deviceInfo = DsmpGetActivePathToBeUsed(group,
                                                   DsmpIsSymmetricAccess((PDSM_DEVICE_INFO)DsmIds->IdList[0]),
                                                   SpecialHandlingFlag);

            if (!deviceInfo) {

                returnStatus = STATUS_UNSUCCESSFUL;

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u - No active/alternative path for device %p.\n",
                            DsmIds,
                            serviceAction,
                            group));

                break;
            }

        } else {

            deviceInfo = group->DeviceList[i];

            //
            // Ignore "bad" paths for now. If the path becomes "good" again,
            // IsPathActive() will send down the register.
            // Also, don't consider newly arrived paths for which the group has
            // a reservation but register has not yet been sent down. This rule
            // applies only to requests that are not Register.
            //
            if ((DsmpIsDeviceFailedState(deviceInfo->State) || !DsmpIsDeviceInitialized(deviceInfo)) ||
                (!DsmpIsDeviceUsablePR(deviceInfo) && !sendDownAll)) {

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveOut (DsmIds %p): Ignoring bad instance - state %x, init %x, key reg %x (key valid %x).\n",
                            DsmIds,
                            deviceInfo->State,
                            deviceInfo->Initialized,
                            deviceInfo->PRKeyRegistered,
                            deviceInfo->Group->PRKeyValid));

                deviceInfo = NULL;
            }

        }

        if (!deviceInfo) {

            //
            // Maybe a remove came through and caused a collapse of the device
            // list, thus making this entry empty.
            //
            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_IOCTL,
                        "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u - Couldn't find path for device %p.\n",
                        DsmIds,
                        serviceAction,
                        group));

            continue;
        }

__DsmpPersistentReserveOut_RetryRequest:

        IoMarkIrpPending(Irp);

        completionContext->DeviceInfo = deviceInfo;

        //
        // Set-up a completion routine.
        //
        IoSetCompletionRoutine(Irp,
                               DsmpPersistentReserveCompletion,
                               completionContext,
                               TRUE,
                               TRUE,
                               TRUE);

        //
        // Always send the original request down a new path
        //
        irpStack = IoGetNextIrpStackLocation(Irp);
        srbCopySucceeded = SrbCopySrb(Srb, SrbGetSrbLength(Srb), srbCopy);
        NT_ASSERT(srbCopySucceeded == TRUE);
        irpStack->Parameters.Scsi.Srb = Srb;

        //
        // Clear the sense buffer if it exists
        //
        senseInfoBuffer = SrbGetSenseInfoBuffer(Srb);
        senseInfoBufferLength = SrbGetSenseInfoBufferLength(Srb);
        if (senseInfoBuffer) {
            RtlZeroMemory(senseInfoBuffer, senseInfoBufferLength);
        }

        servicingDeviceInfo = deviceInfo;

        //
        // Issue the request and wait.
        //
        status = DsmSendRequest(DsmContext->MPIOContext,
                                deviceInfo->TargetObject,
                                Irp,
                                deviceInfo);

        if (status == STATUS_PENDING) {

            KeWaitForSingleObject(&event,
                                  Executive,
                                  KernelMode,
                                  FALSE,
                                  NULL);

            status = Irp->IoStatus.Status;
        }

        if (NT_SUCCESS(status) || status == STATUS_BUFFER_OVERFLOW) {

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_IOCTL,
                        "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u sent down successfully on %p.\n",
                        DsmIds,
                        serviceAction,
                        deviceInfo->FailGroup->PathId));

            if (!passOnlyIfAllSucceed) {

                //
                // Success down any one path means success
                //
                returnStatus = status;
            }

            if (savePRKeyIfAnySucceed) {

                RtlCopyMemory(&group->PersistentReservationRegisteredKey, &prKey, 8);

                group->PRServiceAction = serviceAction;
                group->PRType = prType;
                group->PRScope = prScope;
                group->PRKeyValid = TRUE;
                deviceInfo->PRKeyRegistered = TRUE;
            }

            if (!sendDownAll) {

                //
                // Need for retrying on another path only necessary in the case
                // of request failing down the chosen path. Since the request
                // succeeded down this path, we are done.
                //
                break;
            }
        } else {

            BOOLEAN recordFailure;

            //
            // Check to see if the request failed because of a "transient error",
            // like reservations released for example. If so, this is NOT an actual
            // error and the request must be retried. Multiple retries may be required
            // if for example the UA indicates that the TPGs are in transitioning state.
            //
            if (Srb->SrbStatus & SRB_STATUS_AUTOSENSE_VALID &&
                Srb->SrbStatus & SRB_STATUS_ERROR &&
                SrbGetScsiStatus(Srb) == SCSISTAT_CHECK_CONDITION) {

                KeQueryTickCount((PLARGE_INTEGER)&currentTickCount);

                senseInfoBuffer = SrbGetSenseInfoBuffer(Srb);
                senseInfoBufferLength = SrbGetSenseInfoBufferLength(Srb);

                if (DsmpShouldRetryPersistentReserveCommand(senseInfoBuffer, senseInfoBufferLength) &&
                    currentTickCount < finalTickCount) {

                    TracePrint((TRACE_LEVEL_WARNING,
                                TRACE_FLAG_IOCTL,
                                "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u returned UA with error %x. Retrying same path %p.\n",
                                DsmIds,
                                serviceAction,
                                status,
                                deviceInfo->FailGroup->PathId));

                    KeResetEvent(&event);
                    Irp->IoStatus.Status = 0;

                    goto __DsmpPersistentReserveOut_RetryRequest;
                }
            }

            //
            // The return status is STATUS_SUCCESS by default. This means that if the
            // request failed on the first path and was retried down every other path
            // but fails down all of them, the return status is never updated.
            // So cache the first failure status to cover the above scenario.
            //
            if (!statusUpdated) {

                returnStatus = status;
                statusUpdated = TRUE;
            }

            recordFailure = TRUE;
            if (ignoreIfPreviousFailed && !deviceInfo->PRKeyRegistered) {

                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u - Ignoring status %x for path %p.\n",
                            DsmIds,
                            serviceAction,
                            status,
                            deviceInfo->FailGroup->PathId));

                //
                // Okay to ignore this failure if the previous failed.
                //
                recordFailure = FALSE;
            }

            if (passOnlyIfAllSucceed && recordFailure) {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u - Saving status %x for return.\n",
                            DsmIds,
                            serviceAction,
                            status));

                //
                // Save the failure status to return back.
                //
                returnStatus = status;
            }

            //
            // If the request is not to be sent down all paths, and also
            // a retry (along a different path) on failure is not required,
            // we're done - just return this failure.
            //
            if (!(sendDownAll || retryOnAnother)) {

                returnStatus = status;

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u sent down %p failed with %x. Breaking out.\n",
                            DsmIds,
                            serviceAction,
                            deviceInfo->FailGroup->PathId,
                            status));

                break;

            } else {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveOut (DsmIds %p): PR_OUT %u sent down %p failed with %x. Sending down another path.\n",
                            DsmIds,
                            serviceAction,
                            deviceInfo->FailGroup->PathId,
                            status));
            }
        }

        //
        // If we are here, it is either because the request needs to be sent down
        // all paths, or because the request failed down the chosen path and needs
        // to be retried down a new path.
        //
        KeResetEvent(&event);
        Irp->IoStatus.Status = 0;
    }

    if (clearPRKey) {

        for (i = 0; (ULONG)i < group->NumberDevices; i++) {

            deviceInfo = group->DeviceList[i];

            if (deviceInfo) {

                deviceInfo->RegisterServiced = FALSE;
                deviceInfo->PRKeyRegistered = FALSE;
            }
        }
        group->PersistentReservationRegisteredKey[0] = group->PersistentReservationRegisteredKey[1] =
        group->PersistentReservationRegisteredKey[2] = group->PersistentReservationRegisteredKey[3] =
        group->PersistentReservationRegisteredKey[4] = group->PersistentReservationRegisteredKey[5] =
        group->PersistentReservationRegisteredKey[6] = group->PersistentReservationRegisteredKey[7] = 0;

        group->PRKeyValid = FALSE;
        group->ReservationList = 0;
    }

    if (savePRKeyIfAnySucceed && group->PRKeyValid) {

        ULONG ordinal;

        for (i = 0; (ULONG)i < group->NumberDevices; i++) {

            deviceInfo = group->DeviceList[i];

            if (deviceInfo) {

                deviceInfo->RegisterServiced = TRUE;
                ordinal = (1 << i);
                group->ReservationList |= ordinal;
            }
        }
    }

    TracePrint((TRACE_LEVEL_INFORMATION,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveOut (DsmIds %p): PR_OUT for %u completed with status %x.\n",
                DsmIds,
                serviceAction,
                returnStatus));

    ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);

__Exit_DsmpPersistentReserveOut:

    if (srbCopy != NULL) {
        DsmpFreePool(srbCopy);
    }

    currentIrpStack->Parameters.Others.Argument3 = servicingDeviceInfo;
    Irp->IoStatus.Status = returnStatus;
    if ((!NT_SUCCESS(returnStatus)) &&
        (SrbGetSrbStatus(Srb) == SRB_STATUS_SUCCESS)) {
        SrbSetSrbStatus(Srb, DsmpNtStatusToSrbStatus(returnStatus));
    }
    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveOut (DsmIds %p): Exiting function returning IRP status %x.\n",
                DsmIds,
                returnStatus));

    return returnStatus;
}



NTSTATUS
DsmpPersistentReserveIn(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PKEVENT Event
    )
/*++

Routine Description:

    This routine will handle determine which devices to send the request to based
    on the service action of the PR-in command.
    On READ KEYS, it will send down one path. In case of failure, other paths will
    be tried until one succeeds. Failure is returned only if it fails down all paths.
    On READ_RESERVATION/REPORT_CAPABILITIES, command is sent down one path. Failed
    request is not retried.

Arguments:

    DsmContext - DSM context given to MPIO during initialization
    DsmIds - The collection of DSM IDs that pertain to the MPDISK.
    Irp - Irp containing SRB.
    Srb - Scsi request block
    Event - The event to

Return Value:

    NTSTATUS of the operation.

--*/
{
    PDSM_DEVICE_INFO deviceInfo;
    PDSM_DEVICE_INFO servicingDeviceInfo = NULL;
    PDSM_GROUP_ENTRY group;
    LONG i;
    ULONG count;
    NTSTATUS status = STATUS_UNSUCCESSFUL;
    PDSM_COMPLETION_CONTEXT completionContext;
    PCDB cdb = SrbGetCdb(Srb);
    UCHAR serviceAction;
    BOOLEAN retryOnAnother = FALSE;
    KEVENT event;
    PSTORAGE_REQUEST_BLOCK_HEADER srbCopy = NULL;
    PIO_STACK_LOCATION irpStack;
    PIO_STACK_LOCATION currentIrpStack = IoGetCurrentIrpStackLocation(Irp);
    ULONGLONG currentTickCount;
    ULONGLONG finalTickCount;
    ULONG tickLength = KeQueryTimeIncrement();
    PVOID senseInfoBuffer = NULL;
    UCHAR senseInfoBufferLength = 0;
    BOOLEAN srbCopySucceeded = FALSE;
    ULONG SpecialHandlingFlag = 0;
    
    UNREFERENCED_PARAMETER(Event);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveIn (DsmIds %p): Entering function.\n",
                DsmIds));

    //
    // Cache away a copy of the SRB
    //
    srbCopy = SrbAllocateCopy(Srb, NonPagedPoolNx, DSM_TAG_SCSI_REQUEST_BLOCK);
    if (srbCopy == NULL) {
        status = STATUS_INSUFFICIENT_RESOURCES;
        goto __Exit_DsmpPersistentReserveIn;
    }

    deviceInfo = DsmIds->IdList[0];
    group = deviceInfo->Group;

    serviceAction = cdb->PERSISTENT_RESERVE_IN.ServiceAction;

    switch (serviceAction) {
        case RESERVATION_ACTION_READ_RESERVATIONS:
        case RESERVATION_ACTION_READ_KEYS: {

            //
            // If there is a failure on the chosen path, retry on another path.
            //
            retryOnAnother = TRUE;
            break;
        }

        case SPC3_RESERVATION_ACTION_REPORT_CAPABILITIES: {

            break;
        }

        default: {

            NT_ASSERT(FALSE);
            status = STATUS_INVALID_PARAMETER;
            goto __Exit_DsmpPersistentReserveIn;
        }
    }

    TracePrint((TRACE_LEVEL_INFORMATION,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveIn (DsmIds %p): Srb %p. Service Action %u.\n",
                DsmIds,
                Srb,
                serviceAction));

    //
    // Allocate a context for the completion routine.
    //
    completionContext = ExAllocateFromNPagedLookasideList(&DsmContext->CompletionContextList);
    if (!completionContext) {

        status = STATUS_INSUFFICIENT_RESOURCES;

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_IOCTL,
                    "DsmpPersistentReserveIn (DsmIds %p): PR_IN %u - Failed to allocate completion context.\n",
                    DsmIds,
                    serviceAction));

        goto __Exit_DsmpPersistentReserveIn;
    }

    KeInitializeEvent(&event, NotificationEvent, FALSE);

    //
    // Indicate the target for this request.
    //
    completionContext->DsmContext = DsmContext;
    completionContext->RequestUnique1 = (PVOID)&event;
    completionContext->RequestUnique2 = cdb->PERSISTENT_RESERVE_IN.OperationCode;

    count = group->NumberDevices;

    for (i = count - 1; i >= 0; i--) {

        //
        // A PR command may fail with a "retry-able" UA when reservation is
        // released or preempted (on every I_T_L nexus except the one on which
        // it was released/preempted). In such a case we should retry the PR
        // command on the same path.
        //
        KeQueryTickCount((PLARGE_INTEGER)&currentTickCount);
        finalTickCount = currentTickCount + (DSM_SECONDS_TO_TICKS(group->MaxPRRetryTimeDuringStateTransition) / tickLength);

        if (!retryOnAnother) {

            //
            // If the request doesn't need to be retried (down another path) on
            // failure, better choose the path that has maximum chances of
            // success.
            //
            deviceInfo = DsmpGetActivePathToBeUsed(group,
                                                   DsmpIsSymmetricAccess((PDSM_DEVICE_INFO)DsmIds->IdList[0]),
                                                   SpecialHandlingFlag);

            if (!deviceInfo) {

                status = STATUS_UNSUCCESSFUL;

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveIn (DsmIds %p): PR_IN %u - No active/alternative path for device %p.\n",
                            DsmIds,
                            serviceAction,
                            group));

                break;
            }

        } else {

            deviceInfo = group->DeviceList[i];

            if (DsmpIsDeviceFailedState(deviceInfo->State) || !DsmpIsDeviceInitialized(deviceInfo)) {

                //
                // Ignore "bad" paths for now.
                //
                TracePrint((TRACE_LEVEL_WARNING,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveIn (DsmIds %p): Ignoring bad instance - state %x, init %x.\n",
                            DsmIds,
                            deviceInfo->State,
                            deviceInfo->Initialized));

                deviceInfo = NULL;
            }
        }

        if (!deviceInfo) {

            //
            // Maybe a remove came through and caused a collapse of the device
            // list, thus making this entry empty.
            //
            TracePrint((TRACE_LEVEL_WARNING,
                        TRACE_FLAG_IOCTL,
                        "DsmpPersistentReserveIn (DsmIds %p): PR_IN %u - Couldn't find path for device %p.\n",
                        DsmIds,
                        serviceAction,
                        group));

            continue;
        }

__DsmpPersistentReserveIn_RetryRequest:

        IoMarkIrpPending(Irp);

        completionContext->DeviceInfo = deviceInfo;

        //
        // Set-up a completion routine.
        //
        IoSetCompletionRoutine(Irp,
                               DsmpPersistentReserveCompletion,
                               completionContext,
                               TRUE,
                               TRUE,
                               TRUE);

        //
        // Always send the original request down a new path
        //
        irpStack = IoGetNextIrpStackLocation(Irp);
        srbCopySucceeded = SrbCopySrb(Srb, SrbGetSrbLength(Srb), srbCopy);
        NT_ASSERT(srbCopySucceeded == TRUE);
        irpStack->Parameters.Scsi.Srb = Srb;

        //
        // Clear the sense buffer if it exists
        //
        senseInfoBuffer = SrbGetSenseInfoBuffer(Srb);
        senseInfoBufferLength = SrbGetSenseInfoBufferLength(Srb);
        if (senseInfoBuffer) {
            RtlZeroMemory(senseInfoBuffer, senseInfoBufferLength);
        }

        servicingDeviceInfo = deviceInfo;

        //
        // Issue the request and wait.
        //
        status = DsmSendRequest(DsmContext->MPIOContext,
                                deviceInfo->TargetObject,
                                Irp,
                                deviceInfo);

        if (status == STATUS_PENDING) {

            KeWaitForSingleObject(&event,
                                  Executive,
                                  KernelMode,
                                  FALSE,
                                  NULL);

            status = Irp->IoStatus.Status;
        }

        if (NT_SUCCESS(status) || status == STATUS_BUFFER_OVERFLOW) {

            TracePrint((TRACE_LEVEL_INFORMATION,
                        TRACE_FLAG_IOCTL,
                        "DsmpPersistentReserveIn (DsmIds %p): PR_IN for %u sent down successfully on %p.\n",
                        DsmIds,
                        serviceAction,
                        deviceInfo->FailGroup->PathId));
#if DBG
            if (serviceAction == RESERVATION_ACTION_READ_KEYS) {

                PPRI_REGISTRATION_LIST prInRegistrationList = Irp->AssociatedIrp.SystemBuffer;
                ULONG numberOfKeys;
                ULONG keyIndex;
                ULONGLONG prKey;

                REVERSE_BYTES(&numberOfKeys, &prInRegistrationList->AdditionalLength);
                numberOfKeys /= 8;

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveIn (DsmIds %p): %u registrations keys present:\n",
                            DsmIds,
                            numberOfKeys));

                for (keyIndex = 0; keyIndex < numberOfKeys; keyIndex++) {

                    REVERSE_BYTES_QUAD(&prKey, &(prInRegistrationList->ReservationKeyList[keyIndex]));
                    TracePrint((TRACE_LEVEL_INFORMATION,
                                TRACE_FLAG_IOCTL,
                                "DsmpPersistentReserveIn (DsmIds %p): Registration Key %u: %I64x\n",
                                DsmIds,
                                keyIndex,
                                prKey));
                }

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_IOCTL,
                            "\n"));

            } else if (serviceAction == RESERVATION_ACTION_READ_RESERVATIONS) {

                PPRI_RESERVATION_LIST prInReservationList = Irp->AssociatedIrp.SystemBuffer;
                ULONG numberOfDescriptors;
                PPRI_RESERVATION_DESCRIPTOR prInReservationDescriptor = prInReservationList->Reservations;
                ULONGLONG prKey = 0;

                REVERSE_BYTES(&numberOfDescriptors, &prInReservationList->AdditionalLength);
                numberOfDescriptors /= sizeof(PRI_RESERVATION_DESCRIPTOR);
                NT_ASSERT(numberOfDescriptors <= 1);

                if (numberOfDescriptors == 1) {
                    REVERSE_BYTES_QUAD(&prKey, &prInReservationDescriptor->ReservationKey);
                }

                TracePrint((TRACE_LEVEL_INFORMATION,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveIn (DsmIds %p): %u Reservation Key: %I64x\n",
                            DsmIds,
                            numberOfDescriptors,
                            prKey));
            }
#endif
            //
            // Done.
            //
            break;

        } else {

            //
            // Check to see if the request failed because of a "transient error",
            // like reservations released for example. If so, this is NOT an actual
            // error and the request must be retried. Multiple retries may be required
            // if for example the UA indicates that the TPGs are in transitioning state.
            //
            if (Srb->SrbStatus & SRB_STATUS_AUTOSENSE_VALID &&
                Srb->SrbStatus & SRB_STATUS_ERROR &&
                SrbGetScsiStatus(Srb) == SCSISTAT_CHECK_CONDITION) {

                KeQueryTickCount((PLARGE_INTEGER)&currentTickCount);

                senseInfoBuffer = SrbGetSenseInfoBuffer(Srb);
                senseInfoBufferLength = SrbGetSenseInfoBufferLength(Srb);

                if (group->PRKeyValid &&
                    DsmpShouldRetryPersistentReserveCommand(senseInfoBuffer, senseInfoBufferLength) &&
                    currentTickCount < finalTickCount) {

                    TracePrint((TRACE_LEVEL_WARNING,
                                TRACE_FLAG_IOCTL,
                                "DsmpPersistentReserveIn (DsmIds %p): PR_IN %u returned UA with error %x. Retrying same path %p.\n",
                                DsmIds,
                                serviceAction,
                                status,
                                deviceInfo->FailGroup->PathId));

                    KeResetEvent(&event);
                    Irp->IoStatus.Status = 0;

                    goto __DsmpPersistentReserveIn_RetryRequest;
                }
            }

            //
            // If a retry (along a different path) on failure is not required,
            // we're done - just return this failure.
            //
            if (!retryOnAnother) {

                TracePrint((TRACE_LEVEL_ERROR,
                            TRACE_FLAG_IOCTL,
                            "DsmpPersistentReserveIn (DsmIds %p): PR_IN for %u down %p failed with %x. Breaking out.\n",
                            DsmIds,
                            serviceAction,
                            deviceInfo->FailGroup->PathId,
                            status));

                break;
            }
        }

        TracePrint((TRACE_LEVEL_ERROR,
                    TRACE_FLAG_IOCTL,
                    "DsmpPersistentReserveIn (DsmIds %p): PR_IN for %u down %p failed with %x. Sending down another path.\n",
                    DsmIds,
                    serviceAction,
                    deviceInfo->FailGroup->PathId,
                    status));

        //
        // If we are here, it is because the request failed down the chosen path
        // and needs to be retried down a new path.
        //
        KeResetEvent(&event);
        Irp->IoStatus.Status = 0;
    }

    TracePrint((TRACE_LEVEL_INFORMATION,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveIn (DsmIds %p): PR_IN for %u completed with status %x.\n",
                DsmIds,
                serviceAction,
                status));

    ExFreeToNPagedLookasideList(&DsmContext->CompletionContextList, completionContext);

__Exit_DsmpPersistentReserveIn:

    if (srbCopy != NULL) {
        DsmpFreePool(srbCopy);
    }

    currentIrpStack->Parameters.Others.Argument3 = servicingDeviceInfo;
    Irp->IoStatus.Status = status;

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveIn (DsmIds %p): Exiting function returning IRP status %x.\n",
                DsmIds,
                status));

    return status;
}


NTSTATUS
DsmpPersistentReserveCompletion(
    IN PDEVICE_OBJECT DeviceObject,
    IN PIRP Irp,
    IN PVOID Context
    )
/*++

Routine Description:

    General-purpose completion routine for PR in and out commands sent synchronously.

Arguments:

    DeviceObject - Target of the request.
    Irp - Command being sent.
    Context - The event on which the caller is waiting.

Return Value:

    NTSTATUS

--*/

{
    PDSM_COMPLETION_CONTEXT context = Context;
    PKEVENT event;

    // It is required to specify a DSM completion context
    // when setting DsmpPersistentReserveCompletion as completion routine.
    _Analysis_assume_(context != NULL);

    event = (PKEVENT)(context->RequestUnique1);

    UNREFERENCED_PARAMETER(DeviceObject);

    TracePrint((TRACE_LEVEL_VERBOSE,
                TRACE_FLAG_IOCTL,
                "DsmpPersistentReserveCompletion: DevInfo %p, IRP %p, Context %p\n",
                context->DeviceInfo,
                Irp,
                Context));

    if (Irp->PendingReturned) {

        IoMarkIrpPending(Irp);
    }

    KeSetEvent(event, 0, FALSE);

    return STATUS_MORE_PROCESSING_REQUIRED;
}

