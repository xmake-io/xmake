/*++

Copyright (c) 2002-2003 Microsoft Corporation

Module Name:

    USBVIDDESC.H

Abstract:

    This is a header file for USB Video Class Specific descriptors which are not yet in
    a standard system header file.

Environment:

    user mode

Revision History:

    11-20-2002 : created
    03-28-2003 : major updates to support latest UVC specs

--*/

#pragma pack(push, 1)

/*****************************************************************************
 D E F I N E S
*****************************************************************************/

//global version for USB Video Class spec version
#define BCDVDC     0x0083

//
// USB Device Class Definition for Video Devices v8.c
// Appendix A.  Video Device Class Codes
//

// A.1 Video Interface Class Code
//TBD Normally would be in USB100.h but not official yet
#define USB_DEVICE_CLASS_VIDEO             0x0E
#define USB_DEVICE_CLASS_VIDEO_PRERELEASE  0xFF
//CC_VIDEO in spec.  The rest of the codes will be USB_VIDEO plus text from spec codes

// A.2  Video Interface Subclass Codes
//
#define USB_VIDEO_SC_UNDEFINED                   0x00
#define USB_VIDEO_SC_VIDEOCONTROL                0x01
#define USB_VIDEO_SC_VIDEOSTREAMING              0x02
#define USB_VIDEO_SC_VIDEO_INTERFACE_COLLECTION  0x03

// A.3  Video Interface Protocol Codes
//
#define USB_VIDEO_PC_PROTOCOL_UNDEFINED     0x00

// A.4  Video Class-Specific Descriptor Types
//
#define USB_VIDEO_CS_UNDEFINED              0x20
#define USB_VIDEO_CS_DEVICE                 0x21
#define USB_VIDEO_CS_CONFIGURATION          0x22
#define USB_VIDEO_CS_STRING                 0x23
#define USB_VIDEO_CS_INTERFACE              0x24
#define USB_VIDEO_CS_ENDPOINT               0x25

// A.5  Video Class-Specific VC (Video Control) Interface Descriptor Subtypes
//
#define USB_VIDEO_VC_DESCRIPTOR_UNDEFINED   0x00
#define USB_VIDEO_VC_HEADER                 0x01
#define USB_VIDEO_VC_INPUT_TERMINAL         0x02
#define USB_VIDEO_VC_OUTPUT_TERMINAL        0x03
#define USB_VIDEO_VC_SELECTOR_UNIT          0x04
#define USB_VIDEO_VC_PROCESSING_UNIT        0x05
#define USB_VIDEO_VC_EXTENSION_UNIT         0x06

// A.6  Video Class-Specific VS (Video Streaming) Interface Descriptor Subtypes
//
#define USB_VIDEO_VS_UNDEFINED              0x00
#define USB_VIDEO_VS_INPUT_HEADER           0x01
#define USB_VIDEO_VS_OUTPUT_HEADER          0x02
#define USB_VIDEO_VS_STILL_IMAGE_FRAME      0x03
#define USB_VIDEO_VS_FORMAT_UNCOMPRESSED    0x04
#define USB_VIDEO_VS_FRAME_UNCOMPRESSED     0x05
#define USB_VIDEO_VS_FORMAT_MJPEG           0x06
#define USB_VIDEO_VS_FRAME_MJPEG            0x07
#define USB_VIDEO_VS_FORMAT_MPEG1           0x08
#define USB_VIDEO_VS_FORMAT_MPEG2PS         0x09
#define USB_VIDEO_VS_FORMAT_MPEG2TS         0x0A
#define USB_VIDEO_VS_FORMAT_MPEG4SL         0x0B
#define USB_VIDEO_VS_FORMAT_DV              0x0C
#define USB_VIDEO_VS_COLORFORMAT            0x0D
#define USB_VIDEO_VS_FORMAT_VENDOR          0x0E
#define USB_VIDEO_VS_FRAME_VENDOR           0x0F

// A.7 Video Class-Specific Endpoint Descriptor Subtypes
//
#define USB_VIDEO_EP_UNDEFINED              0x00
#define USB_VIDEO_EP_GENERAL                0x01
#define USB_VIDEO_EP_ENDPOINT               0x02
#define USB_VIDEO_EP_INTERRUPT              0x03

