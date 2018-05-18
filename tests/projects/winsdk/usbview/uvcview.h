/*++

Copyright (c) 1997-2008 Microsoft Corporation

Module Name:

    UVCVIEW.H

Abstract:

    This is the header file for UVCVIEW

Environment:

    user mode

Revision History:

    04-25-97 : created
    04/13/2005 : major bug fixing

--*/

/*****************************************************************************
 I N C L U D E S
*****************************************************************************/
#include <windows.h>
#include <windowsx.h>
#include <initguid.h>
#include <devioctl.h>
#include <dbt.h>
#include <stdio.h>
#include <commctrl.h>
#include <usbioctl.h>
#include <usbiodef.h>
#include <intsafe.h>
#include <strsafe.h>
#include <specstrings.h>
#include <usb.h>
#include <usbuser.h>
#include <basetyps.h>
#include <wtypes.h>
#include <objbase.h>
#include <io.h>
#include <conio.h>
#include <shellapi.h>
#include <cfgmgr32.h>
#include <shlwapi.h>
#include <setupapi.h>
#include <winioctl.h>
#include <devpkey.h>
#include <math.h>

// This is mostly a private USB Audio descriptor header
#include "usbdesc.h"

// This is the inbox USBVideo driver descriptor header (copied locally)
#include "uvcdesc.h"

/*****************************************************************************
 P R A G M A S
*****************************************************************************/

#pragma once

/*****************************************************************************
 D E F I N E S
*****************************************************************************/

// define H264_SUPPORT to add H.264 support to uvcview.exe
#define H264_SUPPORT

#define TEXT_ITEM_LENGTH 64

#ifdef  DEBUG
#undef  DBG
#define DBG 1
#endif

#if DBG
#define OOPS() Oops(__FILE__, __LINE__)
#else
#define  OOPS()
#endif

#if DBG

#define ALLOC(dwBytes) MyAlloc(__FILE__, __LINE__, (dwBytes))

#define REALLOC(hMem, dwBytes) MyReAlloc((hMem), (dwBytes))

#define FREE(hMem)  MyFree((hMem))

#define CHECKFORLEAKS() MyCheckForLeaks()

#else

#define ALLOC(dwBytes) GlobalAlloc(GPTR,(dwBytes))

#define REALLOC(hMem, dwBytes) GlobalReAlloc((hMem), (dwBytes), (GMEM_MOVEABLE|GMEM_ZEROINIT))

#define FREE(hMem)  GlobalFree((hMem))

#define CHECKFORLEAKS()

#endif

#define DEVICE_CONFIGURATION_TEXT_LENGTH 10240

#define STR_INVALID_POWER_STATE    "(invalid state) "
#define STR_UNKNOWN_CONTROLLER_FLAVOR "Unknown"

FORCEINLINE
VOID
InitializeListHead(
    _Out_ PLIST_ENTRY ListHead
    )
{
    ListHead->Flink = ListHead->Blink = ListHead;
}

//
//  BOOLEAN
//  IsListEmpty(
//      PLIST_ENTRY ListHead
//      );
//

#define IsListEmpty(ListHead) \
    ((ListHead)->Flink == (ListHead))

//
//  PLIST_ENTRY
//  RemoveHeadList(
//      PLIST_ENTRY ListHead
//      );
//

#define RemoveHeadList(ListHead) \
    (ListHead)->Flink;\
    {RemoveEntryList((ListHead)->Flink)}

//
//  VOID
//  RemoveEntryList(
//      PLIST_ENTRY Entry
//      );
//

#define RemoveEntryList(Entry) {\
    PLIST_ENTRY _EX_Blink;\
    PLIST_ENTRY _EX_Flink;\
    _EX_Flink = (Entry)->Flink;\
    _EX_Blink = (Entry)->Blink;\
    _EX_Blink->Flink = _EX_Flink;\
    _EX_Flink->Blink = _EX_Blink;\
    }

//
//  VOID
//  InsertTailList(
//      PLIST_ENTRY ListHead,
//      PLIST_ENTRY Entry
//      );
//

