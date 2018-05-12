
/*++

Copyright (C) 2004  Microsoft Corporation

Module Name:

    prototypes.h

Abstract:

    Contains function prototypes for all the functions defined
    by Microsoft Device Specific Module (DSM).

Environment:

    kernel mode only

Notes:

--*/

#pragma warning (disable:4214) // bit field usage
#pragma warning (disable:4200) // zero-sized array

#ifndef _PROTOTYPES_H_
#define _PROTOTYPES_H_

#define DSM_VENDOR_ID_LEN       8
#define DSM_PRODUCT_ID_LEN      16
#define DSM_VENDPROD_ID_LEN     24

//
// In accordance with SPC-3 specs
//
#define SPC3_TARGET_PORT_GROUPS_HEADER_SIZE         4

typedef struct _SPC3_CDB_REPORT_TARGET_PORT_GROUPS {
    UCHAR OperationCode;
    UCHAR ServiceAction : 5;
    UCHAR Reserved1 : 3;
    UCHAR Reserved2[4];
    UCHAR AllocationLength[4];
    UCHAR Reserved3;
    UCHAR Control;
} SPC3_CDB_REPORT_TARGET_PORT_GROUPS, *PSPC3_CDB_REPORT_TARGET_PORT_GROUPS;

typedef struct _SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR {
    UCHAR AsymmetricAccessState : 4;
    UCHAR Reserved : 3;
    UCHAR Preferred : 1;
    UCHAR ActiveOptimizedSupported : 1;
    UCHAR ActiveUnoptimizedSupported : 1;
    UCHAR StandbySupported : 1;
    UCHAR UnavailableSupported : 1;
    UCHAR Reserved2 : 3;
    UCHAR TransitioningSupported : 1;
    USHORT TPG_Identifier;
    UCHAR Reserved3;
    UCHAR StatusCode;
    UCHAR VendorUnique;
    UCHAR NumberTargetPorts;
    ULONG TargetPortIds[0];
} SPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR, *PSPC3_REPORT_TARGET_PORT_GROUP_DESCRIPTOR;

typedef struct _SPC3_CDB_SET_TARGET_PORT_GROUPS {
    UCHAR OperationCode;
    UCHAR ServiceAction : 5;
    UCHAR Reserved1 : 3;
    UCHAR Reserved2[4];
    UCHAR ParameterListLength[4];
    UCHAR Reserved3;
    UCHAR Control;
} SPC3_CDB_SET_TARGET_PORT_GROUPS, *PSPC3_CDB_SET_TARGET_PORT_GROUPS;

typedef struct _SPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR {
    UCHAR AsymmetricAccessState : 4;
    UCHAR Reserved1 : 4;
    UCHAR Reserved2;
    USHORT TPG_Identifier;
} SPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR, *PSPC3_SET_TARGET_PORT_GROUP_DESCRIPTOR;

typedef struct _SPC3_CONTROL_EXTENSION_MODE_PAGE {
    UCHAR PageCode : 6;
    UCHAR SubpageFormat : 1;
    UCHAR ParametersSavable : 1;
    UCHAR SubpageCode;
    UCHAR PageLength[2];
    UCHAR ImplicitALUAEnable : 1;
    UCHAR ScsiPrecendence : 1;
    UCHAR TimestampChangeable : 1;
    UCHAR Reserved1 : 5;
    UCHAR InitialPriority : 4;
    UCHAR Reserved2 : 4;
    UCHAR Reserved3[26];
} SPC3_CONTROL_EXTENSION_MODE_PAGE, *PSPC3_CONTROL_EXTENSION_MODE_PAGE;

#define SPC3_SCSIOP_REPORT_TARGET_PORT_GROUPS       0xA3
#define SPC3_SCSIOP_SET_TARGET_PORT_GROUPS          0xA4
#define SPC3_SERVICE_ACTION_TARGET_PORT_GROUPS      0xA
#define SPC3_RESERVATION_ACTION_REPORT_CAPABILITIES 0x2

#define SPC3_SCSI_ADSENSE_COMMANDS_CLEARED_BY_ANOTHER_INITIATOR 0x2F
#define SPC3_SCSI_ADSENSE_LOGICAL_UNIT_COMMAND_FAILED       0x67

#define SPC3_SCSI_SENSEQ_MODE_PARAMETERS_CHANGED            0x1
#define SPC3_SCSI_SENSEQ_RESERVATIONS_PREEMPTED             0x3
#define SPC3_SCSI_SENSEQ_RESERVATIONS_RELEASED              0x4
#define SPC3_SCSI_SENSEQ_REGISTRATIONS_PREEMPTED            0x5
#define SPC3_SCSI_SENSEQ_ASYMMETRIC_ACCESS_STATE_CHANGED    0x6
#define SPC3_SCSI_SENSEQ_IMPLICIT_ASYMMETRIC_ACCESS_STATE_TRANSITION_FAILED 0x7
#define SPC3_SCSI_SENSEQ_CAPACITY_DATA_HAS_CHANGED          0x9
#define SPC3_SCSI_SENSEQ_ASYMMETRIC_ACCESS_STATE_TRANSITION 0xA
#define SPC3_SCSI_SENSEQ_TARGET_PORT_IN_STANDBY_STATE       0xB
#define SPC3_SCSI_SENSEQ_TARGET_PORT_IN_UNAVAILABLE_STATE   0xC

