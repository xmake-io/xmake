/*++

Copyright (c) 1997-2008 Microsoft Corporation

Module Name:

    USBDESC.H

Abstract:

    This is a header file for USB descriptors which are not yet in
    a standard system header file.

Environment:

    user mode

Revision History:

    03-06-1998 : created
    03-28-2003 : minor changes to support UVC and USB200

--*/

#pragma pack(push, 1)

/*****************************************************************************
 D E F I N E S
*****************************************************************************/

//
//Device Descriptor bDeviceClass values
//
#define USB_INTERFACE_CLASS_DEVICE      0x00
#define USB_COMMUNICATION_DEVICE        0x02
#define USB_HUB_DEVICE                  0x09
#define USB_DEVICE_CLASS_BILLBOARD      0x11
#define USB_DIAGNOSTIC_DEVICE           0xDC
#define USB_WIRELESS_CONTROLLER_DEVICE  0xE0
#define USB_MISCELLANEOUS_DEVICE        0xEF
#define USB_VENDOR_SPECIFIC_DEVICE      0xFF

//
//Device Descriptor bDeviceSubClass values
//
#define USB_COMMON_SUB_CLASS            0x02

//
//Interface Descriptor bInterfaceClass values:
//
//#define USB_AUDIO_INTERFACE                0x01
//#define USB_CDC_CONTROL_INTERFACE          0x02
//#define USB_HID_INTERFACE                  0x03
//#define USB_PHYSICAL_INTERFACE             0x05
//#define USB_IMAGE_INTERFACE                0x06
//#define USB_PRINTER_INTERFACE              0x07
//#define USB_MASS_STORAGE_INTERFACE         0x08
//#define USB_HUB_INTERFACE                  0x09
#define USB_CDC_DATA_INTERFACE              0x0A
#define USB_CHIP_SMART_CARD_INTERFACE       0x0B
#define USB_CONTENT_SECURITY_INTERFACE      0x0D
#define USB_DIAGNOSTIC_DEVICE_INTERFACE     0xDC
#define USB_WIRELESS_CONTROLLER_INTERFACE   0xE0
#define USB_APPLICATION_SPECIFIC_INTERFACE  0xFE
//#define USB_VENDOR_SPECIFIC_INTERFACE      0xFF
#define USB_HID_DESCRIPTOR_TYPE             0x21

//
//IAD protocol values
//
#define USB_IAD_PROTOCOL                    0x01

//
//Device class specific values
//
#define BILLBOARD_MAX_NUM_ALT_MODE  0x34

//
//USB 2.0 Specification Changes - New Descriptors
//
#define USB_OTHER_SPEED_CONFIGURATION_DESCRIPTOR_TYPE  0x07
#define USB_INTERFACE_POWER_DESCRIPTOR_TYPE            0x08
#define USB_OTG_DESCRIPTOR_TYPE                        0x09
#define USB_DEBUG_DESCRIPTOR_TYPE                      0x0A
#define USB_IAD_DESCRIPTOR_TYPE                        0x0B

//
// USB Device Class Definition for Audio Devices
// Appendix A.  Audio Device Class Codes
//

// A.2  Audio Interface Subclass Codes
//
#define USB_AUDIO_SUBCLASS_UNDEFINED        0x00
#define USB_AUDIO_SUBCLASS_AUDIOCONTROL     0x01
#define USB_AUDIO_SUBCLASS_AUDIOSTREAMING   0x02
#define USB_AUDIO_SUBCLASS_MIDISTREAMING    0x03

// A.4  Audio Class-Specific Descriptor Types
//
#define USB_AUDIO_CS_UNDEFINED              0x20
#define USB_AUDIO_CS_DEVICE                 0x21
#define USB_AUDIO_CS_CONFIGURATION          0x22
#define USB_AUDIO_CS_STRING                 0x23
#define USB_AUDIO_CS_INTERFACE              0x24
#define USB_AUDIO_CS_ENDPOINT               0x25

// A.5  Audio Class-Specific AC (Audio Control) Interface Descriptor Subtypes
//
#define USB_AUDIO_AC_UNDEFINED              0x00
#define USB_AUDIO_AC_HEADER                 0x01
#define USB_AUDIO_AC_INPUT_TERMINAL         0x02
#define USB_AUDIO_AC_OUTPUT_TERMINAL        0x03
#define USB_AUDIO_AC_MIXER_UNIT             0x04
#define USB_AUDIO_AC_SELECTOR_UNIT          0x05
#define USB_AUDIO_AC_FEATURE_UNIT           0x06
#define USB_AUDIO_AC_PROCESSING_UNIT        0x07
#define USB_AUDIO_AC_EXTENSION_UNIT         0x08