#define InsertTailList(ListHead,Entry) {\
    PLIST_ENTRY _EX_Blink;\
    PLIST_ENTRY _EX_ListHead;\
    _EX_ListHead = (ListHead);\
    _EX_Blink = _EX_ListHead->Blink;\
    (Entry)->Flink = _EX_ListHead;\
    (Entry)->Blink = _EX_Blink;\
    _EX_Blink->Flink = (Entry);\
    _EX_ListHead->Blink = (Entry);\
    }

// global version for USB Video Class spec version (pre-release)
#define BCDVDC     0x0083

// A.2  Video Interface Subclass Codes
#define SC_VIDEO_INTERFACE_COLLECTION  0x03

// A.3  Video Interface Protocol Codes
#define PC_PROTOCOL_UNDEFINED     0x00

// USB Video Class spec version
#define NOT_UVC 0x0
#define UVC10   0x100
#define UVC11   0x110

#ifdef H264_SUPPORT
#define UVC15   0x150
#endif

#define OUTPUT_MESSAGE_MAX_LENGTH    1024
#define MAX_DEVICE_PROP 200
#define MAX_DRIVER_KEY_NAME 256

/*****************************************************************************
 T Y P E D E F S
*****************************************************************************/

typedef enum _TREEICON
{
    ComputerIcon,
    HubIcon,
    NoDeviceIcon,
    GoodDeviceIcon,
    BadDeviceIcon,
    GoodSsDeviceIcon,
    NoSsDeviceIcon
} TREEICON;

// Callback function for walking TreeView items
//
typedef VOID
(*LPFNTREECALLBACK)(
    HWND        hTreeWnd,
    HTREEITEM   hTreeItem,
    PVOID       pContext
);


// Callback notification function called at end of every tree depth
typedef VOID
(*LPFNTREENOTIFYCALLBACK)(PVOID pContext);

//
// Structure used to build a linked list of String Descriptors
// retrieved from a device.
//

typedef struct _STRING_DESCRIPTOR_NODE
{
    struct _STRING_DESCRIPTOR_NODE *Next;
    UCHAR                           DescriptorIndex;
    USHORT                          LanguageID;
    USB_STRING_DESCRIPTOR           StringDescriptor[1];
} STRING_DESCRIPTOR_NODE, *PSTRING_DESCRIPTOR_NODE;

//
// A collection of device properties. The device can be hub, host controller or usb device
//
typedef struct _USB_DEVICE_PNP_STRINGS
{
    PCHAR DeviceId;
    PCHAR DeviceDesc;
    PCHAR HwId;
    PCHAR Service;
    PCHAR DeviceClass;
    PCHAR PowerState;
} USB_DEVICE_PNP_STRINGS, *PUSB_DEVICE_PNP_STRINGS;

typedef struct _DEVICE_INFO_NODE {
    HDEVINFO                         DeviceInfo;
    LIST_ENTRY                       ListEntry;
    SP_DEVINFO_DATA                  DeviceInfoData;
    SP_DEVICE_INTERFACE_DATA         DeviceInterfaceData;
    PSP_DEVICE_INTERFACE_DETAIL_DATA DeviceDetailData;
    PSTR                             DeviceDescName;
    ULONG                            DeviceDescNameLength;
    PSTR                             DeviceDriverName;
    ULONG                            DeviceDriverNameLength;
    DEVICE_POWER_STATE               LatestDevicePowerState;
} DEVICE_INFO_NODE, *PDEVICE_INFO_NODE;

//
// Structures assocated with TreeView items through the lParam.  When an item
// is selected, the lParam is retrieved and the structure it which it points
// is used to display information in the edit control.
//

typedef enum _USBDEVICEINFOTYPE
{
    HostControllerInfo,
    RootHubInfo,
    ExternalHubInfo,
    DeviceInfo
} USBDEVICEINFOTYPE, *PUSBDEVICEINFOTYPE;