//
// Below definitions only necessary if testing requests
//
// A.8 Video Class-Specific Request Codes
//
#define USB_VIDEO_RC_UNDEFINED  0x00
#define USB_VIDEO_SET_CUR       0x01
#define USB_VIDEO_GET_CUR       0x81
#define USB_VIDEO_GET_MIN       0x82
#define USB_VIDEO_GET_MAX       0x83
#define USB_VIDEO_GET_RES       0x84
#define USB_VIDEO_GET_LEN       0x85
#define USB_VIDEO_GET_INFO      0x86
#define USB_VIDEO_GET_DEF       0x87

// A.9 Control Selector Codes
// A.9.1 VideoControl Interface Control Selectors
#define USB_VIDEO_VC_UNDEFINED_CONTROL            0x00
#define USB_VIDEO_VC_VIDEO_POWER_MODE_CONTROL     0x01
#define USB_VIDEO_VC_REQUEST_ERROR_CODE_CONTROL   0x02
#define USB_VIDEO_VC_INDICATE_HOST_CLOCK_CONTROL  0x03

//A.9.2 Terminal Control Selectors
//
#define USB_VIDEO_TE_CONTROL_UNDEFINED  0x00

//A.9.3 Selector Unit Control Selectors
//
#define USB_VIDEO_SU_CONTROL_UNDEFINED     0x00
#define USB_VIDEO_SU_INPUT_SELECT_CONTROL  0x01

//A.9.4 Camera Terminal Control Selectors
//
#define USB_VIDEO_CT_CONTROL_UNDEFINED               0x00
#define USB_VIDEO_CT_SCANNING_MODE_CONTROL           0x01
#define USB_VIDEO_CT_AE_MODE_CONTROL                 0x02
#define USB_VIDEO_CT_AE_PRIORITY_CONTROL             0x03
#define USB_VIDEO_CT_EXPOSURE_TIME_ABSOLUTE_CONTROL  0x04
#define USB_VIDEO_CT_EXPOSURE_TIME_RELATIVE_CONTROL  0x05
#define USB_VIDEO_CT_FOCUS_ABSOLUTE_CONTROL          0x06
#define USB_VIDEO_CT_FOCUS_RELATIVE_CONTROL          0x07
#define USB_VIDEO_CT_FOCUS_AUTO_CONTROL              0x08
#define USB_VIDEO_CT_IRIS_ABSOLUTE_CONTROL           0x09
#define USB_VIDEO_CT_IRIS_RELATIVE_CONTROL           0x0A
#define USB_VIDEO_CT_ZOOM_ABSOLUTE_CONTROL           0x0B
#define USB_VIDEO_CT_ZOOM_RELATIVE_CONTROL           0x0C
#define USB_VIDEO_CT_PANTILT_ABSOLUTE_CONTROL        0x0D
#define USB_VIDEO_CT_PANTILT_RELATIVE_CONTROL        0x0E
#define USB_VIDEO_CT_ROLL_ABSOLUTE_CONTROL           0x0F
#define USB_VIDEO_CT_ROLL_RELATIVE_CONTROL           0x10

//A.9.5 Processing Unit Control Selectors
//
#define USB_VIDEO_PU_CONTROL_UNDEFINED                       0x04
#define USB_VIDEO_PU_BACKLIGHT_COMPENSATION_CONTROL          0x01
#define USB_VIDEO_PU_BRIGHTNESS_CONTROL                      0x02
#define USB_VIDEO_PU_CONTRAST_CONTROL                        0x03
#define USB_VIDEO_PU_GAIN_CONTROL                            0x04
#define USB_VIDEO_PU_POWER_LINE_FREQUENCY_CONTROL            0x05
#define USB_VIDEO_PU_HUE_CONTROL                             0x06
#define USB_VIDEO_PU_SATURATION_CONTROL                      0x07
#define USB_VIDEO_PU_SHARPNESS_CONTROL                       0x08
#define USB_VIDEO_PU_GAMMA_CONTROL                           0x09
#define USB_VIDEO_PU_WHITE_BALANCE_TEMPERATURE_CONTROL       0x0A
#define USB_VIDEO_PU_WHITE_BALANCE_TEMPERATURE_AUTO_CONTROL  0x0B
#define USB_VIDEO_PU_WHITE_BALANCE_COMPONENT_CONTROL         0x0C
#define USB_VIDEO_PU_WHITE_BALANCE_COMPONENT_AUTO_CONTROL    0x0D
#define USB_VIDEO_PU_DIGITAL_MULTIPLIER_CONTROL              0x0E
#define USB_VIDEO_PU_DIGITAL_MULTIPLIER_LIMIT_CONTROL        0x0F
#define USB_VIDEO_PU_HUE_AUTO_CONTROL                        0x10