#define SPC3_SCSI_SENSEQ_SET_TARGET_PORT_GROUPS_FAILED      0xA

#define SPC3_SET_TARGET_PORT_GROUPS_TIMEOUT     10
#define SPC3_REPORT_TARGET_PORT_GROUPS_TIMEOUT  10


//
// Function prototypes for functions intrface.c
//

DRIVER_INITIALIZE DriverEntry;
DRIVER_UNLOAD DsmDriverUnload;

NTSTATUS
DsmInquire (
    _In_ IN PVOID DsmContext,
    _In_ IN PDEVICE_OBJECT TargetDevice,
    _In_ IN PDEVICE_OBJECT PortObject,
    _In_ IN PSTORAGE_DEVICE_DESCRIPTOR Descriptor,
    _In_ IN PSTORAGE_DEVICE_ID_DESCRIPTOR DeviceIdList,
    _Out_ OUT PVOID *DsmIdentifier
    );

BOOLEAN
DsmCompareDevices(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId1,
    _In_ IN PVOID DsmId2
    );

NTSTATUS
DsmGetControllerInfo(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId,
    _In_ IN ULONG Flags,
    _Inout_ IN OUT PCONTROLLER_INFO *ControllerInfo
    );

NTSTATUS
DsmSetDeviceInfo(
    _In_ IN PVOID DsmContext,
    _In_ IN PDEVICE_OBJECT TargetObject,
    _In_ IN PVOID DsmId,
    _Inout_ IN OUT PVOID *PathId
    );

BOOLEAN
DsmIsPathActive(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID PathId,
    _In_ IN PVOID DsmId
    );

NTSTATUS
DsmPathVerify(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId,
    _In_ IN PVOID PathId
    );

NTSTATUS
DsmInvalidatePath(
    _In_ IN PVOID DsmContext,
    _In_ IN ULONG ErrorMask,
    _In_ IN PVOID PathId,
    _Inout_ IN OUT PVOID *NewPathId
    );

NTSTATUS
DsmMoveDevice(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PVOID MPIOPath,
    _In_ IN PVOID SuggestedPath,
    _In_ IN ULONG Flags
    );

NTSTATUS
DsmRemovePending(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId
    );

NTSTATUS
DsmRemoveDevice(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId,
    _In_ IN PVOID PathId
    );

NTSTATUS
DsmRemovePath(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PVOID PathId
    );

NTSTATUS
DsmSrbDeviceControl(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PKEVENT Event
    );

PVOID
DsmLBGetPath(
    _In_ IN PVOID DsmContext,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PDSM_IDS DsmList,
    _In_ IN PVOID CurrentPath,
    _Out_ OUT NTSTATUS *Status
    );

ULONG
DsmInterpretError(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _Inout_ IN OUT NTSTATUS *Status,
    _Out_ OUT PBOOLEAN Retry,
    _Out_ OUT PLONG RetryInterval,
    ...
    );

NTSTATUS
DsmUnload(
    _In_ IN PVOID DsmContext
    );

VOID
DsmSetCompletion(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _Inout_ IN OUT PDSM_COMPLETION_INFO DsmCompletion
    );

_Success_(return == DSM_PATH_SET)
ULONG
DsmCategorizeRequest(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PVOID CurrentPath,
    _Outptr_result_maybenull_ OUT PVOID *PathId,
    _Out_ OUT NTSTATUS *Status
    );

NTSTATUS
DsmBroadcastRequest(
    _In_ IN PVOID DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PKEVENT Event
    );

BOOLEAN
DsmIsAddressTypeSupported(
    _In_ IN PVOID DsmContext,
    _In_ IN ULONG AddressType
    );

NTSTATUS
DsmDeviceNotUsed(
    _In_ IN PVOID DsmContext,
    _In_ IN PVOID DsmId
    );


//
// Function prototypes for functions in dsmmain.c
//

VOID
DsmpFreeDSMResources(
    _In_ IN PDSM_CONTEXT DsmContext
    );

PDSM_GROUP_ENTRY
DsmpFindDevice(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN BOOLEAN AcquireDSMLockExclusive
    );

PDSM_GROUP_ENTRY
DsmpBuildGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    );

NTSTATUS
DsmpParseTargetPortGroupsInformation(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_reads_bytes_(TargetPortGroupsInfoLength) IN PUCHAR TargetPortGroupsInfo,
    _In_ IN ULONG TargetPortGroupsInfoLength
    );

PDSM_TARGET_PORT_GROUP_ENTRY
DsmpFindTargetPortGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_reads_bytes_(TPGs_BufferLength) IN PUCHAR TargetPortGroupsDescriptor,
    _In_ IN ULONG TPGs_BufferLength
    );