typedef struct _USBHOSTCONTROLLERINFO
{
    USBDEVICEINFOTYPE                   DeviceInfoType;
    LIST_ENTRY                          ListEntry;
    PCHAR                               DriverKey;
    ULONG                               VendorID;
    ULONG                               DeviceID;
    ULONG                               SubSysID;
    ULONG                               Revision;
    USB_POWER_INFO                      USBPowerInfo[6];
    BOOL                                BusDeviceFunctionValid;
    ULONG                               BusNumber;
    USHORT                              BusDevice;
    USHORT                              BusFunction;
    PUSB_CONTROLLER_INFO_0              ControllerInfo;
    PUSB_DEVICE_PNP_STRINGS             UsbDeviceProperties;
} USBHOSTCONTROLLERINFO, *PUSBHOSTCONTROLLERINFO;

typedef struct _USBROOTHUBINFO
{
    USBDEVICEINFOTYPE                   DeviceInfoType;
    PUSB_NODE_INFORMATION               HubInfo;
    PUSB_HUB_INFORMATION_EX             HubInfoEx;
    PCHAR                               HubName;
    PUSB_PORT_CONNECTOR_PROPERTIES      PortConnectorProps;
    PUSB_DEVICE_PNP_STRINGS             UsbDeviceProperties;
    PDEVICE_INFO_NODE                   DeviceInfoNode;
    PUSB_HUB_CAPABILITIES_EX            HubCapabilityEx;

} USBROOTHUBINFO, *PUSBROOTHUBINFO;

typedef struct _USBEXTERNALHUBINFO
{
    USBDEVICEINFOTYPE                      DeviceInfoType;
    PUSB_NODE_INFORMATION                  HubInfo;
    PUSB_HUB_INFORMATION_EX                HubInfoEx;
    PCHAR                                  HubName;
    PUSB_NODE_CONNECTION_INFORMATION_EX    ConnectionInfo;
    PUSB_PORT_CONNECTOR_PROPERTIES         PortConnectorProps;
    PUSB_DESCRIPTOR_REQUEST                ConfigDesc;
    PUSB_DESCRIPTOR_REQUEST                BosDesc;
    PSTRING_DESCRIPTOR_NODE                StringDescs;
    PUSB_NODE_CONNECTION_INFORMATION_EX_V2 ConnectionInfoV2; // NULL if root HUB
    PUSB_DEVICE_PNP_STRINGS                UsbDeviceProperties;
    PDEVICE_INFO_NODE                      DeviceInfoNode;
    PUSB_HUB_CAPABILITIES_EX               HubCapabilityEx;
} USBEXTERNALHUBINFO, *PUSBEXTERNALHUBINFO;


// HubInfo, HubName may be in USBDEVICEINFOTYPE, so they can be removed
typedef struct
{
    USBDEVICEINFOTYPE                      DeviceInfoType;
    PUSB_NODE_INFORMATION                  HubInfo;          // NULL if not a HUB
    PUSB_HUB_INFORMATION_EX                HubInfoEx;        // NULL if not a HUB
    PCHAR                                  HubName;          // NULL if not a HUB
    PUSB_NODE_CONNECTION_INFORMATION_EX    ConnectionInfo;   // NULL if root HUB
    PUSB_PORT_CONNECTOR_PROPERTIES         PortConnectorProps;
    PUSB_DESCRIPTOR_REQUEST                ConfigDesc;       // NULL if root HUB
    PUSB_DESCRIPTOR_REQUEST                BosDesc;          // NULL if root HUB
    PSTRING_DESCRIPTOR_NODE                StringDescs;
    PUSB_NODE_CONNECTION_INFORMATION_EX_V2 ConnectionInfoV2; // NULL if root HUB
    PUSB_DEVICE_PNP_STRINGS                UsbDeviceProperties;
    PDEVICE_INFO_NODE                      DeviceInfoNode;
    PUSB_HUB_CAPABILITIES_EX               HubCapabilityEx;  // NULL if not a HUB
} USBDEVICEINFO, *PUSBDEVICEINFO;

typedef struct _STRINGLIST
{
#ifdef H264_SUPPORT
    ULONGLONG       ulFlag;
#else
    ULONG           ulFlag;
#endif
    PCHAR     pszString;
    PCHAR     pszModifier;

} STRINGLIST, * PSTRINGLIST;

