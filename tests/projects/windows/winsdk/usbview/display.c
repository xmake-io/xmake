/*++

Copyright (c) 1997-2011 Microsoft Corporation

Module Name:

DISPLAY.C

Abstract:

This source file contains the routines which update the edit control
to display information about the selected USB device.

Environment:

user mode

Revision History:

04-25-97 : created
03-28-03 : extensive changes to support new USBVCD
03-28-08 : extensive changes to support new USB Video Class 1.1

--*/

/*****************************************************************************
I N C L U D E S
*****************************************************************************/

#include "uvcview.h"
#include "h264.h"
#include <usb200.h>

#include "vndrlist.h"
#include "langidlist.h"

/*****************************************************************************
D E F I N E S
*****************************************************************************/

#define BUFFERALLOCINCREMENT        0x10000
#define BUFFERMINFREESPACE          0x1000

/*****************************************************************************
T Y P E D E F S
*****************************************************************************/

//
// Hardcoded information about specific EHCI controllers
//
typedef struct _EHCI_CONTROLLER_DATA
{
    USHORT  VendorID;
    USHORT  DeviceID;
    UCHAR   DebugPortNumber;
} EHCI_CONTROLLER_DATA, *PEHCI_CONTROLLER_DATA;


/*****************************************************************************
G L O B A L S    P R I V A T E    T O    T H I S    F I L E
*****************************************************************************/

// Workspace for text info which is used to update the edit control
//
CHAR  *TextBuffer = NULL;
UINT   TextBufferLen = 0;
UINT   TextBufferPos = 0;

STRINGLIST slPowerState [] =
{
    {WdmUsbPowerNotMapped,          "S? (unmapped)   ", ""},

    {WdmUsbPowerSystemUnspecified,  "S? (unspecified)", ""},
    {WdmUsbPowerSystemWorking,      "S0 (working)    ", ""},
    {WdmUsbPowerSystemSleeping1,    "S1 (sleep)      ", ""},
    {WdmUsbPowerSystemSleeping2,    "S2 (sleep)      ", ""},
    {WdmUsbPowerSystemSleeping3,    "S3 (sleep)      ", ""},
    {WdmUsbPowerSystemHibernate,    "S4 (Hibernate)  ", ""},
    {WdmUsbPowerSystemShutdown,     "S5 (shutdown)   ", ""},

    {WdmUsbPowerDeviceUnspecified,  "D? (unspecified)", ""},
    {WdmUsbPowerDeviceD0,           "D0              ", ""},
    {WdmUsbPowerDeviceD1,           "D1              ", ""},
    {WdmUsbPowerDeviceD2,           "D2              ", ""},
    {WdmUsbPowerDeviceD3,           "D3              ", ""},
};

STRINGLIST slControllerFlavor[] =
{
    { USB_HcGeneric, "USB_HcGeneric", "" },
    { OHCI_Generic, "OHCI_Generic", "" },
    { OHCI_Hydra, "OHCI_Hydra", "" },
    { OHCI_NEC, "OHCI_NEC", "" },
    { UHCI_Generic, "UHCI_Generic", "" },
    { UHCI_Piix4, "UHCI_Piix4", "" },
    { UHCI_Piix3, "UHCI_Piix3", "" },
    { UHCI_Ich2, "UHCI_Ich2", "" },
    { UHCI_Reserved204, "UHCI_Reserved204", "" },
    { UHCI_Ich1, "UHCI_Ich1", "" },
    { UHCI_Ich3m, "UHCI_Ich3m", "" },
    { UHCI_Ich4, "UHCI_Ich4", "" },
    { UHCI_Ich5, "UHCI_Ich5", "" },
    { UHCI_Ich6, "UHCI_Ich6", "" },
    { UHCI_Intel, "UHCI_Intel", "" },
    { UHCI_VIA, "UHCI_VIA", "" },
    { UHCI_VIA_x01, "UHCI_VIA_x01", "" },
    { UHCI_VIA_x02, "UHCI_VIA_x02", "" },
    { UHCI_VIA_x03, "UHCI_VIA_x03", "" },
    { UHCI_VIA_x04, "UHCI_VIA_x04", "" },
    { UHCI_VIA_x0E_FIFO, "UHCI_VIA_x0E_FIFO", "" },
    { EHCI_Generic, "EHCI_Generic", "" },
    { EHCI_NEC, "EHCI_NEC", "" },
    { EHCI_Lucent, "EHCI_Lucent", "" },
    { EHCI_NVIDIA_Tegra2, "EHCI_NVIDIA_Tegra2", "" },
    { EHCI_NVIDIA_Tegra3, "EHCI_NVIDIA_Tegra3", "" },
    { EHCI_Intel_Medfield, "EHCI_Intel_Medfield", "" }
};

//
// For supporting pre Win8 versions of Windows, a hardcoded list is maintained for determining
// debug port numbers.  As usbport.inf is augmented with new host controllers, this list should
// be updated.
//
// The following entries do not have a debug port:
// PCI\VEN_8086&DEV_0806 - "Intel(R) SM35 Express Chipset USB2 Enhanced Host Controller MPH  - 0806"
// PCI\VEN_8086&DEV_0811 - "Intel(R) SM35 Express Chipset USB2 Enhanced Host Controller SPM  - 0811"
//

EHCI_CONTROLLER_DATA EhciControllerData[] =
{
    {0x8086, 0x24CD, 1}, // ICH4 - Intel(R) 82801DB/DBM USB 2.0 Enhanced Host Controller - 24CD
    {0x8086, 0x24DD, 1}, // ICH5 - Intel(R) 82801EB USB2 Enhanced Host Controller - 24DD
    {0x8086, 0x25AD, 1}, // ICH5 - Intel(R) 6300ESB USB2 Enhanced Host Controller - 25AD
    {0x8086, 0x265C, 1}, // ICH6 - Intel(R) 82801FB/FBM USB2 Enhanced Host Controller - 265C
    {0x8086, 0x268C, 1}, // Intel(R) 631xESB/6321ESB/3100 Chipset USB2 Enhanced Host Controller - 268C
    {0x8086, 0x27CC, 1}, // ICH7 - Intel(R) 82801G (ICH7 Family) USB2 Enhanced Host Controller - 27CC
    {0x8086, 0x2836, 1}, // ICH8 - Intel(R) ICH8 Family USB2 Enhanced Host Controller - 2836
    {0x8086, 0x283A, 1}, // ICH8 - Intel(R) ICH8 Family USB2 Enhanced Host Controller - 283A
    {0x8086, 0x293A, 1}, // ICH9 - Intel(R) ICH9 Family USB2 Enhanced Host Controller - 293A
    {0x8086, 0x293C, 1}, // ICH9 - Intel(R) ICH9 Family USB2 Enhanced Host Controller - 293C
    {0x8086, 0x3A3A, 1}, // ICH10 - Intel(R) ICH10 Family USB Enhanced Host Controller - 3A3A
    {0x8086, 0x3A3C, 1}, // ICH10 - Intel(R) ICH10 Family USB Enhanced Host Controller - 3A3C
    {0x8086, 0x3A6A, 1}, // ICH10 - Intel(R) ICH10 Family USB Enhanced Host Controller - 3A6A
    {0x8086, 0x3A6C, 1}, // ICH10 - Intel(R) ICH10 Family USB Enhanced Host Controller - 3A6C
    {0x8086, 0x3B34, 2}, // 5 series - Intel(R) 5 Series/3400 Series Chipset Family USB Enhanced Host Controller - 3B34
    {0x8086, 0x3B36, 2}, // 5 series - Intel(R) 5 Series/3400 Series Chipset Family USB Universal Host Controller - 3B36
    {0x8086, 0x1C26, 2}, // 6 series - Intel(R) 6 Series/C200 Series Chipset Family USB Enhanced Host Controller - 1C26
    {0x8086, 0x1C2D, 2}, // 6 series - Intel(R) 6 Series/C200 Series Chipset Family USB Enhanced Host Controller - 1C2D
    {0x8086, 0x1D26, 2}, // Intel(R) C600/X79 series chipset USB2 Enhanced Host Controller #1 - 1D26
    {0x8086, 0x1D2D, 2}, // Intel(R) C600/X79 series chipset USB2 Enhanced Host Controller #2 - 1D2D
    {0x8086, 0x268C, 1}, // Intel(R) 631xESB/6321ESB/3100 Chipset USB2 Enhanced Host Controller - 268C
    {0x10DE, 0x00D8, 1},
    {0,0,0},
};


/*****************************************************************************
L O C A L    F U N C T I O N    P R O T O T Y P E S
*****************************************************************************/

VOID
DisplayPortConnectorProperties (
    _In_     PUSB_PORT_CONNECTOR_PROPERTIES         PortConnectorProps,
    _In_opt_ PUSB_NODE_CONNECTION_INFORMATION_EX_V2 ConnectionInfoV2
    );

void
DisplayDevicePowerState (
    _In_     PDEVICE_INFO_NODE DeviceInfoNode
    );

VOID
DisplayHubInfo (
    PUSB_HUB_INFORMATION HubInfo,
    BOOL DisplayDescriptor
    );

VOID
DisplayHubInfoEx (
    PUSB_HUB_INFORMATION_EX    HubInfoEx
    );

VOID
DisplayHubCapabilityEx (
    PUSB_HUB_CAPABILITIES_EX HubCapabilityEx
    );

VOID
DisplayPowerState(
    PUSB_POWER_INFO pUPI
    );

VOID
DisplayConnectionInfo (
    _In_     PUSB_NODE_CONNECTION_INFORMATION_EX    ConnectInfo,
    _In_     PUSBDEVICEINFO                         info,
    _In_     PSTRING_DESCRIPTOR_NODE                StringDescs,
    _In_opt_ PUSB_NODE_CONNECTION_INFORMATION_EX_V2 ConnectionInfoV2
    );

VOID
DisplayPipeInfo (
     ULONG           NumPipes,
     USB_PIPE_INFO  *PipeInfo
     );

VOID
DisplayConfigDesc (
    PUSBDEVICEINFO                  info,
    PUSB_CONFIGURATION_DESCRIPTOR   ConfigDesc,
    PSTRING_DESCRIPTOR_NODE         StringDescs
    );

VOID
DisplayBosDescriptor (
    PUSBDEVICEINFO            info,
    PUSB_BOS_DESCRIPTOR       BosDesc,
    PSTRING_DESCRIPTOR_NODE   StringDescs
    );

VOID
DisplayBillboardCapabilityDescriptor (
    PUSBDEVICEINFO info,
    PUSB_DEVICE_CAPABILITY_BILLBOARD_DESCRIPTOR billboardCapDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs
);

VOID
DisplayDeviceQualifierDescriptor (
    PUSB_DEVICE_QUALIFIER_DESCRIPTOR DevQualDesc
    );

VOID
DisplayConfigurationDescriptor (
    PUSBDEVICEINFO                  info,
    PUSB_CONFIGURATION_DESCRIPTOR   ConfigDesc,
    PSTRING_DESCRIPTOR_NODE         StringDescs
    );

VOID
DisplayInterfaceDescriptor (
    PUSB_INTERFACE_DESCRIPTOR   InterfaceDesc,
    PSTRING_DESCRIPTOR_NODE     StringDescs,
    DEVICE_POWER_STATE          LatestDevicePowerState
    );

VOID
DisplayEndpointDescriptor (
    _In_     PUSB_ENDPOINT_DESCRIPTOR
                        EndpointDesc,
    _In_opt_ PUSB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR
                        EpCompDesc,
    _In_opt_ PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR
                        SspIsochCompDesc,
    _In_     UCHAR      InterfaceClass,
    _In_     BOOLEAN    EpCompDescAvail
    );

VOID
DisplaySuperSpeedPlusIsochEndpointCompanionDescriptor(
     _In_ PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR SspIsochEpCompDesc
     );

VOID
DisplayEndointCompanionDescriptor (
    _In_     PUSB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR EpCompDesc,
    _In_opt_ PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR
                                                           SspIsochEpCompDesc,
    _In_     UCHAR                                         DescType
    );


VOID
DisplayHidDescriptor (
    PUSB_HID_DESCRIPTOR         HidDesc
    );

VOID
DisplayOTGDescriptor (
    PUSB_OTG_DESCRIPTOR         OTGDesc
    );

void
InitializePerDeviceSettings (
    PUSBDEVICEINFO info
    );

UINT
IsUVCDevice (
    PUSBDEVICEINFO info
    );

VOID
DisplayIADDescriptor (
    PUSB_IAD_DESCRIPTOR         IADDesc,
    PSTRING_DESCRIPTOR_NODE     StringDescs,
    int                         nInterfaces,
    DEVICE_POWER_STATE          LatestDevicePowerState
    );

VOID
DisplayUSEnglishStringDescriptor (
    UCHAR                       Index,
    PSTRING_DESCRIPTOR_NODE     USStringDescs,
    DEVICE_POWER_STATE          LatestDevicePowerState
    );

VOID
DisplayUnknownDescriptor (
    PUSB_COMMON_DESCRIPTOR      CommonDesc
    );

VOID
DisplayRemainingUnknownDescriptor(
    PUCHAR DescriptorData,
    ULONG  Start,
    ULONG  Stop
    );

PCHAR
GetVendorString (
    USHORT     idVendor
    );

PCHAR
GetLangIDString (
    USHORT     idLang
    );

UINT
GetConfigurationSize (
    PUSBDEVICEINFO info
    );

UINT
GetInterfaceCount (
    PUSBDEVICEINFO info
    );


/*****************************************************************************
L O C A L    F U N C T I O N S
*****************************************************************************/

/*****************************************************************************

NextDescriptor()

*****************************************************************************/
//__forceinline
PUSB_COMMON_DESCRIPTOR
NextDescriptor(
    _In_ PUSB_COMMON_DESCRIPTOR Descriptor
    )
{
    if (Descriptor->bLength == 0)
    {
        return NULL;
    }
    return (PUSB_COMMON_DESCRIPTOR)((PUCHAR)Descriptor + Descriptor->bLength);
}

/*****************************************************************************

GetNextDescriptor()

*****************************************************************************/
PUSB_COMMON_DESCRIPTOR
GetNextDescriptor(
    _In_reads_bytes_(TotalLength)
        PUSB_COMMON_DESCRIPTOR FirstDescriptor,
    _In_
        ULONG TotalLength,
    _In_
        PUSB_COMMON_DESCRIPTOR StartDescriptor,
    _In_ long
        DescriptorType
    )
{
    PUSB_COMMON_DESCRIPTOR currentDescriptor = NULL;
    PUSB_COMMON_DESCRIPTOR endDescriptor     = NULL;

    endDescriptor = (PUSB_COMMON_DESCRIPTOR)((PUCHAR)FirstDescriptor + TotalLength);

    if (StartDescriptor >= endDescriptor ||
        NextDescriptor(StartDescriptor)>= endDescriptor)
    {
        return NULL;
    }

    if (DescriptorType == -1) // -1 means any type
    {
        return NextDescriptor(StartDescriptor);
    }

    currentDescriptor = StartDescriptor;

    while (((currentDescriptor = NextDescriptor(currentDescriptor)) < endDescriptor)
            && currentDescriptor != NULL)
    {
        if (currentDescriptor->bDescriptorType == (UCHAR)DescriptorType)
        {
            return currentDescriptor;
        }
    }
    return NULL;
}



/*****************************************************************************

CreateTextBuffer()

*****************************************************************************/

BOOL
CreateTextBuffer (
                  )
{
    // Allocate the buffer
    //
    TextBuffer = ALLOC(BUFFERALLOCINCREMENT);

    if (TextBuffer == NULL)
    {
        OOPS();

        return FALSE;
    }

    TextBufferLen = BUFFERALLOCINCREMENT;

    // Reset the buffer position and terminate the buffer
    //
    memset(TextBuffer, 0, BUFFERALLOCINCREMENT);
    TextBufferPos = 0;

    return TRUE;
}


/*****************************************************************************

DestroyTextBuffer()

*****************************************************************************/

VOID
DestroyTextBuffer (
                   )
{
    if (TextBuffer != NULL)
    {
        FREE(TextBuffer);

        TextBuffer = NULL;
    }
}


/*****************************************************************************

ResetTextBuffer()

*****************************************************************************/

BOOL
ResetTextBuffer (
                 )
{
    // Fail if the text buffer has not been allocated
    //
    if (TextBuffer == NULL)
    {
        OOPS();

        return FALSE;
    }

    // Reset the buffer position and terminate the buffer
    //
    *TextBuffer = 0;
    TextBufferPos = 0;

    return TRUE;
}


/*****************************************************************************

GetTextBufferPos()

*****************************************************************************/

UINT
GetTextBufferPos (
                   )
{
    return TextBufferPos;
}


/*****************************************************************************

AppendTextBuffer()

*****************************************************************************/

VOID __cdecl
AppendTextBuffer (
    LPCTSTR lpFormat,
    ...
    )
{
    va_list arglist;
    HRESULT hr = S_OK;
    int     nPos = TextBufferPos;
    char    LocalTextBuffer[512];

    va_start(arglist, lpFormat);

    // Make sure we have a healthy amount of space free in the buffer,
    // reallocating the buffer if necessary.
    //

    if (TextBufferLen - TextBufferPos < BUFFERMINFREESPACE)
    {
        CHAR *TextBufferTmp;
        UINT uNewTextBufferLen = 0;
        hr = UIntAdd(TextBufferLen, BUFFERALLOCINCREMENT, &uNewTextBufferLen);

        if (hr != S_OK)
            {
            // we've exceeded DWORD length of (2^32)-1 for buffer
            OOPS();

            return;
            }

        TextBufferTmp = REALLOC(TextBuffer, uNewTextBufferLen);

        if (TextBufferTmp != NULL)
        {
            TextBuffer = TextBufferTmp;
            TextBufferLen += BUFFERALLOCINCREMENT;  // update TextBufferLen to reflect the new, bigger size of the text buffer
        }
        else
        {
            // If GlobalReAlloc fails, the original memory is not freed,
            // and the original handle and pointer are still valid.
            //

            OOPS();

            return;
        }
    }

    // Add the text to the end of the buffer
    //
    hr = StringCchVPrintf(LocalTextBuffer, sizeof(LocalTextBuffer), lpFormat, arglist);
    if (SUCCEEDED(hr))
    {
        size_t cbMax = 512;
        size_t pcb = 0;

        // Ensure TextBuffer is zero terminated
        // The text buffer size is specified by TextBufferLen.
        // the text buffer size will be bigger than BUFFERALLOCINCREMENT if the buffer has been reallocated more than
        // once (which would happen if it had to be made bigger to hold more text)
        hr = StringCbLength((LPCTSTR) TextBuffer,
            TextBufferLen, // the maximum number of bytes allowed in TextBuffer.
            &pcb);

        if (FAILED(hr)) // buffer is not null-terminated, go ahead and do that
        {
            TextBuffer[TextBufferLen-1] = 0;
        }
        hr = StringCbLength((LPCTSTR) LocalTextBuffer, cbMax, &pcb);
        if (SUCCEEDED(hr))
        {
            StringCbCatN(TextBuffer, TextBufferLen, LocalTextBuffer, pcb);

            // Increment the text position by the number of charcters we just added to it.
            TextBufferPos += (UINT) pcb;
        }

        // If DebugLog flag set, send output to the debugger
        //
        if (gLogDebug)
        {
            OutputDebugString(TextBuffer + nPos); // print the string just added to the text buffer
        }
    }
}

//*****************************************************************************
//
//  GetTextBuffer
//
//  Returns the display text buffer
//
//*****************************************************************************
PCHAR GetTextBuffer(void)
{
    return (TextBuffer);
}


//*****************************************************************************
//
//  GetEhciDebugPort
//
//  Returns debug port value if present for EHCI controller. 0 if its not present
//
//*****************************************************************************
ULONG GetEhciDebugPort(ULONG vendorId, ULONG deviceId)
{
    int i = 0;
    ULONG debugPort = 0;

    for (i = 0; EhciControllerData[i].VendorID != 0; i++)
    {
        if (vendorId == EhciControllerData[i].VendorID &&
            deviceId == EhciControllerData[i].DeviceID)
        {
            debugPort = EhciControllerData[i].DebugPortNumber;
            break;
        }
    }

    return debugPort;
}

