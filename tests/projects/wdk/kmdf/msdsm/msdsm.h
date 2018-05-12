/*++

Copyright (C) 2004-2010  Microsoft Corporation

Module Name:

    msdsm.h

Abstract:

    Header for the Microsoft Device Specific Module (DSM).

Environment:

    kernel mode only

Notes:

--*/

#ifndef _MSDSM_H_
#define _MSDSM_H_

//
// Maximum number of paths per device supported by the DSM.
// This is a limit currently set by MPIO itself and needs to be updated if MPIO
// supports more paths-per-device in the future.
//
#define DSM_MAX_PATHS 32

//
// MPIO control object's well known symbolic name
//
#define DSM_MPIO_CONTROL_OBJECT_SYMLINK         L"\\DosDevices\\MPIOControl"

//
// Location of System class node in the registry
//
#define DSM_SYSTEM_CLASS_GUID_KEY               L"\\Registry\\Machine\\System\\CurrentControlSet\\Control\\Class\\{4D36E97D-E325-11CE-BFC1-08002BE10318}"

//
// Values used for matching and figuring out the DriverVersion
//
#define DSM_INF_PATH                            L"InfPath"
#define DSM_MSDSM_INF_PATH                      L"msdsm.inf"
#define DSM_DRIVER_VERSION                      L"DriverVersion"
#define DSM_DRIVER_VERSION_FIELD_DELIMITER      L'.'
#define DSM_BUFFER_MAXCOUNT                     64

//
// MSDSM's display name.
//
#define DSM_FRIENDLY_NAME                       L"Microsoft DSM"

//
// Name of the value for the supported devices in the registry, found in the
// DSM's Services' Parameters key
//
#define DSM_SUPPORTED_DEVICELIST_VALUE_NAME     L"DsmSupportedDeviceList"

//
// Value used to determine if per-IO statistics gathering needs to be turned OFF
//
#define DSM_DISABLE_STATISTICS                  L"DsmDisableStatistics"

//
// Names of the values in the registry for whether to use the same path for
// sequential IOs when employing Least Blocks load balance policy, as well
// as its size.
//
#define DSM_USE_CACHE_FOR_LEAST_BLOCKS          L"DsmUseCacheForLeastBlocks"
#define DSM_CACHE_SIZE_FOR_LEAST_BLOCKS         L"DsmCacheSizeForLeastBlocks"

//
// Name of the value in the registry for the maximum request retry time during ALUA
// state transitions. This value is found in the DSM's Services' Parameters key, and
// applies only to Persistent Reservation commands.
//
#define DSM_MAX_STATE_TRANSITION_TIME_VALUE_NAME  L"DsmMaximumStateTransitionTime"


//
// Default max amount of time (in seconds) that a PR failing with retry-able UA will be retried
//
#define DSM_MAX_PR_UNIT_ATTENTION_RETRY_TIME    3

//
// Macro to translate seconds to ticks. Each system tick is 10^(-7) seconds.
//
#define DSM_SECONDS_TO_TICKS(_Seconds)              ((_Seconds) * 10000000)

//
// Size of the buffer allocated to retrieve device serial number.
// This is as defined by SPC-3 spec. The identifier with the biggest size is
// SCSI name type (0x8).
//
#define DSM_SERIAL_NUMBER_BUFFER_SIZE 255

//
// Number of LB Policies that are supported by this driver.
//
#define DSM_NUMBER_OF_LB_POLICIES 6

//
// Size of the buffer passed to read in Persistent Reserve keys.
//
#define DSM_READ_PERSISTENT_KEYS_BUFFER_SIZE  4096

//
// The default threshold for sequential IO for the Least Blocks load balance
// policy is 1MB.
//
#define DSM_LEAST_BLOCKS_DEFAULT_THRESHOLD 0x00100000

//
// Initialization data structure that needs to be filled in for MPIO
//
DSM_INIT_DATA gDsmInitData;

//
// Macro used to round of a number to the nearest 8 byte aligned one.
//
#ifdef AlignOn8Bytes
#undef AlignOn8Bytes
#endif
#define AlignOn8Bytes(x)    (((x) + 7) & ~7)

//
// Macro for determining minimum of two numbers
//
#ifdef MIN
#undef MIN
#endif
#define MIN(a, b)           ((ULONGLONG)(a) < (ULONGLONG)(b) ? (a) : (b))

//
// Macro used to convert a 4 byte array to a ULONG (where byte 0 MSB, byte 3 LSB)
//
#define GetUlongFrom4ByteArray(UCharArray, ULongValue)                                 \
         ((UNALIGNED UCHAR *)&(ULongValue))[3] = ((UNALIGNED UCHAR *)(UCharArray))[0]; \
         ((UNALIGNED UCHAR *)&(ULongValue))[2] = ((UNALIGNED UCHAR *)(UCharArray))[1]; \
         ((UNALIGNED UCHAR *)&(ULongValue))[1] = ((UNALIGNED UCHAR *)(UCharArray))[2]; \
         ((UNALIGNED UCHAR *)&(ULongValue))[0] = ((UNALIGNED UCHAR *)(UCharArray))[3];