typedef struct _DEVICE_GUID_LIST {
    HDEVINFO   DeviceInfo;
    LIST_ENTRY ListHead;
} DEVICE_GUID_LIST, *PDEVICE_GUID_LIST;


/*****************************************************************************
 G L O B A L S
*****************************************************************************/

//
// USBVIEW.C
//

BOOL gDoConfigDesc;
BOOL gDoAnnotation;
BOOL gLogDebug;
int  TotalHubs;

//
// ENUM.C
//

PCHAR ConnectionStatuses[];

//
// DISPVID.C
//
DEFINE_GUID(YUY2_Format,0x32595559L,0x0000,0x0010,0x80,0x00,0x00,0xAA,0x00,0x38,0x9B,0x71);
DEFINE_GUID(NV12_Format,0x3231564EL,0x0000,0x0010,0x80,0x00,0x00,0xAA,0x00,0x38,0x9B,0x71);

#ifdef H264_SUPPORT
DEFINE_GUID(H264_Format,0x34363248, 0x0000, 0x0010, 0x80, 0x00, 0x00, 0xAA, 0x00, 0x38, 0x9B, 0x71);
#endif

// The following flags/variables are all initialized in Display.c InitializePerDeviceSettings() 
//
// Save the default frame from the MJPEG, Uncompressed, Vendor and Frame Based Format descriptor
// Check for this when processing the individual Frame descriptors
UCHAR   g_chMJPEGFrameDefault;
UCHAR   g_chUNCFrameDefault;
UCHAR   g_chVendorFrameDefault;
UCHAR   g_chFrameBasedFrameDefault;

// Spec version of UVC device
UINT g_chUVCversion;

// Base address of the USBDEVICEINFO for device we're parsing
PUSBDEVICEINFO CurrentUSBDeviceInfo;

// Base address of the Configuration descriptor we're parsing
PUSB_CONFIGURATION_DESCRIPTOR  CurrentConfigDesc;

// Length of the current configuration descriptor
DWORD dwConfigLength;
// Our current position from the beginning of the config descriptor
DWORD dwConfigIndex;

//
// DISPLAY.C
//
int gDeviceSpeed;

// Save the current Configuration starting and ending addresses
// Used in ValidateDescAddress() 
//
PUSB_CONFIGURATION_DESCRIPTOR   g_pConfigDesc;
PSTRING_DESCRIPTOR_NODE         g_pStringDescs;
PUCHAR                          g_descEnd;

/*****************************************************************************
 F U N C T I O N    P R O T O T Y P E S
*****************************************************************************/

//
// USBVIEW.C
//

HTREEITEM
AddLeaf (
    HTREEITEM hTreeParent,
    LPARAM    lParam,
    _In_ LPTSTR    lpszText,
    TREEICON  TreeIcon
);

VOID
Oops
(
    _In_ PCHAR  File,
    ULONG       Line
);

//
// DISPLAY.C
//

EXTERN_C UINT IsIADDevice (PUSBDEVICEINFO info);
EXTERN_C UINT IsUVCDevice (PUSBDEVICEINFO info);
EXTERN_C PCHAR GetVendorString(USHORT idVendor);
EXTERN_C PCHAR GetLangIDString(USHORT idLang);
EXTERN_C UINT GetConfigurationSize (PUSBDEVICEINFO info);
EXTERN_C PUSB_COMMON_DESCRIPTOR
GetNextDescriptor(
    _In_reads_bytes_(TotalLength) 
        PUSB_COMMON_DESCRIPTOR FirstDescriptor,
    _In_
        ULONG TotalLength,
    _In_ 
        PUSB_COMMON_DESCRIPTOR StartDescriptor,
    _In_ long 
        DescriptorType
    );

HRESULT
UpdateTreeItemDeviceInfo(
        HWND hTreeWnd,
        HTREEITEM hTreeItem
        );

PCHAR
GetTextBuffer(
);

BOOL
ResetTextBuffer(
);