//*****************************************************************************
//
//  UpdateTreeItemDeviceInfo
//
//  hTreeItem - Handle of selected TreeView item for which information should
//  be added to the TextBuffer global
//
//  The functions returns error status if AppendTextBuffer() used in Display*() functions
//  fails. The display text would be missing or truncated in such cases.
//*****************************************************************************
HRESULT
UpdateTreeItemDeviceInfo(
        HWND hTreeWnd,
        HTREEITEM hTreeItem
        )
{
    TV_ITEM tvi;
    PVOID   info;
    ULONG   i;
    HRESULT hr = S_OK;
    PCHAR tviName = NULL;

    SetLastError(0);

#ifndef H264_SUPPORT
    UNREFERENCED_PARAMETER(bShowVersion)
#endif

#ifdef H264_SUPPORT
    ResetErrorCounts();
#endif

    tviName = ALLOC(256);

    if(NULL == tviName)
    {
        OOPS();
        hr = E_OUTOFMEMORY;
        return hr;
    }

    //
    // Get the name of the TreeView item, along with the a pointer to the
    // info we stored about the item in the item's lParam.
    //

    tvi.mask = TVIF_HANDLE | TVIF_TEXT | TVIF_PARAM;
    tvi.hItem = hTreeItem;
    tvi.pszText = (LPSTR) tviName;
    tvi.cchTextMax = 256;

    TreeView_GetItem(hTreeWnd,
                     &tvi);

    info = (PVOID)tvi.lParam;

    AppendTextBuffer(tviName);
    AppendTextBuffer("\r\n");

    //
    // If we didn't store any info for the item, just display the item's
    // name, else display the info we stored for the item.
    //
    if (NULL != info)
    {
        PUSB_NODE_INFORMATION                  HubInfo = NULL;
        PCHAR                                  HubName = NULL;
        PUSB_NODE_CONNECTION_INFORMATION_EX    ConnectionInfo = NULL;
        PUSB_DESCRIPTOR_REQUEST                ConfigDesc = NULL;
        PSTRING_DESCRIPTOR_NODE                StringDescs = NULL;
        PUSB_HUB_INFORMATION_EX                HubInfoEx = NULL;
        PUSB_HUB_CAPABILITIES_EX               HubCapabilityEx = NULL;
        PUSB_PORT_CONNECTOR_PROPERTIES         PortConnectorProps = NULL;
        PUSB_NODE_CONNECTION_INFORMATION_EX_V2 ConnectionInfoV2 = NULL;
        PUSB_DESCRIPTOR_REQUEST                BosDesc = NULL;
        PDEVICE_INFO_NODE                      DeviceInfoNode = NULL;

        // The TextBuffer has the TreeView name; add 2 lines for display
        AppendTextBuffer("\r\n\r\n");

        switch (*(PUSBDEVICEINFOTYPE)info)
        {
            case HostControllerInfo:
            {
                HTREEITEM       rootHubItem     = NULL;
                BOOL            dbgPortFound    = FALSE;

                AppendTextBuffer("DriverKey: %s\r\n",
                                 ((PUSBHOSTCONTROLLERINFO)info)->DriverKey);

                AppendTextBuffer("VendorID: %04X\r\n",
                                 ((PUSBHOSTCONTROLLERINFO)info)->VendorID);

                AppendTextBuffer("DeviceID: %04X\r\n",
                                 ((PUSBHOSTCONTROLLERINFO)info)->DeviceID);

                AppendTextBuffer("SubSysID: %08X\r\n",
                                 ((PUSBHOSTCONTROLLERINFO)info)->SubSysID);

                AppendTextBuffer("Revision: %02X\r\n",
                                 ((PUSBHOSTCONTROLLERINFO)info)->Revision);

                //
                // Search for the debug port number.  If running on Win8 or later,
                // the USB_PORT_CONNECTOR_PROPERTIES structure will contain the
                // port number.  If that fails, the list of known host controllers
                // with debug ports will be searched.
                //

                AppendTextBuffer("\r\nDebug Port Number:  ");

                rootHubItem = TreeView_GetChild(hTreeWnd, hTreeItem);

                if (rootHubItem != NULL)
                {
                    HTREEITEM portItem = NULL;
                    PVOID     portInfo;

                    portItem = TreeView_GetChild(hTreeWnd, rootHubItem);

                    while (portItem != NULL)
                    {
                        tvi.mask = TVIF_PARAM;
                        tvi.hItem = portItem;
                        tvi.pszText = NULL;
                        tvi.cchTextMax = 0;

                        TreeView_GetItem(hTreeWnd, &tvi);

                        portInfo = (PVOID)tvi.lParam;

                        //
                        // Note that an empty port is a port without a device attached
                        // is still a DeviceInfo instance.
                        //

                        if ((*(PUSBDEVICEINFOTYPE)portInfo) == DeviceInfo)
                        {
                            ConnectionInfo = ((PUSBDEVICEINFO)portInfo)->ConnectionInfo;
                            PortConnectorProps = ((PUSBDEVICEINFO)portInfo)->PortConnectorProps;
                        }
                        else if ((*(PUSBDEVICEINFOTYPE)portInfo) == ExternalHubInfo)
                        {
                            ConnectionInfo = ((PUSBEXTERNALHUBINFO)portInfo)->ConnectionInfo;
                            PortConnectorProps = ((PUSBEXTERNALHUBINFO)portInfo)->PortConnectorProps;

                        }

                        if (ConnectionInfo != NULL     &&
                            PortConnectorProps != NULL &&
                            PortConnectorProps->UsbPortProperties.PortIsDebugCapable)
                        {
                            dbgPortFound = TRUE;
                            AppendTextBuffer("%d\r\n", ((PUSBDEVICEINFO)portInfo)->ConnectionInfo->ConnectionIndex);
                            break;
                        }
                        portItem = TreeView_GetNextSibling(hTreeWnd, portItem);
                    }

                    //
                    // Resetting ConnectionInfo and PortConnectorProps to NULL so that they won't be erroneously
                    // be displayed below.
                    //

                    ConnectionInfo = NULL;
                    PortConnectorProps = NULL;
                }
                if (dbgPortFound == FALSE)
                {
                    for (i = 0; EhciControllerData[i].VendorID; i++)
                    {
                        if (((PUSBHOSTCONTROLLERINFO)info)->VendorID ==
                              EhciControllerData[i].VendorID &&
                            ((PUSBHOSTCONTROLLERINFO)info)->DeviceID ==
                              EhciControllerData[i].DeviceID)
                        {
                            dbgPortFound = TRUE;
                            AppendTextBuffer("%d\r\n", EhciControllerData[i].DebugPortNumber);
                            break;
                        }
                    }
                }
                if (dbgPortFound == FALSE)
                {
                    AppendTextBuffer("None\r\n");
                }

                //
                // Display bus/device/function to help with setting debug
                // settings.
                //
                if (((PUSBHOSTCONTROLLERINFO)info)->BusDeviceFunctionValid)
                {
                    AppendTextBuffer("Bus.Device.Function (in decimal): %d.%d.%d\r\n",
                                        ((PUSBHOSTCONTROLLERINFO)info)->BusNumber,
                                        ((PUSBHOSTCONTROLLERINFO)info)->BusDevice,
                                        ((PUSBHOSTCONTROLLERINFO)info)->BusFunction);
                }

                // Display the USB Host Controller Power State Info
                {
                    PUSB_POWER_INFO pUPI = (PUSB_POWER_INFO) &((PUSBHOSTCONTROLLERINFO)info)->USBPowerInfo[0];
                    int                     nIndex = 0;
                    int                     nPowerState = WdmUsbPowerSystemWorking;

                    AppendTextBuffer("\r\nHost Controller Power State Mappings\r\n");
                    AppendTextBuffer("System State\t\tHost Controller\t\tRoot Hub\tUSB wakeup\tPowered\r\n");
                    for ( ; nPowerState < WdmUsbPowerSystemShutdown; nIndex++, nPowerState++, pUPI++)
                    {
                        DisplayPowerState(pUPI);
                    }

                    AppendTextBuffer("%s\t%s\r\n",
                                    "Last Sleep State",
                                    GetPowerStateString(pUPI->LastSystemSleepState)
                                    );
                }

                break;
            }

            case RootHubInfo:
                HubInfo   = ((PUSBROOTHUBINFO)info)->HubInfo;
                HubName   = ((PUSBROOTHUBINFO)info)->HubName;
                HubCapabilityEx  = ((PUSBROOTHUBINFO)info)->HubCapabilityEx;

                AppendTextBuffer("Root Hub: %s\r\n",
                                 HubName);

                break;

            case ExternalHubInfo:
                HubInfo            = ((PUSBEXTERNALHUBINFO)info)->HubInfo;
                HubName            = ((PUSBEXTERNALHUBINFO)info)->HubName;
                HubInfoEx          = ((PUSBEXTERNALHUBINFO)info)->HubInfoEx;
                HubCapabilityEx    = ((PUSBEXTERNALHUBINFO)info)->HubCapabilityEx;
                ConnectionInfo     = ((PUSBEXTERNALHUBINFO)info)->ConnectionInfo;
                ConnectionInfoV2   = ((PUSBEXTERNALHUBINFO)info)->ConnectionInfoV2;
                PortConnectorProps = ((PUSBEXTERNALHUBINFO)info)->PortConnectorProps;
                ConfigDesc         = ((PUSBEXTERNALHUBINFO)info)->ConfigDesc;
                StringDescs        = ((PUSBEXTERNALHUBINFO)info)->StringDescs;
                BosDesc            = ((PUSBEXTERNALHUBINFO)info)->BosDesc;
                DeviceInfoNode     = ((PUSBEXTERNALHUBINFO)info)->DeviceInfoNode;

                AppendTextBuffer("External Hub: %s\r\n",
                                 HubName);
                break;

            case DeviceInfo:
                ConnectionInfo     = ((PUSBDEVICEINFO)info)->ConnectionInfo;
                ConnectionInfoV2   = ((PUSBDEVICEINFO)info)->ConnectionInfoV2;
                PortConnectorProps = ((PUSBDEVICEINFO)info)->PortConnectorProps;
                ConfigDesc         = ((PUSBDEVICEINFO)info)->ConfigDesc;
                StringDescs        = ((PUSBDEVICEINFO)info)->StringDescs;
                BosDesc            = ((PUSBDEVICEINFO)info)->BosDesc;
                DeviceInfoNode     = ((PUSBDEVICEINFO)info)->DeviceInfoNode;
                break;
        }

        if (PortConnectorProps)
        {
            DisplayPortConnectorProperties(PortConnectorProps, ConnectionInfoV2);
        }

        if (DeviceInfoNode)
        {
            DisplayDevicePowerState(DeviceInfoNode);
        }

        if (HubInfo)
        {
            DisplayHubInfo(&HubInfo->u.HubInformation,
                           (HubInfoEx == NULL));
        }

        if (HubInfoEx)
        {
            DisplayHubInfoEx(HubInfoEx);
        }

        if(HubCapabilityEx)
        {
            DisplayHubCapabilityEx(HubCapabilityEx);
        }

        if (ConnectionInfo)
        {
            DisplayConnectionInfo(ConnectionInfo,
                (PUSBDEVICEINFO)info,
                StringDescs,
                ConnectionInfoV2);
        }

        if (ConfigDesc)
        {
            DisplayConfigDesc((PUSBDEVICEINFO)info,
                (PUSB_CONFIGURATION_DESCRIPTOR)(ConfigDesc + 1),
                StringDescs);
        }

        if (BosDesc)
        {
            DisplayBosDescriptor((PUSBDEVICEINFO) info,
                (PUSB_BOS_DESCRIPTOR) (BosDesc + 1),
                StringDescs);
        }
    }

    if(tviName != NULL)
    {
        FREE(tviName);
    }

    // AppendTextBuffer() which is used in Display*() functions uses GlobalRealloc() which can fail if realloc fails.
    // Obtain last error code from GetLastError() and propagate the error to caller.
    hr = HRESULT_FROM_WIN32(GetLastError());

    return hr;
}

//*****************************************************************************
//
// UpdateEditControl()
//
// hTreeItem - Handle of selected TreeView item for which information should
// be displayed in the edit control.
//
//*****************************************************************************

VOID
UpdateEditControl (
    HWND      hEditWnd,
    HWND      hTreeWnd,
    HTREEITEM hTreeItem
)
{
    HRESULT hr = S_OK;

    // Start with an empty text buffer.
    //
    if (!ResetTextBuffer())
    {
        return;
    }

    // Get the item information in global TextBuffer
    hr = UpdateTreeItemDeviceInfo(hTreeWnd, hTreeItem);

    if(FAILED(hr))
    {
        OOPS();
    }

    // All done formatting text buffer with info, now update the edit
    // control with the contents of the text buffer
    //
    SetWindowText(hEditWnd, TextBuffer);

}

/*****************************************************************************

DisplayPortConnectorProperties()

PortConnectorProps - Info about the port connector properties.

*****************************************************************************/

void
DisplayPortConnectorProperties (
    _In_     PUSB_PORT_CONNECTOR_PROPERTIES         PortConnectorProps,
    _In_opt_ PUSB_NODE_CONNECTION_INFORMATION_EX_V2 ConnectionInfoV2
    )
{
    AppendTextBuffer("Is Port User Connectable:         %s\r\n",
                     PortConnectorProps->UsbPortProperties.PortIsUserConnectable
                     ? "yes" : "no");

    AppendTextBuffer("Is Port Debug Capable:            %s\r\n",
                     PortConnectorProps->UsbPortProperties.PortIsDebugCapable
                     ? "yes" : "no");
    AppendTextBuffer("Companion Port Number:            %d\r\n",
                     PortConnectorProps->CompanionPortNumber);
    AppendTextBuffer("Companion Hub Symbolic Link Name: %ws\r\n",
                     PortConnectorProps->CompanionHubSymbolicLinkName);
    if (ConnectionInfoV2 != NULL)
    {
        AppendTextBuffer("Protocols Supported:\r\n");
        AppendTextBuffer(" USB 1.1:                         %s\r\n",
                         ConnectionInfoV2->SupportedUsbProtocols.Usb110
                         ? "yes" : "no");
        AppendTextBuffer(" USB 2.0:                         %s\r\n",
                         ConnectionInfoV2->SupportedUsbProtocols.Usb200
                         ? "yes" : "no");
        AppendTextBuffer(" USB 3.0:                         %s\r\n",
                         ConnectionInfoV2->SupportedUsbProtocols.Usb300
                         ? "yes" : "no");
    }

    AppendTextBuffer("\r\n");
}

/*****************************************************************************

DisplayDevicePowerState()

DeviceInfoNode - Structure containing info used to acquire device state

*****************************************************************************/

void
DisplayDevicePowerState (
    _In_     PDEVICE_INFO_NODE DeviceInfoNode
    )
{

    DEVICE_POWER_STATE powerState;

    powerState = AcquireDevicePowerState(DeviceInfoNode);

    AppendTextBuffer("Device Power State:               ");
    if (powerState >= PowerDeviceD0 && powerState <= PowerDeviceD3)
    {
        AppendTextBuffer("PowerDeviceD%d\r\n", powerState-1);
    }
    else
    {
        AppendTextBuffer("Invalid Device Power State Value %d\r\n", powerState);
    }

    AppendTextBuffer("\r\n");
}


/*****************************************************************************

DisplayHubDescriptorBase()

HubDescriptor - hub descriptor, could also be PUSB_30_HUB_DESCRIPTOR which has
                these field in common at the beginning of the data structure:

                - UCHAR   bLength;
                - UCHAR   bDescriptorType;
                - UCHAR   bNumberOfPorts;
                - USHORT  wHubCharacteristics;
                - UCHAR   bPowerOnToPowerGood;
                - UCHAR   bHubControlCurrent;

*****************************************************************************/
VOID
DisplayHubDescriptorBase(
    PUSB_HUB_DESCRIPTOR HubDescriptor
    )
{
    USHORT wHubChar = 0;

    AppendTextBuffer("Number of Ports:              %d\r\n",
        HubDescriptor->bNumberOfPorts);

    wHubChar = HubDescriptor->wHubCharacteristics;

    switch (wHubChar & 0x0003)
    {
    case 0x0000:
        AppendTextBuffer("Power switching:              Ganged\r\n");
        break;

    case 0x0001:
        AppendTextBuffer("Power switching:              Individual\r\n");
        break;

    case 0x0002:
    case 0x0003:
        AppendTextBuffer("Power switching:              None\r\n");
        break;
    }

    switch (wHubChar & 0x0004)
    {
    case 0x0000:
        AppendTextBuffer("Compound device:              No\r\n");
        break;

    case 0x0004:
        AppendTextBuffer("Compound device:              Yes\r\n");
        break;
    }

    switch (wHubChar & 0x0018)
    {
    case 0x0000:
        AppendTextBuffer("Over-current Protection:      Global\r\n");
        break;

    case 0x0008:
        AppendTextBuffer("Over-current Protection:      Individual\r\n");
        break;

    case 0x0010:
    case 0x0018:
        AppendTextBuffer("No Over-current Protection (Bus Power Only)\r\n");
        break;
    }
}



/*****************************************************************************

DisplayHubInfo()

HubInfo - Info about the hub.

*****************************************************************************/

VOID
DisplayHubInfo (
    PUSB_HUB_INFORMATION  HubInfo,
    BOOL                  DisplayDescriptor
    )
{
    AppendTextBuffer("Hub Power:                    %s\r\n",
        HubInfo->HubIsBusPowered ?
        "Bus Power" : "Self Power");

    if (DisplayDescriptor == TRUE)
    {
        DisplayHubDescriptorBase(&HubInfo->HubDescriptor);
    }
}

/*****************************************************************************

DisplayHubInfoEx()

HubInfo - Extended info about the hub.

*****************************************************************************/


VOID
DisplayHubInfoEx (
    PUSB_HUB_INFORMATION_EX    HubInfoEx
    )
{
    AppendTextBuffer("Hub type:                     ");

    switch (HubInfoEx->HubType) {

        case UsbRootHub:
            AppendTextBuffer("USB Root Hub\r\n");
            break;

        case Usb20Hub:
            AppendTextBuffer("USB 2.0 Hub\r\n");
            DisplayHubDescriptorBase((PUSB_HUB_DESCRIPTOR)&HubInfoEx->u.UsbHubDescriptor);
            break;

        case Usb30Hub:
            AppendTextBuffer("USB 3.0 Hub\r\n");

            //
            // Note that the DisplayHubDescriptorBase will display the fields of either
            // the legacy hub descriptor and the USB 3.0 descriptor which have the same
            // offset
            //

            DisplayHubDescriptorBase((PUSB_HUB_DESCRIPTOR)&HubInfoEx->u.UsbHubDescriptor);
            AppendTextBuffer("Packet Header Decode Latency: 0x%x\r\n", HubInfoEx->u.Usb30HubDescriptor.bHubHdrDecLat);
            AppendTextBuffer("Delay:                        0x%x ns\r\n", HubInfoEx->u.Usb30HubDescriptor.wHubDelay);

            break;

        default:
            AppendTextBuffer("ERROR: Unknown hub type %d\r\n", HubInfoEx->HubType);
            break;
    }

    AppendTextBuffer("\r\n");
}



/*****************************************************************************

DisplayHubCapabilityEx()

HubCapabilityInfo - Hub capability information

*****************************************************************************/

VOID
DisplayHubCapabilityEx (
    PUSB_HUB_CAPABILITIES_EX    HubCapabilityEx
    )
{
    if(HubCapabilityEx != NULL)
    {
       AppendTextBuffer("High speed capable:           %s\r\n",
                         HubCapabilityEx->CapabilityFlags.HubIsHighSpeedCapable
                         ? "Yes" : "No");
       AppendTextBuffer("High speed:                   %s\r\n",
                         HubCapabilityEx->CapabilityFlags.HubIsHighSpeed
                         ? "Yes" : "No");
       AppendTextBuffer("Multiple transaction translations capable:                 %s\r\n",
                         HubCapabilityEx->CapabilityFlags.HubIsMultiTtCapable
                         ? "Yes" : "No");
       AppendTextBuffer("Performs multiple transaction translations simultaneously: %s\r\n",
                         HubCapabilityEx->CapabilityFlags.HubIsMultiTt
                         ? "Yes" : "No");
       AppendTextBuffer("Hub wakes when device is connected:                        %s\r\n",
                         HubCapabilityEx->CapabilityFlags.HubIsArmedWakeOnConnect
                         ? "Yes" : "No");
       AppendTextBuffer("Hub is bus powered:           %s\r\n",
                         HubCapabilityEx->CapabilityFlags.HubIsBusPowered
                         ? "Yes" : "No");
       AppendTextBuffer("Hub is root:                  %s\r\n",
                         HubCapabilityEx->CapabilityFlags.HubIsRoot
                         ? "Yes" : "No");
    }
}

/*****************************************************************************

DisplayConnectionInfo()

ConnectInfo - Info about the connection.

PUSB_NODE_CONNECTION_INFORMATION_EX    ConnectInfo,
PSTRING_DESCRIPTOR_NODE             StringDescs

DisplayConnectionInfo(info->ConnectionInfo,
info->StringDescs);

DisplayConnectionInfo (
PUSB_NODE_CONNECTION_INFORMATION_EX    ConnectInfo,
PSTRING_DESCRIPTOR_NODE             StringDescs
)

*****************************************************************************/