//
// Macro used to convert a ULONG into a 4 byte array (as big-endian)
//
#define Get4ByteArrayFromUlong(ULongValue, UCharArray)                                 \
         ((UNALIGNED UCHAR *)(UCharArray))[3] = ((UNALIGNED UCHAR *)&(ULongValue))[0]; \
         ((UNALIGNED UCHAR *)(UCharArray))[2] = ((UNALIGNED UCHAR *)&(ULongValue))[1]; \
         ((UNALIGNED UCHAR *)(UCharArray))[1] = ((UNALIGNED UCHAR *)&(ULongValue))[2]; \
         ((UNALIGNED UCHAR *)(UCharArray))[0] = ((UNALIGNED UCHAR *)&(ULongValue))[3];

//
// Macro to check if passed in opcode is a read, write
//
#define DsmIsReadRequest(_Opcode)       (_Opcode == SCSIOP_READ || _Opcode == SCSIOP_READ16)
#define DsmIsWriteRequest(_Opcode)      (_Opcode == SCSIOP_WRITE || _Opcode == SCSIOP_WRITE16)
#define DsmIsReadWrite(_Opcode)         (_Opcode == SCSIOP_READ || _Opcode == SCSIOP_READ16 || \
                                         _Opcode == SCSIOP_WRITE || _Opcode == SCSIOP_WRITE16)

#define DsmIsReadCapacity( _Opcode )    (_Opcode == SCSIOP_READ_CAPACITY || _Opcode == SCSIOP_READ_CAPACITY16)


//
// Macro to find the number of bytes consumed by the array
//
#define ARRAY_SIZE(x) (sizeof(x) / sizeof(x[0]))


//
// Signature used to identify various structures.
// Used solely for debugging purposes.
//
#define DSM_DEVICE_SIG              0xAAAAAAAA
#define DSM_GROUP_SIG               0x55555555
#define DSM_FOG_SIG                 0x88888888
#define DSM_TARGET_PORT_GROUP_SIG   0x33333333
#define DSM_TARGET_PORT_SIG         0xCCCCCCCC
#define DSM_CONTROLLER_SIG          0xEEEEEEEE

#define WNULL             (L'\0')
#define WNULL_SIZE        (sizeof(WNULL))

#if DBG

//
// NT_ASSERT wrapper.
//
#define DSM_ASSERT(exp)    if (DoAssert) {    \
                               NT_ASSERT(exp);   \
                           }

#else // DBG

#define DSM_ASSERT(exp)

#endif // DBG

#define DSM_PARAMETER_PATH_W                L"MSDSM\\Parameters"

//
// Pool Tags used in memory allocation
//
#define DSM_TAG_GENERIC                     '00ZZ'
#define DSM_TAG_PASS_THRU                   '10ZZ'
#define DSM_TAG_GROUP_ENTRY                 '20ZZ'
#define DSM_TAG_FO_GROUP                    '30ZZ'
#define DSM_TAG_DSM_CONTEXT                 '40ZZ'
#define DSM_TAG_DEV_INFO                    '50ZZ'
#define DSM_TAG_SERIAL_NUM                  '60ZZ'
#define DSM_TAG_CTRL_INFO                   '70ZZ'
#define DSM_TAG_SUPPORTED_DEV               '80ZZ'
#define DSM_TAG_REG_PATH                    '90ZZ'
#define DSM_TAG_FOG_DEV_ENTRY               'A0ZZ'
#define DSM_TAG_DEV_ID                      'B0ZZ'
#define DSM_TAG_DEV_NAME                    'C0ZZ'
#define DSM_TAG_LB_POLICY                   'D0ZZ'
#define DSM_TAG_PR_KEYS                     'E0ZZ'
#define DSM_TAG_RESERVED_DEVICE             'F0ZZ'
#define DSM_TAG_BIN_TO_ASCII                '01ZZ'
#define DSM_TAG_TARGET_PORT_LIST_ENTRY      '11ZZ'
#define DSM_TAG_TARGET_PORT_GROUP_ENTRY     '21ZZ'
#define DSM_TAG_RELATIVE_TARGET_PORT_ID     '31ZZ'
#define DSM_TAG_TARGET_PORT_GROUPS          '41ZZ'
#define DSM_TAG_CONTROLLER_LIST_ENTRY       '51ZZ'
#define DSM_TAG_CONTROLLER_INFO             '61ZZ'
#define DSM_TAG_IO_STATUS_BLOCK             '71ZZ'
#define DSM_TAG_DEVICE_ID_LIST              '81ZZ'
#define DSM_TAG_TP_DEVICE_LIST_ENTRY        '91ZZ'
#define DSM_TAG_RETRY_RESERVE               'A1ZZ'
#define DSM_TAG_WORKITEM                    'B1ZZ'
#define DSM_TAG_SCSI_ADDRESS                'C1ZZ'
#define DSM_TAG_FAIL_DEVINFO_LIST_ENTRY     'D1ZZ'
#define DSM_TAG_TPG_COMPLETION_CONTEXT      'E1ZZ'
#define DSM_TAG_SCSI_REQUEST_BLOCK          'F1ZZ'
#define DSM_TAG_SCSI_SENSE_INFO             '02ZZ'
#define DSM_TAG_SPT_DATA_BUFFER             '12ZZ'
#define DSM_TAG_REG_KEY_RELATED             '22ZZ'
#define DSM_TAG_DEV_HARDWARE_ID             '32ZZ'
#define DSM_TAG_REG_VALUE_RELATED           '42ZZ'
#define DSM_TAG_ZOMBIEGROUP_ENTRY           '52ZZ'
#define DSM_TAG_PERSISTENT_RESERVATION      '62ZZ'