_Success_(return!=0)
PDSM_TARGET_PORT_GROUP_ENTRY
DsmpUpdateTargetPortGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_reads_bytes_(TPGs_BufferLength) IN PUCHAR TargetPortGroupsDescriptor,
    _In_ IN ULONG TPGs_BufferLength,
    _Out_ OUT PULONG DescriptorSize
    );

PDSM_TARGET_PORT_GROUP_ENTRY
DsmpBuildTargetPortGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_reads_bytes_(TPGs_BufferLength) IN PUCHAR TargetPortGroupsDescriptor,
    _In_ IN ULONG TPGs_BufferLength,
    _Out_ OUT PULONG DescriptorSize
    );

PDSM_TARGET_PORT_LIST_ENTRY
DsmpFindTargetPortListEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN ULONG RelativeTargetPortId
    );

PDSM_TARGET_PORT_LIST_ENTRY
DsmpBuildTargetPortListEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN ULONG RelativeTargetPortId
    );

PDSM_TARGET_PORT_GROUP_ENTRY
DsmpFindTargetPortGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PUSHORT TargetPortGroupId
    );

PDSM_TARGET_PORT_LIST_ENTRY
DsmpFindTargetPort(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN PULONG TargetPortGroupId
    );

NTSTATUS
DsmpAddDeviceEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    );

PDSM_CONTROLLER_LIST_ENTRY
DsmpFindControllerEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDEVICE_OBJECT PortObject,
    _In_ IN PSCSI_ADDRESS ScsiAddress,
    _In_reads_(ControllerSerialNumberLength) IN PSTR ControllerSerialNumber,
    _In_ IN SIZE_T ControllerSerialNumberLength,
    _In_ IN STORAGE_IDENTIFIER_CODE_SET CodeSet,
    _In_ IN BOOLEAN AcquireLock
    );

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
    );

VOID
DsmpFreeControllerEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ __drv_freesMem(Mem) IN PDSM_CONTROLLER_LIST_ENTRY ControllerEntry
    );

BOOLEAN
DsmpIsDeviceBelongsToController(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN PDSM_CONTROLLER_LIST_ENTRY ControllerEntry
    );

PDSM_DEVICE_INFO
DsmpFindDevInfoFromGroupAndFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_FAILOVER_GROUP FOGroup
    );

PDSM_FAILOVER_GROUP
DsmpFindFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PVOID PathId
    );

PDSM_FAILOVER_GROUP
DsmpBuildFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN PVOID        *PathId
    );

NTSTATUS
DsmpUpdateFOGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_FAILOVER_GROUP FailGroup,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    );

VOID
DsmpRemoveDeviceFailGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_FAILOVER_GROUP FailGroup,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN BOOLEAN AcquireDSMLockExclusive
    );

ULONG
DsmpRemoveDeviceEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    );

VOID
DsmpRemoveDeviceFromTargetPortList(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    );

PDSM_FAILOVER_GROUP
DsmpSetNewPath(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDevice
    );

PDSM_FAILOVER_GROUP
DsmpSetNewPathUsingGroup(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY Group
    );

VOID
DsmpRemoveZombieGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY ZombieGroup
    );

NTSTATUS
DsmpUpdateTargetPortGroupDevicesStates(
    _In_ IN PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup,
    _In_ IN DSM_DEVICE_STATE NewState
    );

VOID
DsmpIncrementCounters(
    _In_ PDSM_FAILOVER_GROUP FailGroup,
    _In_ PSCSI_REQUEST_BLOCK Srb
    );

BOOLEAN
DsmpDecrementCounters(
    _In_ PDSM_FAILOVER_GROUP FailGroup,
    _In_ PSCSI_REQUEST_BLOCK Srb
    );

PDSM_FAILOVER_GROUP
DsmpGetPath(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmList,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,    
    _In_ IN ULONG SpecialHandlingFlag
    );

PVOID
DsmpGetPathIdFromPassThroughPath(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmList,
    _In_ IN PIRP Irp,
    _Inout_ IN OUT NTSTATUS *Status
    );

VOID
DsmpRemoveGroupEntry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_GROUP_ENTRY GroupEntry,
    _In_ IN BOOLEAN AcquireDSMLockExclusive
    );

BOOLEAN
DsmpMpioPassThroughPathCommand(
    _In_ IN PIRP Irp
    );

BOOLEAN
DsmpReservationCommand(
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb
    );

VOID
DsmpRequestComplete(
    _In_ IN PVOID DsmId,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PVOID DsmContext
    );

NTSTATUS
DsmpRegisterPersistentReservationKeys(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN BOOLEAN      Register
    );


BOOLEAN
DsmpShouldRetryPassThroughRequest(
    _In_ IN PVOID   SenseData,
    _In_ IN UCHAR   SenseDataSize
    );

BOOLEAN
DsmpShouldRetryPersistentReserveCommand(
    _In_ IN PVOID   SenseData,
    _In_ IN UCHAR   SenseDataSize
    );