// A.6  Audio Class-Specific AS (Audio Streaming) Interface Descriptor Subtypes
//
#define USB_AUDIO_AS_UNDEFINED              0x00
#define USB_AUDIO_AS_GENERAL                0x01
#define USB_AUDIO_AS_FORMAT_TYPE            0x02
#define USB_AUDIO_AS_FORMAT_SPECIFIC        0x03

// A.7 Processing Unit Process Types
//
#define USB_AUDIO_PROCESS_UNDEFINED         0x00
#define USB_AUDIO_PROCESS_UPDOWNMIX         0x01
#define USB_AUDIO_PROCESS_DOLBYPROLOGIC     0x02
#define USB_AUDIO_PROCESS_3DSTEREOEXTENDER  0x03
#define USB_AUDIO_PROCESS_REVERBERATION     0x04
#define USB_AUDIO_PROCESS_CHORUS            0x05
#define USB_AUDIO_PROCESS_DYNRANGECOMP      0x06


/*****************************************************************************
 T Y P E D E F S
*****************************************************************************/

// HID Class HID Descriptor
//
typedef struct _USB_HID_DESCRIPTOR
{
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    USHORT  bcdHID;
    UCHAR   bCountryCode;
    UCHAR   bNumDescriptors;
    struct
    {
        UCHAR   bDescriptorType;
        USHORT  wDescriptorLength;
    } OptionalDescriptors[1];
} USB_HID_DESCRIPTOR, *PUSB_HID_DESCRIPTOR;


// OTG Descriptor
//
typedef struct _USB_OTG_DESCRIPTOR
{
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bmAttributes;
} USB_OTG_DESCRIPTOR, *PUSB_OTG_DESCRIPTOR;

// IAD Descriptor
//
typedef struct _USB_IAD_DESCRIPTOR
{
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bFirstInterface;
    UCHAR   bInterfaceCount;
    UCHAR   bFunctionClass;
    UCHAR   bFunctionSubClass;
    UCHAR   bFunctionProtocol;
    UCHAR   iFunction;
} USB_IAD_DESCRIPTOR, *PUSB_IAD_DESCRIPTOR;


// Common Class Endpoint Descriptor
//
typedef struct _USB_ENDPOINT_DESCRIPTOR2 {
    UCHAR  bLength;             // offset 0, size 1
    UCHAR  bDescriptorType;     // offset 1, size 1
    UCHAR  bEndpointAddress;    // offset 2, size 1
    UCHAR  bmAttributes;        // offset 3, size 1
    USHORT wMaxPacketSize;      // offset 4, size 2
    USHORT wInterval;           // offset 6, size 2
    UCHAR  bSyncAddress;        // offset 8, size 1
} USB_ENDPOINT_DESCRIPTOR2, *PUSB_ENDPOINT_DESCRIPTOR2;

// Common Class Interface Descriptor
//
typedef struct _USB_INTERFACE_DESCRIPTOR2 {
    UCHAR  bLength;             // offset 0, size 1
    UCHAR  bDescriptorType;     // offset 1, size 1
    UCHAR  bInterfaceNumber;    // offset 2, size 1
    UCHAR  bAlternateSetting;   // offset 3, size 1
    UCHAR  bNumEndpoints;       // offset 4, size 1
    UCHAR  bInterfaceClass;     // offset 5, size 1
    UCHAR  bInterfaceSubClass;  // offset 6, size 1
    UCHAR  bInterfaceProtocol;  // offset 7, size 1
    UCHAR  iInterface;          // offset 8, size 1
    USHORT wNumClasses;         // offset 9, size 2
} USB_INTERFACE_DESCRIPTOR2, *PUSB_INTERFACE_DESCRIPTOR2;


//
// USB Device Class Definition for Audio Devices
//

typedef struct _USB_AUDIO_COMMON_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
} USB_AUDIO_COMMON_DESCRIPTOR,
*PUSB_AUDIO_COMMON_DESCRIPTOR;

// 4.3.2 Class-Specific AC (Audio Control) Interface Descriptor
//
typedef struct _USB_AUDIO_AC_INTERFACE_HEADER_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    USHORT bcdADC;
    USHORT wTotalLength;
    UCHAR  bInCollection;
    UCHAR  baInterfaceNr[1];
} USB_AUDIO_AC_INTERFACE_HEADER_DESCRIPTOR,
*PUSB_AUDIO_AC_INTERFACE_HEADER_DESCRIPTOR;

// 4.3.2.1 Input Terminal Descriptor
//
typedef struct _USB_AUDIO_INPUT_TERMINAL_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bTerminalID;
    USHORT wTerminalType;
    UCHAR  bAssocTerminal;
    UCHAR  bNrChannels;
    USHORT wChannelConfig;
    UCHAR  iChannelNames;
    UCHAR  iTerminal;
} USB_AUDIO_INPUT_TERMINAL_DESCRIPTOR,
*PUSB_AUDIO_INPUT_TERMINAL_DESCRIPTOR;