VOID
DisplayConnectionInfo (
    _In_     PUSB_NODE_CONNECTION_INFORMATION_EX    ConnectInfo,
    _In_     PUSBDEVICEINFO                         info,
    _In_     PSTRING_DESCRIPTOR_NODE                StringDescs,
    _In_opt_ PUSB_NODE_CONNECTION_INFORMATION_EX_V2 ConnectionInfoV2
)
{

    //@@DisplayConnectionInfo - Device Information
    PCHAR                               VendorString = NULL;
    UINT                                tog = 1;
    UINT                                uIADcount = 0;

    // No device connected
    if (ConnectInfo->ConnectionStatus == NoDeviceConnected)
    {
        AppendTextBuffer("ConnectionStatus:      NoDeviceConnected\r\n");
        return;
    }

    // This is the entry point to the device display functions.
    // First, save this device's PUSBDEVICEINFO address
    // In a future version of this test, we will keep track of the the
    //  descriptor that we're parsing (# of bytes from beginning of info->configuration descriptor)
    // Then we can linked descriptors by reading forward through the remaining descriptors
    //  while still keeping our place in this main DisplayConnectionInfo() and called
    //  functions.
    //
    // We also initialize some global flags in uvcview.h that are used to
    //  verify items in MJPEG, Uncompressed and Vendor Frame descriptors
    //
    InitializePerDeviceSettings(info);

    if(gDoAnnotation)
    {

        AppendTextBuffer("       ---===>Device Information<===---\r\n");

        if (ConnectInfo->DeviceDescriptor.iProduct)
        {
            DisplayUSEnglishStringDescriptor(ConnectInfo->DeviceDescriptor.iProduct,
                StringDescs,
                info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);
        }

        AppendTextBuffer("\r\nConnectionStatus:                  %s\r\n",
            ConnectionStatuses[ConnectInfo->ConnectionStatus]);

        AppendTextBuffer("Current Config Value:              0x%02X",
            ConnectInfo->CurrentConfigurationValue);
    }

    switch (ConnectInfo->Speed){
    case UsbLowSpeed:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Device Bus Speed: Low\r\n");
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        gDeviceSpeed = UsbLowSpeed;
        break;

    case UsbFullSpeed:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Device Bus Speed: Full");
            if (ConnectionInfoV2 != NULL)
            {
                if (ConnectionInfoV2->Flags.DeviceIsSuperSpeedPlusCapableOrHigher)
                {
                    AppendTextBuffer(" (is SuperSpeedPlus or higher capable)\r\n");
                }
                else if (ConnectionInfoV2->Flags.DeviceIsSuperSpeedCapableOrHigher)
                {
                    AppendTextBuffer(" (is SuperSpeed or higher capable)\r\n");
                }
                else
                {
                    AppendTextBuffer(" (is not SuperSpeed or higher capable)\r\n");
                }
            }
            else
            {
                AppendTextBuffer("\r\n");
            }
         }
        else
        {
            AppendTextBuffer("\r\n");
        }
        gDeviceSpeed = UsbFullSpeed;
        break;
    case UsbHighSpeed:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Device Bus Speed: High");
            if (ConnectionInfoV2 != NULL)
            {
                if (ConnectionInfoV2->Flags.DeviceIsSuperSpeedPlusCapableOrHigher)
                {
                    AppendTextBuffer(" (is SuperSpeedPlus or higher capable)\r\n");
                }
                else if (ConnectionInfoV2->Flags.DeviceIsSuperSpeedCapableOrHigher)
                {
                    AppendTextBuffer(" (is SuperSpeed or higher capable)\r\n");
                }
                else
                {
                    AppendTextBuffer(" (is not SuperSpeed or higher capable)\r\n");
                }
            }
            else
            {
                AppendTextBuffer("\r\n");
            }
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        gDeviceSpeed = UsbHighSpeed;
        break;

    case UsbSuperSpeed:
        if(gDoAnnotation)
        {
            if (ConnectionInfoV2 != NULL)
            {
                AppendTextBuffer("  -> Device Bus Speed: Super%s\r\n",
                    ConnectionInfoV2->Flags.DeviceIsOperatingAtSuperSpeedPlusOrHigher
                    ? "SpeedPlus"
                    : "Speed");
            }
            else
            {
                AppendTextBuffer("  -> Device Bus Speed: Super Speed\r\n");
            }
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        gDeviceSpeed = UsbSuperSpeed;
        break;

    default:
        if(gDoAnnotation){AppendTextBuffer("  -> Device Bus Speed: Unknown\r\n");}
        else {AppendTextBuffer("\r\n");}
    }

    if(gDoAnnotation){
        AppendTextBuffer("Device Address:                    0x%02X\r\n",
            ConnectInfo->DeviceAddress);

        AppendTextBuffer("Open Pipes:                          %2d\r\n",
            ConnectInfo->NumberOfOpenPipes);
    }

    // No open pipes means the USB stack has not loaded the device
    if (ConnectInfo->NumberOfOpenPipes == 0)
    {
        AppendTextBuffer("*!*ERROR:  No open pipes!\r\n");
    }

    AppendTextBuffer("\r\n          ===>Device Descriptor<===\r\n");
    //@@DisplayConnectionInfo - Device Descriptor

    if (ConnectInfo->DeviceDescriptor.bLength != 18)
    {
        //@@TestCase A1.1
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the
        //@@  required length in the USB Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            ConnectInfo->DeviceDescriptor.bLength,
            18);
        OOPS();
    }

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        ConnectInfo->DeviceDescriptor.bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        ConnectInfo->DeviceDescriptor.bDescriptorType);

    //@@TestCase A1.2
    //@@Not implemented - Priority 1
    //@@Descriptor Field - bcdUSB
    //@@Need to check that any UVC device is set to 0x0200 or later.
    AppendTextBuffer("bcdUSB:                          0x%04X\r\n",
        ConnectInfo->DeviceDescriptor.bcdUSB);

    AppendTextBuffer("bDeviceClass:                      0x%02X",
        ConnectInfo->DeviceDescriptor.bDeviceClass);

    // Quit on these device failures
    if ((ConnectInfo->ConnectionStatus == DeviceFailedEnumeration) ||
        (ConnectInfo->ConnectionStatus == DeviceGeneralFailure))
    {
        AppendTextBuffer("\r\n*!*ERROR:  Device enumeration failure\r\n");
        return;
    }

    // Is this an IAD device?
    uIADcount = IsIADDevice((PUSBDEVICEINFO) info);

    if (uIADcount)
    {
        // this device configuration has 1 or more IAD descriptors
        if (ConnectInfo->DeviceDescriptor.bDeviceClass == USB_MISCELLANEOUS_DEVICE)
        {
            tog = 0;
            if (gDoAnnotation)
            {
                AppendTextBuffer("  -> This is a Multi-interface Function Code Device\r\n");
            }
            else
            {
                AppendTextBuffer("\r\n");
            }
        } else {
            AppendTextBuffer("\r\n*!*ERROR: device class should be Multi-interface Function 0x%02X\r\n"\
                "          When IAD descriptor is used\r\n",
                USB_MISCELLANEOUS_DEVICE);
        }
        // Is this a UVC device?
        g_chUVCversion = IsUVCDevice((PUSBDEVICEINFO) info);
    }
    else
    {
        // this is not an IAD device
        switch (ConnectInfo->DeviceDescriptor.bDeviceClass)
        {
        case USB_INTERFACE_CLASS_DEVICE:
            if(gDoAnnotation)
            {AppendTextBuffer("  -> This is an Interface Class Defined Device\r\n");}
            else {AppendTextBuffer("\r\n");}
            break;

        case USB_COMMUNICATION_DEVICE:
            tog = 0;
            if(gDoAnnotation)
            {AppendTextBuffer("  -> This is a Communication Device\r\n");}
            else {AppendTextBuffer("\r\n");}
            break;

        case USB_HUB_DEVICE:
            tog = 0;
            if(gDoAnnotation)
            {AppendTextBuffer("  -> This is a HUB Device\r\n");}
            else {AppendTextBuffer("\r\n");}
            break;

        case USB_DIAGNOSTIC_DEVICE:
            tog = 0;
            if(gDoAnnotation)
            {AppendTextBuffer("  -> This is a Diagnostic Device\r\n");}
            else {AppendTextBuffer("\r\n");}
            break;

        case USB_WIRELESS_CONTROLLER_DEVICE:
            tog = 0;
            if(gDoAnnotation)
            {AppendTextBuffer("  -> This is a Wireless Controller(Bluetooth) Device\r\n");}
            else {AppendTextBuffer("\r\n");}
            break;

        case USB_VENDOR_SPECIFIC_DEVICE:
            tog = 0;
            if(gDoAnnotation)
            {AppendTextBuffer("  -> This is a Vendor Specific Device\r\n");}
            else {AppendTextBuffer("\r\n");}
            break;

        case USB_DEVICE_CLASS_BILLBOARD:
            tog = 0;
            if (gDoAnnotation)
            {
                AppendTextBuffer("  -> This is a billboard class device\r\n");
            }
            else { AppendTextBuffer("\r\n"); }
            break;

        case USB_MISCELLANEOUS_DEVICE:
            tog = 0;
            //@@TestCase A1.3
            //@@ERROR
            //@@Descriptor Field - bDeviceClass
            //@@Multi-interface Function code used for non-IAD device
            AppendTextBuffer("\r\n*!*ERROR:  Multi-interface Function code %d used for "\
                "device with no IAD descriptors\r\n",
                ConnectInfo->DeviceDescriptor.bDeviceClass);
            break;

        default:
            //@@TestCase A1.4
            //@@ERROR
            //@@Descriptor Field - bDeviceClass
            //@@An unknown device class has been defined
            AppendTextBuffer("\r\n*!*ERROR:  unknown bDeviceClass %d\r\n",
                ConnectInfo->DeviceDescriptor.bDeviceClass);
            OOPS();
            break;
        }
    }

    AppendTextBuffer("bDeviceSubClass:                   0x%02X",
        ConnectInfo->DeviceDescriptor.bDeviceSubClass);

    // check the subclass
    if (uIADcount)
    {
        // this device configuration has 1 or more IAD descriptors
        if (ConnectInfo->DeviceDescriptor.bDeviceSubClass == USB_COMMON_SUB_CLASS)
        {
            if (gDoAnnotation)
            {
                AppendTextBuffer("  -> This is the Common Class Sub Class\r\n");
            } else
            {
                AppendTextBuffer("\r\n");
            }
        }
        else
        {
            //@@TestCase A1.5
            //@@ERROR
            //@@Descriptor Field - bDeviceSubClass
            //@@An invalid device sub class used for Multi-interface Function (IAD) device
            AppendTextBuffer("\r\n*!*ERROR: device SubClass should be USB Common Sub Class %d\r\n"\
                "          When IAD descriptor is used\r\n",
                USB_COMMON_SUB_CLASS);
            OOPS();
        }
    }
    else
    {
        // Not an IAD device, so all subclass values are invalid
        if(ConnectInfo->DeviceDescriptor.bDeviceSubClass > 0x00 &&
            ConnectInfo->DeviceDescriptor.bDeviceSubClass < 0xFF)
        {
            //@@TestCase A1.6
            //@@ERROR
            //@@Descriptor Field - bDeviceSubClass
            //@@An invalid device sub class has been defined
            AppendTextBuffer("\r\n*!*ERROR:  bDeviceSubClass of %d is invalid\r\n",
                ConnectInfo->DeviceDescriptor.bDeviceSubClass);
            OOPS();
        } else
        {
            AppendTextBuffer("\r\n");
        }
    }

    AppendTextBuffer("bDeviceProtocol:                   0x%02X",
        ConnectInfo->DeviceDescriptor.bDeviceProtocol);

    // check the protocol
    if (uIADcount)
    {
        // this device configuration has 1 or more IAD descriptors
        if (ConnectInfo->DeviceDescriptor.bDeviceProtocol == USB_IAD_PROTOCOL)
        {
            if (gDoAnnotation)
            {
                AppendTextBuffer("  -> This is the Interface Association Descriptor protocol\r\n");
            }
            else
            {
                AppendTextBuffer("\r\n");
            }
        }
        else
        {
            //@@TestCase A1.7
            //@@ERROR
            //@@Descriptor Field - bDeviceSubClass
            //@@An invalid device sub class used for Multi-interface Function (IAD) device
            AppendTextBuffer("\r\n*!*ERROR: device Protocol should be USB IAD Protocol %d\r\n"\
                "          When IAD descriptor is used\r\n",
                USB_IAD_PROTOCOL);
            OOPS();
        }
    }
    else
    {
        // Not an IAD device, so all subclass values are invalid
        if(ConnectInfo->DeviceDescriptor.bDeviceProtocol > 0x00 &&
            ConnectInfo->DeviceDescriptor.bDeviceProtocol < 0xFF && tog==1)
        {
            //@@TestCase A1.8
            //@@ERROR
            //@@Descriptor Field - bDeviceProtocol
            //@@An invalid device protocol has been defined
            AppendTextBuffer("\r\n*!*ERROR:  bDeviceProtocol of %d is invalid\r\n",
                ConnectInfo->DeviceDescriptor.bDeviceProtocol);
            OOPS();
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
    }

    AppendTextBuffer("bMaxPacketSize0:                   0x%02X",
        ConnectInfo->DeviceDescriptor.bMaxPacketSize0);

    if(gDoAnnotation)
    {
        AppendTextBuffer(" = (%d) Bytes\r\n",
            ConnectInfo->DeviceDescriptor.bMaxPacketSize0);
    }
    else
    {
        AppendTextBuffer("\r\n");
    }

    switch (gDeviceSpeed){
        case UsbLowSpeed:
            if(ConnectInfo->DeviceDescriptor.bMaxPacketSize0 != 8)
            {
                //@@TestCase A1.9
                //@@ERROR
                //@@Descriptor Field - bMaxPacketSize0
                //@@An invalid bMaxPacketSize0 has been defined for a low speed device
                AppendTextBuffer("*!*ERROR:  Low Speed Devices require bMaxPacketSize0 = 8\r\n");
                OOPS();
            }
            break;
        case UsbFullSpeed:
            if(!(ConnectInfo->DeviceDescriptor.bMaxPacketSize0 == 8 ||
                ConnectInfo->DeviceDescriptor.bMaxPacketSize0 == 16 ||
                ConnectInfo->DeviceDescriptor.bMaxPacketSize0 == 32 ||
                ConnectInfo->DeviceDescriptor.bMaxPacketSize0 == 64))
            {
                //@@TestCase A1.10
                //@@ERROR
                //@@Descriptor Field - bMaxPacketSize0
                //@@An invalid bMaxPacketSize0 has been defined for a full speed device
                AppendTextBuffer("*!*ERROR:  Full Speed Devices require bMaxPacketSize0 = 8, 16, 32, or 64\r\n");
                OOPS();
            }
            break;
        case UsbHighSpeed:
            if(ConnectInfo->DeviceDescriptor.bMaxPacketSize0 != 64)
            {
                //@@TestCase A1.11
                //@@ERROR
                //@@Descriptor Field - bMaxPacketSize0
                //@@An invalid bMaxPacketSize0 has been defined for a high speed device
                AppendTextBuffer("*!*ERROR:  High Speed Devices require bMaxPacketSize0 = 64\r\n");
                OOPS();
            }
            break;
        case UsbSuperSpeed:
            if(ConnectInfo->DeviceDescriptor.bMaxPacketSize0 != 9)
            {
                AppendTextBuffer("*!*ERROR:  SuperSpeed Devices require bMaxPacketSize0 = 9 (512)\r\n");
                OOPS();
            }
            break;
    }

    AppendTextBuffer("idVendor:                        0x%04X",
        ConnectInfo->DeviceDescriptor.idVendor);

    if (gDoAnnotation)
    {
        VendorString = GetVendorString(ConnectInfo->DeviceDescriptor.idVendor);
        if (VendorString != NULL)
        {
            AppendTextBuffer(" = %s\r\n",
                VendorString);
        }
    }
    else {AppendTextBuffer("\r\n");}

    AppendTextBuffer("idProduct:                       0x%04X\r\n",
        ConnectInfo->DeviceDescriptor.idProduct);

    AppendTextBuffer("bcdDevice:                       0x%04X\r\n",
        ConnectInfo->DeviceDescriptor.bcdDevice);

    AppendTextBuffer("iManufacturer:                     0x%02X\r\n",
        ConnectInfo->DeviceDescriptor.iManufacturer);

    if (ConnectInfo->DeviceDescriptor.iManufacturer && gDoAnnotation)
    {
        DisplayStringDescriptor(ConnectInfo->DeviceDescriptor.iManufacturer,
            StringDescs,
            info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);
    }

    AppendTextBuffer("iProduct:                          0x%02X\r\n",
        ConnectInfo->DeviceDescriptor.iProduct);

    if (ConnectInfo->DeviceDescriptor.iProduct && gDoAnnotation)
    {
        DisplayStringDescriptor(ConnectInfo->DeviceDescriptor.iProduct,
            StringDescs,
            info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);
    }

    AppendTextBuffer("iSerialNumber:                     0x%02X\r\n",
        ConnectInfo->DeviceDescriptor.iSerialNumber);

    if (ConnectInfo->DeviceDescriptor.iSerialNumber && gDoAnnotation)
    {
        DisplayStringDescriptor(ConnectInfo->DeviceDescriptor.iSerialNumber,
            StringDescs,
            info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);
    }

    AppendTextBuffer("bNumConfigurations:                0x%02X\r\n",
        ConnectInfo->DeviceDescriptor.bNumConfigurations);

    if(ConnectInfo->DeviceDescriptor.bNumConfigurations != 1)
    {
        //@@TestCase A1.12
        //@@CAUTION
        //@@Descriptor Field - bNumConfigurations
        //@@Most host controllers do not handle more than one configuration
        AppendTextBuffer("*!*CAUTION:    Most host controllers will only work with "\
            "one configuration per speed\r\n");
        OOPS();
    }

    if (ConnectInfo->NumberOfOpenPipes)
    {
        AppendTextBuffer("\r\n          ---===>Open Pipes<===---\r\n");
        DisplayPipeInfo(ConnectInfo->NumberOfOpenPipes,
                        ConnectInfo->PipeList);
    }

    return;
}

/*****************************************************************************

DisplayPipeInfo()

NumPipes - Number of pipe for we info should be displayed.

PipeInfo - Info about the pipes.

*****************************************************************************/

VOID
DisplayPipeInfo (
    ULONG           NumPipes,
    USB_PIPE_INFO  *PipeInfo
    )
{
    ULONG i = 0;

    for (i = 0; i < NumPipes; i++)
    {
        DisplayEndpointDescriptor(&PipeInfo[i].EndpointDescriptor, NULL, NULL, 0, FALSE);
    }

}

/*****************************************************************************

GetControllerFlavorString()

Returns the text for given controller flavor

*****************************************************************************/
PCHAR GetControllerFlavorString(USB_CONTROLLER_FLAVOR flavor)
{
    return(GetStringFromList(slControllerFlavor,
                        sizeof(slControllerFlavor) / sizeof(STRINGLIST),
                        flavor,
                        STR_UNKNOWN_CONTROLLER_FLAVOR));
}



/*****************************************************************************

GetPowerStateString()

Returns the descriptive string for given power state

*****************************************************************************/
PCHAR GetPowerStateString(WDMUSB_POWER_STATE powerState)
{
    return(GetStringFromList(slPowerState,
                        sizeof(slPowerState) / sizeof(STRINGLIST),
                        powerState,
                        STR_INVALID_POWER_STATE));
}

/*****************************************************************************

DisplayPowerState()

PUSB_POWER_INFO pUPI - USBUSER.H USB_Power_Info data

*****************************************************************************/

VOID
DisplayPowerState(
    PUSB_POWER_INFO pUPI
    )
{
    AppendTextBuffer("%s\t%s\t%s%s\t\t%s\r\n",
                        GetPowerStateString(pUPI->SystemState),
                        GetPowerStateString(pUPI->HcDevicePowerState),
                        GetPowerStateString(pUPI->RhDevicePowerState),
                        pUPI->CanWakeup ? "Yes" : "",
                        pUPI->IsPowered ? "Yes" : ""
                     );
    return;
}



/*****************************************************************************

ValidateDescAddress()

Given a descriptor address and the Configuration Descriptor length
    (saved in DisplayConfigDesc(), and initialized for each new device)
return TRUE if the descriptor is within the Configuration length
else FALSE

*****************************************************************************/

BOOL
ValidateDescAddress (
    PUSB_COMMON_DESCRIPTOR          commonDesc
    )
{
    if ((PUCHAR) commonDesc + commonDesc->bLength <= g_descEnd)
    {
        return TRUE;
    }
    return FALSE;
}

/*****************************************************************************

DisplayConfigDesc()

ConfigDesc - The Configuration Descriptor, and associated Interface and
Endpoint Descriptors

*****************************************************************************/