BOOLEAN
DsmpShouldRetryTPGRequest(
    _In_ IN PVOID   SenseData,
    _In_ IN UCHAR   SenseDataSize
    );

BOOLEAN
DsmpIsDeviceRemoved(
    _In_ IN PVOID   SenseData,
    _In_ IN UCHAR   SenseDataSize
    );

PDSM_DEVICE_INFO
DsmpGetActivePathToBeUsed(
    _In_ PDSM_GROUP_ENTRY Group,
    _In_ BOOLEAN Symmetric,
    _In_ IN ULONG SpecialHandlingFlag
    );

PDSM_DEVICE_INFO
DsmpGetAnyActivePath(
    _In_ PDSM_GROUP_ENTRY Group,
    _In_ BOOLEAN Exception,
    _In_opt_ PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    );

PDSM_DEVICE_INFO
DsmpFindStandbyPathToActivate(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG SpecialHandlingFlag
    );

PDSM_DEVICE_INFO
DsmpFindStandbyPathToActivateALUA(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PBOOLEAN SendTPG,
    _In_ IN ULONG SpecialHandlingFlag
    );

PDSM_DEVICE_INFO
DsmpFindStandbyPathInAlternateTpgALUA(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetLBForDsmPolicyAdjustment(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONGLONG PreferredPath
    );

NTSTATUS
DsmpSetLBForVidPidPolicyAdjustment(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PWSTR TargetHardwareId,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONGLONG PreferredPath
    );

NTSTATUS
DsmpSetNewDefaultLBPolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_opt_ IN PDSM_DEVICE_INFO NewDeviceInfo,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetLBForPathArrival(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO NewDeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetLBForPathArrivalALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO NewDeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetLBForPathRemoval(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO RemovedDeviceInfo,
    _In_opt_ IN OPTIONAL PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetLBForPathRemovalALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO RemovedDeviceInfo,
    _In_opt_ IN OPTIONAL PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetLBForPathFailing(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDeviceInfo,
    _In_ IN BOOLEAN MarkDevInfoFailed,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetLBForPathFailingALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDeviceInfo,
    _In_ IN BOOLEAN MarkDevInfoFailed,
    _In_ IN ULONG SpecialHandlingFlag
    );

NTSTATUS
DsmpSetPathForIoRetryALUA(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO FailingDeviceInfo,
    _In_ IN BOOLEAN TPGException,
    _In_ IN BOOLEAN DeviceInfoException
    );

PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY
DsmpFindFailPathDevInfoEntry(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO FailingDevInfo
    );

PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY
DsmpBuildFailPathDevInfoEntry(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_DEVICE_INFO FailingDevInfo,
    _In_ IN PDSM_DEVICE_INFO AlternateDevInfo
    );

IO_COMPLETION_ROUTINE DsmpPhase1ProcessPathFailingALUA;

NTSTATUS
DsmpRemoveFailPathDevInfoEntry(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY FailPathDevInfoEntry
    );

IO_COMPLETION_ROUTINE DsmpPhase2ProcessPathFailingALUA;

NTSTATUS
DsmpPersistentReserveOut(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PKEVENT Event
    );

__inline
BOOLEAN
DsmpIsPersistentReservationKeyZeroKey(
    _In_ ULONG KeyLength,
    _In_reads_bytes_(KeyLength) PUCHAR Key
    )
{
    BOOLEAN zeroKey = FALSE;

    NT_ASSERT(KeyLength == 8);

    if ((KeyLength) == 8 &&
        (Key[0] == 0 && Key[1] == 0 && Key[2] == 0 && Key[3] == 0 &&
         Key[4] == 0 && Key[5] == 0 && Key[6] == 0 && Key[7] == 0)) {

        zeroKey = TRUE;
    }

    return zeroKey;
}


NTSTATUS
DsmpPersistentReserveIn(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmIds,
    _In_ IN PIRP Irp,
    _In_ IN PSCSI_REQUEST_BLOCK Srb,
    _In_ IN PKEVENT Event
    );

IO_COMPLETION_ROUTINE DsmpPersistentReserveCompletion;


//
// Function prototypes for functions in utils.c
//

_Success_(return != NULL)
__drv_allocatesMem(Mem)
_When_(((PoolType&0x1))!=0, _IRQL_requires_max_(APC_LEVEL))
_When_(((PoolType&0x1))==0, _IRQL_requires_max_(DISPATCH_LEVEL))
_When_(((PoolType&0x2))!=0,
    __drv_reportError("Must succeed pool allocations are forbidden. "
    "Allocation failures cause a system crash"))
_When_(((PoolType&(0x2|POOL_RAISE_IF_ALLOCATION_FAILURE)))==0,
    _Post_maybenull_ _Must_inspect_result_)
_When_(((PoolType&(0x2|POOL_RAISE_IF_ALLOCATION_FAILURE)))!=0,
   _Post_notnull_)
_When_((PoolType&NonPagedPoolMustSucceed)!=0,
    __drv_reportError("Must succeed pool allocations are forbidden. "
                      "Allocation failures cause a system crash"))
_Post_writable_byte_size_(NumberOfBytes)
PVOID
DsmpAllocatePool(
    _In_ _Strict_type_match_ IN POOL_TYPE PoolType,
    _In_ IN SIZE_T NumberOfBytes,
    _In_ IN ULONG Tag
    );

_Success_(return != NULL)
_Post_maybenull_
_Must_inspect_result_
__drv_allocatesMem(Mem)
_Post_writable_byte_size_(*BytesAllocated)
_When_(((PoolType&0x1))!=0, _IRQL_requires_max_(APC_LEVEL))
_When_(((PoolType&0x1))==0, _IRQL_requires_max_(DISPATCH_LEVEL))
_When_((PoolType&NonPagedPoolMustSucceed)!=0,
    __drv_reportError("Must succeed pool allocations are forbidden. "
                      "Allocation failures cause a system crash"))
PVOID
DsmpAllocateAlignedPool(
    _In_ IN POOL_TYPE PoolType,
    _In_ IN SIZE_T NumberOfBytes,
    _In_ IN ULONG AlignmentMask,
    _In_ IN ULONG Tag,
    _Out_ OUT SIZE_T *BytesAllocated
    );

_IRQL_requires_max_(DISPATCH_LEVEL)
VOID
DsmpFreePool(
    _In_opt_ __drv_freesMem(Mem) IN PVOID Block
    );

NTSTATUS
DsmpGetStatsGatheringChoice(
    _In_ IN PDSM_CONTEXT Context,
    _Out_ OUT PULONG StatsGatherChoice
    );

NTSTATUS
DsmpSetStatsGatheringChoice(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN ULONG StatsGatherChoice
    );


NTSTATUS
DsmpGetDeviceList(
    _In_ IN PDSM_CONTEXT Context
    );

_Success_(return==0)
NTSTATUS
DsmpGetStandardInquiryData(
    _In_ IN PDEVICE_OBJECT DeviceObject,
    _Out_ OUT PINQUIRYDATA InquiryData
    );

BOOLEAN
DsmpCheckScsiCompliance(
    _In_ IN PDEVICE_OBJECT DeviceObject,
    _In_ IN PINQUIRYDATA InquiryData,
    _In_ IN PSTORAGE_DEVICE_DESCRIPTOR Descriptor,
    _In_ IN PSTORAGE_DEVICE_ID_DESCRIPTOR DeviceIdList
    );

BOOLEAN
DsmpDeviceSupported(
    _In_ IN PDSM_CONTEXT Context,
    _In_ IN PCSTR VendorId,
    _In_ IN PCSTR ProductId
    );

BOOLEAN
DsmpFindSupportedDevice(
    _In_ IN PUNICODE_STRING DeviceName,
    _In_ IN PUNICODE_STRING SupportedDevices
    );

_Success_(return!=0)
PVOID
DsmpParseDeviceID (
    _In_ IN PSTORAGE_DEVICE_ID_DESCRIPTOR DeviceID,
    _In_ IN DSM_DEVID_TYPE DeviceIdType,
    _In_opt_ IN PULONG IdNumber,
    _Out_opt_ PSTORAGE_IDENTIFIER_CODE_SET CodeSet,
    _In_ IN BOOLEAN Legacy
    );

PUCHAR
DsmpBinaryToAscii(
    _In_reads_(Length) IN PUCHAR HexBuffer,
    _In_ IN ULONG Length,
    _Inout_ IN OUT PULONG UpdateLength,
    _In_ IN BOOLEAN Legacy
    );

PSTR
DsmpGetSerialNumber(
    _In_ IN PDEVICE_OBJECT DeviceObject
    );


NTSTATUS
DsmpDisableImplicitStateTransition(
    _In_ IN PDEVICE_OBJECT DeviceObject,
    _Out_ OUT PBOOLEAN DisableImplicit
    );

PWSTR
DsmpBuildHardwareId(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    );

PWSTR
DsmpBuildDeviceNameLegacyPage0x80(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo
    );


PWSTR
DsmpBuildDeviceName(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_reads_(SerialNumberLength) IN PSTR SerialNumber,
    _In_ IN SIZE_T SerialNumberLength
    );

NTSTATUS
DsmpApplyDeviceNameCorrection(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_reads_(DeviceNameLegacyLen) PWSTR DeviceNameLegacy,
    _In_ IN SIZE_T DeviceNameLegacyLen,
    _In_reads_(DeviceNameLen) PWSTR DeviceName,
    _In_ IN SIZE_T DeviceNameLen
    );

NTSTATUS
DsmpQueryDeviceLBPolicyFromRegistry(
    _In_ PDSM_DEVICE_INFO DeviceInfo,
    _In_ PWSTR RegistryKeyName,
    _Inout_ PDSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _Inout_ PULONGLONG PreferredPath,
    _Inout_ PUCHAR ExplicitlySet
    );

NTSTATUS
DsmpQueryTargetLBPolicyFromRegistry(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _Out_ OUT PDSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _Out_ OUT PULONGLONG PreferredPath
    );

NTSTATUS
DsmpQueryDsmLBPolicyFromRegistry(
    _Out_ OUT PDSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _Out_ OUT PULONGLONG PreferredPath
    );

NTSTATUS
DsmpSetDsmLBPolicyInRegistry(
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONGLONG PreferredPath
    );

NTSTATUS
DsmpSetVidPidLBPolicyInRegistry(
    _In_ IN PWSTR TargetHardwareId,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _In_ IN ULONGLONG PreferredPath
    );

NTSTATUS
DsmpOpenLoadBalanceSettingsKey(
    _In_ IN ACCESS_MASK AccessMask,
    _Out_ OUT PHANDLE LoadBalanceSettingsKey
    );

NTSTATUS
DsmpOpenTargetsLoadBalanceSettingKey(
    _In_ IN ACCESS_MASK AccessMask,
    _Out_ OUT PHANDLE TargetsLoadBalanceSettingKey
    );

NTSTATUS
DsmpOpenDsmServicesParametersKey(
    _In_ IN ACCESS_MASK AccessMask,
    _Out_ OUT PHANDLE ParametersSettingsKey
    );

IO_COMPLETION_ROUTINE DsmpReportTargetPortGroupsSyncCompletion;

_Success_(return==0)
NTSTATUS
DsmpReportTargetPortGroups(
    _In_ PDEVICE_OBJECT DeviceObject,
    _Outptr_result_buffer_maybenull_(*TargetPortGroupsInfoLength) PUCHAR *TargetPortGroupsInfo,
    _Out_ PULONG TargetPortGroupsInfoLength
    );

NTSTATUS
DsmpReportTargetPortGroupsAsync(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN PIO_COMPLETION_ROUTINE CompletionRoutine,
    _Inout_ __drv_aliasesMem IN PDSM_TPG_COMPLETION_CONTEXT CompletionContext,
    _In_ IN ULONG TargetPortGroupsInfoLength,
    _Inout_ __drv_aliasesMem IN OUT PUCHAR TargetPortGroupsInfo
    );

NTSTATUS
DsmpQueryLBPolicyForDevice(
    _In_ IN PWSTR RegistryKeyName,
    _In_ IN  ULONGLONG PathId,
    _In_ IN DSM_LOAD_BALANCE_TYPE LoadBalanceType,
    _Out_ OUT PULONG PrimaryPath,
    _Out_ OUT PULONG OptimizedPath,
    _Out_ OUT PULONG PathWeight
    );

VOID
DsmpGetDSMPathKeyName(
    _In_ ULONGLONG DSMPathId,
    _Out_writes_(DsmPathKeyNameSize) PWCHAR DsmPathKeyName,
    _In_ ULONG  DsmPathKeyNameSize
    );

UCHAR
DsmpGetAsciiForBinary(
    _In_ UCHAR BinaryChar
    );

NTSTATUS
DsmpGetDeviceIdList (
    _In_ IN PDEVICE_OBJECT DeviceObject,
    _Out_ OUT PSTORAGE_DESCRIPTOR_HEADER *Descriptor
    );

NTSTATUS
DsmpSetTargetPortGroups(
    _In_ IN PDEVICE_OBJECT DeviceObject,
    _In_reads_bytes_(TargetPortGroupsInfoLength) IN PUCHAR TargetPortGroupsInfo,
    _In_ IN ULONG TargetPortGroupsInfoLength
    );

NTSTATUS
DsmpSetTargetPortGroupsAsync(
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN PIO_COMPLETION_ROUTINE CompletionRoutine,
    _In_ __drv_aliasesMem IN PDSM_TPG_COMPLETION_CONTEXT CompletionContext,
    _In_ IN ULONG TargetPortGroupsInfoLength,
    _In_ __drv_aliasesMem IN PUCHAR TargetPortGroupsInfo
    );

PDSM_LOAD_BALANCE_POLICY_SETTINGS
DsmpCopyLoadBalancePolicies(
    _In_ IN PDSM_GROUP_ENTRY GroupEntry,
    _In_ IN ULONG DsmWmiVersion,
    _In_ IN PVOID SupportedLBPolicies
    );

NTSTATUS
DsmpPersistLBSettings(
    _In_ IN PDSM_LOAD_BALANCE_POLICY_SETTINGS LoadBalanceSettings
    );

NTSTATUS
DsmpSetDeviceALUAState(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_ IN DSM_DEVICE_STATE DevState
    );

NTSTATUS
DsmpGetDeviceALUAState(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_DEVICE_INFO DeviceInfo,
    _In_opt_ IN PDSM_DEVICE_STATE DevState
    );

NTSTATUS
DsmpAdjustDeviceStatesALUA(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_opt_ IN PDSM_DEVICE_INFO PreferredActiveDeviceInfo,
    _In_ IN ULONG SpecialHandlingFlag
    );

PDSM_WORKITEM
DsmpAllocateWorkItem(
    _In_ IN PDEVICE_OBJECT DeviceObject,
    _In_ IN PVOID Context
    );

VOID
DsmpFreeWorkItem(
    _In_ IN PDSM_WORKITEM DsmWorkItem
    );

VOID
DsmpFreeZombieGroupList(
    _In_ IN PDSM_FAILOVER_GROUP FailGroup
    );

NTSTATUS
DsmpRegCopyTree(
    _In_ IN HANDLE SourceKey,
    _In_ IN HANDLE DestKey
    );

NTSTATUS
DsmpRegDeleteTree(
    _In_ IN HANDLE KeyRoot
    );

#if defined (_WIN64)
VOID
DsmpPassThroughPathTranslate32To64(
    _In_ IN PMPIO_PASS_THROUGH_PATH32 MpioPassThroughPath32,
    _Inout_ IN OUT PMPIO_PASS_THROUGH_PATH MpioPassThroughPath64
    );

VOID
DsmpPassThroughPathTranslate64To32(
    _In_ IN PMPIO_PASS_THROUGH_PATH MpioPassThroughPath64,
    _Inout_ IN OUT PMPIO_PASS_THROUGH_PATH32 MpioPassThroughPath32
    );
#endif

NTSTATUS
DsmpGetMaxPRRetryTime(
    _In_ IN PDSM_CONTEXT Context,
    _Out_ OUT PULONG RetryTime
    );

NTSTATUS
DsmpQueryCacheInformationFromRegistry(
    _In_ IN PDSM_CONTEXT DsmContext,
    _Out_ OUT PBOOLEAN UseCacheForLeastBlocks,
    _Out_ OUT PULONGLONG CacheSizeForLeastBlocks
    );

BOOLEAN
DsmpConvertSharedSpinLockToExclusive(
    _Inout_ _Requires_lock_held_(*_Curr_) PEX_SPIN_LOCK SpinLock
    );


//
// Function prototypes for functions in wmi.c
//

VOID
DsmpDsmWmiInitialize(
    _In_ IN PDSM_WMILIB_CONTEXT WmiGlobalInfo,
    _In_ IN PUNICODE_STRING RegistryPath
    );

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
    );

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
    );

VOID
DsmpWmiInitialize(
    _In_ IN PDSM_WMILIB_CONTEXT WmiInfo,
    _In_ IN PUNICODE_STRING RegistryPath
    );

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
    _When_(GuidIndex == 0 || GuidIndex == 7, _Pre_notnull_ _Const_)
    _When_(!(GuidIndex == 0 || GuidIndex == 7), _Out_writes_to_(BufferAvail, *DataLength))
          OUT PUCHAR Buffer,
    _Out_ OUT PULONG DataLength,
    ...
    );