//A.9.6 Extension Unit Control Selectors
//
#define USB_VIDEO_XU_CONTROL_UNDEFINED  0x00

//A.9.7 VideoStreaming Interface Control Selectors
//
#define USB_VIDEO_VS_CONTROL_UNDEFINED             0x00
#define USB_VIDEO_VS_PROBE_CONTROL                 0x01
#define USB_VIDEO_VS_COMMIT_CONTROL                0x02
#define USB_VIDEO_VS_STILL_PROBE_CONTROL           0x03
#define USB_VIDEO_VS_STILL_COMMIT_CONTROL          0x04
#define USB_VIDEO_VS_STILL_IMAGE_TRIGGER_CONTROL   0x05
#define USB_VIDEO_VS_STREAM_ERROR_CODE_CONTROL     0x06
#define USB_VIDEO_VS_GENERATE_KEY_FRAME_CONTROL    0x07
#define USB_VIDEO_VS_UPDATE_FRAME_SEGMENT_CONTROL  0x08
#define USB_VIDEO_VS_SYNCH_DELAY_CONTROL           0x09

#define TapeControls       0
#define TransportModes     1
#define CameraControls     2
#define ProcessorControls  3
#define InHeaderControls   4

/*****************************************************************************
 T Y P E D E F S
*****************************************************************************/


/*****************************************************************************
 USB Device Class Definition for Video Devices v8.b
*****************************************************************************/

typedef struct _USB_VIDEO_COMMON_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
} USB_VIDEO_COMMON_DESCRIPTOR,
*PUSB_VIDEO_COMMON_DESCRIPTOR;

// 3.6.2 Class-Specific VC (Video Control) Interface Descriptor
//
typedef struct _USB_VIDEO_VC_INTERFACE_HEADER_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    USHORT   bcdVDC;
    USHORT   wTotalLength;
    ULONG32  dwClockFrequency;
    UCHAR    bInCollection;
//    UCHAR    baInterfaceNr;          // variable length (0 minimum)
} USB_VIDEO_VC_INTERFACE_HEADER_DESCRIPTOR,
*PUSB_VIDEO_VC_INTERFACE_HEADER_DESCRIPTOR;

// 3.6.2.1 Input Terminal Descriptor
//
typedef struct _USB_VIDEO_INPUT_TERMINAL_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bTerminalID;
    USHORT   wTerminalType;
    UCHAR    bAssocTerminal;
    UCHAR    iTerminal;
} USB_VIDEO_INPUT_TERMINAL_DESCRIPTOR,
*PUSB_VIDEO_INPUT_TERMINAL_DESCRIPTOR;

// 3.6.2.2 Output Terminal Descriptor
//
typedef struct _USB_VIDEO_OUTPUT_TERMINAL_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bTerminalID;
    USHORT   wTerminalType;
    UCHAR    bAssocTerminal;
    UCHAR    bSourceID;
    UCHAR    iTerminal;
} USB_VIDEO_OUTPUT_TERMINAL_DESCRIPTOR,
*PUSB_VIDEO_OUTPUT_TERMINAL_DESCRIPTOR;

// 3.6.2.3 Camera Unit Descriptor
//
typedef struct _USB_VIDEO_CAMERA_TERMINAL_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bTerminalID;
    USHORT   wTerminalType;
    UCHAR    bAssocTerminal;
    UCHAR    iTerminal;
    USHORT   wObjectiveFocalLengthMin;
    USHORT   wObjectiveFocalLengthMax;
    USHORT   wOcularFocalLength;
    UCHAR    bControlSize;