VOID
DisplayConfigDesc (
    PUSBDEVICEINFO                  info,
    PUSB_CONFIGURATION_DESCRIPTOR   ConfigDesc,
    PSTRING_DESCRIPTOR_NODE         StringDescs
    )
{
    PUSB_COMMON_DESCRIPTOR          commonDesc = NULL;
    UCHAR                           bInterfaceClass = 0;
    UCHAR                           bInterfaceSubClass = 0;
    UCHAR                           bInterfaceProtocol = 0;
    BOOL                            displayUnknown = FALSE;

    BOOL                            isSS;

    isSS = info->ConnectionInfoV2
        && info->ConnectionInfoV2->Flags.DeviceIsOperatingAtSuperSpeedOrHigher
       ? TRUE
       : FALSE;

    commonDesc = (PUSB_COMMON_DESCRIPTOR)ConfigDesc;

    // initialize global Configuration start/end address and string desc address
    g_pConfigDesc  = ConfigDesc;
    g_pStringDescs = StringDescs;
    g_descEnd      = (PUCHAR)ConfigDesc + ConfigDesc->wTotalLength;

    AppendTextBuffer("\r\n       ---===>Full Configuration Descriptor<===---\r\n");

    do
    {
        displayUnknown = FALSE;

        switch (commonDesc->bDescriptorType)
        {
        case USB_DEVICE_QUALIFIER_DESCRIPTOR_TYPE:
            //@@DisplayConfigDesc - Device Qualifier Descriptor
            if (commonDesc->bLength != sizeof(USB_DEVICE_QUALIFIER_DESCRIPTOR))
            {
                //@@TestCase A2.1
                //@@ERROR
                //@@Descriptor Field - bLength
                //@@The declared length in the device descriptor is not equal to the
                //@@  required length in the USB Device Specification
                AppendTextBuffer("*!*ERROR:  bLength of %d for Device Qualifier incorrect, "\
                    "should be %d\r\n",
                    commonDesc->bLength,
                    sizeof(USB_DEVICE_QUALIFIER_DESCRIPTOR));
                OOPS();
                displayUnknown = TRUE;
                break;
            }
            DisplayDeviceQualifierDescriptor((PUSB_DEVICE_QUALIFIER_DESCRIPTOR)commonDesc);
            break;

        case USB_OTHER_SPEED_CONFIGURATION_DESCRIPTOR_TYPE:
            //@@DisplayConfigDesc - Other Speed Configuration Descriptor
            if (commonDesc->bLength != sizeof(USB_CONFIGURATION_DESCRIPTOR))
            {
                //@@TestCase A2.2
                //@@ERROR
                //@@Descriptor Field - bLength
                //@@The declared length in the device descriptor is not equal to the
                //@@  required length in the USB Device Specification
                AppendTextBuffer("*!*ERROR:  bLength of %d for Other Speed Configuration "\
                    "incorrect, should be %d\r\n",
                    commonDesc->bLength,
                    sizeof(USB_CONFIGURATION_DESCRIPTOR));
                OOPS();
                displayUnknown = TRUE;
            }
            DisplayConfigurationDescriptor(
                (PUSBDEVICEINFO) info,
                (PUSB_CONFIGURATION_DESCRIPTOR)commonDesc,
                StringDescs);
            break;

        case USB_CONFIGURATION_DESCRIPTOR_TYPE:
            //@@DisplayConfigDesc - Configuration Descriptor
            if (commonDesc->bLength != sizeof(USB_CONFIGURATION_DESCRIPTOR))
            {
                //@@TestCase A2.3
                //@@ERROR
                //@@Descriptor Field - bLength
                //@@The declared length in the device descriptor is not equal to the
                //@@required length in the USB Device Specification
                AppendTextBuffer("*!*ERROR:  bLength of %d for Configuration incorrect, "\
                    "should be %d\r\n",
                    commonDesc->bLength,
                    sizeof(USB_CONFIGURATION_DESCRIPTOR));
                OOPS();
                displayUnknown = TRUE;
                break;
            }
            DisplayConfigurationDescriptor((PUSBDEVICEINFO)info,
                (PUSB_CONFIGURATION_DESCRIPTOR)commonDesc,
                StringDescs);
            break;

        case USB_INTERFACE_DESCRIPTOR_TYPE:
            //@@DisplayConfigDesc - Interface Descriptor
            if ((commonDesc->bLength != sizeof(USB_INTERFACE_DESCRIPTOR)) &&
                (commonDesc->bLength != sizeof(USB_INTERFACE_DESCRIPTOR2)))
            {
                //@@TestCase A2.4
                //@@ERROR
                //@@Descriptor Field - bLength
                //@@The declared length in the device descriptor is not equal to the
                //@@required length in the USB Device Specification
                AppendTextBuffer("*!*ERROR:  bLength of %d for Interface incorrect, "\
                    "should be %d or %d\r\n",
                    commonDesc->bLength,
                    sizeof(USB_INTERFACE_DESCRIPTOR),
                    sizeof(USB_INTERFACE_DESCRIPTOR2));
                OOPS();
                displayUnknown = TRUE;
                break;
            }
            bInterfaceClass = ((PUSB_INTERFACE_DESCRIPTOR)commonDesc)->bInterfaceClass;
            bInterfaceSubClass = ((PUSB_INTERFACE_DESCRIPTOR)commonDesc)->bInterfaceSubClass;
            bInterfaceProtocol = ((PUSB_INTERFACE_DESCRIPTOR)commonDesc)->bInterfaceProtocol;

            DisplayInterfaceDescriptor(
                    (PUSB_INTERFACE_DESCRIPTOR)commonDesc,
                    StringDescs,
                    info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);

            break;

        case USB_ENDPOINT_DESCRIPTOR_TYPE:
            {
                PUSB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR epCompDesc = NULL;
                PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR
                                                              sspIsochCompDesc = NULL;


                //@@DisplayConfigDesc - Endpoint Descriptor
                if ((commonDesc->bLength != sizeof(USB_ENDPOINT_DESCRIPTOR)) &&
                    (commonDesc->bLength != sizeof(USB_ENDPOINT_DESCRIPTOR2)))
                {
                    //@@TestCase A2.5
                    //@@ERROR
                    //@@Descriptor Field - bLength
                    //@@The declared length in the device descriptor is not equal to
                    //@@  the required length in the USB Device Specification
                    AppendTextBuffer("*!*ERROR:  bLength of %d for Endpoint incorrect, "\
                        "should be %d or %d\r\n",
                        commonDesc->bLength,
                        sizeof(USB_ENDPOINT_DESCRIPTOR),
                        sizeof(USB_ENDPOINT_DESCRIPTOR2));
                    OOPS();
                    displayUnknown = TRUE;
                    break;
                }

                if (isSS)
                {
                     epCompDesc = (PUSB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR)
                        GetNextDescriptor((PUSB_COMMON_DESCRIPTOR)ConfigDesc, ConfigDesc->wTotalLength, commonDesc, -1);
                }

                if (epCompDesc != NULL &&
                    epCompDesc->bmAttributes.Isochronous.SspCompanion == 1)
                {
                    sspIsochCompDesc = (PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR)
                        GetNextDescriptor((PUSB_COMMON_DESCRIPTOR)ConfigDesc,
                            ConfigDesc->wTotalLength,
                            (PUSB_COMMON_DESCRIPTOR)epCompDesc,
                            -1);
                }

                DisplayEndpointDescriptor((PUSB_ENDPOINT_DESCRIPTOR)commonDesc,
                    epCompDesc,
                    sspIsochCompDesc,
                    bInterfaceClass,
                    TRUE);

                if (sspIsochCompDesc != NULL)
                {
                    commonDesc = (PUSB_COMMON_DESCRIPTOR)sspIsochCompDesc;
                }
                else if (epCompDesc != NULL)
                {
                     commonDesc = (PUSB_COMMON_DESCRIPTOR)epCompDesc;
                }
            }

            break;

        case USB_HID_DESCRIPTOR_TYPE:
            if (commonDesc->bLength < sizeof(USB_HID_DESCRIPTOR))
            {
                OOPS();
                displayUnknown = TRUE;
                break;
            }
            DisplayHidDescriptor((PUSB_HID_DESCRIPTOR)commonDesc);
            break;

        case USB_OTG_DESCRIPTOR_TYPE:
            if (commonDesc->bLength < sizeof(USB_OTG_DESCRIPTOR))
            {
                OOPS();
                displayUnknown = TRUE;
                break;
            }
            DisplayOTGDescriptor((PUSB_OTG_DESCRIPTOR)commonDesc);
            break;

        case USB_IAD_DESCRIPTOR_TYPE:
            if (commonDesc->bLength < sizeof(USB_IAD_DESCRIPTOR))
            {
                OOPS();
                displayUnknown = TRUE;
                break;
            }
            DisplayIADDescriptor((PUSB_IAD_DESCRIPTOR)commonDesc, StringDescs,
                    ConfigDesc->bNumInterfaces,
                    info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);
            break;

        default:
            //@@DisplayConfigDesc - Interface Class Device
            // TODO: BUG: bInterfaceClass is initialized before this code
            switch (bInterfaceClass)
            {
            case USB_DEVICE_CLASS_AUDIO:
                displayUnknown = ! DisplayAudioDescriptor(
                    (PUSB_AUDIO_COMMON_DESCRIPTOR)commonDesc,
                    bInterfaceSubClass);
                break;

            case USB_DEVICE_CLASS_VIDEO:
                displayUnknown = ! DisplayVideoDescriptor(
                    (PVIDEO_SPECIFIC)commonDesc,
                    bInterfaceSubClass,
                    StringDescs,
                    info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);
                break;

            case USB_DEVICE_CLASS_RESERVED:
                //@@TestCase A2.6
                //@@ERROR
                //@@Descriptor Field - bInterfaceClass
                //@@An unknown interface class has been defined
                AppendTextBuffer("*!*ERROR:  %d is a Reserved USB Device Interface Class\r\n",
                    USB_DEVICE_CLASS_RESERVED);
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_COMMUNICATIONS:
                AppendTextBuffer("  -> This is a Communications (CDC Control) USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_HUMAN_INTERFACE:
                AppendTextBuffer("  -> This is a HID USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_MONITOR:
                AppendTextBuffer("  -> This is a Monitor USB Device Interface Class (This may be obsolete)\r\n");
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_PHYSICAL_INTERFACE:
                AppendTextBuffer("  -> This is a Physical Interface USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_POWER:
                if(bInterfaceSubClass == 1 && bInterfaceProtocol == 1)
                {
                    AppendTextBuffer("  -> This is an Image USB Device Interface Class\r\n");
                }
                else
                {
                    AppendTextBuffer("  -> This is a Power USB Device Interface Class (This may be obsolete)\r\n");
                }
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_PRINTER:
                AppendTextBuffer("  -> This is a Printer USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_STORAGE:
                AppendTextBuffer("  -> This is a Mass Storage USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_DEVICE_CLASS_HUB:
                AppendTextBuffer("  -> This is a HUB USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_CDC_DATA_INTERFACE:
                AppendTextBuffer("  -> This is a CDC Data USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_CHIP_SMART_CARD_INTERFACE:
                AppendTextBuffer("  -> This is a Chip/Smart Card USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_CONTENT_SECURITY_INTERFACE:
                AppendTextBuffer("  -> This is a Content Security USB Device Interface Class\r\n");
                displayUnknown = TRUE;
                break;

            case USB_DIAGNOSTIC_DEVICE_INTERFACE:
                if(bInterfaceSubClass == 1 && bInterfaceProtocol == 1)
                {
                    AppendTextBuffer("  -> This is a Reprogrammable USB2 Compliance Diagnostic Device USB Device\r\n");
                }
                else
                {
                    //@@TestCase A2.7
                    //@@CAUTION
                    //@@Descriptor Field - bInterfaceClass
                    //@@An unknown diagnostic interface class device has been defined
                    AppendTextBuffer("*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
                    OOPS();
                }
                displayUnknown = TRUE;
                break;

            case USB_WIRELESS_CONTROLLER_INTERFACE:
                if(bInterfaceSubClass == 1 && bInterfaceProtocol == 1)
                {
                    AppendTextBuffer("  -> This is a Wireless RF Controller USB Device Interface Class with Bluetooth Programming Interface\r\n");
                }
                else
                {
                    //@@TestCase A2.8
                    //@@CAUTION
                    //@@Descriptor Field - bInterfaceClass
                    //@@An unknown wireless controller interface class device has been defined
                    AppendTextBuffer("*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
                    OOPS();
                }
                displayUnknown = TRUE;
                break;

            case USB_APPLICATION_SPECIFIC_INTERFACE:
                AppendTextBuffer("  -> This is an Application Specific USB Device Interface Class\r\n");

                switch(bInterfaceSubClass)
                {
                case 1:
                    AppendTextBuffer("  -> This is a Device Firmware Application Specific USB Device Interface Class\r\n");
                    break;
                case 2:
                    AppendTextBuffer("  -> This is an IrDA Bridge Application Specific USB Device Interface Class\r\n");
                    break;
                case 3:
                    AppendTextBuffer("  -> This is a Test & Measurement Class (USBTMC) Application Specific USB Device Interface Class\r\n");
                    break;
                default:
                    //@@TestCase A2.9
                    //@@CAUTION
                    //@@Descriptor Field - bInterfaceClass
                    //@@A possibly invalid interface class has been defined
                    AppendTextBuffer("*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
                    OOPS();
                }
                displayUnknown = TRUE;
                break;

            default:
                if (bInterfaceClass == USB_DEVICE_CLASS_VENDOR_SPECIFIC)
                {
                    AppendTextBuffer("  -> This is a Vendor Specific USB Device Interface Class\r\n");
                }
                else
                {
                    //@@TestCase A2.10
                    //@@CAUTION
                    //@@Descriptor Field - bInterfaceClass
                    //@@An unknown interface class has been defined
                    AppendTextBuffer("*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
                    OOPS();
                }
                displayUnknown = TRUE;
                break;
            }
            break;
        }

        if (displayUnknown)
        {
            DisplayUnknownDescriptor(commonDesc);
        }
    } while ((commonDesc = GetNextDescriptor((PUSB_COMMON_DESCRIPTOR)ConfigDesc,
                                             ConfigDesc->wTotalLength,
                                             commonDesc,
                                             -1)) != NULL);

#ifdef H264_SUPPORT
    DoAdditionalErrorChecks();
#endif
}


/*****************************************************************************

DisplayDeviceQualifierDescriptor()

*****************************************************************************/

VOID
DisplayDeviceQualifierDescriptor (
    PUSB_DEVICE_QUALIFIER_DESCRIPTOR   DevQualDesc
    )
{
    //@@DisplayDeviceQualifierDescriptor - Device Qualifier Descriptor

    AppendTextBuffer("\r\n          ===>Device Qualifier Descriptor<===\r\n");

    //length checked in DisplayConfigDesc()

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        DevQualDesc->bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        DevQualDesc->bDescriptorType);

    AppendTextBuffer("bcdUSB:                          0x%04X\r\n",
        DevQualDesc->bcdUSB);

    AppendTextBuffer("bDeviceClass:                      0x%02X",
        DevQualDesc->bDeviceClass);

    switch (DevQualDesc->bDeviceClass)
    {
    case USB_INTERFACE_CLASS_DEVICE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> This is an Interface Class Defined Device\r\n");
        }
        break;

    case USB_COMMUNICATION_DEVICE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> This is a Communication Device\r\n");
        }
        break;

    case USB_HUB_DEVICE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> This is a HUB Device\r\n");
        }
        break;

    case USB_DIAGNOSTIC_DEVICE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> This is a Diagnostic Device\r\n");
        }
        break;

    case USB_WIRELESS_CONTROLLER_DEVICE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> This is a Wireless Controller(Bluetooth) Device\r\n");
        }
        break;

    case USB_VENDOR_SPECIFIC_DEVICE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> This is a Vendor Specific Device\r\n");
        }
        break;
    case USB_DEVICE_CLASS_BILLBOARD:
        if (gDoAnnotation)
        {
            AppendTextBuffer("  -> This is a billboard class device\r\n");
        }
        break;
    default:
        //@@TestCase A3.1
        //@@ERROR
        //@@Descriptor Field - bDeviceClass
        //@@An unknown device class has been defined
        AppendTextBuffer("*!*ERROR:  bDeviceClass of %d is invalid\r\n",
            DevQualDesc->bDeviceClass);
        OOPS();
        break;
    }

    AppendTextBuffer("bDeviceSubClass:                   0x%02X\r\n",
        DevQualDesc->bDeviceSubClass);

    if(DevQualDesc->bDeviceSubClass > 0x00 && DevQualDesc->bDeviceSubClass < 0xFF)
    {
        //@@TestCase A3.2
        //@@ERROR
        //@@Descriptor Field - bDeviceSubClass
        //@@An unknown device sub class has been defined
        AppendTextBuffer("*!*ERROR:  bDeviceSubClass of %d is invalid\r\n",
            DevQualDesc->bDeviceSubClass);
        OOPS();
    }

    AppendTextBuffer("bDeviceProtocol:                   0x%02X\r\n",
        DevQualDesc->bDeviceProtocol);

    if(DevQualDesc->bDeviceProtocol > 0x00 && DevQualDesc->bDeviceProtocol < 0xFF)
    {
        //@@TestCase A3.4
        //@@ERROR
        //@@Descriptor Field - bDeviceProtocol
        //@@An invalid device protocol has been defined
        AppendTextBuffer("*!*ERROR:  bDeviceProtocol of %d is invalid",
            DevQualDesc->bDeviceProtocol);
        OOPS();
    }

    //@@TestCase A3.5
    //@@Priority 1
    //@@Descriptor Field - bcdDevice
    //@@We should test to verify a valid bMaxPacketSize0 based on speed
    AppendTextBuffer("bMaxPacketSize0:                   0x%02X",
        DevQualDesc->bMaxPacketSize0);

    if(gDoAnnotation)
    {
        AppendTextBuffer(" = (%d) Bytes\r\n",
            DevQualDesc->bMaxPacketSize0);
    }
    else {AppendTextBuffer("\r\n");}

    AppendTextBuffer("bNumConfigurations:                0x%02X\r\n",
        DevQualDesc->bNumConfigurations);

    if(DevQualDesc->bNumConfigurations != 1)
    {
        //@@TestCase A3.6
        //@@CAUTION
        //@@Descriptor Field - bNumConfigurations
        //@@Most host controllers do not handle more than one configuration
        AppendTextBuffer("*!*CAUTION:    Most host controllers will only work with one configuration per speed\r\n");
        OOPS();
    }

    AppendTextBuffer("bReserved:                         0x%02X\r\n",
        DevQualDesc->bReserved);

    if(DevQualDesc->bReserved != 0)
    {
        AppendTextBuffer("*!*WARNING:    bReserved needs to be set to 0 to be valid\r\n");
        OOPS();
    }


}

VOID
DisplayUsb20ExtensionCapabilityDescriptor (
    PUSB_DEVICE_CAPABILITY_USB20_EXTENSION_DESCRIPTOR extCapDesc
    )
{
    AppendTextBuffer("\r\n          ===>USB 2.0 Extension Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        extCapDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        extCapDesc->bDescriptorType);
    AppendTextBuffer("bDevCapabilityType:                0x%02X\r\n",
        extCapDesc->bDevCapabilityType);
    AppendTextBuffer("bmAttributes:                      0x%08X",
        extCapDesc->bmAttributes);
    if (extCapDesc->bmAttributes.AsUlong & USB_DEVICE_CAPABILITY_USB20_EXTENSION_BMATTRIBUTES_RESERVED_MASK)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("\r\n*!*ERROR: bits 31..2 and bit 0 are reserved and must be 0\r\n");
        }
    }
    if (extCapDesc->bmAttributes.LPMCapable == 1)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Supports Link Power Management protocol\r\n");
        }
    }
    if (extCapDesc->bmAttributes.AsUlong == 0)
    {
        AppendTextBuffer("\r\n");
    }
}

VOID
DisplaySuperSpeedCapabilityDescriptor (
    PUSB_DEVICE_CAPABILITY_SUPERSPEED_USB_DESCRIPTOR ssCapDesc
    )
{
    AppendTextBuffer("\r\n          ===>SuperSpeed USB Device Capability Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        ssCapDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        ssCapDesc->bDescriptorType);
    AppendTextBuffer("bDevCapabilityType:                0x%02X\r\n",
        ssCapDesc->bDevCapabilityType);
    AppendTextBuffer("bmAttributes:                      0x%02X\r\n",
        ssCapDesc->bmAttributes);
    if (ssCapDesc->bmAttributes & USB_DEVICE_CAPABILITY_SUPERSPEED_BMATTRIBUTES_RESERVED_MASK)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("\r\n*!*ERROR: bits 7:2 and bit 0 are reserved\r\n");
        }
    }
    if (ssCapDesc->bmAttributes & USB_DEVICE_CAPABILITY_SUPERSPEED_BMATTRIBUTES_LTM_CAPABLE)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> capable of generating Latency Tolerance Messages\r\n");
        }
    }
    AppendTextBuffer("wSpeedsSupported:                  0x%02X\r\n",
        ssCapDesc->wSpeedsSupported);

    if (ssCapDesc->wSpeedsSupported & USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_LOW)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Supports low-speed operation\r\n");
        }
    }
    if (ssCapDesc->wSpeedsSupported & USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_FULL)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Supports full-speed operation\r\n");
        }
    }
    if (ssCapDesc->wSpeedsSupported & USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_HIGH)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Supports high-speed operation\r\n");
        }
    }
    if (ssCapDesc->wSpeedsSupported & USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_SUPER)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Supports SuperSpeed operation\r\n");
        }
    }
    if (ssCapDesc->wSpeedsSupported & USB_DEVICE_CAPABILITY_SUPERSPEED_SPEEDS_SUPPORTED_RESERVED_MASK)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("\r\n*!*ERROR: bits 15:4 are reserved\r\n");
        }
    }
    if (!gDoAnnotation)
    {
        AppendTextBuffer("\r\n");
    }
    AppendTextBuffer("bFunctionalitySupport:             0x%02X",
        ssCapDesc->bFunctionalitySupport);
    if(gDoAnnotation)
    {
        switch (ssCapDesc->bFunctionalitySupport)
        {
        case UsbLowSpeed:
            AppendTextBuffer(" -> lowest speed = low-speed\r\n");
            break;
        case UsbFullSpeed:
            AppendTextBuffer(" -> lowest speed = full-speed\r\n");
            break;
        case UsbHighSpeed:
            AppendTextBuffer(" -> lowest speed = high-speed\r\n");
            break;
        case UsbSuperSpeed:
            AppendTextBuffer(" -> lowest speed = SuperSpeed\r\n");
            break;
        default:
            AppendTextBuffer("\r\n*!*ERROR: Invalid value\r\n");
            break;
        }
    }
    else
    {
        AppendTextBuffer("\r\n");
    }

    AppendTextBuffer("bU1DevExitLat:                     0x%02X",
        ssCapDesc->bU1DevExitLat);
    if(gDoAnnotation)
    {
        if (ssCapDesc->bU1DevExitLat <= USB_DEVICE_CAPABILITY_SUPERSPEED_U1_DEVICE_EXIT_MAX_VALUE)
        {
            AppendTextBuffer(" -> less than %d micro-seconds\r\n",
                ssCapDesc->bU1DevExitLat);
        }
        else
        {
            AppendTextBuffer("\r\n*!*ERROR: Invalid value\r\n");
        }
    }
    else
    {
        AppendTextBuffer("\r\n");
    }

    AppendTextBuffer("wU2DevExitLat:                     0x%04X",
        ssCapDesc->wU2DevExitLat);
    if(gDoAnnotation)
    {
        if (ssCapDesc->wU2DevExitLat <= USB_DEVICE_CAPABILITY_SUPERSPEED_U2_DEVICE_EXIT_MAX_VALUE)
        {
            AppendTextBuffer(" -> less than %d micro-seconds\r\n",
                ssCapDesc->wU2DevExitLat);
        }
        else
        {
            AppendTextBuffer("\r\n*!*ERROR: Invalid value\r\n");
        }
    }
    else
    {
        AppendTextBuffer("\r\n");
    }
}