NTSTATUS
DsmpQueryLoadBalancePolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds,
    _In_ IN ULONG        DsmWmiVersion,
    _In_ IN ULONG        InBufferSize,
    _In_ IN PULONG       OutBufferSize,
    _Out_writes_bytes_(*OutBufferSize) OUT PVOID Buffer
    );

NTSTATUS
DsmpQuerySupportedLBPolicies(
    _In_ IN   PDSM_CONTEXT DsmContext,
    _In_ IN   PDSM_IDS DsmIds,
    _In_ IN   ULONG BufferAvail,
    _In_ IN   ULONG DsmWmiVersion,
    _Out_ OUT PULONG OutBufferSize,
    _Out_writes_to_(BufferAvail, *OutBufferSize) OUT PUCHAR Buffer
   );

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
    );

NTSTATUS
DsmpClearLoadBalancePolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds
    );

NTSTATUS
DsmpSetLoadBalancePolicy(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds,
    _In_ IN ULONG        DsmWmiVersion,
    _In_ IN ULONG        InBufferSize,
    _In_ IN PULONG       OutBufferSize,
    _In_ IN PVOID        Buffer
    );

NTSTATUS
DsmpValidateSetLBPolicyInput(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS     DsmIds,
    _In_ IN ULONG        DsmWmiVersion,
    _In_ IN PVOID        SetLoadBalancePolicyIN,
    _In_ IN ULONG        InBufferSize
    );