//
// Parameters subkey name under HKLM\System\CCS\Services\MSDSM
//
#define DSM_SERVICE_PARAMETERS              L"Parameters"

//
// Load Balance settings are persisted in the registry under this key
//
#define DSM_LOAD_BALANCE_SETTINGS           L"DsmLoadBalanceSettings"

//
// Load Balance settings on a VID/PID basis are persistented in the registry
// under this key
//
#define DSM_TARGETS_LOAD_BALANCE_SETTING    L"DsmTargetsLoadBalanceSetting"

//
// Values persisted per device:
// 1. Load Balance Policy
// 2. Preferred Path
// 3. Whether LB policy has been explicitly set
//
#define DSM_LOAD_BALANCE_POLICY             L"DsmLoadBalancePolicy"
#define DSM_PREFERRED_PATH                  L"DsmPreferredPath"
#define DSM_POLICY_EXPLICITLY_SET           L"DsmLoadBalancePolicyExplicitlySet"

//
// Prefix for subkey created for each path
//
#define DSM_PATH                            L"DSMPath"

//
// Values persisted per path:
// 1. Whether primary
// 2. Whether optimized
// 3. Path weight.
//
// Primary      Optimized       State
//====================================
// True         True            Active-Optimized
// True         False           Active-Unoptimized
// False        True            StandBy
// False        False           Unavailable
//
#define DSM_PRIMARY_PATH            L"DsmPrimaryPath"
#define DSM_OPTIMIZED_PATH          L"DsmOptimizedPath"
#define DSM_PATH_WEIGHT             L"DsmPathWeight"

//
// Indicates that device doesn't support ALUA.
//
#define DSM_DEVINFO_ALUA_NOT_SUPPORTED  0

//
// Implies that device supports implicit ALUA transistions.
//
#define DSM_DEVINFO_ALUA_IMPLICIT       1

//
// Implies that device supports explicit ALUA state transitions.
//
#define DSM_DEVINFO_ALUA_EXPLICIT       2

//
// Type of device identifier (VPD 0x83)
//
typedef enum _DSM_DEVID_TYPE {
    DSM_DEVID_SERIAL_NUMBER = 1,
    DSM_DEVID_RELATIVE_TARGET_PORT,
    DSM_DEVID_TARGET_PORT_GROUP
} DSM_DEVID_TYPE, *PDSM_DEVID_TYPE;

#define _DSM_TERNARY_BOOLEAN UCHAR
typedef _DSM_TERNARY_BOOLEAN DSM_TERNARY_BOOLEAN, *PDSM_TERNARY_BOOLEAN;
#define DSM_TERNARY_UNKNOWN 0
#define DSM_TERNARY_TRUE 1
#define DSM_TERNARY_FALSE 2

//
// Macro to determine if _Id2 is more preferred than _Id1 to build a device's
// serial number.
//
#define DsmpIsPreferredDeviceId(_Id1, _Id2)     (((_Id2) == StorageIdTypeScsiNameString) || \
                                                 ((_Id2) == StorageIdTypeFCPHName && (_Id1) != StorageIdTypeScsiNameString) || \
                                                 ((_Id2) == StorageIdTypeEUI64 && (_Id1) != StorageIdTypeScsiNameString && (_Id1) != StorageIdTypeFCPHName) || \
                                                 ((_Id2) == StorageIdTypeVendorId && (_Id1) != StorageIdTypeScsiNameString && (_Id1) != StorageIdTypeFCPHName && (_Id1) != StorageIdTypeEUI64) || \
                                                 ((_Id2) == StorageIdTypeVendorSpecific && (_Id1) != StorageIdTypeScsiNameString && (_Id1) != StorageIdTypeFCPHName && (_Id1) != StorageIdTypeEUI64 && (_Id1) != StorageIdTypeVendorId))

//
// Device State
//
typedef enum _DSM_DEVICE_STATE {

    //
    // If ALUA is not supported, this state indicates that the device is active
    // and a request can be sent to the device.
    // If ALUA is supported, then this state indicates optimizied device-path
    // pair for the device.
    //
    DSM_DEV_ACTIVE_OPTIMIZED = 0,

    //
    // If ALUA is not supported, this state is not used.
    // If ALUA is supported, then this state indicates active but unoptimized
    // device-path pairing for the device. Can be used in in case no
    // active/optimized path is available to service the IO.
    //
    DSM_DEV_ACTIVE_UNOPTIMIZED,

    //
    // If ALUA is not supported, this state indicates that the device is in
    // standby state. A request can be sent to the device in this state.
    // If ALUA is supported, then this state indicates standby device-path
    // pairing and only certain requests can be handled in this state.
    //
    DSM_DEV_STANDBY,

    //
    // If ALUA is not supported, this state is not used.
    // If ALUA is supported, then this state indicates that the device-path pairing
    // is not active and incapable of handling any requests.
    //
    DSM_DEV_UNAVAILABLE,

    //
    // If ALUA is not supported, this state is not used.
    // If ALUA is supported, then this state indicates that the device-path pairing
    // (actually its TPG) is in a transitioning state.
    //
    DSM_DEV_TRANSITIONING = 15,

    //
    // Initial state when devInfo is created.
    //
    DSM_DEV_NOT_USED_STATE = 16,

    //
    // Indicates that the state was undetermined (this is applicable only for
    // a deviceInfo's DesiredState or if the device instance's path was not
    // determined).
    //
    DSM_DEV_UNDETERMINED,

    //
    // Indicates that a request sent down previously failed with a fatal error
    //
    DSM_DEV_FAILED,

    //
    // Indicates that InvalidatePath has been called
    //
    DSM_DEV_INVALIDATED,

    //
    // This indicates the device is about to be removed. No new request
    // should be sent to the device.
    //
    DSM_DEV_REMOVE_PENDING,

    //
    // This indicates the device has been removed.
    //
    DSM_DEV_REMOVED

} DSM_DEVICE_STATE, *PDSM_DEVICE_STATE;