VOID
DisplaySuperSpeedPlusCapabilityDescriptor (
    PUSB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_USB_DESCRIPTOR sspCapDesc
    )
{
    UCHAR i;

    AppendTextBuffer("\r\n          ===>SuperSpeed USB Device Capability Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        sspCapDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        sspCapDesc->bDescriptorType);
    AppendTextBuffer("bDevCapabilityType:                0x%02X\r\n",
        sspCapDesc->bDevCapabilityType);
    AppendTextBuffer("bReserved:                         0x%02X\r\n",
        sspCapDesc->bReserved);
    if (sspCapDesc->bReserved != 0)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("*!*ERROR: field is reserved\r\n");
        }
    }

    AppendTextBuffer("bmAttributes:                      0x%08X\r\n",
        sspCapDesc->bmAttributes.AsUlong);
    AppendTextBuffer("  SublinkSpeedAttrCount:           0x%02X\r\n",
        sspCapDesc->bmAttributes.SublinkSpeedAttrCount);
    AppendTextBuffer("  SublinkSpeedIDCount:             0x%02X\r\n",
        sspCapDesc->bmAttributes.SublinkSpeedIDCount);

    AppendTextBuffer("wFunctionalitySupport:             0x%04X\r\n",
        sspCapDesc->wFunctionalitySupport.AsUshort);
    AppendTextBuffer("  SublinkSpeedAttrID:              0x%02X\r\n",
        sspCapDesc->wFunctionalitySupport.SublinkSpeedAttrID);
    AppendTextBuffer("  Reserved:                        0x%02X\r\n",
        sspCapDesc->wFunctionalitySupport.Reserved);
    if (sspCapDesc->wFunctionalitySupport.Reserved != 0)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("*!*ERROR: field is reserved\r\n");
        }
    }
    AppendTextBuffer("  MinRxLaneCount:                  0x%02X\r\n",
        sspCapDesc->wFunctionalitySupport.MinRxLaneCount);
    AppendTextBuffer("  MinTxLaneCount:                  0x%02X\r\n",
        sspCapDesc->wFunctionalitySupport.MinTxLaneCount);

    AppendTextBuffer("wReserved:                         0x%04X\r\n",
        sspCapDesc->wReserved);
    if (sspCapDesc->wReserved != 0)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("*!*ERROR: field is reserved\r\n");
        }
    }

    // The array size = SublinkSpeedAttrCount + 1
    for (i = 0; i <= sspCapDesc->bmAttributes.SublinkSpeedAttrCount; i++)
    {
        PUSB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_SPEED speed = &sspCapDesc->bmSublinkSpeedAttr[i];

        AppendTextBuffer("bmSublinkSpeedAttr #:              0x%02X\r\n",
            i);
        AppendTextBuffer("  SublinkSpeedAttrID:              0x%02X\r\n",
            speed->SublinkSpeedAttrID);
        AppendTextBuffer("  LaneSpeedExponent:               0x%02X",
            speed->LaneSpeedExponent);
        if(gDoAnnotation)
        {
            switch (speed->LaneSpeedExponent)
            {
            case 0:
                AppendTextBuffer(" -> Bits per second\r\n");
                break;
            case 1:
                AppendTextBuffer(" -> Kb/s\r\n");
                break;
            case 2:
                AppendTextBuffer(" -> Mb/s\r\n");
                break;
            case 3:
                AppendTextBuffer(" -> Gb/s\r\n");
                break;
            }
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        AppendTextBuffer("  SublinkTypeMode:                 0x%02X",
            speed->SublinkTypeMode);
        if(gDoAnnotation)
        {
            switch (speed->SublinkTypeMode)
            {
            case 0:
                AppendTextBuffer(" -> Symmetric\r\n");
                break;
            case 1:
                AppendTextBuffer(" -> Asymmetric\r\n");
                break;
            }
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        AppendTextBuffer("  SublinkTypeDir:                  0x%02X",
            speed->SublinkTypeDir);
        if(gDoAnnotation)
        {
            switch (speed->SublinkTypeDir)
            {
            case 0:
                AppendTextBuffer(" -> Receive mode\r\n");
                break;
            case 1:
                AppendTextBuffer(" -> Transmit mode\r\n");
                break;
            }
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        AppendTextBuffer("  Reserved:                        0x%02X\r\n",
            speed->Reserved);
        AppendTextBuffer("  LinkProtocol:                    0x%02X",
            speed->LinkProtocol);
        if(gDoAnnotation)
        {
            switch (speed->LinkProtocol)
            {
            case 0:
                AppendTextBuffer(" -> SuperSpeed\r\n");
                break;
            case 1:
                AppendTextBuffer(" -> SuperSpeedPlus\r\n");
                break;
            default:
                AppendTextBuffer(" -> Reserved\r\n");
                break;
            }
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        AppendTextBuffer("  LaneSpeedMantissa:               0x%04X\r\n",
            speed->LaneSpeedMantissa);
    }
}


VOID
DisplayPlatformCapabilityDescriptor (
    PUSB_DEVICE_CAPABILITY_PLATFORM_DESCRIPTOR platformCapDesc
    )
{
    LPGUID pGuid;

    AppendTextBuffer("\r\n          ===>Platform Capability Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        platformCapDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        platformCapDesc->bDescriptorType);
    AppendTextBuffer("bDevCapabilityType:                0x%02X\r\n",
        platformCapDesc->bDevCapabilityType);

    AppendTextBuffer("bReserved:                         0x%02X\r\n",
        platformCapDesc->bReserved);
    if (platformCapDesc->bReserved != 0)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("*!*ERROR: field is reserved\r\n");
        }
    }

    pGuid = (LPGUID)&platformCapDesc->PlatformCapabilityUuid;
    AppendTextBuffer("Platform Capability UUID:          ");
    AppendTextBuffer("%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X\r\n",
        pGuid->Data1,
        pGuid->Data2,
        pGuid->Data3,
        pGuid->Data4[0],
        pGuid->Data4[1],
        pGuid->Data4[2],
        pGuid->Data4[3],
        pGuid->Data4[4],
        pGuid->Data4[5],
        pGuid->Data4[6],
        pGuid->Data4[7]);

    DisplayRemainingUnknownDescriptor((PUCHAR)platformCapDesc,
                                        (ULONG)offsetof(USB_DEVICE_CAPABILITY_PLATFORM_DESCRIPTOR, CapabililityData),
                                        platformCapDesc->bLength);
}


VOID
DisplayContainerIdCapabilityDescriptor (
    PUSB_DEVICE_CAPABILITY_CONTAINER_ID_DESCRIPTOR containerIdCapDesc
    )
{
    LPGUID pGuid;

    AppendTextBuffer("\r\n          ===>Container ID Capability Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        containerIdCapDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        containerIdCapDesc->bDescriptorType);
    AppendTextBuffer("bDevCapabilityType:                0x%02X\r\n",
        containerIdCapDesc->bDevCapabilityType);
    AppendTextBuffer("bReserved:                         0x%02X\r\n",
        containerIdCapDesc->bReserved);
    if (containerIdCapDesc->bReserved != 0)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("*!*ERROR: field is reserved\r\n");
        }
    }

    pGuid = (LPGUID)containerIdCapDesc->ContainerID;
    AppendTextBuffer("Container ID:                      ");
    AppendTextBuffer("%08X-%04X-%04X-%02X%02X-%02X%02X%02X%02X%02X%02X\r\n",
        pGuid->Data1,
        pGuid->Data2,
        pGuid->Data3,
        pGuid->Data4[0],
        pGuid->Data4[1],
        pGuid->Data4[2],
        pGuid->Data4[3],
        pGuid->Data4[4],
        pGuid->Data4[5],
        pGuid->Data4[6],
        pGuid->Data4[7]);
}

VOID
DisplayBillboardCapabilityDescriptor (
    PUSBDEVICEINFO info,
    PUSB_DEVICE_CAPABILITY_BILLBOARD_DESCRIPTOR billboardCapDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs
    )
{
    UCHAR i = 0;
    UCHAR bNumAlternateModes = 0;
    UCHAR alternateModeConfiguration = 0;
    UCHAR adjustedBLength = 0;

    AppendTextBuffer("\r\n          ===>Billboard Capability Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X",
        billboardCapDesc->bLength);

    adjustedBLength = sizeof(USB_DEVICE_CAPABILITY_BILLBOARD_DESCRIPTOR) +
        sizeof(billboardCapDesc->AlternateMode[0]) * (billboardCapDesc->bNumberOfAlternateModes - 1);
    AppendTextBuffer("  -> Actual Length: 0x%02X\r\n", adjustedBLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        billboardCapDesc->bDescriptorType);
    AppendTextBuffer("bDevCapabilityType:                0x%02X  -> Billboard capability\r\n",
        billboardCapDesc->bDevCapabilityType);
    AppendTextBuffer("iAdditionalInfoURL:                0x%02X  ->",
        billboardCapDesc->iAddtionalInfoURL);
    if (billboardCapDesc->iAddtionalInfoURL && gDoAnnotation) {
        DisplayStringDescriptor(billboardCapDesc->iAddtionalInfoURL,
            StringDescs,
            info->DeviceInfoNode != NULL ? info->DeviceInfoNode->LatestDevicePowerState : PowerDeviceUnspecified);
    }
    AppendTextBuffer("bNumberOfAlternateModes:           0x%02X\r\n",
        billboardCapDesc->bNumberOfAlternateModes);

    if (billboardCapDesc->bNumberOfAlternateModes > BILLBOARD_MAX_NUM_ALT_MODE)
    {
        AppendTextBuffer("*!*ERROR: Invalid bNumberofAlternateModes\r\n");
    }
    AppendTextBuffer("bPreferredAlternateMode:           0x%02X\r\n",
        billboardCapDesc->bPreferredAlternateMode);

    AppendTextBuffer("VCONN Power:                       0x%04X",
        billboardCapDesc->VconnPower);

    if (billboardCapDesc->VconnPower.NoVconnPowerRequired)
    {
        AppendTextBuffer("  -> The adapter does not require Vconn Power. Bits 2..0 ignored\r\n");
    }
    else
    {
        switch (billboardCapDesc->VconnPower.VConnPowerNeededForFullFunctionality)
        {
        case 0:
            AppendTextBuffer("  -> 1W needed by adapter for full functionality\r\n");
            break;
        case 1:
            AppendTextBuffer("  -> 1.5W needed by adapter for full functionality\r\n");
            break;
        case 7:
            AppendTextBuffer("  -> *!*ERROR: VConnPowerNeededForFullFunctionality - Reserved value being used\r\n");
            break;
        default:
            AppendTextBuffer("  -> %2XW needed by adapter for full functionality\r\n", billboardCapDesc->VconnPower.VConnPowerNeededForFullFunctionality);
        }
    }

    if (billboardCapDesc->VconnPower.Reserved)
    {
        AppendTextBuffer("*!*ERROR: Reserved bits in VCONN Power being used\r\n");
    }
    if (billboardCapDesc->bReserved)
    {
        AppendTextBuffer("*!*ERROR: bReserved being used\r\n");
    }


    bNumAlternateModes = billboardCapDesc->bNumberOfAlternateModes;
    if (bNumAlternateModes > BILLBOARD_MAX_NUM_ALT_MODE)
    {
        bNumAlternateModes = BILLBOARD_MAX_NUM_ALT_MODE;
    }
    if (bNumAlternateModes > 0)
    {
        AppendTextBuffer("\r\nAlternate Modes Identified:\r\n");
    }
    for (i = 0; i < bNumAlternateModes; i++)
    {
        alternateModeConfiguration = ((billboardCapDesc->bmConfigured[i / 4]) >> ((i % 4) * 2)) & 0x3;
        AppendTextBuffer("wSVID - 0x%04X  bAlternateMode - 0x%02X   ->",
            billboardCapDesc->AlternateMode[i].wSVID,
            billboardCapDesc->AlternateMode[i].bAlternateMode,
            billboardCapDesc->AlternateMode[i].iAlternateModeSetting);

        switch (alternateModeConfiguration)
        {
        case 0:
            AppendTextBuffer("Unspecified Error\r\n");
            break;
        case 1:
            AppendTextBuffer("Alternate Mode configuration not attempted\r\n");
            break;
        case 2:
            AppendTextBuffer("Alternate Mode configuration attempted but unsuccessful\r\n");
            break;
        case 3:
            AppendTextBuffer("Alternate Mode configuration successful\r\n");
            break;
        }
        AppendTextBuffer("iAlternateModeString - 0x%02X  ", billboardCapDesc->AlternateMode[i].iAlternateModeSetting);
        if (billboardCapDesc->AlternateMode[i].iAlternateModeSetting && gDoAnnotation)
        {
            DisplayStringDescriptor(billboardCapDesc->AlternateMode[i].iAlternateModeSetting,
                StringDescs,
                info->DeviceInfoNode != NULL ? info->DeviceInfoNode->LatestDevicePowerState : PowerDeviceUnspecified);
        }
        else
        {
            AppendTextBuffer("\r\n");
        }
        AppendTextBuffer("\r\n");
    }
}


#ifdef USB_DEVICE_CAPABILITY_CONFIGURATION_SUMMARY

VOID
DisplayConfigurationSummaryCapabilityDescriptor (
    PUSB_DEVICE_CAPABILITY_CONFIGURATION_SUMMARY_DESCRIPTOR configSummaryCapDesc
    )
{
    UCHAR i;
    AppendTextBuffer("\r\n          ===>Configuration Summary Capability Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        configSummaryCapDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        configSummaryCapDesc->bDescriptorType);
    AppendTextBuffer("bDevCapabilityType:                0x%02X\r\n",
        configSummaryCapDesc->bDevCapabilityType);

    AppendTextBuffer("bcdVersion:                        0x%04X\r\n",
        configSummaryCapDesc->bcdVersion);
    AppendTextBuffer("bConfigurationValue:               0x%02X\r\n",
        configSummaryCapDesc->bConfigurationValue);
    AppendTextBuffer("bMaxPower:                         0x%02X\r\n",
        configSummaryCapDesc->bMaxPower);
    AppendTextBuffer("bNumFunctions:                     0x%02X\r\n",
        configSummaryCapDesc->bNumFunctions);

    for (i = 0; i < configSummaryCapDesc->bNumFunctions; i++)
    {
        AppendTextBuffer("Function #:                        0x%02X\r\n",
            i);
        AppendTextBuffer("  bClass:                          0x%02X\r\n",
            configSummaryCapDesc->Function[i].bClass);
        AppendTextBuffer("  bSubClass:                       0x%02X\r\n",
            configSummaryCapDesc->Function[i].bSubClass);
        AppendTextBuffer("  bProtocol:                       0x%02X\r\n",
            configSummaryCapDesc->Function[i].bProtocol);
    }
}

#endif

/*****************************************************************************

DisplayBosDescriptor()

BosDesc - The Binary Object Store (BOS) Descriptor, and associated Descriptors

*****************************************************************************/

VOID
DisplayBosDescriptor (
    PUSBDEVICEINFO          info,
    PUSB_BOS_DESCRIPTOR     BosDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs
    )
{
    PUSB_COMMON_DESCRIPTOR            commonDesc = NULL;
    PUSB_DEVICE_CAPABILITY_DESCRIPTOR capDesc = NULL;

    AppendTextBuffer("\r\n          ===>BOS Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        BosDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        BosDesc->bDescriptorType);
    AppendTextBuffer("wTotalLength:                      0x%04X\r\n",
        BosDesc->wTotalLength);
    AppendTextBuffer("bNumDeviceCaps:                    0x%02X\r\n",
        BosDesc->bNumDeviceCaps);

    commonDesc = (PUSB_COMMON_DESCRIPTOR)BosDesc;

    while ((commonDesc = GetNextDescriptor((PUSB_COMMON_DESCRIPTOR)BosDesc,
                                          BosDesc->wTotalLength,
                                          commonDesc,
                                          -1)) != NULL)
    {
        switch (commonDesc->bDescriptorType)
        {
        case USB_DEVICE_CAPABILITY_DESCRIPTOR_TYPE:

            capDesc = (PUSB_DEVICE_CAPABILITY_DESCRIPTOR)commonDesc;

            switch (capDesc->bDevCapabilityType)
            {
            case USB_DEVICE_CAPABILITY_USB20_EXTENSION:
                DisplayUsb20ExtensionCapabilityDescriptor((PUSB_DEVICE_CAPABILITY_USB20_EXTENSION_DESCRIPTOR)capDesc);
                break;
            case USB_DEVICE_CAPABILITY_SUPERSPEED_USB:
                DisplaySuperSpeedCapabilityDescriptor((PUSB_DEVICE_CAPABILITY_SUPERSPEED_USB_DESCRIPTOR)capDesc);
                break;
            case USB_DEVICE_CAPABILITY_CONTAINER_ID:
                DisplayContainerIdCapabilityDescriptor((PUSB_DEVICE_CAPABILITY_CONTAINER_ID_DESCRIPTOR)capDesc);
                break;
            case USB_DEVICE_CAPABILITY_PLATFORM:
                DisplayPlatformCapabilityDescriptor((PUSB_DEVICE_CAPABILITY_PLATFORM_DESCRIPTOR)capDesc);
                break;
            case USB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_USB:
                DisplaySuperSpeedPlusCapabilityDescriptor((PUSB_DEVICE_CAPABILITY_SUPERSPEEDPLUS_USB_DESCRIPTOR)capDesc);
                break;
            case USB_DEVICE_CAPABILITY_BILLBOARD:
                DisplayBillboardCapabilityDescriptor((PUSBDEVICEINFO) info, (PUSB_DEVICE_CAPABILITY_BILLBOARD_DESCRIPTOR) capDesc, StringDescs);
                break;
#ifdef USB_DEVICE_CAPABILITY_CONFIGURATION_SUMMARY
            case USB_DEVICE_CAPABILITY_CONFIGURATION_SUMMARY:
                DisplayConfigurationSummaryCapabilityDescriptor((PUSB_DEVICE_CAPABILITY_CONFIGURATION_SUMMARY_DESCRIPTOR)capDesc);
                break;
#endif
            default:
                AppendTextBuffer("\r\n          ===>Unknown Capability Descriptor<===\r\n");

                AppendTextBuffer("bLength:                           0x%02X\r\n",
                    capDesc->bLength);
                AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
                    capDesc->bDescriptorType);
                AppendTextBuffer("bDevCapabilityType:                0x%02X\r\n",
                    capDesc->bDevCapabilityType);

                DisplayRemainingUnknownDescriptor((PUCHAR)commonDesc,
                                                  (ULONG)sizeof(USB_DEVICE_CAPABILITY_DESCRIPTOR),
                                                  commonDesc->bLength);
                break;
            }
            break;

        default:
            DisplayUnknownDescriptor(commonDesc);
            break;
        }
    }
}


/*****************************************************************************

DisplayConfigurationDescriptor()

*****************************************************************************/

VOID
DisplayConfigurationDescriptor (
    PUSBDEVICEINFO                  info,
    PUSB_CONFIGURATION_DESCRIPTOR   ConfigDesc,
    PSTRING_DESCRIPTOR_NODE         StringDescs
    )
{
    UINT    uCount = 0;
    BOOL    isSS;


    isSS = info->ConnectionInfoV2
           && (info->ConnectionInfoV2->Flags.DeviceIsOperatingAtSuperSpeedOrHigher ||
               info->ConnectionInfoV2->Flags.DeviceIsOperatingAtSuperSpeedPlusOrHigher)
           ? TRUE
           : FALSE;

    AppendTextBuffer("\r\n          ===>Configuration Descriptor<===\r\n");
    //@@DisplayConfigurationDescriptor - Configuration Descriptor

    //length checked in DisplayConfigDesc()

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        ConfigDesc->bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        ConfigDesc->bDescriptorType);

    //@@TestCase A4.1
    //@@Priority 1
    //@@Descriptor Field - wTotalLength
    //@@Verify Configuration length is valid
    AppendTextBuffer("wTotalLength:                    0x%04X",
        ConfigDesc->wTotalLength);
    uCount = GetConfigurationSize(info);
    if (uCount != ConfigDesc->wTotalLength) {
        AppendTextBuffer("\r\n*!*ERROR: Invalid total configuration size 0x%02X, should be 0x%02X\r\n",
            ConfigDesc->wTotalLength, uCount);
    } else {
        AppendTextBuffer("  -> Validated\r\n");
    }

    //@@TestCase A4.2
    //@@Priority 1
    //@@Descriptor Field - bNumInterfaces
    //@@Verify the number of interfaces is valid
    AppendTextBuffer("bNumInterfaces:                    0x%02X\r\n",
        ConfigDesc->bNumInterfaces);

/* Need to check spec vs composite devices
    uCount = GetInterfaceCount(info);
    if (uCount != ConfigDesc->bNumInterfaces) {
        AppendTextBuffer("\r\n*!*ERROR: Invalid total Interfaces %d, should be %d\r\n",
            ConfigDesc->bNumInterfaces, uCount);
    } else {
        AppendTextBuffer("  -> Validated\r\n");
    }
*/

    AppendTextBuffer("bConfigurationValue:               0x%02X\r\n",
        ConfigDesc->bConfigurationValue);

    if(ConfigDesc->bConfigurationValue != 1)
    {
        //@@TestCase A4.3
        //@@CAUTION
        //@@Descriptor Field - bConfigurationValue
        //@@Most host controllers do not handle more than one configuration
        AppendTextBuffer("*!*CAUTION:    Most host controllers will only work with one configuration per speed\r\n");
        OOPS();
    }

    AppendTextBuffer("iConfiguration:                    0x%02X\r\n",
        ConfigDesc->iConfiguration);

    if (ConfigDesc->iConfiguration && gDoAnnotation)
    {
        DisplayStringDescriptor(ConfigDesc->iConfiguration,
            StringDescs,
            info->DeviceInfoNode != NULL? info->DeviceInfoNode->LatestDevicePowerState: PowerDeviceUnspecified);
    }

    AppendTextBuffer("bmAttributes:                      0x%02X",
        ConfigDesc->bmAttributes);

    if (info->ConnectionInfo->DeviceDescriptor.bcdUSB == 0x0100)
    {
        if (ConfigDesc->bmAttributes & USB_CONFIG_SELF_POWERED)
        {
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> Self Powered\r\n");
            }
        }
        if (ConfigDesc->bmAttributes & USB_CONFIG_BUS_POWERED)
        {
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> Bus Powered\r\n");
            }
        }
    }
    else
    {
        if (ConfigDesc->bmAttributes & USB_CONFIG_SELF_POWERED)
        {
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> Self Powered\r\n");
            }
        }
        else
        {
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> Bus Powered\r\n");
            }
        }
        if ((ConfigDesc->bmAttributes & USB_CONFIG_BUS_POWERED) == 0)
        {
            AppendTextBuffer("\r\n*!*ERROR:    Bit 7 is reserved and must be set\r\n");
            OOPS();
        }
    }

    if (ConfigDesc->bmAttributes & USB_CONFIG_REMOTE_WAKEUP)
    {
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Remote Wakeup\r\n");
        }
    }

    if (ConfigDesc->bmAttributes & USB_CONFIG_RESERVED)
    {
        //@@TestCase A4.4
        //@@WARNING
        //@@Descriptor Field - bmAttributes
        //@@A bit has been set in reserved space
        AppendTextBuffer("\r\n*!*ERROR:    Bits 4...0 are reserved\r\n");
        OOPS();
    }

    AppendTextBuffer("MaxPower:                          0x%02X",
        ConfigDesc->MaxPower);

    if(gDoAnnotation)
    {
        AppendTextBuffer(" = %3d mA\r\n",
            isSS ? ConfigDesc->MaxPower * 8 : ConfigDesc->MaxPower * 2);
    }
    else {AppendTextBuffer("\r\n");}

}