BOOL
CreateTextBuffer (
);

VOID
DestroyTextBuffer (
);

UINT
GetTextBufferPos (
);

VOID
UpdateEditControl (
    HWND      hEditWnd,
    HWND      hTreeWnd,
    HTREEITEM hTreeItem
);


VOID __cdecl
AppendBuffer (
    LPCTSTR lpFormat,
    ...
);

VOID __cdecl
AppendTextBuffer (
    LPCTSTR lpFormat,
    ...
);

VOID
DisplayStringDescriptor (
    UCHAR                   Index,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
);

PCHAR
GetStringFromList(
            PSTRINGLIST     slPowerState,
            ULONG           ulNumElements,

#ifdef H264_SUPPORT
            ULONGLONG      ulFlag,
#else
            ULONG          ulFlag,
#endif
       _In_ PCHAR           szDefault
            );

EXTERN_C PCHAR GetPowerStateString(
            WDMUSB_POWER_STATE powerState
            );

EXTERN_C PCHAR GetControllerFlavorString(
            USB_CONTROLLER_FLAVOR flavor
            );

EXTERN_C ULONG GetEhciDebugPort(
            ULONG vendorId, 
            ULONG deviceId
            );

VOID
WalkTreeTopDown(
          _In_ HTREEITEM        hTreeItem,
          _In_ LPFNTREECALLBACK lpfnTreeCallback,
          _In_opt_ PVOID            pContext,
          _In_opt_ LPFNTREENOTIFYCALLBACK lpfnTreeNotifyCallback
          );

VOID RefreshTree (VOID);

//
// ENUM.C
//

VOID
EnumerateHostControllers (
    HTREEITEM  hTreeParent,
    ULONG     *DevicesConnected
    );


VOID
CleanupItem (
    HWND      hTreeWnd,
    HTREEITEM hTreeItem,
    PVOID pContext
    );

DEVICE_POWER_STATE
AcquireDevicePowerState(
    _Inout_ PDEVICE_INFO_NODE pNode
    );

_Success_(return == TRUE)
BOOL
GetDeviceProperty(
    _In_    HDEVINFO         DeviceInfoSet,
    _In_    PSP_DEVINFO_DATA DeviceInfoData,
    _In_    DWORD            Property,
    _Outptr_ LPTSTR         *ppBuffer
    );

void
ClearDeviceList(
    PDEVICE_GUID_LIST DeviceList
    );

//
// DEBUG.C
//

_Success_(return != NULL)
_Post_writable_byte_size_(dwBytes)
HGLOBAL
MyAlloc (
    _In_    PCHAR   File,
    ULONG   Line,
    DWORD   dwBytes
    );

_Success_(return != NULL)
_Post_writable_byte_size_(dwBytes)
HGLOBAL
MyReAlloc (
    HGLOBAL hMem,
    DWORD   dwBytes
    );

HGLOBAL
MyFree (
    HGLOBAL hMem
    );

VOID
MyCheckForLeaks (
    VOID
    );

//
// DEVNODE.C
//


PUSB_DEVICE_PNP_STRINGS
DriverNameToDeviceProperties(
    _In_reads_bytes_(cbDriverName) PCHAR   DriverName, 
    _In_ size_t                       cbDriverName
    );

VOID FreeDeviceProperties(
        _In_ PUSB_DEVICE_PNP_STRINGS *ppDevProps
        );
//
// DISPAUD.C
//

BOOL
DisplayAudioDescriptor (
    PUSB_AUDIO_COMMON_DESCRIPTOR CommonDesc,
    UCHAR                        bInterfaceSubClass
    );

//
// DISPVID.C
//

BOOL
DisplayVideoDescriptor (
    PVIDEO_SPECIFIC VidCommonDesc,
    UCHAR                        bInterfaceSubClass,
    PSTRING_DESCRIPTOR_NODE      StringDescs,
    DEVICE_POWER_STATE           LatestDevicePowerState
    );

//
// DISPLAY.C
//

BOOL
ValidateDescAddress (
    PUSB_COMMON_DESCRIPTOR          commonDesc
    );