//    UCHAR    bmControls;               // variable length (0 min, 3 max)
} USB_VIDEO_CAMERA_TERMINAL_DESCRIPTOR,
*PUSB_VIDEO_CAMERA_TERMINAL_DESCRIPTOR;

// 3.6.2.4 Selector Unit Descriptor
//
typedef struct _USB_VIDEO_SELECTOR_UNIT_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bUnitID;
    UCHAR    bNrInPins;
    UCHAR    baSourceID;               // variable length (1 minimum)
    UCHAR    iSelector;
} USB_VIDEO_SELECTOR_UNIT_DESCRIPTOR,
*PUSB_VIDEO_SELECTOR_UNIT_DESCRIPTOR;

// 3.6.2.5 Processing Unit Descriptor
//
typedef struct _USB_VIDEO_PROCESSING_UNIT_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bUnitID;
    UCHAR    bSourceID;
    USHORT   wMaxMultiplier;
    UCHAR    bControlSize;
//    UCHAR    bmControls;             // variable length (0 minimum)
    UCHAR    iProcessing;
} USB_VIDEO_PROCESSING_UNIT_DESCRIPTOR,
*PUSB_VIDEO_PROCESSING_UNIT_DESCRIPTOR;

// 3.6.2.6 Extension Unit Descriptor
//
typedef struct _USB_VIDEO_EXTENSION_UNIT_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bUnitID;
    GUID     guidExtensionCode;
    UCHAR    bNumControls;
    UCHAR    bNrInPins;
    UCHAR    baSourceID;               // variable length (1 minimum)
//    UCHAR    bControlSize;
//    UCHAR    bmControls;             // variable length (0 minimum)
//    UCHAR    iExtension;
} USB_VIDEO_EXTENSION_UNIT_DESCRIPTOR,
*PUSB_VIDEO_EXTENSION_UNIT_DESCRIPTOR;

// 3.7.2.2 Class-Specific VC Interrupt EndPoint Descriptor
//
typedef struct _USB_VIDEO_VC_INTERRUPT_ENDPOINT_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubType;
    USHORT   wMaxTransferSize;
} USB_VIDEO_VC_INTERRUPT_ENDPOINT_DESCRIPTOR,
*PUSB_VIDEO_VC_INTERRUPT_ENDPOINT_DESCRIPTOR;
// 3.8.2.1 Class-Specific Input Header Descriptor
//
typedef struct _USB_VIDEO_INPUT_HEADER_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bNumFormats;
    USHORT   wTotalLength;
    UCHAR    bEndpointAddress;
    UCHAR    bmInfo;
    UCHAR    bTerminalLink;
    UCHAR    bStillCaptureMethod;
    UCHAR    bTriggerSupport;
    UCHAR    bTriggerUsage;
    UCHAR    bControlSize;
//    UCHAR    bmaControls;            // variable length (0 minimum)
} USB_VIDEO_INPUT_HEADER_DESCRIPTOR,
*PUSB_VIDEO_INPUT_HEADER_DESCRIPTOR;

// 3.8.2.2 Class-Specific Output Header Descriptor
//
typedef struct _USB_VIDEO_OUTPUT_HEADER_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bNumFormats;
    USHORT wTotalLength;
    UCHAR  bEndpointAddress;
    UCHAR  bTerminalLink;
} USB_VIDEO_OUTPUT_HEADER_DESCRIPTOR,
*PUSB_VIDEO_OUTPUT_HEADER_DESCRIPTOR;

// 3.8.2.3  Payload Format Descriptors
//Payload Format Descriptor  Document
//Uncompressed Video         DWGVideo Payload Uncompressed 0.xx.doc
//MJPEG Video                DWGVideo Payload MJPEG Format Ver0.xx.doc
//MPEG1 System Stream        DWGVideo Payload MPEG1 System Stream, MPEG2-PS Format Ver0.xx.doc
//MPEG2 PS                   DWGVideo Payload MPEG1 System Stream, MPEG2-PS Format Ver0.xx.doc
//MPEG-2 TS                  DWGVideo Payload MPEG2TS Format Ver0.xx.doc
//MPEG-4 SL                  DWGVideo Payload MPEG4 SL format Ver0.xx.doc
//DV                         DWGVideo Payload DV Format Ver0.xx.doc