/*****************************************************************************

DisplayInterfaceDescriptor()

*****************************************************************************/

VOID
DisplayInterfaceDescriptor (
    PUSB_INTERFACE_DESCRIPTOR   InterfaceDesc,
    PSTRING_DESCRIPTOR_NODE     StringDescs,
    DEVICE_POWER_STATE          LatestDevicePowerState
    )
{
    //@@DisplayInterfaceDescriptor - Interface Descriptor
    AppendTextBuffer("\r\n          ===>Interface Descriptor<===\r\n");

    //length checked in DisplayConfigDesc()
    AppendTextBuffer("bLength:                           0x%02X\r\n",
        InterfaceDesc->bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        InterfaceDesc->bDescriptorType);

    //@@TestCase A5.1
    //@@Priority 1
    //@@Descriptor Field - bInterfaceNumber
    //@@Question - Should we test to verify bInterfaceNumber is valid?
    AppendTextBuffer("bInterfaceNumber:                  0x%02X\r\n",
        InterfaceDesc->bInterfaceNumber);

    //@@TestCase A5.2
    //@@Priority 1
    //@@Descriptor Field - bAlternateSetting
    //@@Question - Should we test to verify bAlternateSetting is valid?
    AppendTextBuffer("bAlternateSetting:                 0x%02X\r\n",
        InterfaceDesc->bAlternateSetting);

    //@@TestCase A5.3
    //@@Priority 1
    //@@Descriptor Field - bNumEndpoints
    //@@Question - Should we test to verify bNumEndpoints is valid?
    AppendTextBuffer("bNumEndpoints:                     0x%02X\r\n",
        InterfaceDesc->bNumEndpoints);

    AppendTextBuffer("bInterfaceClass:                   0x%02X",
        InterfaceDesc->bInterfaceClass);

    switch (InterfaceDesc->bInterfaceClass)
    {
    case USB_DEVICE_CLASS_AUDIO:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Audio Interface Class\r\n");
        }

        AppendTextBuffer("bInterfaceSubClass:                0x%02X",
            InterfaceDesc->bInterfaceSubClass);

        if(gDoAnnotation)
        {
            switch (InterfaceDesc->bInterfaceSubClass)
            {
            case USB_AUDIO_SUBCLASS_AUDIOCONTROL:
                AppendTextBuffer("  -> Audio Control Interface SubClass\r\n");
                break;

            case USB_AUDIO_SUBCLASS_AUDIOSTREAMING:
                AppendTextBuffer("  -> Audio Streaming Interface SubClass\r\n");
                break;

            case USB_AUDIO_SUBCLASS_MIDISTREAMING:
                AppendTextBuffer("  -> MIDI Streaming Interface SubClass\r\n");
                break;

            default:
                //@@TestCase A5.4
                //@@CAUTION
                //@@Descriptor Field - bInterfaceSubClass
                //@@Invalid bInterfaceSubClass
                AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid bInterfaceSubClass\r\n");
                OOPS();
                break;
            }
        }
        break;

    case USB_DEVICE_CLASS_VIDEO:
        if(gDoAnnotation)
            AppendTextBuffer("  -> Video Interface Class\r\n");

        AppendTextBuffer("bInterfaceSubClass:                0x%02X",
            InterfaceDesc->bInterfaceSubClass);

        switch(InterfaceDesc->bInterfaceSubClass)
        {
        case VIDEO_SUBCLASS_CONTROL:
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> Video Control Interface SubClass\r\n");
            }
            break;

        case VIDEO_SUBCLASS_STREAMING:
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> Video Streaming Interface SubClass\r\n");
            }
            break;

        default:
            //@@TestCase A5.5
            //@@CAUTION
            //@@Descriptor Field - bInterfaceSubClass
            //@@Invalid bInterfaceSubClass
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid bInterfaceSubClass\r\n");
            OOPS();
            break;
        }
        break;

    case USB_DEVICE_CLASS_HUMAN_INTERFACE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> HID Interface Class\r\n");
        }
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_HUB:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> HUB Interface Class\r\n");
        }
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_RESERVED:
        //@@TestCase A5.6
        //@@CAUTION
        //@@Descriptor Field - bInterfaceClass
        //@@A reserved USB Device Interface Class has been defined
        AppendTextBuffer("\r\n*!*CAUTION:  %d is a Reserved USB Device Interface Class\r\n",
            USB_DEVICE_CLASS_RESERVED);
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_COMMUNICATIONS:
        AppendTextBuffer("  -> This is Communications (CDC Control) USB Device Interface Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_MONITOR:
        AppendTextBuffer("  -> This is a Monitor USB Device Interface Class*** (This may be obsolete)\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_PHYSICAL_INTERFACE:
        AppendTextBuffer("  -> This is a Physical Interface USB Device Interface Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_POWER:
        if(InterfaceDesc->bInterfaceSubClass == 1 && InterfaceDesc->bInterfaceProtocol == 1)
        {
            AppendTextBuffer("  -> This is an Image USB Device Interface Class\r\n");
        }
        else
        {
            AppendTextBuffer("  -> This is a Power USB Device Interface Class (This may be obsolete)\r\n");
        }
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_PRINTER:
        AppendTextBuffer("  -> This is a Printer USB Device Interface Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DEVICE_CLASS_STORAGE:
        AppendTextBuffer("  -> This is a Mass Storage USB Device Interface Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_CDC_DATA_INTERFACE:
        AppendTextBuffer("  -> This is a CDC Data USB Device Interface Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_CHIP_SMART_CARD_INTERFACE:
        AppendTextBuffer("  -> This is a Chip/Smart Card USB Device Interface Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_CONTENT_SECURITY_INTERFACE:
        AppendTextBuffer("  -> This is a Content Security USB Device Interface Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_DIAGNOSTIC_DEVICE_INTERFACE:
        if(InterfaceDesc->bInterfaceSubClass == 1 && InterfaceDesc->bInterfaceProtocol == 1)
        {
            AppendTextBuffer("  -> This is a Reprogrammable USB2 Compliance Diagnostic Device USB Device\r\n");
        }
        else
        {
            //@@TestCase A5.7
            //@@CAUTION
            //@@Descriptor Field - bInterfaceClass
            //@@Invalid Interface Class
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
            OOPS();
        }
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_WIRELESS_CONTROLLER_INTERFACE:
        if(InterfaceDesc->bInterfaceSubClass == 1 && InterfaceDesc->bInterfaceProtocol == 1)
        {
            AppendTextBuffer("  -> This is a Wireless RF Controller USB Device Interface Class with Bluetooth Programming Interface\r\n");
        }
        else
        {
            //@@TestCase A5.8
            //@@CAUTION
            //@@Descriptor Field - bInterfaceClass
            //@@Invalid Interface Class
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
            OOPS();
        }
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;

    case USB_APPLICATION_SPECIFIC_INTERFACE:
        AppendTextBuffer("  -> This is an Application Specific USB Device Interface Class\r\n");

        switch(InterfaceDesc->bInterfaceSubClass)
        {
        case 1:
            AppendTextBuffer("  -> This is a Device Firmware Application Specific USB Device Interface Class\r\n");
            break;
        case 2:
            AppendTextBuffer("  -> This is an IrDA Bridge Application Specific USB Device Interface Class\r\n");
            break;
        case 3:
            AppendTextBuffer("  -> This is a Test & Measurement Class (USBTMC) Application Specific USB Device Interface Class\r\n");
            break;
        default:
            //@@TestCase A5.9
            //@@CAUTION
            //@@Descriptor Field - bInterfaceClass
            //@@Invalid Interface Class
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
            OOPS();
        }
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;
    case USB_DEVICE_CLASS_BILLBOARD:
        AppendTextBuffer("  -> Billboard Class\r\n");
        AppendTextBuffer("bInterfaceSubClass:                0x%02X", InterfaceDesc->bInterfaceSubClass);
        switch (InterfaceDesc->bInterfaceSubClass)
        {
        case 0:
            AppendTextBuffer("  -> Billboard Subclass\r\n");
            break;
        default:
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid bInterfaceSubClass\r\n");
            break;
        }
        break;

    default:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Interface Class Unknown to USBView\r\n");
        }
        AppendTextBuffer("bInterfaceSubClass:                0x%02X\r\n",
            InterfaceDesc->bInterfaceSubClass);
        break;
    }

    AppendTextBuffer("bInterfaceProtocol:                0x%02X\r\n",
        InterfaceDesc->bInterfaceProtocol);

    //This is basically the check for PC_PROTOCOL_UNDEFINED
    if ((InterfaceDesc->bInterfaceClass == USB_DEVICE_CLASS_VIDEO) ||
        (InterfaceDesc->bInterfaceClass == USB_DEVICE_CLASS_AUDIO))
    {
        if(InterfaceDesc->bInterfaceProtocol != PC_PROTOCOL_UNDEFINED)
        {
            //@@TestCase A5.10
            //@@WARNING
            //@@Descriptor Field - iInterface
            //@@bInterfaceProtocol must be set to PC_PROTOCOL_UNDEFINED
            AppendTextBuffer("*!*WARNING:  must be set to PC_PROTOCOL_UNDEFINED %d for this class\r\n",
                PC_PROTOCOL_UNDEFINED);
            OOPS();
        }
    }

    AppendTextBuffer("iInterface:                        0x%02X\r\n",
        InterfaceDesc->iInterface);

    if(gDoAnnotation)
    {
        if (InterfaceDesc->iInterface)
        {
            DisplayStringDescriptor(InterfaceDesc->iInterface,
                StringDescs,
                LatestDevicePowerState);
        }
    }

    if (InterfaceDesc->bLength == sizeof(USB_INTERFACE_DESCRIPTOR2))
    {
        PUSB_INTERFACE_DESCRIPTOR2 interfaceDesc2;

        interfaceDesc2 = (PUSB_INTERFACE_DESCRIPTOR2)InterfaceDesc;

        AppendTextBuffer("wNumClasses:                     0x%04X\r\n",
            interfaceDesc2->wNumClasses);
    }

}

/*****************************************************************************

DisplayEndpointDescriptor()

*****************************************************************************/

VOID
DisplayEndpointDescriptor (
    _In_     PUSB_ENDPOINT_DESCRIPTOR
                        EndpointDesc,
    _In_opt_ PUSB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR
                        EpCompDesc,
    _In_opt_ PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR
                        SspIsochEpCompDesc,
    _In_     UCHAR      InterfaceClass,
    _In_     BOOLEAN    EpCompDescAvail
    )
{
    UCHAR epType = EndpointDesc->bmAttributes & USB_ENDPOINT_TYPE_MASK;
    PUSB_HIGH_SPEED_MAXPACKET hsMaxPacket;

    AppendTextBuffer("\r\n          ===>Endpoint Descriptor<===\r\n");
    //@@DisplayEndpointDescriptor - Endpoint Descriptor
    //length checked in DisplayConfigDesc()

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        EndpointDesc->bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        EndpointDesc->bDescriptorType);

    AppendTextBuffer("bEndpointAddress:                  0x%02X",
        EndpointDesc->bEndpointAddress);

    if(gDoAnnotation)
    {
        if(USB_ENDPOINT_DIRECTION_OUT(EndpointDesc->bEndpointAddress))
        {
            AppendTextBuffer("  -> Direction: OUT - EndpointID: %d\r\n",
                (EndpointDesc->bEndpointAddress & USB_ENDPOINT_ADDRESS_MASK));
        }
        else if(USB_ENDPOINT_DIRECTION_IN(EndpointDesc->bEndpointAddress))
        {
            AppendTextBuffer("  -> Direction: IN - EndpointID: %d\r\n",
                (EndpointDesc->bEndpointAddress & USB_ENDPOINT_ADDRESS_MASK));
        }
        else
        {
            //@@TestCase A6.1
            //@@ERROR
            //@@Descriptor Field - bEndpointAddress
            //@@An invalid endpoint addressl has been defined
            AppendTextBuffer("\r\n*!*ERROR:  This appears to be an invalid bEndpointAddress\r\n");
            OOPS();
        }
    }
    else {AppendTextBuffer("\r\n");}

    AppendTextBuffer("bmAttributes:                      0x%02X",
        EndpointDesc->bmAttributes);

    if(gDoAnnotation)
    {
        AppendTextBuffer("  -> ");

        switch (epType)
        {
        case USB_ENDPOINT_TYPE_CONTROL:
            AppendTextBuffer("Control Transfer Type\r\n");
            if (EndpointDesc->bmAttributes & USB_ENDPOINT_TYPE_CONTROL_RESERVED_MASK)
            {
                AppendTextBuffer("\r\n*!*ERROR:     Bits 7..2 are reserved and must be set to 0\r\n");
                OOPS();
            }
            break;

        case USB_ENDPOINT_TYPE_ISOCHRONOUS:
            AppendTextBuffer("Isochronous Transfer Type, Synchronization Type = ");

            switch (USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION(EndpointDesc->bmAttributes))
            {
            case USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_NO_SYNCHRONIZATION:
                AppendTextBuffer("No Synchronization");
                break;

            case USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_ASYNCHRONOUS:
                AppendTextBuffer("Asynchronous");
                break;

            case USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_ADAPTIVE:
                AppendTextBuffer("Adaptive");
                break;

            case USB_ENDPOINT_TYPE_ISOCHRONOUS_SYNCHRONIZATION_SYNCHRONOUS:
                AppendTextBuffer("Synchronous");
                break;
            }
            AppendTextBuffer(", Usage Type = ");

            switch (USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE(EndpointDesc->bmAttributes))
            {
            case USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_DATA_ENDOINT:
                AppendTextBuffer("Data Endpoint\r\n");
                break;

            case USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_FEEDBACK_ENDPOINT:
                AppendTextBuffer("Feedback Endpoint\r\n");
                break;

            case USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_IMPLICIT_FEEDBACK_DATA_ENDPOINT:
                AppendTextBuffer("Implicit Feedback Data Endpoint\r\n");
                break;

            case USB_ENDPOINT_TYPE_ISOCHRONOUS_USAGE_RESERVED:
                //@@TestCase A6.2
                //@@ERROR
                //@@Descriptor Field - bmAttributes
                //@@A reserved bit has a value
                AppendTextBuffer("\r\n*!*ERROR:     This value is Reserved\r\n");
                OOPS();
                break;
            }
            if (EndpointDesc->bmAttributes & USB_ENDPOINT_TYPE_ISOCHRONOUS_RESERVED_MASK)
            {
                AppendTextBuffer("\r\n*!*ERROR:     Bits 7..6 are reserved and must be set to 0\r\n");
                OOPS();
            }
            break;

        case USB_ENDPOINT_TYPE_BULK:
            AppendTextBuffer("Bulk Transfer Type\r\n");
            if (EndpointDesc->bmAttributes & USB_ENDPOINT_TYPE_BULK_RESERVED_MASK)
            {
                AppendTextBuffer("\r\n*!*ERROR:     Bits 7..2 are reserved and must be set to 0\r\n");
                OOPS();
            }
            break;

        case USB_ENDPOINT_TYPE_INTERRUPT:

            if (gDeviceSpeed != UsbSuperSpeed)
            {
                AppendTextBuffer("Interrupt Transfer Type\r\n");
                if (EndpointDesc->bmAttributes & USB_20_ENDPOINT_TYPE_INTERRUPT_RESERVED_MASK)
                {
                    AppendTextBuffer("\r\n*!*ERROR:     Bits 7..2 are reserved and must be set to 0\r\n");
                    OOPS();
                }
            }
            else
            {
                AppendTextBuffer("Interrupt Transfer Type, Usage Type = ");

                switch (USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE(EndpointDesc->bmAttributes))
                {
                case USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_PERIODIC:
                    AppendTextBuffer("Periodic\r\n");
                    break;

                case USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_NOTIFICATION:
                    AppendTextBuffer("Notification\r\n");
                    break;

                case USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_RESERVED10:
                case USB_30_ENDPOINT_TYPE_INTERRUPT_USAGE_RESERVED11:
                    AppendTextBuffer("\r\n*!*ERROR:     This value is Reserved\r\n");
                    OOPS();
                    break;
                }

                if (EndpointDesc->bmAttributes & USB_30_ENDPOINT_TYPE_INTERRUPT_RESERVED_MASK)
                {
                    AppendTextBuffer("\r\n*!*ERROR:     Bits 7..6 and 3..2 are reserved and must be set to 0\r\n");
                    OOPS();
                }

                if (EpCompDescAvail)
                {
                    if (EpCompDesc == NULL)
                    {
                        AppendTextBuffer("\r\n*!*ERROR:     Endpoint Companion Descriptor missing\r\n");
                        OOPS();
                    }
                    else if (EpCompDesc->bmAttributes.Isochronous.SspCompanion == 1 &&
                        SspIsochEpCompDesc == NULL)
                    {
                        AppendTextBuffer("\r\n*!*ERROR:     SuperSpeedPlus Isoch Endpoint Companion Descriptor missing\r\n");
                        OOPS();
                    }
                }
            }
            break;
        }
    }
    else
    {
        AppendTextBuffer("\r\n");
    }

    //@@TestCase A6.3
    //@@Priority 1
    //@@Descriptor Field - bInterfaceNumber
    //@@Question - Should we test to verify bInterfaceNumber is valid?
    AppendTextBuffer("wMaxPacketSize:                  0x%04X",
        EndpointDesc->wMaxPacketSize);
    if(gDoAnnotation)
    {
        switch (gDeviceSpeed)
        {
        case UsbSuperSpeed:
            switch (epType)
            {
            case USB_ENDPOINT_TYPE_BULK:
                if (EndpointDesc->wMaxPacketSize != USB_ENDPOINT_SUPERSPEED_BULK_MAX_PACKET_SIZE)
                {
                    AppendTextBuffer("\r\n*!*ERROR:     SuperSpeed Bulk endpoints must be %d bytes\r\n",
                        USB_ENDPOINT_SUPERSPEED_BULK_MAX_PACKET_SIZE);
                }
                else
                {
                    AppendTextBuffer("\r\n");
                }
                break;

            case USB_ENDPOINT_TYPE_CONTROL:
                if (EndpointDesc->wMaxPacketSize != USB_ENDPOINT_SUPERSPEED_CONTROL_MAX_PACKET_SIZE)
                {
                    AppendTextBuffer("\r\n*!*ERROR:     SuperSpeed Control endpoints must be %d bytes\r\n",
                        USB_ENDPOINT_SUPERSPEED_CONTROL_MAX_PACKET_SIZE);
                }
                else
                {
                    AppendTextBuffer("\r\n");
                }
                break;

            case USB_ENDPOINT_TYPE_ISOCHRONOUS:

                if (EpCompDesc != NULL)
                {
                    if (EpCompDesc->bMaxBurst > 0)
                    {
                        if (EndpointDesc->wMaxPacketSize != USB_ENDPOINT_SUPERSPEED_ISO_MAX_PACKET_SIZE)
                        {
                            AppendTextBuffer("\r\n*!*ERROR:     SuperSpeed isochronous endpoints must have wMaxPacketSize value of %d bytes\r\n",
                                USB_ENDPOINT_SUPERSPEED_ISO_MAX_PACKET_SIZE);
                            AppendTextBuffer("                  when the SuperSpeed endpoint companion descriptor bMaxBurst value is greater than 0\r\n");
                        }
                        else
                        {
                            AppendTextBuffer("\r\n");
                        }
                    }
                    else if (EndpointDesc->wMaxPacketSize > USB_ENDPOINT_SUPERSPEED_ISO_MAX_PACKET_SIZE)
                    {
                        AppendTextBuffer("\r\n*!*ERROR:     Invalid SuperSpeed isochronous maximum packet size\r\n");
                    }
                    else
                    {
                        AppendTextBuffer("\r\n");
                    }
                }
                else
                {
                    AppendTextBuffer("\r\n");
                }
                break;

            case USB_ENDPOINT_TYPE_INTERRUPT:

                if (EpCompDesc != NULL)
                {
                    if (EpCompDesc->bMaxBurst > 0)
                    {
                        if (EndpointDesc->wMaxPacketSize != USB_ENDPOINT_SUPERSPEED_INTERRUPT_MAX_PACKET_SIZE)
                        {
                            AppendTextBuffer("\r\n*!*ERROR:     SuperSpeed interrupt endpoints must have wMaxPacketSize value of %d bytes\r\n",
                                USB_ENDPOINT_SUPERSPEED_INTERRUPT_MAX_PACKET_SIZE);
                            AppendTextBuffer("                  when the SuperSpeed endpoint companion descriptor bMaxBurst value is greater than 0\r\n");
                        }
                        else
                        {
                            AppendTextBuffer("\r\n");
                        }
                    }
                    else if (EndpointDesc->wMaxPacketSize > USB_ENDPOINT_SUPERSPEED_INTERRUPT_MAX_PACKET_SIZE)
                    {
                        AppendTextBuffer("\r\n*!*ERROR:     Invalid SuperSpeed interrupt maximum packet size\r\n");
                    }
                    else
                    {
                        AppendTextBuffer("\r\n");
                    }
                }
                else
                {
                    AppendTextBuffer("\r\n");
                }
                break;
            }
            break;

        case UsbHighSpeed:
            hsMaxPacket = (PUSB_HIGH_SPEED_MAXPACKET)&EndpointDesc->wMaxPacketSize;

            switch (epType)
            {
            case USB_ENDPOINT_TYPE_ISOCHRONOUS:
            case USB_ENDPOINT_TYPE_INTERRUPT:
                switch (hsMaxPacket->HSmux) {
                case 0:
                    if ((hsMaxPacket->MaxPacket < 1) || (hsMaxPacket->MaxPacket >1024))
                    {
                        AppendTextBuffer("*!*ERROR:  Invalid maximum packet size, should be between 1 and 1024\r\n");
                    }
                    break;

                case 1:
                    if ((hsMaxPacket->MaxPacket < 513) || (hsMaxPacket->MaxPacket >1024))
                    {
                        AppendTextBuffer("*!*ERROR:  Invalid maximum packet size, should be between 513 and 1024\r\n");
                    }
                    break;

                case 2:
                    if ((hsMaxPacket->MaxPacket < 683) || (hsMaxPacket->MaxPacket >1024))
                    {
                        AppendTextBuffer("*!*ERROR:  Invalid maximum packet size, should be between 683 and 1024\r\n");
                    }
                    break;

                case 3:
                    AppendTextBuffer("*!*ERROR:  Bits 12-11 set to Reserved value in wMaxPacketSize\r\n");
                    break;
                }

                AppendTextBuffer(" = %d transactions per microframe, 0x%02X max bytes\r\n", hsMaxPacket->HSmux + 1, hsMaxPacket->MaxPacket);
                break;

            case USB_ENDPOINT_TYPE_BULK:
            case USB_ENDPOINT_TYPE_CONTROL:
                AppendTextBuffer(" = 0x%02X max bytes\r\n", hsMaxPacket->MaxPacket);
                break;
            }
            break;

        case UsbFullSpeed:
            // full speed
            AppendTextBuffer(" = 0x%02X bytes\r\n",
                EndpointDesc->wMaxPacketSize & 0x7FF);
            break;
        default:
            // low or invalid speed
            if (InterfaceClass == USB_DEVICE_CLASS_VIDEO)
            {
                AppendTextBuffer(" = Invalid bus speed for USB Video Class\r\n");
            }
            else
            {
                AppendTextBuffer("\r\n");
            }
            break;
        }
    }
    else
    {
        AppendTextBuffer("\r\n");
    }

    if (EndpointDesc->wMaxPacketSize & 0xE000)
    {
        //@@TestCase A6.4
        //@@Priority 1
        //@@OTG Descriptor Field - wMaxPacketSize
        //@@Attribute bits D7-2 reserved (reset to 0)
        AppendTextBuffer("*!*ERROR:  wMaxPacketSize bits 15-13 should be 0\r\n");
    }

    if (EndpointDesc->bLength == sizeof(USB_ENDPOINT_DESCRIPTOR))
    {
        //@@TestCase A6.5
        //@@Priority 1
        //@@Descriptor Field - bInterfaceNumber
        //@@Question - Should we test to verify bInterfaceNumber is valid?
        AppendTextBuffer("bInterval:                         0x%02X\r\n",
            EndpointDesc->bInterval);
    }
    else
    {
        PUSB_ENDPOINT_DESCRIPTOR2 endpointDesc2;

        endpointDesc2 = (PUSB_ENDPOINT_DESCRIPTOR2)EndpointDesc;

        AppendTextBuffer("wInterval:                       0x%04X\r\n",
            endpointDesc2->wInterval);

        AppendTextBuffer("bSyncAddress:                      0x%02X\r\n",
            endpointDesc2->bSyncAddress);
    }

    if (EpCompDesc != NULL)
    {
        DisplayEndointCompanionDescriptor(EpCompDesc, SspIsochEpCompDesc, epType);
    }
    if (SspIsochEpCompDesc != NULL)
    {
        DisplaySuperSpeedPlusIsochEndpointCompanionDescriptor(SspIsochEpCompDesc);
    }

}

/*****************************************************************************

DisplaySuperSpeedPlusIsochEndpointCompanionDescriptor()

*****************************************************************************/
VOID
DisplaySuperSpeedPlusIsochEndpointCompanionDescriptor(
     _In_ PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR SspIsochEpCompDesc
     )
     {
    AppendTextBuffer("\r\n ===>SuperSpeedPlus Isochronous Endpoint Companion Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        SspIsochEpCompDesc->bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        SspIsochEpCompDesc->bDescriptorType);

    AppendTextBuffer("wReserved:                         0x%02X\r\n",
        SspIsochEpCompDesc->wReserved);

    if (gDoAnnotation)
    {
        if (SspIsochEpCompDesc->wReserved != 0)
        {
            AppendTextBuffer("*!*ERROR: field is reserved\r\n");
        }
    }

    AppendTextBuffer("dwBytesPerInterval:                0x%04X\r\n",
        SspIsochEpCompDesc->dwBytesPerInterval);
}

/*****************************************************************************

DisplayEndointCompanionDescriptor()

*****************************************************************************/
VOID
DisplayEndointCompanionDescriptor (
    _In_     PUSB_SUPERSPEED_ENDPOINT_COMPANION_DESCRIPTOR EpCompDesc,
    _In_opt_ PUSB_SUPERSPEEDPLUS_ISOCH_ENDPOINT_COMPANION_DESCRIPTOR SspIsochEpCompDesc,
    _In_     UCHAR                                         DescType
    )
{
    AppendTextBuffer("\r\n ===>SuperSpeed Endpoint Companion Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        EpCompDesc->bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        EpCompDesc->bDescriptorType);

    AppendTextBuffer("bMaxBurst:                         0x%02X\r\n",
        EpCompDesc->bMaxBurst);

    AppendTextBuffer("bmAttributes:                      0x%02X",
        EpCompDesc->bmAttributes.AsUchar);
    if(gDoAnnotation)
    {
        switch (DescType)
        {
        case USB_ENDPOINT_TYPE_CONTROL:
        case USB_ENDPOINT_TYPE_INTERRUPT:
            if (EpCompDesc->bmAttributes.AsUchar != 0)
            {
                AppendTextBuffer("*!*ERROR:  Control/Interrupt SuperSpeed endpoints do not support streams\r\n");
            }
            else
            {
                AppendTextBuffer("\r\n");
            }
            break;
        case USB_ENDPOINT_TYPE_BULK:
            if(EpCompDesc->bmAttributes.Bulk.MaxStreams == 0)
            {
                AppendTextBuffer("The bulk endpoint does not define streams (MaxStreams == 0)\r\n");
            }
            else
            {
                AppendTextBuffer(" = %d streams supported\r\n", 1 << EpCompDesc->bmAttributes.Bulk.MaxStreams);
            }

            if (EpCompDesc->bmAttributes.Bulk.Reserved1 != 0)
            {
                AppendTextBuffer("*!*ERROR:  bmAttributes bits 7-5 should be 0\r\n");
            }
            break;

        case USB_ENDPOINT_TYPE_ISOCHRONOUS:
            if (EpCompDesc->bmAttributes.Isochronous.SspCompanion == 0)
            {
                if (EpCompDesc->bMaxBurst == 0 &&
                    EpCompDesc->bmAttributes.Isochronous.Mult != 0)
                {
                    AppendTextBuffer("*!*ERROR: SuperSpeed isochronous endpoint multiplier value should be zero if bMaxBurst is zero\r\n");
                }
                else
                {
                    AppendTextBuffer(" = %d maximum number of packets within a service interval\r\n",
                        (EpCompDesc->bmAttributes.Isochronous.Mult + 1)*(EpCompDesc->bMaxBurst + 1));

                    if (EpCompDesc->bmAttributes.Isochronous.Mult > USB_SUPERSPEED_ISOCHRONOUS_MAX_MULTIPLIER)
                    {
                        AppendTextBuffer("*!*ERROR:  Maximum SuperSpeed isochronous endpoint multiplier value exceeded\r\n");
                    }
                }
            }
            else
            {
                if (EpCompDesc->bMaxBurst != 0 && SspIsochEpCompDesc != NULL)
                {
                    AppendTextBuffer(" = %d maximum number of packets within a service interval\r\n",
                        (SspIsochEpCompDesc->dwBytesPerInterval*USB_ENDPOINT_SUPERSPEED_ISO_MAX_PACKET_SIZE) /
                        EpCompDesc->bMaxBurst);
                }
            }

            if (EpCompDesc->bmAttributes.Isochronous.Reserved2 != 0)
            {
                AppendTextBuffer("*!*ERROR:  bmAttributes bits 7-2 should be 0\r\n");
            }
            else
            {
                AppendTextBuffer("\r\n");
            }
            break;
        }
    }
    AppendTextBuffer("wBytesPerInterval:                 0x%04X\r\n",
        EpCompDesc->wBytesPerInterval);

    if (EpCompDesc->bmAttributes.Isochronous.SspCompanion == 1 &&
        EpCompDesc->wBytesPerInterval != 0x1)
    {
        AppendTextBuffer("*!*ERROR: SuperSpeed endpoint wBytesPerInterval value should be 1 if \
                         SuperSpeedPlus Isoch companion descriptor is present\r\n");
    }
}


/*****************************************************************************

DisplayHidDescriptor()

*****************************************************************************/

VOID
DisplayHidDescriptor (
    PUSB_HID_DESCRIPTOR         HidDesc
    )
{
    UCHAR i = 0;

    AppendTextBuffer("\r\n          ===>HID Descriptor<===\r\n");

    //length checked in DisplayConfigDesc()

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        HidDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        HidDesc->bDescriptorType);
    AppendTextBuffer("bcdHID:                          0x%04X\r\n",
        HidDesc->bcdHID);
    AppendTextBuffer("bCountryCode:                      0x%02X\r\n",
        HidDesc->bCountryCode);
    AppendTextBuffer("bNumDescriptors:                   0x%02X\r\n",
        HidDesc->bNumDescriptors);

    for (i=0; i<HidDesc->bNumDescriptors; i++)
    {
        if (HidDesc->OptionalDescriptors[i].bDescriptorType == 0x22) {
            AppendTextBuffer("bDescriptorType:                   0x%02X (Report Descriptor)\r\n",
                HidDesc->OptionalDescriptors[i].bDescriptorType);
        }
        else {
            AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
                HidDesc->OptionalDescriptors[i].bDescriptorType);
        }

        AppendTextBuffer("wDescriptorLength:               0x%04X\r\n",
            HidDesc->OptionalDescriptors[i].wDescriptorLength);
    }
}

/*****************************************************************************

DisplayOTGDescriptor()

*****************************************************************************/

VOID
DisplayOTGDescriptor (
    PUSB_OTG_DESCRIPTOR         OTGDesc
    )
{
    AppendTextBuffer("\r\n          ===>OTG Descriptor<===\r\n");

    //length checked in DisplayConfigDesc()

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        OTGDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        OTGDesc->bDescriptorType);
    AppendTextBuffer("bmAttributes:                      0x%02X",
        OTGDesc->bmAttributes);

    switch (OTGDesc->bmAttributes)
    {
    case 0:
        break;
    case 1:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> SRP support\r\n");
        }
        break;
    case 2:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> HNP support\r\n");
        }
        break;
    case 3:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> SRP and HNP support\r\n");
        }
        break;
    default:
        //@@TestCase A6.5
        //@@Priority 1
        //@@OTG Descriptor Field - bmAttributes
        //@@Attribute bits D7-2 reserved (reset to 0)
        AppendTextBuffer("*!*ERROR:  bmAttributes bits 2-7 are reserved "\
            "(should be 0)\r\n");
        OOPS();
        break;
    }
}