//
// Device states supported
//
#define DSM_STATE_ACTIVE_OPTIMIZED_SUPPORTED        0
#define DSM_STATE_STANDBY_SUPPORTED                 1
#define DSM_STATE_ACTIVE_UNOPTIMIZED_SUPPORTED      2
#define DSM_STATE_UNAVAILABLE_SUPPORTED             4


//
// Macro to determine if devInfo is in a failure state.
//
#define DsmpIsDeviceFailedState(_State)             ((_State) > DSM_DEV_NOT_USED_STATE)

//
// Macro to determine if devInfo was initialized.
//
#define DsmpIsDeviceInitialized(_DeviceInfo)        ((_DeviceInfo)->Initialized)

//
// Macro to determine if device is "usable" (ie. IsPathActive was successfully called).
//
#define DsmpIsDeviceUsable(_DeviceInfo)             ((_DeviceInfo)->Usable)

//
// Macro to determine if devInfo was used to send down registration.
// It the devInfo's group is not reserved, then the devInfo doesn't need to have
// had a register go down it.
// It the group is reserved, then the devInfo MUST have had a register go down it
// for it to be used.
//
#define DsmpIsDeviceUsablePR(_DeviceInfo)           (!(_DeviceInfo)->Group->PRKeyValid || (_DeviceInfo)->PRKeyRegistered)


//
// Macro to determine if _State2 is a more preferred state than _State1.
//
#define DsmpIsBetterDeviceState(_State1, _State2)   (((_State1) == DSM_DEV_STANDBY && (_State2) == DSM_DEV_ACTIVE_UNOPTIMIZED) || \
                                                     ((_State1) == DSM_DEV_UNAVAILABLE && \
                                                      ((_State2) == DSM_DEV_ACTIVE_UNOPTIMIZED || (_State2) == DSM_DEV_STANDBY)) || \
                                                     ((_State1) == DSM_DEV_TRANSITIONING && \
                                                      ((_State2) == DSM_DEV_ACTIVE_UNOPTIMIZED || (_State2) == DSM_DEV_STANDBY) || (_State2) == DSM_DEV_UNAVAILABLE))

//
// Macro to determine if passed in _State is active.
//
#define DsmpIsDeviceStateActive(_State)             ((_State) == DSM_DEV_ACTIVE_OPTIMIZED || (_State) == DSM_DEV_ACTIVE_UNOPTIMIZED)

//
// Macro to determine if symmetric access to the storage
//
#define DsmpIsSymmetricAccess(_DeviceInfo)          ((_DeviceInfo)->ALUASupport == DSM_DEVINFO_ALUA_NOT_SUPPORTED || \
                                                     ((_DeviceInfo)->ALUASupport == DSM_DEVINFO_ALUA_IMPLICIT && \
                                                      (_DeviceInfo)->Group->Symmetric))

//
// Multi-path Group State
//
typedef enum _DSM_GROUP_STATE {

    //
    // This indicates that the device is in working state.
    //
    DSM_GP_NORMAL = 1,

    //
    // This indicates that there is a pending reservation failover
    //
    DSM_GP_PENDING,

    //
    // This indicates that the device has lost all its paths
    //
    DSM_GP_FAILED

} DSM_GROUP_STATE, *PDSM_GROUP_STATE;

//
// Fail-Over Group State
//
typedef enum _DSM_FAILOVER_GROUP_STATE {

    //
    // This indicates that the path is in working state.
    //
    DSM_FG_NORMAL = 1,

    //
    // This indicates the path which had failed earlier
    // is back to working state now.
    //
    DSM_FG_FAILBACK,

    //
    // This indicates the path is about to be removed
    //
    DSM_FG_PENDING_REMOVE,

    //
    // This indicates the path has failed.
    //
    DSM_FG_FAILED

} DSM_FAILOVER_GROUP_STATE, *PDSM_FAILOVER_GROUP_STATE;

#define DsmpIsPathFailedState(_State)   ((_State) >= DSM_FG_PENDING_REMOVE)