// 3.8.2.4  Video Frame Descriptor
//
//Video Frame Descriptor     Document
//Uncompressed               DWGVideo Payload Uncompressed 0.xx.doc
//MJPEG                      DWGVideo Payload MJPEG Format Ver0.xx.doc

// 3.8.2.5  Still Image Frame Descriptor
//
typedef struct _VIDEO_STILL_IMAGE {
    USHORT  wWidth;
    USHORT  wHeight;
} VIDEO_STILL_IMAGE,
*PVIDEO_STILL_IMAGE;

typedef struct _USB_VIDEO_STILL_IMAGE_FRAME_DESCRIPTOR {
    UCHAR              bLength;
    UCHAR              bDescriptorType;
    UCHAR              bDescriptorSubtype;
    UCHAR              bEndpointAddress;
    UCHAR              bNumImageSizePatterns;
    VIDEO_STILL_IMAGE  dwStillImage;             // variable count
    UCHAR              bNumCompressionPattern;
    UCHAR              bCompression;             // variable count
} USB_VIDEO_STILL_IMAGE_FRAME_DESCRIPTOR,
*PUSB_VIDEO_STILL_IMAGE_FRAME_DESCRIPTOR;

// 3.8.2.6  Color Matching Descriptor
//
typedef struct _USB_VIDEO_COLOR_MATCHING_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bColorPrimaries;
    UCHAR  bTransferCharacteristics;
    UCHAR  bMatrixCoefficients;
} USB_VIDEO_COLOR_MATCHING_DESCRIPTOR,
*PUSB_VIDEO_COLOR_MATCHING_DESCRIPTOR;
/*
// 3.9.1  Class-specific VC Interrupt Endpoint Descriptor
typedef struct _USB_VIDEO_VS_ENDPOINT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubType;
    USHORT  wMaxTransferSize;
} USB_VIDEO_VS_ENDPOINT_DESCRIPTOR,
*PUSB_VIDEO_VS_ENDPOINT_DESCRIPTOR;
*/
//
// USB Device Class Definition for Video Devices: Uncompressed Payload 0.8a Draft Revision
//

// 3.1.1    Uncompressed Video Format Descriptor
//
typedef struct _USB_VIDEO_UNCOMPRESSED_FORMAT_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFormatIndex;
    UCHAR    bNumFrameDescriptors;
    GUID     guidFormat;
    UCHAR    bBitsPerPixel;
    UCHAR    bDefaultFrameIndex;
    UCHAR    bAspectRatioX;
    UCHAR    bAspectRatioY;
    UCHAR    bmInterlaceFlags;
    UCHAR    bCopyProtect;
} USB_VIDEO_UNCOMPRESSED_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_UNCOMPRESSED_FORMAT_DESCRIPTOR;

// 3.1.2    Uncompressed Video Frame Descriptor Common
//
typedef struct _USB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_COMMON {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
} USB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_COMMON,
*PUSB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_COMMON;

// 3.1.2    Uncompressed Video Frame Descriptor - Continuous
//
typedef struct _USB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_CONTINUOUS {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
    ULONG32  dwMinFrameInterval;
    ULONG32  dwMaxFrameInterval;
    ULONG32  dwFrameIntervalStep;
} USB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_CONTINUOUS,
*PUSB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_CONTINUOUS;

// 3.1.2    Uncompressed Video Frame Descriptor - Discrete
//
typedef struct _USB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_DISCRETE {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
    ULONG32  dwFrameInterval;                    // variable count
} USB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_DISCRETE,
*PUSB_VIDEO_UNCOMPRESSED_FRAME_DESCRIPTOR_DISCRETE;

//
// USB Device Class Definition for Video Devices: Motion-JPEG Payload 0.8a Draft Revision
// 3.1.1    MJPEG Video Format Descriptor
//
typedef struct _USB_VIDEO_MJPEG_FORMAT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bFormatIndex;
    UCHAR  bNumFrameDescriptors;
    UCHAR  bmFlags;
    UCHAR  bDefaultFrameIndex;
    UCHAR  bAspectRatioX;
    UCHAR  bAspectRatioY;
    UCHAR  bmInterlaceFlags;
    UCHAR  bCopyProtect;
} USB_VIDEO_MJPEG_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_MJPEG_FORMAT_DESCRIPTOR;