VOID
DsmpSaveDeviceState(
    _In_ IN PVOID SupportedLBPolicies,
    _In_ IN ULONG DsmWmiVersion
    );

VOID
DsmpRestorePreviousDeviceState(
    _In_ IN PVOID SupportedLBPolicies,
    _In_ IN ULONG DsmWmiVersion
    );

VOID
DsmpUpdateDesiredStateAndWeight(
    _In_ IN PDSM_GROUP_ENTRY Group,
    _In_ IN ULONG DsmWmiVersion,
    _In_ IN PVOID SupportedLBPolicies
    );

NTSTATUS
DsmpQueryDevicePerf(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ PDSM_IDS DsmIds,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    );

NTSTATUS
DsmpClearPerfCounters(
    _In_ IN PDSM_CONTEXT DsmContext,
    _In_ IN PDSM_IDS DsmIds
    );

NTSTATUS
DsmpQuerySupportedDevicesList(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    );

NTSTATUS
DsmpQueryTargetsDefaultPolicy(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    );

NTSTATUS
DsmpQueryDsmDefaultPolicy(
    _In_ PDSM_CONTEXT DsmContext,
    _In_ ULONG InBufferSize,
    _Inout_ PULONG OutBufferSize,
    _Out_writes_to_(*OutBufferSize, *OutBufferSize) PUCHAR Buffer
    );