//
// DSM Context is the global driver context that gets passed to each of the DSM
// entry points.
//
// The DSM Context will maintain a list of all DeviceInfos (device-path pairing).
// It will maintain a list of Group entries. Each entry in the Group list will
//         represent a LUN's different instances down different paths (i.e. DeviceInfos).
//         Each entry in the Group will maintain a list of target port groups.
//         Each entry in the target port group list will maintain a list of target
//         ports that make up the target port group. Every deviceInfo that isn't
//         in a failure state will be in the same state as the Asymmetric Access
//         State of the target port group.
// There will be a list of Fail Over Group entries, where each entry represents
//         the list of devices that fail over as a group (i.e. devices on the same path).
// There will also be a list of controller entries, representing the controllers
//         on all storages connected to the system.
//
typedef struct _DSM_CONTEXT {

    //
    // Used to synchronize access to the SupportedDevices list.
    //
    KSPIN_LOCK SupportedDevicesListLock;

    //
    // List of supported devices - added into the INF.
    //
    UNICODE_STRING SupportedDevices;

    //
    // Used to synchronize access to the elements in this structure.
    //
    EX_SPIN_LOCK DsmContextLock;

    //
    // Flag cached that indicates if statistics don't need to be gathered
    //
    BOOLEAN DisableStatsGathering;

    UCHAR Reserved[3];

    //
    // Number of devices currently found.
    //
    ULONG NumberDevices;

    //
    // List of devices.
    //
    LIST_ENTRY DeviceList;

    //
    // Number of multi-path groups.
    //
    ULONG NumberGroups;

    //
    // List of multi-path groups.
    //
    LIST_ENTRY GroupList;

    //
    // Number of fail-over groups.
    //
    ULONG NumberFOGroups;

    //
    // List of fail-over groups.
    //
    LIST_ENTRY FailGroupList;

    //
    // Number of controllers.
    //
    ULONG NumberControllers;

    //
    // List of controllers
    //
    LIST_ENTRY ControllerList;

    //
    // Number of stale fail-over groups
    //
    ULONG NumberStaleFOGroups;

    //
    // List of stale fail-over groups maintained for paths for which all devices
    // have gotten removed but for which there is still outstanding IO-statistics
    //
    LIST_ENTRY StaleFailGroupList;

    //
    // Context value passed to the DSM from MPIO.
    //
    PVOID MPIOContext;


    //
    // Look-aside list of completion routine context structures.
    //
    NPAGED_LOOKASIDE_LIST CompletionContextList;

} DSM_CONTEXT, *PDSM_CONTEXT;

//
// Statistics structure. Used by the device and path routines.
//
typedef struct _DSM_STATS {

    ULONG      NumberReads;
    ULONG      NumberWrites;
    ULONGLONG  BytesRead;
    ULONGLONG  BytesWritten;

} DSM_STATS, *PDSM_STATS;


//
// Information about each device that is supported by the DSM.
//
typedef struct _DSM_DEVICE_INFO {

    //
    // To link to the next device info structure in the list
    //
    LIST_ENTRY ListEntry;

    //
    // The device SIG. Used for debug.
    //
    ULONG DeviceSig;

    //
    // Back-pointer to the DSM_CONTEXT.
    //
    PVOID DsmContext;

    //
    // The underlying port driver PDO.
    //
    PDEVICE_OBJECT PortPdo;

    //
    // The port FDO to which PortPdo is attached.
    //
    PDEVICE_OBJECT PortFdo;

    //
    // The DeviceObject to which I/Os generated by the DSM should
    // be sent. This is given to us by MPIO.
    //
    PDEVICE_OBJECT TargetObject;

    //
    // The multi-path group to which this device belongs.
    //
    struct _DSM_GROUP_ENTRY *Group;

    //
    // The fail-over group to which this device belongs.
    //
    struct _DSM_FAILOVER_GROUP *FailGroup;

    //
    // The controller through which this device showed up.
    //
    struct _DSM_CONTROLLER_LIST_ENTRY *Controller;

    //
    // The Target Port Group that this device belongs to.
    //
    struct _DSM_TARGET_PORT_GROUP_ENTRY *TargetPortGroup;

    //
    // The Target Port that this device was exposed via.
    //
    struct _DSM_TARGET_PORT_LIST_ENTRY *TargetPort;

    //
    // The current state of this device: ACTIVE_O, ACTIVE_U, STANDBY, UNAVAILABLE, etc.
    //
    DSM_DEVICE_STATE State;

    //
    // Previous state of this device. Updated whenever this deviceInfo makes a
    // state transition.
    //
    DSM_DEVICE_STATE PreviousState;

    //
    // The desired state of this device: based on PrimaryPath and OptimizedPath
    // specified in the registry.
    //
    DSM_DEVICE_STATE DesiredState;

    //
    // The ALUA state of the TPG immediately after a ReportTPG is issued.
    //
    DSM_DEVICE_STATE ALUAState;

    //
    // Holds state information temporarily while applying LB policy. Used in case
    // changes need to be reverted in case of failure to apply the policy.
    //
    DSM_DEVICE_STATE TempPreviousStateForLB;

    //
    // This is to save off the last known non-failed state.
    // In case of an error down this deviceInfo, it is marked to be in Failed state.
    // However, if no remove comes down for this device and a PathVerify down this
    // deviceInfo succeeds, we need to put the deviceInfo back into a usable state.
    //
    DSM_DEVICE_STATE LastKnownGoodState;

    //
    // This counter indicates that this deviceInfo is being used and a remove
    // must thus wait until the counter falls to 0.
    //
    LONG BlockRemove;


    //
    // This indicates whether this device has handled a register/register_ignore_existing request,
    // irrespective of the actual status of the operation.
    //
    BOOLEAN RegisterServiced;

    //
    // This flag is set when a register/register_ignore_existing succeeds down this device-path pair.
    //
    BOOLEAN PRKeyRegistered;

    //
    // Indicates whether the serial number was embedded in the device
    // descriptor, or it was allocated.
    //
    BOOLEAN SerialNumberAllocated;

    //
    // Flag to indicate that SetDeviceInfo has been called (and succeeded) on this device
    //
    BOOLEAN Initialized;

    //
    // Flag to indicate that IsPathActive has been called (and succeeded) on this device.
    //
    BOOLEAN Usable;

    //
    // Flag to indicate if IALUAE was disabled (via mode select)
    //
    BOOLEAN ImplicitDisabled;

    //
    // Flag to indicate that RTPG has already been sent down in Inquire, so
    // PathVerify can ignore sending down one more if it is called during
    // device initialization.
    //
    BOOLEAN IgnorePathVerify;

    //
    // Bit map indicating whether (and what kind) of ALUA support.
    //
    UCHAR ALUASupport;

    //
    // Weight assigned to this path by management application. This is used
    // when doing Load Balancing based on weighted paths.
    //
    ULONG PathWeight;

    //
    // Number of requests outstanding on this device.
    //
    LONG NumberOfRequestsInProgress;

    //
    // I/O, Fail-Over statistics.
    //
    DSM_STATS DeviceStats;

    //
    // The device's serial number.
    //
    PSTR SerialNumber;

    //
    // The scsi address of the port pdo.
    //
    PSCSI_ADDRESS ScsiAddress;


    //
    // Kernel structure that describes this device. Passed in to Inquire.
    //
    // NOTE: Descriptor should be the LAST field in this structure
    //
    STORAGE_DEVICE_DESCRIPTOR Descriptor;
    
} DSM_DEVICE_INFO, *PDSM_DEVICE_INFO;