// 3.1.2    MJPEG Video Frame Descriptors Common
//
typedef struct _USB_VIDEO_MJPEG_FRAME_DESCRIPTOR_COMMON {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
} USB_VIDEO_MJPEG_FRAME_DESCRIPTOR_COMMON,
*PUSB_VIDEO_MJPEG_FRAME_DESCRIPTOR_COMMON;

// 3.1.2    MJPEG Video Frame Descriptors - Continuous
//
typedef struct _USB_VIDEO_MJPEG_FRAME_DESCRIPTOR_CONTINUOUS {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
    ULONG32  dwMinFrameInterval;
    ULONG32  dwMaxFrameInterval;
    ULONG32  dwFrameIntervalStep;
} USB_VIDEO_MJPEG_FRAME_DESCRIPTOR_CONTINUOUS,
*PUSB_VIDEO_MJPEG_FRAME_DESCRIPTOR_CONTINUOUS;

// 3.1.2    MJPEG Video Frame Descriptors -Discrete
//
typedef struct _USB_VIDEO_MJPEG_FRAME_DESCRIPTOR_DISCRETE {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
    ULONG32  dwFrameInterval;                    // variable count
} USB_VIDEO_MJPEG_FRAME_DESCRIPTOR_DISCRETE,
*PUSB_VIDEO_MJPEG_FRAME_DESCRIPTOR_DISCRETE;

//
// USB Device Class Definition for Video Devices: MPEG1-SS, MPEG2-PS Payload 0.8a Draft Revision
// 3.1.1    MPEG1 System Stream Format Descriptor
//
typedef struct _USB_VIDEO_MPEG1_SS_FORMAT_DESCRIPTOR {
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bDescriptorSubtype;
    UCHAR   bFormatIndex;
    USHORT  wPacketLength;
    USHORT  wPackLength;
    UCHAR   bPackdataType;
} USB_VIDEO_MPEG1_SS_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_MPEG1_SS_FORMAT_DESCRIPTOR;

// 3.1.2    MPEG2 PS Format Descriptor
//
typedef struct _USB_VIDEO_MPEG2_PS_FORMAT_DESCRIPTOR {
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bDescriptorSubtype;
    UCHAR   bFormatIndex;
    USHORT  wPacketLength;
    USHORT  wPackLength;
    UCHAR   bPackdataType;
} USB_VIDEO_MPEG2_PS_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_MPEG2_PS_FORMAT_DESCRIPTOR;

//
// USB Device Class Definition for Video Devices: MPEG-2 TS Payload 0.8a Draft Revision
// 3.1.1    MPEG-2 TS Format Descriptor
//
typedef struct _USB_VIDEO_MPEG2_TS_FORMAT_DESCRIPTOR {
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bDescriptorSubtype;
    UCHAR   bFormatIndex;
    UCHAR   bDataOffset;
    UCHAR   bPacketLength;
    UCHAR   bStrideLength;
} USB_VIDEO_MPEG2_TS_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_MPEG2_TS_FORMAT_DESCRIPTOR;

//
// USB Device Class Definition for Video Devices: MPEG4 SL Payload 0.8a Draft Revision
// 3.1.1    MPEG4 SL Format Descriptor
//
typedef struct _USB_VIDEO_MPEG4_SL_FORMAT_DESCRIPTOR {
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bDescriptorSubtype;
    UCHAR   bFormatIndex;
    USHORT  wPacketLength;
} USB_VIDEO_MPEG4_SL_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_MPEG4_SL_FORMAT_DESCRIPTOR;

// USB Device Class Definition for Video Devices: DV Payload 0.8a Draft Revision
// 3.1.1    DV Format Descriptor
typedef struct _USB_VIDEO_DV_FORMAT_DESCRIPTOR {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFormatIndex;
    ULONG32  dwMaxVideoFrameBufferSize;
    UCHAR    bFormatType;
} USB_VIDEO_DV_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_DV_FORMAT_DESCRIPTOR;