/*****************************************************************************

InitializeGlobalFlags ()

Initialize the global device flags in UVCView.h

*****************************************************************************/

void
InitializePerDeviceSettings (
    PUSBDEVICEINFO info
    )
{
    // Save base address for this current device's info (including Configuration descriptor)
    CurrentUSBDeviceInfo = info;

    // Initialize Configuration descriptor length
    dwConfigLength = 0;

    // Save # of bytes from start of Configuration descriptor
    // (Update this in the descriptor parsing routines)
    dwConfigIndex = 0;

    // Flags used in dispvid.c to display default Frame descriptor for MJPEG,
    //  Uncompressed, Vendor and FrameBased Formats
    g_chMJPEGFrameDefault = 0;
    g_chUNCFrameDefault = 0;
    g_chVendorFrameDefault = 0;
    g_chFrameBasedFrameDefault = 0;

    // Spec version of UVC device
    g_chUVCversion = 0;

    // Start and end address of the configuration descriptor and start of the string descriptors
    g_pConfigDesc  = NULL;
    g_pStringDescs = NULL;
    g_descEnd      = NULL;

    //
    // The GetConfigDescriptor() function in enum.c does not always work
    // If that fails, the Configuration descriptor will be NULL
    //  and we can only display the device descriptor
    //
    CurrentConfigDesc = NULL;
    if (NULL != info)
    {
         if (NULL != info->ConfigDesc)
        {
            CurrentConfigDesc = (PUSB_CONFIGURATION_DESCRIPTOR)(info->ConfigDesc + 1);

            // Save the LENGTH of the Config descriptor
            // Note that IsIADDevice() saves the ADDRESS of the END of the Config desc
            // Be aware of the difference
            dwConfigLength = CurrentConfigDesc->wTotalLength;
        }
    }

    return;
}

/*****************************************************************************

IsUVCDevice()

Return Spec version of UVC device
 0x0  = Not a UVC device
 0x10 = UVC 1.0
 0x11 = UVC 1.1

 *****************************************************************************/

UINT
IsUVCDevice (
    PUSBDEVICEINFO info
    )
{
    PUSB_CONFIGURATION_DESCRIPTOR  ConfigDesc = NULL;
    PUSB_COMMON_DESCRIPTOR         commonDesc = NULL;
    PUCHAR                         descEnd = NULL;
    UINT  uUVCversion = 0;

    //
    // The GetConfigDescriptor() function in enum.c does not always work
    // If that fails, the Configuration descriptor will be NULL
    //  and we can only display the device descriptor
    //
    if (NULL == info)
    {
        return 0;
    }
    if (NULL == info->ConfigDesc)
    {
        return 0;
    }
    ConfigDesc = (PUSB_CONFIGURATION_DESCRIPTOR)(info->ConfigDesc + 1);
    if (NULL == ConfigDesc)
    {
        return 0;
    }

    // We've got a good Configuration Descriptor
    commonDesc = (PUSB_COMMON_DESCRIPTOR)ConfigDesc;
    descEnd = (PUCHAR)ConfigDesc + ConfigDesc->wTotalLength;

    // walk through all the descriptors looking for the VIDEO_CONTROL_HEADER_UNIT
    while ((PUCHAR)commonDesc + sizeof(USB_COMMON_DESCRIPTOR) < descEnd &&
        (PUCHAR)commonDesc + commonDesc->bLength <= descEnd)
    {
        if ((commonDesc->bDescriptorType == CS_INTERFACE) &&
            (commonDesc->bLength > sizeof(VIDEO_CONTROL_HEADER_UNIT)))
        {
            // Right type, size. Now check subtype
            PVIDEO_CONTROL_HEADER_UNIT pCSVC = NULL;
            pCSVC = (PVIDEO_CONTROL_HEADER_UNIT) commonDesc;
            if (VC_HEADER == pCSVC->bDescriptorSubtype)
            {
                // found the Class-specific VC Interface Header descriptor
                uUVCversion = pCSVC->bcdVideoSpec;
                // Save the version to global
                g_chUVCversion = uUVCversion;
                // We're done
                break;
            }
        }
        commonDesc = (PUSB_COMMON_DESCRIPTOR) ((PUCHAR) commonDesc + commonDesc->bLength);
    }
    return (uUVCversion);
}

/*****************************************************************************

IsIADDevice()

*****************************************************************************/