typedef enum _DSM_DEFAULT_LB_POLICY_TYPE {
    DSM_DEFAULT_LB_POLICY_ALUA_CAPABILITY = 0,  // DSM assigned based on LUN access capability
    DSM_DEFAULT_LB_POLICY_DSM_WIDE,             // Admin has set a DSM-wide default policy
    DSM_DEFAULT_LB_POLICY_VID_PID,              // Admin has set a default policy for LUN's VID/PID
    DSM_DEFAULT_LB_POLICY_LUN_EXPLICIT          // Admin has explicitly set the policy on the LUN
} DSM_DEFAULT_LB_POLICY_TYPE, *PDSM_DEFAULT_LB_POLICY_TYPE;

typedef ULONG   DSM_LOAD_BALANCE_TYPE, *PDSM_LOAD_BALANCE_TYPE;


//
// Information about multi-path groups: The same device found via multiple paths
// are put under one group. Each group will have it's own Load Balance policy
// settings. In other words, Load Balance policy settings are on per-device basis.
//
typedef struct _DSM_GROUP_ENTRY {

    //
    // To link to the next entry in the multi-path group.
    //
    LIST_ENTRY ListEntry;

    //
    // Group signature. Used for debug.
    //
    ULONG GroupSig;

    //
    // Ordinal of creation. Never decremented.
    //
    ULONG GroupNumber;

    //
    // State of the group.
    //
    DSM_GROUP_STATE State;

    //
    // Number of devices in the multi-path group.
    //
    ULONG NumberDevices;

    //
    // Array of devices belonging to this group.
    //
    PDSM_DEVICE_INFO DeviceList[DSM_MAX_PATHS];

    //
    // Max time to retry failed PR requests
    //
    ULONG MaxPRRetryTimeDuringStateTransition;

    //
    // Number of target port groups that this device is accessible via.
    //
    ULONG NumberTargetPortGroups;

    //
    // Array of the target port groups that this LUN belongs in.
    //
    struct _DSM_TARGET_PORT_GROUP_ENTRY *TargetPortGroupList[DSM_MAX_PATHS];

    //
    // Key used in Persistent Reserve\Release. This key is provided to the DSM
    // by Cluster service. If cluster service has provided the key PRKeyValid
    // is set to TRUE. PRKeyValid is set to FALSE otherwise.
    // PRServiceAction, PRType and PRScope are the service action, type and
    // scope associated with the PR registration.
    //
    UCHAR PersistentReservationRegisteredKey[8];
    UCHAR PRServiceAction;
    UCHAR PRType;
    UCHAR PRScope;
    UCHAR PRKeyValid;


    //
    // Flag used to denote that LU access is symmetric down all paths
    //
    BOOLEAN Symmetric;

    //
    // Flag to indicate whether or not to use same path for sequential IO
    // when employing Least Blocks load balance policy.
    //
    BOOLEAN UseCacheForLeastBlocks;    

    //
    // Flag used to indicate if a throttle request succeeded.
    //
    ULONG Throttled;

    //
    // Counter to track the number of RTPG in flight.
    //
    ULONG InFlightRTPG;

    //
    // A bitmask of which devices are currently reserved.
    //
    ULONG ReservationList;

    //
    // Which type of Load Balancing is being performed.
    //
    DSM_LOAD_BALANCE_TYPE LoadBalanceType;

    //
    // Indicates how the Load Balancing policy was selected.
    //
    DSM_DEFAULT_LB_POLICY_TYPE LBPolicySelection;

    //
    // The path to use when possible - if in F.O. Only, if failover had taken
    // place and this path comes back online, failback to this path will take
    // place.
    //
    ULONGLONG PreferredPath;

    //
    // The path to choose when Round Robin Load Balance policy is in use
    //
    PVOID PathToBeUsed;

    //
    // Size of cache set by Admin. Used in case of handling sequential
    // IO in Least Blocks policy.
    //
    ULONGLONG CacheSizeForLeastBlocks;

    //
    // The HardwareId (VID/PID) of the LUN
    //
    PWSTR HardwareId;

    //
    // The registry key under which Load Balance Policy settings
    // are stored in the registry for this Device Group.
    //
    PWSTR RegistryKeyName;

    //
    // Number of failing deviceInfos
    //
    ULONG NumberFailingDevInfos;

    //
    // To link the list of failed A/O devInfos and the corresponding non-A/O
    // devInfos that are temporarily being used to service IO until STPG can
    // properly update the device states. This is applicable only for ALUA
    // devices.
    //
    LIST_ENTRY FailingDevInfoList;

    //
    // General Purpose Event.
    //
    KEVENT Event;

} DSM_GROUP_ENTRY, *PDSM_GROUP_ENTRY;