// USB Device Class Definition for Video Devices: Vendor Payload 0.8c Draft Revision
// 3.1.1    Vendor Video Format Descriptor
typedef struct _USB_VIDEO_VENDOR_VIDEO_FORMAT_DESCRIPTOR {
    UCHAR  bLength;
    UCHAR  bDescriptorType;
    UCHAR  bDescriptorSubtype;
    UCHAR  bFormatIndex;
    UCHAR  bNumFrameDescriptors;
    GUID   guidMajorFormat;
    GUID   guidSubFormat;
    GUID   guidSpecifier;
    UCHAR  bPayloadClass;
    UCHAR  bDefaultFrameIndex;
    UCHAR  bCopyProtect;
} USB_VIDEO_VENDOR_VIDEO_FORMAT_DESCRIPTOR,
*PUSB_VIDEO_VENDOR_VIDEO_FORMAT_DESCRIPTOR;

// USB Device Class Definition for Video Devices: Vendor Payload 0.8c Draft Revision
// 3.1.2    Vendor Video Frame Descriptor
typedef struct _USB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_COMMON {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
} USB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_COMMON,
*PUSB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_COMMON;

typedef struct _USB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_CONTINUOUS {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
    ULONG32  dwMinFrameInterval;
    ULONG32  dwMaxFrameInterval;
    ULONG32  dwFrameIntervalStep;
} USB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_CONTINUOUS,
*PUSB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_CONTINUOUS;

typedef struct _USB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_DISCRETE {
    UCHAR    bLength;
    UCHAR    bDescriptorType;
    UCHAR    bDescriptorSubtype;
    UCHAR    bFrameIndex;
    UCHAR    bmCapabilities;
    USHORT   wWidth;
    USHORT   wHeight;
    ULONG32  dwMinBitRate;
    ULONG32  dwMaxBitRate;
    ULONG32  dwMaxVideoFrameBufferSize;
    ULONG32  dwDefaultFrameInterval;
    UCHAR    bFrameIntervalType;
    ULONG32  dwFrameInterval;                    // variable count
} USB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_DISCRETE,
*PUSB_VIDEO_VENDOR_VIDEO_FRAME_DESCRIPTOR_DISCRETE;

// USB Device Class Definition for Video Devices: Media Transport Terminal 0.8a Draft Revision
// 3.1  Media Transport Input Descriptor
typedef struct _USB_VIDEO_MEDIA_TRANSPORT_INPUT_DESCRIPTOR {
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bDescriptorSubtype;
    UCHAR   bTerminalID;
    USHORT  wTerminalType;
    UCHAR   bAssocTerminal;
    UCHAR   iTerminal;
    UCHAR   bControlSize;
    UCHAR   bmControls;                          // variable size (min 1)
//    UCHAR   bTransportModeSize;                // variable count (min 0)
//    UCHAR   bmTransportModes;                  // variable count (min 0)
} USB_VIDEO_MEDIA_TRANSPORT_INPUT_DESCRIPTOR,
*PUSB_VIDEO_MEDIA_TRANSPORT_INPUT_DESCRIPTOR;

// 3.2  Media Transport Output Descriptor
typedef struct _USB_VIDEO_MEDIA_TRANSPORT_OUTPUT_DESCRIPTOR {
    UCHAR   bLength;
    UCHAR   bDescriptorType;
    UCHAR   bDescriptorSubtype;
    UCHAR   bTerminalID;
    USHORT  wTerminalType;
    UCHAR   bAssocTerminal;
    UCHAR   bSourceID;
    UCHAR   iTerminal;
    UCHAR   bControlSize;
    UCHAR   bmControls;                          // variable size (min 1)
//    UCHAR   bTransportModeSize;                // variable count (min 0)
//    UCHAR   bmTransportModes;                  // variable count (min 0)
} USB_VIDEO_MEDIA_TRANSPORT_OUTPUT_DESCRIPTOR,
*PUSB_VIDEO_MEDIA_TRANSPORT_OUTPUT_DESCRIPTOR;

#pragma pack(pop)