//
// Function prototypes for functions in debug.c
//

VOID
DsmpDebugPrint(
    _In_ ULONG DebugPrintLevel,
    _In_ PCCHAR DebugMessage,
    ...
    );

//
// SRB Helpers not found in srbhelper.h
//
_Success_(return != 0)
__drv_allocatesMem(mem)
_When_(((PoolType&0x1))!=0, _IRQL_requires_max_(APC_LEVEL))
_When_(((PoolType&0x1))==0, _IRQL_requires_max_(DISPATCH_LEVEL))
_When_(((PoolType&0x2))!=0,
    __drv_reportError("Must succeed pool allocations are forbidden. "
    "Allocation failures cause a system crash"))
_When_(((PoolType&(0x2|POOL_RAISE_IF_ALLOCATION_FAILURE)))==0,
    _Post_maybenull_ _Must_inspect_result_)
_When_(((PoolType&(0x2|POOL_RAISE_IF_ALLOCATION_FAILURE)))!=0,
    _Post_notnull_ )
__inline PSTORAGE_REQUEST_BLOCK_HEADER
SrbAllocateCopy(
    _Inout_ PVOID Srb,
    _In_ _Strict_type_match_ POOL_TYPE PoolType,
    _In_ ULONG Tag
    )
/*

Description:
    This function returns an allocated copy of the given SRB. The memory is
    allocated using DsmpAllocatePool().

    ***It is up to the caller to free the memory returned by this function.***

Arguments:
    Srb - A pointer to either a STORAGE_REQUEST_BLOCK or a SCSI_REQUEST_BLOCK.
    PoolType - The pool type to use. See documentation for ExAllocatePoolWithTag().
    Tag - The allocation tag to use. See documentation for ExAllocatePoolWithTag().

Returns:
    NULL, if the copy could not be allocated; or
    A pointer to either a STORAGE_REQUEST_BLOCK or a SCSI_REQUEST_BLOCK that is
    direct copy of the given SRB.

*/
{
    PSTORAGE_REQUEST_BLOCK srb = (PSTORAGE_REQUEST_BLOCK)Srb;
    PSTORAGE_REQUEST_BLOCK_HEADER srbCopy = NULL;
    ULONG allocationSize = 0;

    if (srb->Function == SRB_FUNCTION_STORAGE_REQUEST_BLOCK)
    {
        allocationSize = srb->SrbLength;
        NT_ASSERT(allocationSize >= (sizeof(STORAGE_REQUEST_BLOCK) + sizeof(STOR_ADDR_BTL8)));
    }
    else
    {
        allocationSize = SCSI_REQUEST_BLOCK_SIZE;
        NT_ASSERT(allocationSize >= sizeof(SCSI_REQUEST_BLOCK));
    }

    #pragma warning(suppress: 28160 28118) // False-positive; PoolType is simply passed through
    srbCopy = (PSTORAGE_REQUEST_BLOCK_HEADER)DsmpAllocatePool(PoolType, allocationSize, Tag);
    if (srbCopy != NULL)
    {
        RtlCopyMemory(srbCopy, Srb, allocationSize);
    }

    return srbCopy;
}