//
// The collection of devices on one path. These fail-over as a unit.
// A path is considered an I_T nexus, i.e. Initiator port to Target (controller) port.
//
typedef struct _DSM_FAILOVER_GROUP {

    //
    // To link to the next entry in the failover group
    //
    LIST_ENTRY ListEntry;

    //
    // Signature. Used for debug.
    //
    ULONG FailOverSig;

    //
    // State of the Path.
    //
    DSM_FAILOVER_GROUP_STATE State;

    //
    // The pathId corresponding to this FOG. It may or may not be
    // the same as what MPIO gave us as the default value.
    //
    PVOID PathId;

    //
    // The default pathId (port FDO).
    //
    PDEVICE_OBJECT MPIOPath;

    //
    // Last LBA
    //
    ULONGLONG LastLba;

    //
    // Cumulative outstanding IO (in terms of size)
    //
    ULONGLONG OutstandingBytesOfIO;

    //
    // Count of inflight IOs. This will be used in LQD load balance policy.
    //
    volatile LONG NumberOfRequestsInFlight;

    //
    // Number of devices in this FOG.
    //
    ULONG Count;

    //
    // List of devices that will over together.
    //
    LIST_ENTRY FOG_DeviceList;

    //
    // List of zombie groups (in case a device is removed before the failover
    // processing begins).
    //
    LIST_ENTRY ZombieGroupList;

} DSM_FAILOVER_GROUP, *PDSM_FAILOVER_GROUP;


//
// Information about a target port group entry for a given LUN.
// Note: This is not a global list of all TPGs that are built. It is local to a Group entry.
//
typedef struct _DSM_TARGET_PORT_GROUP_ENTRY {

    //
    // Signature. Used for debug.
    //
    ULONG TargetPortGroupSig;

    //
    // The asymmetric access state for this target port group:
    // ACTIVE_O, ACTIVE_U, STANDBY or UNAVAILABLE
    //
    DSM_DEVICE_STATE AsymmetricAccessState;

    //
    // Flag to indicate if this is the preferred target port group.
    //
    BOOLEAN Preferred;

    //
    // Supported access states
    //
    BOOLEAN ActiveOptimizedSupported;
    BOOLEAN ActiveUnoptimizedSupported;
    BOOLEAN StandBySupported;
    BOOLEAN UnavailableSupported;

    //
    // Indicates if the device reports asymmetric state as being under transition.
    //
    BOOLEAN TransitioningSupported;

    //
    // Flag to indicate if this has been returned in any subsequent RTPG after
    // it is initially built. (If this flag is not set after parsing the RTPG
    // information, it indicates that this TPG entry is stale and should be
    // deleted).
    //
    BOOLEAN Traversed;

    UCHAR Reserved;

    //
    // The target group identifier
    //
    USHORT Identifier;

    //
    // Status code
    //
    UCHAR StatusCode;

    //
    // Vendor unique
    //
    UCHAR VendorUnique;

    //
    // Backpointer to owning group
    //
    PDSM_GROUP_ENTRY Group;

    //
    // Number of target ports that make up this group
    //
    ULONG NumberTargetPorts;

    //
    // Linked list of target ports that make up this target port group.
    //
    LIST_ENTRY TargetPortList;

} DSM_TARGET_PORT_GROUP_ENTRY, *PDSM_TARGET_PORT_GROUP_ENTRY;


//
// Information about each target port list entry for a given target port group.
// Note: this is not a global list of all TPs. It is local to a given TPG entry.
//
typedef struct _DSM_TARGET_PORT_LIST_ENTRY {

    //
    // Link
    //
    LIST_ENTRY ListEntry;

    //
    // Signature. Used for debug.
    //
    ULONG TargetPortSig;

    //
    // Relative target port identifier
    //
    ULONG Identifier;

    //
    // Backpointer to owning target port group
    //
    PDSM_TARGET_PORT_GROUP_ENTRY TargetPortGroup;

    //
    // Number of device instances exposed via this target port
    //
    ULONG Count;

    //
    // List of device instances exposed via this target port
    //
    LIST_ENTRY TP_DeviceList;

} DSM_TARGET_PORT_LIST_ENTRY, *PDSM_TARGET_PORT_LIST_ENTRY;

//
// Information about each controller entry
//
typedef struct _DSM_CONTROLLER_LIST_ENTRY {

    //
    // To link to the next contoller entry.
    //
    LIST_ENTRY ListEntry;

    //
    // It's signature. Used for debug.
    //
    ULONG ControllerSig;

    //
    // Device object (this controller's PDO).
    //
    PDEVICE_OBJECT DeviceObject;

    //
    // Port FDO through which this controller object was exposed.
    //
    PDEVICE_OBJECT PortObject;

    //
    // Identifier.
    //
    _Field_size_(IdLength) PUCHAR Identifier;

    //
    // Identifier length.
    //
    ULONG IdLength;

    //
    // Identifier code set.
    //
    STORAGE_IDENTIFIER_CODE_SET IdCodeSet;

    //
    // Controller's SCSI address.
    //
    PSCSI_ADDRESS ScsiAddress;

    //
    // Number of references to this entry.
    //
    UCHAR RefCount;

    //
    // Flag to indicate whether this is a fake entry built for storage that do
    // NOT have controllers
    //
    BOOLEAN IsFakeController;

    UCHAR Reserved[2];

} DSM_CONTROLLER_LIST_ENTRY, *PDSM_CONTROLLER_LIST_ENTRY;