// 4.3.2.2 Output Terminal Descriptor
//
typedef struct _USB_AUDIO_OUTPUT_TERMINAL_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bTerminalID;
    USHORT wTerminalType;
    UCHAR  bAssocTerminal;
    UCHAR  bSourceID;
    UCHAR  iTerminal;
} USB_AUDIO_OUTPUT_TERMINAL_DESCRIPTOR,
*PUSB_AUDIO_OUTPUT_TERMINAL_DESCRIPTOR;

// 4.3.2.3 Mixer Unit Descriptor
//
typedef struct _USB_AUDIO_MIXER_UNIT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bUnitID;
    UCHAR  bNrInPins;
    UCHAR  baSourceID[1];
} USB_AUDIO_MIXER_UNIT_DESCRIPTOR,
*PUSB_AUDIO_MIXER_UNIT_DESCRIPTOR;

// 4.3.2.4 Selector Unit Descriptor
//
typedef struct _USB_AUDIO_SELECTOR_UNIT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bUnitID;
    UCHAR  bNrInPins;
    UCHAR  baSourceID[1];
} USB_AUDIO_SELECTOR_UNIT_DESCRIPTOR,
*PUSB_AUDIO_SELECTOR_UNIT_DESCRIPTOR;

// 4.3.2.5 Feature Unit Descriptor
//
typedef struct _USB_AUDIO_FEATURE_UNIT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bUnitID;
    UCHAR  bSourceID;
    UCHAR  bControlSize;
    UCHAR  bmaControls[1];
} USB_AUDIO_FEATURE_UNIT_DESCRIPTOR,
*PUSB_AUDIO_FEATURE_UNIT_DESCRIPTOR;

// 4.3.2.6 Processing Unit Descriptor
//
typedef struct _USB_AUDIO_PROCESSING_UNIT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bUnitID;
    USHORT wProcessType;
    UCHAR  bNrInPins;
    UCHAR  baSourceID[1];
} USB_AUDIO_PROCESSING_UNIT_DESCRIPTOR,
*PUSB_AUDIO_PROCESSING_UNIT_DESCRIPTOR;

// 4.3.2.7 Extension Unit Descriptor
//
typedef struct _USB_AUDIO_EXTENSION_UNIT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bUnitID;
    USHORT wExtensionCode;
    UCHAR  bNrInPins;
    UCHAR  baSourceID[1];
} USB_AUDIO_EXTENSION_UNIT_DESCRIPTOR,
*PUSB_AUDIO_EXTENSION_UNIT_DESCRIPTOR;

// 4.5.2 Class-Specific AS Interface Descriptor
//
typedef struct _USB_AUDIO_GENERAL_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bTerminalLink;
    UCHAR  bDelay;
    USHORT wFormatTag;
} USB_AUDIO_GENERAL_DESCRIPTOR,
*PUSB_AUDIO_GENERAL_DESCRIPTOR;

// 4.6.1.2 Class-Specific AS Endpoint Descriptor
//
typedef struct _USB_AUDIO_ENDPOINT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bmAttributes;
    UCHAR  bLockDelayUnits;
    USHORT wLockDelay;
} USB_AUDIO_ENDPOINT_DESCRIPTOR,
*PUSB_AUDIO_ENDPOINT_DESCRIPTOR;

//
// USB Device Class Definition for Audio Data Formats
//

typedef struct _USB_AUDIO_COMMON_FORMAT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bFormatType;
} USB_AUDIO_COMMON_FORMAT_DESCRIPTOR,
*PUSB_AUDIO_COMMON_FORMAT_DESCRIPTOR;


// 2.1.5 Type I   Format Type Descriptor
// 2.3.1 Type III Format Type Descriptor
//
typedef struct _USB_AUDIO_TYPE_I_OR_III_FORMAT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bFormatType;
    UCHAR  bNrChannels;
    UCHAR  bSubframeSize;
    UCHAR  bBitResolution;
    UCHAR  bSamFreqType;
} USB_AUDIO_TYPE_I_OR_III_FORMAT_DESCRIPTOR,
*PUSB_AUDIO_TYPE_I_OR_III_FORMAT_DESCRIPTOR;


// 2.2.6 Type II  Format Type Descriptor
//
typedef struct _USB_AUDIO_TYPE_II_FORMAT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bFormatType;
    USHORT wMaxBitRate;
    USHORT wSamplesPerFrame;
    UCHAR  bSamFreqType;
} USB_AUDIO_TYPE_II_FORMAT_DESCRIPTOR,
*PUSB_AUDIO_TYPE_II_FORMAT_DESCRIPTOR;

#pragma pack(pop)