__inline
BOOLEAN DsmpIsMPIOPassThroughEx(
    ULONG ControlCode
    )
//
// Returns TRUE if the given passthrough IOCTL's control code indicates it is
// an "extended" passthrough.  Returns FALSE otherwise.
//
{
    if (ControlCode == IOCTL_MPIO_PASS_THROUGH_PATH_EX ||
        ControlCode == IOCTL_MPIO_PASS_THROUGH_PATH_DIRECT_EX) {
        return TRUE;
    } else {
        return FALSE;
    }
}

__inline
UCHAR DsmpNtStatusToSrbStatus(
    _In_ NTSTATUS Status
    )
/*++

Routine Description:

    Translate an NT status value into a SCSI Srb status code.

Arguments:

    Status - Supplies the NT status code to translate.

Return Value:

    SRB status code.

--*/
{
    switch (Status) {

        case STATUS_DEVICE_BUSY:
            return SRB_STATUS_BUSY;

        case STATUS_INVALID_DEVICE_REQUEST:
            return SRB_STATUS_BAD_FUNCTION;
 
        case STATUS_INSUFFICIENT_RESOURCES:
            return SRB_STATUS_INTERNAL_ERROR;

        case STATUS_INVALID_PARAMETER:
            return SRB_STATUS_INVALID_REQUEST;

        default:
            if (NT_SUCCESS (Status)) {
                return SRB_STATUS_SUCCESS;
            } else {
                return SRB_STATUS_ERROR;
            }
    }
}


#endif // _PROTOTYPES_H_