//
// Generic linked list of devices
//
typedef struct _DSM_DEVICELIST_ENTRY {

    //
    // To link to the next device info structure in the list
    //
    LIST_ENTRY ListEntry;

    //
    // Representation of device-path pair
    //
    PDSM_DEVICE_INFO DeviceInfo;

} DSM_DEVICELIST_ENTRY, *PDSM_DEVICELIST_ENTRY;

//
// Zombie Group List Entry
//
typedef struct _DSM_ZOMBIEGROUP_ENTRY {

    //
    // To link to the next zombie group structure in the list
    //
    LIST_ENTRY ListEntry;

    //
    // Pointer to actual group entry
    //
    PDSM_GROUP_ENTRY Group;

    //
    // Flag to indicate that the failover thread has processed this entry.
    //
    BOOLEAN Processed;

} DSM_ZOMBIEGROUP_ENTRY, *PDSM_ZOMBIEGROUP_ENTRY;

//
// Linked list of devices that will failover as a group
//
typedef DSM_DEVICELIST_ENTRY DSM_FOG_DEVICELIST_ENTRY, *PDSM_FOG_DEVICELIST_ENTRY;

//
// Linked list of the same device being exposed off of a particular target port
// (possibly because the controller is connected to multiple HBAs).
//
typedef DSM_DEVICELIST_ENTRY DSM_TARGET_PORT_DEVICELIST_ENTRY, *PDSM_TARGET_PORT_DEVICELIST_ENTRY;

//
// Information about each failing devInfo and its corresponding devInfo
// being used temporarily to service requests until STPG can update new
// device states.
//
typedef struct _DSM_FAIL_PATH_PROCESSING_LIST_ENTRY {

    //
    // To link to the next device info structure in the list
    //
    LIST_ENTRY ListEntry;

    //
    // Representation of the failing device-path pair
    //
    PDSM_DEVICE_INFO FailingDeviceInfo;

    //
    // Representation of the new candidate device-path pair that will take over
    // processing of requests
    //
    PDSM_DEVICE_INFO TempDeviceInfo;

} DSM_FAIL_PATH_PROCESSING_LIST_ENTRY, *PDSM_FAIL_PATH_PROCESSING_LIST_ENTRY;

//
// Completion context structure.
//
typedef struct _DSM_COMPLETION_CONTEXT {

    //
    // The device that handled the request.
    //
    PDSM_DEVICE_INFO DeviceInfo;

    //
    // The global context.
    //
    PDSM_CONTEXT DsmContext;

    //
    // These are used to store control code, pointer to KEVENT, etc.
    //
    PVOID RequestUnique1;

    ULONG_PTR RequestUnique2;

#if DBG
    //
    // Request time-stamp.
    //
    LARGE_INTEGER TickCount;
#endif

} DSM_COMPLETION_CONTEXT, *PDSM_COMPLETION_CONTEXT;

//
// Completion context structure for report/set target port groups.
//
typedef struct _DSM_TPG_COMPLETION_CONTEXT {

    PDSM_COMPLETION_CONTEXT CompletionContext;

    PSCSI_REQUEST_BLOCK Srb;

    PVOID SenseInfoBuffer;

    ULONG NumberRetries;

    UCHAR SenseInfoBufferLength;

} DSM_TPG_COMPLETION_CONTEXT, *PDSM_TPG_COMPLETION_CONTEXT;

//
// Version number used to determine whice version of MPIO_DSM_Path to use.
//
#define DSM_WMI_VERSION_1   1
#define DSM_WMI_VERSION_2   2

//
// Version of MPIO_DSM_Path that is currently supported by this DSM.
//
#define DSM_WMI_VERSION   DSM_WMI_VERSION_2

//
// This struct is used to save Load Balance Policy Settings in the registry
//
typedef struct _DSM_LOAD_BALANCE_POLICY_SETTINGS {

    WCHAR RegistryKeyName[256];
    ULONG LoadBalancePolicy;
    ULONG PathCount;
    MPIO_DSM_Path_V2 DsmPath[1];

} DSM_LOAD_BALANCE_POLICY_SETTINGS, *PDSM_LOAD_BALANCE_POLICY_SETTINGS;

//
// This structure is used to pass in information used by the workitem
// to failover reservations down another path.
//
typedef struct _DSM_RETRY_RESERVE {

    PDSM_COMPLETION_CONTEXT CompletionContext;

    PIRP Irp;

    PKEVENT Event;

} DSM_RETRY_RESERVE, *PDSM_RETRY_RESERVE;

//
// This structure defines the workitem that will be used to handle reservation
// failover.
//
typedef struct _DSM_WORKITEM {

    //
    // Work item that should be freed by the worker routine
    //
    PIO_WORKITEM WorkItem;

    //
    // Context to be passed to worker routine
    //
    PVOID Context;

} DSM_WORKITEM, *PDSM_WORKITEM;

#endif // _MSDSM_H