UINT
IsIADDevice (
    PUSBDEVICEINFO info
    )
{
    PUSB_CONFIGURATION_DESCRIPTOR  ConfigDesc = NULL;
    PUSB_COMMON_DESCRIPTOR         commonDesc = NULL;
    PUCHAR                         descEnd = NULL;
    UINT  uIADcount = 0;

    //
    // The GetConfigDescriptor() function in enum.c does not always work
    // If that fails, the Configuration descriptor will be NULL
    //  and we can only display the device descriptor
    //
    if (NULL == info)
    {
        return 0;
    }
    if (NULL == info->ConfigDesc)
    {
        return 0;
    }

    ConfigDesc = (PUSB_CONFIGURATION_DESCRIPTOR)(info->ConfigDesc + 1);
    if (NULL != ConfigDesc)
    {
        commonDesc = (PUSB_COMMON_DESCRIPTOR)ConfigDesc;
        descEnd = (PUCHAR)ConfigDesc + ConfigDesc->wTotalLength;
    }

    // return total number of IAD descriptors in this device configuration
    while ((PUCHAR)commonDesc + sizeof(USB_COMMON_DESCRIPTOR) < descEnd &&
        (PUCHAR)commonDesc + commonDesc->bLength <= descEnd)
    {
        if (commonDesc->bDescriptorType == USB_IAD_DESCRIPTOR_TYPE)
        {
            uIADcount++;
        }
        commonDesc = (PUSB_COMMON_DESCRIPTOR) ((PUCHAR) commonDesc + commonDesc->bLength);
    }
    return (uIADcount);
}

/*****************************************************************************

DisplayIADDescriptor()

*****************************************************************************/

VOID
DisplayIADDescriptor (
    PUSB_IAD_DESCRIPTOR         IADDesc,
    PSTRING_DESCRIPTOR_NODE     StringDescs,
    int                         nInterfaces,
    DEVICE_POWER_STATE          LatestDevicePowerState
    )
{
    AppendTextBuffer("\r\n          ===>IAD Descriptor<===\r\n");

    //length checked in DisplayConfigDesc()

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        IADDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        IADDesc->bDescriptorType);
    AppendTextBuffer("bFirstInterface:                   0x%02X\r\n",
        IADDesc->bFirstInterface);
    AppendTextBuffer("bInterfaceCount:                   0x%02X\r\n",
        IADDesc->bInterfaceCount);
    if (IADDesc->bInterfaceCount == 1)
    {
        //@@TestCase A7.1
        //@@Priority 1
        //@@Standard IAD Descriptor Field - bInterfaceCount
        //@@The number of interfaces must be greater than 1
        AppendTextBuffer("*!*ERROR:  bInterfaceCount must be greater than 1 \r\n");
        OOPS();
    }
    if (nInterfaces < IADDesc->bFirstInterface + IADDesc->bInterfaceCount)
    {
        //@@TestCase A7.2
        //@@Priority 1
        //@@Standard IAD Descriptor Field - bInterfaceCount
        //@@The total number of interfaces must be greater than or equal to
        //@@  the highest linked interface number (base interface number plus count)
        AppendTextBuffer("*!*ERROR:  The total number of interfaces (%d) must be greater "\
            "than or equal to\r\n",
            nInterfaces);
        AppendTextBuffer("           the highest linked interface number (base %d + "\
            "count %d = %d)\r\n",
            IADDesc->bFirstInterface, IADDesc->bInterfaceCount,
            (IADDesc->bFirstInterface + IADDesc->bInterfaceCount));
        OOPS();
    }
    AppendTextBuffer("bFunctionClass:                    0x%02X",
        IADDesc->bFunctionClass);
    if (IADDesc->bFunctionClass == 0)
    {
        //@@TestCase A7.3
        //@@Priority 1
        //@@Standard IAD Descriptor Field - bFunctionClass
        //@@"A value of zero is not allowed in this descriptor"
        AppendTextBuffer("\r\n*!*ERROR:  bFunctionClass contains an illegal value 0 \r\n");
        OOPS();
    }

    switch (IADDesc->bFunctionClass)
    {
    case USB_DEVICE_CLASS_AUDIO:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Audio Interface Class\r\n");
        }

        AppendTextBuffer("bFunctionSubClass:                 0x%02X",
            IADDesc->bFunctionSubClass);

        if(gDoAnnotation)
        {
            switch (IADDesc->bFunctionSubClass)
            {
            case USB_AUDIO_SUBCLASS_AUDIOCONTROL:
                AppendTextBuffer("  -> Audio Control Interface SubClass\r\n");
                break;

            case USB_AUDIO_SUBCLASS_AUDIOSTREAMING:
                AppendTextBuffer("  -> Audio Streaming Interface SubClass\r\n");
                break;

            case USB_AUDIO_SUBCLASS_MIDISTREAMING:
                AppendTextBuffer("  -> MIDI Streaming Interface SubClass\r\n");
                break;

            default:
                //@@TestCase A7.4
                //@@CAUTION
                //@@Descriptor Field - bFunctionSubClass
                //@@Invalid bFunctionSubClass
                AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid bFunctionSubClass\r\n");
                OOPS();
                break;
            }
        }
        break;

    case USB_DEVICE_CLASS_VIDEO:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Video Interface Class\r\n");
        }

        AppendTextBuffer("bFunctionSubClass:                 0x%02X",
            IADDesc->bFunctionSubClass);

        switch(IADDesc->bFunctionSubClass)
        {
        case SC_VIDEO_INTERFACE_COLLECTION:
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> Video Interface Collection\r\n");
            }
            break;

        default:
            //@@TestCase A7.5
            //@@CAUTION
            //@@Descriptor Field - bFunctionSubClass
            //@@Invalid bFunctionSubClass
            AppendTextBuffer("\r\n*!*ERROR:    This should be USB_VIDEO_SC_VIDEO_INTERFACE_COLLECTION %d\r\n",
                SC_VIDEO_INTERFACE_COLLECTION);
            OOPS();
            break;
        }
        break;

    case USB_DEVICE_CLASS_HUMAN_INTERFACE:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> HID Interface Class\r\n");
        }
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_HUB:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> HUB Interface Class\r\n");
        }
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_RESERVED:
        //@@TestCase A7.6
        //@@CAUTION
        //@@Descriptor Field - bFunctionClass
        //@@A reserved USB Device Interface Class has been defined
        AppendTextBuffer("\r\n*!*CAUTION:  %d is a Reserved USB Device Interface Class\r\n",
            USB_DEVICE_CLASS_RESERVED);
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_COMMUNICATIONS:
        AppendTextBuffer("  -> This is Communications (CDC Control) USB Device Interface Class\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_MONITOR:
        AppendTextBuffer("  -> This is a Monitor USB Device Interface Class*** (This may be obsolete)\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_PHYSICAL_INTERFACE:
        AppendTextBuffer("  -> This is a Physical Interface USB Device Interface Class\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_POWER:
        if(IADDesc->bFunctionSubClass == 1 && IADDesc->bFunctionProtocol == 1)
        {
            AppendTextBuffer("  -> This is an Image USB Device Interface Class\r\n");
        }
        else
        {
            AppendTextBuffer("  -> This is a Power USB Device Interface Class (This may be obsolete)\r\n");
        }
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_PRINTER:
        AppendTextBuffer("  -> This is a Printer USB Device Interface Class\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DEVICE_CLASS_STORAGE:
        AppendTextBuffer("  -> This is a Mass Storage USB Device Interface Class\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_CDC_DATA_INTERFACE:
        AppendTextBuffer("  -> This is a CDC Data USB Device Interface Class\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_CHIP_SMART_CARD_INTERFACE:
        AppendTextBuffer("  -> This is a Chip/Smart Card USB Device Interface Class\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_CONTENT_SECURITY_INTERFACE:
        AppendTextBuffer("  -> This is a Content Security USB Device Interface Class\r\n");
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_DIAGNOSTIC_DEVICE_INTERFACE:
        if(IADDesc->bFunctionSubClass == 1 && IADDesc->bFunctionProtocol == 1)
        {
            AppendTextBuffer("  -> This is a Reprogrammable USB2 Compliance Diagnostic Device USB Device\r\n");
        }
        else
        {
            //@@TestCase A7.7
            //@@CAUTION
            //@@Descriptor Field - bFunctionClass
            //@@Invalid Interface Class
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
            OOPS();
        }
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_WIRELESS_CONTROLLER_INTERFACE:
        if(IADDesc->bFunctionSubClass == 1 && IADDesc->bFunctionProtocol == 1)
        {
            AppendTextBuffer("  -> This is a Wireless RF Controller USB Device Interface Class with Bluetooth Programming Interface\r\n");
        }
        else
        {
            //@@TestCase A7.8
            //@@CAUTION
            //@@Descriptor Field - bFunctionClass
            //@@Invalid Interface Class
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
            OOPS();
        }
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    case USB_APPLICATION_SPECIFIC_INTERFACE:
        AppendTextBuffer("  -> This is an Application Specific USB Device Interface Class\r\n");

        switch(IADDesc->bFunctionSubClass)
        {
        case 1:
            AppendTextBuffer("  -> This is a Device Firmware Application Specific USB Device Interface Class\r\n");
            break;
        case 2:
            AppendTextBuffer("  -> This is an IrDA Bridge Application Specific USB Device Interface Class\r\n");
            break;
        case 3:
            AppendTextBuffer("  -> This is a Test & Measurement Class (USBTMC) Application Specific USB Device Interface Class\r\n");
            break;
        default:
            //@@TestCase A7.9
            //@@CAUTION
            //@@Descriptor Field - bFunctionClass
            //@@Invalid Interface Class
            AppendTextBuffer("\r\n*!*CAUTION:    This appears to be an invalid Interface Class\r\n");
            OOPS();
        }
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;

    default:
        if(gDoAnnotation)
        {
            AppendTextBuffer("  -> Interface Class Unknown to USBView\r\n");
        }
        AppendTextBuffer("bFunctionSubClass:                 0x%02X\r\n",
            IADDesc->bFunctionSubClass);
        break;
    }

    AppendTextBuffer("bFunctionProtocol:                 0x%02X",
        IADDesc->bFunctionProtocol);

    // check protocol for our class
    if ((IADDesc->bFunctionClass == USB_DEVICE_CLASS_VIDEO))
    {
        // USB Video Class
        if(IADDesc->bFunctionProtocol == PC_PROTOCOL_UNDEFINED)
        {
            // correct protocol for UVC
            if(gDoAnnotation)
            {
                AppendTextBuffer("  -> PC_PROTOCOL_UNDEFINED protocol\r\n");
            } else {
                AppendTextBuffer("\r\n");
            }
        } else {
            // incorrect protocol for UVC
            //@@TestCase A7.10
            //@@WARNING
            //@@Descriptor Field - iInterface
            //@@bFunctionProtocol must be set to PC_PROTOCOL_UNDEFINED
            AppendTextBuffer("*!*WARNING:  must be set to PC_PROTOCOL_UNDEFINED %d for this class\r\n",
                PC_PROTOCOL_UNDEFINED);
            OOPS();
        }
    } else {
        AppendTextBuffer("\r\n");
    }

    AppendTextBuffer("iFunction:                         0x%02X\r\n",
        IADDesc->iFunction);

    if(gDoAnnotation)
    {
        if (IADDesc->iFunction)
        {
            DisplayStringDescriptor(IADDesc->iFunction,
                StringDescs,
                LatestDevicePowerState);
        }
    }
}

/*****************************************************************************

GetConfigurationSize()

*****************************************************************************/

UINT
GetConfigurationSize (
    PUSBDEVICEINFO info
    )
{
    PUSB_CONFIGURATION_DESCRIPTOR
        ConfigDesc = (PUSB_CONFIGURATION_DESCRIPTOR)(info->ConfigDesc + 1);
    PUSB_COMMON_DESCRIPTOR
        commonDesc = (PUSB_COMMON_DESCRIPTOR)ConfigDesc;
    PUCHAR
        descEnd = (PUCHAR)ConfigDesc + ConfigDesc->wTotalLength;
    UINT  uCount = 0;

    // return this device configuration's total sum of descriptor lengths
    while ((PUCHAR)commonDesc + sizeof(USB_COMMON_DESCRIPTOR) < descEnd &&
        (PUCHAR)commonDesc + commonDesc->bLength <= descEnd)
    {
        uCount += commonDesc->bLength;
        commonDesc = (PUSB_COMMON_DESCRIPTOR) ((PUCHAR) commonDesc + commonDesc->bLength);
    }
    return (uCount);
}

/*****************************************************************************

GetInterfaceCount()

*****************************************************************************/

UINT
GetInterfaceCount (
    PUSBDEVICEINFO info
    )
{
    // how do we handle composite devices?
    PUSB_CONFIGURATION_DESCRIPTOR
        ConfigDesc = (PUSB_CONFIGURATION_DESCRIPTOR)(info->ConfigDesc + 1);
    PUSB_COMMON_DESCRIPTOR
        commonDesc = (PUSB_COMMON_DESCRIPTOR)ConfigDesc;
    PUCHAR
        descEnd = (PUCHAR)ConfigDesc + ConfigDesc->wTotalLength;
    UINT  uCount = 0;

    // return this device configuration's total number of interface descriptors
    while ((PUCHAR)commonDesc + sizeof(USB_COMMON_DESCRIPTOR) < descEnd &&
        (PUCHAR)commonDesc + commonDesc->bLength <= descEnd)
    {
        if (commonDesc->bDescriptorType == USB_INTERFACE_DESCRIPTOR_TYPE)
        {
            uCount++;
        }
        commonDesc = (PUSB_COMMON_DESCRIPTOR) ((PUCHAR) commonDesc + commonDesc->bLength);
    }
    return (uCount);
}


/*****************************************************************************

DisplayUSEnglishStringDescriptor()

*****************************************************************************/

VOID
DisplayUSEnglishStringDescriptor (
    UCHAR                       Index,
    PSTRING_DESCRIPTOR_NODE     USStringDescs,
    DEVICE_POWER_STATE          LatestDevicePowerState
    )
{
    ULONG nBytes = 0;
    BOOLEAN FoundMatchingString = FALSE;
    CHAR  pString[512];

    //@@DisplayUSEnglishStringDescriptor - String Descriptor
    for (; USStringDescs; USStringDescs = USStringDescs->Next)
    {
        if (USStringDescs->DescriptorIndex == Index && USStringDescs->LanguageID == 0x0409)
        {
            FoundMatchingString = TRUE;

            AppendTextBuffer("English product name: \"");
            memset(pString, 0, 512);
            nBytes = WideCharToMultiByte(
                CP_ACP,     // CodePage
                WC_NO_BEST_FIT_CHARS,
                USStringDescs->StringDescriptor->bString,
                (USStringDescs->StringDescriptor->bLength - 2) / 2,
                pString,
                512,
                NULL,       // lpDefaultChar
                NULL);      // pUsedDefaultChar
            if (nBytes)
                AppendTextBuffer("%s\"\r\n", pString);
            else
                AppendTextBuffer("\"\r\n", pString);
            return;
        }
    }

    //@@TestCase A8.1
    //@@WARNING
    //@@Descriptor Field - string index
    //@@No support for english
    if (!FoundMatchingString)
    {
        if (LatestDevicePowerState == PowerDeviceD0)
        {
            AppendTextBuffer("*!*ERROR:  No String Descriptor for index %d!\r\n", Index);
            OOPS();
        }
        else
        {
            AppendTextBuffer("String Descriptor for index %d not available while device is in low power state.\r\n", Index);
        }
    }
    else
    {
        AppendTextBuffer("*!*ERROR:  The index selected does not support English(US)\r\n");
        OOPS();
    }
    return;

}


/*****************************************************************************

DisplayStringDescriptor()

*****************************************************************************/
VOID
DisplayStringDescriptor (
    UCHAR                    Index,
    PSTRING_DESCRIPTOR_NODE  StringDescs,
    DEVICE_POWER_STATE       LatestDevicePowerState
    )
{
    ULONG nBytes = 0;
    BOOLEAN FoundMatchingString = FALSE;
    PCHAR pStr = NULL;
    CHAR  pString[512];

    //@@DisplayStringDescriptor - String Descriptor

    while (StringDescs)
    {
        if (StringDescs->DescriptorIndex == Index)
        {
            FoundMatchingString = TRUE;
            if(gDoAnnotation)
            {
                pStr= GetLangIDString(StringDescs->LanguageID);
                if(pStr)
                {
                    AppendTextBuffer("     %s  \"",
                        pStr);
                }
                else
                {
                    //@@TestCase A9.1
                    //@@WARNING
                    //@@Descriptor Field - string index
                    //@@The Language ID does not match any known languages supported by USB ORG
                    AppendTextBuffer("*!*WARNING:  %d is an invalid Language ID\r\n",
                        Index);
                    OOPS();
                }
            }
            else
            {
                AppendTextBuffer("     0x%04X:  \"", StringDescs->LanguageID);
            }
            memset(pString, 0, 512);

            if (StringDescs->StringDescriptor->bLength > sizeof(USHORT))
            {
                 nBytes = WideCharToMultiByte(
                              CP_ACP,     // CodePage
                              WC_NO_BEST_FIT_CHARS,
                              StringDescs->StringDescriptor->bString,
                              (StringDescs->StringDescriptor->bLength - 2) / 2,
                              pString,
                              512,
                              NULL,       // lpDefaultChar
                              NULL);      // pUsedDefaultChar
                 if (nBytes)
                 {
                      AppendTextBuffer("%s\"\r\n", pString);
                 }
                 else
                 {
                      AppendTextBuffer("\"\r\n");
                 }
            }
            else
            {
                 //
                 // This is NULL string which is invalid
                 //
                 AppendTextBuffer("\"\r\n");
            }
        }
        StringDescs = StringDescs->Next;
    }

    if (!FoundMatchingString)
    {
        if (LatestDevicePowerState == PowerDeviceD0)
        {
            AppendTextBuffer("*!*ERROR:  No String Descriptor for index %d!\r\n", Index);
            OOPS();
        }
        else
        {
            AppendTextBuffer("String Descriptor for index %d not available while device is in low power state.\r\n", Index);
        }
    }
}

/*****************************************************************************

DisplayUnknownDescriptor()

*****************************************************************************/
VOID
DisplayUnknownDescriptor (
    PUSB_COMMON_DESCRIPTOR      CommonDesc
    )
{
    AppendTextBuffer("\r\n          ===>Descriptor Hex Dump<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n",
        CommonDesc->bLength);

    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n",
        CommonDesc->bDescriptorType);

    DisplayRemainingUnknownDescriptor((PUCHAR)CommonDesc, 0, CommonDesc->bLength);
}

VOID
DisplayRemainingUnknownDescriptor(
    PUCHAR DescriptorData,
    ULONG  Start,
    ULONG  Stop
    )
{
    ULONG i;

    for (i = Start; i < Stop; i++)
    {
        AppendTextBuffer("%02X ",
            DescriptorData[i]);

        if (i % 16 == 15)
        {
            AppendTextBuffer("\r\n");
        }
    }

    if (i % 16 != 0)
    {
        AppendTextBuffer("\r\n");
    }
}



/*****************************************************************************

GetVendorString()

idVendor - USB Vendor ID

Return Value - Vendor name string associated with idVendor, or NULL if
no vendor name string is found which is associated with idVendor.

*****************************************************************************/

PCHAR
GetVendorString (
    USHORT     idVendor
    )
{
    PVENDOR_ID vendorID = NULL;

    if (idVendor == 0x0000)
    {
        return NULL;
    }

    vendorID = USBVendorIDs;

    while (vendorID->usVendorID != 0x0000)
    {
        if (vendorID->usVendorID == idVendor)
        {
            break;
        }
        vendorID++;
    }

    return (vendorID->szVendor);
}

/*****************************************************************************

GetLangIDString()

idVendor - USB Vendor ID

Return Value - Vendor name string associated with idVendor, or NULL if
no vendor name string is found which is associated with idVendor.

*****************************************************************************/

PCHAR
GetLangIDString (
    USHORT     idLang
    )
{
    PUSBLANGID langID = NULL;

    if (idLang != 0x0000)
    {
        langID = USBLangIDs;

        while (langID->usLangID != 0x0000)
        {
            if (langID->usLangID == idLang)
            {
                return (langID->szLanguage);
            }
            langID++;
        }
    }

    return NULL;
}

/*****************************************************************************

GetStringFromList()

PSTRINGLIST     slList,        - pointer to STRINGLIST used

ULONG ulNumElements, -
    number of elements in that STRINGLIST calc before call with sizeof(slList) / sizeof(STRINGLIST),
ULONG or ULONGLONG (if H264_SUPPORT is defined)ulFlag -  - flag to look for
PCHAR           szDefault      - string to return if no match

Return a string associated with a value from a stringtable.

example:
    GetStringFromList(slPowerState,
        sizeof(slPowerState) / sizeof(STRINGLIST),
        pUPI->SystemState,
        "Invalid Power State")

*****************************************************************************/

PCHAR
GetStringFromList(
    PSTRINGLIST     slList,
    ULONG           ulNumElements,
#ifdef H264_SUPPORT
    ULONGLONG       ulFlag,
#else
    ULONG           ulFlag,
#endif
    _In_ PCHAR           szDefault
    )
{
    // ulIndex is zero based, but ulNumElements is 1 based
    // subtract 1 from ulNumElements so that are same base
#ifdef H264_SUPPORT
    ULONGLONG ulIndex = 0;
#else
    ULONG ulIndex = 0;
#endif
    ulNumElements--;


    for ( ; ulIndex <= ulNumElements; ulIndex++)
    {
        if (ulFlag == slList[ulIndex].ulFlag)
        {
            return (slList[ulIndex].pszString);
        }
    }

    return szDefault;
}

