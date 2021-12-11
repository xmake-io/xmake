//+-------------------------------------------------------------------------
//
//  Microsoft Windows
//
//  Copyright (C) Microsoft Corporation, 1999 - 2008
//
//  File:       uvcdesc.h
//
//  This header is from the UVC 1.1 USBVideo driver
//
//--------------------------------------------------------------------------

#ifndef ___UVCDESC_H___
#define ___UVCDESC_H___


// USB Video Device Class Code
#define USB_DEVICE_CLASS_VIDEO     0x0E 

// Video sub-classes
#define SUBCLASS_UNDEFINED              0x00
#define VIDEO_SUBCLASS_CONTROL          0x01
#define VIDEO_SUBCLASS_STREAMING        0x02

// Video Class-Specific Descriptor Types
#define CS_UNDEFINED     0x20
#define CS_DEVICE        0x21
#define CS_CONFIGURATION 0x22
#define CS_STRING        0x23
#define CS_INTERFACE     0x24
#define CS_ENDPOINT      0x25

// Video Class-Specific VC Interface Descriptor Subtypes
#define VC_HEADER       0x01
#define INPUT_TERMINAL  0x02
#define OUTPUT_TERMINAL 0x03
#define SELECTOR_UNIT   0x04
#define PROCESSING_UNIT 0x05
#define EXTENSION_UNIT  0x06 
#define MAX_TYPE_UNIT   0x07

// Video Class-Specific VS Interface Descriptor Subtypes
#define VS_DESCRIPTOR_UNDEFINED 0x00
#define VS_INPUT_HEADER         0x01
#define VS_OUTPUT_HEADER        0x02
#define VS_STILL_IMAGE_FRAME    0x03
#define VS_FORMAT_UNCOMPRESSED  0x04
#define VS_FRAME_UNCOMPRESSED   0x05
#define VS_FORMAT_MJPEG         0x06
#define VS_FRAME_MJPEG          0x07
#define VS_FORMAT_MPEG1         0x08
#define VS_FORMAT_MPEG2PS       0x09
#define VS_FORMAT_MPEG2TS       0x0A
#define VS_FORMAT_MPEG4SL       0x0B
#define VS_FORMAT_DV            0x0C
#define VS_COLORFORMAT          0x0D
#define VS_FORMAT_VENDOR        0x0E
#define VS_FRAME_VENDOR         0x0F

// Video Class-Specific Endpoint Descriptor Subtypes
#define EP_UNDEFINED            0x00
#define EP_GENERAL              0x01
#define EP_ENDPOINT             0x02
#define EP_INTERRUPT            0x03

// Video Class-Specific Terminal Types
#define TERMINAL_TYPE_VENDOR_SPECIFIC           0x0100
#define TERMINAL_TYPE_USB_STREAMING             0x0101
#define TERMINAL_TYPE_INPUT_MASK                0x0200
#define TERMINAL_TYPE_INPUT_VENDOR_SPECIFIC     0x0200
#define TERMINAL_TYPE_INPUT_CAMERA              0x0201
#define TERMINAL_TYPE_INPUT_MEDIA_TRANSPORT     0x0202
#define TERMINAL_TYPE_OUTPUT_MASK               0x0300
#define TERMINAL_TYPE_OUTPUT_VENDOR_SPECIFIC    0x0300
#define TERMINAL_TYPE_OUTPUT_DISPLAY            0x0301
#define TERMINAL_TYPE_OUTPUT_MEDIA_TRANSPORT    0x0302
#define TERMINAL_TYPE_EXTERNAL_VENDOR_SPECIFIC  0x0400
#define TERMINAL_TYPE_EXTERNAL_UNDEFINED        0x0400
#define TERMINAL_TYPE_EXTERNAL_COMPOSITE        0x0401
#define TERMINAL_TYPE_EXTERNAL_SVIDEO           0x0402
#define TERMINAL_TYPE_EXTERNAL_COMPONENT        0x0403


// Controls for error checking only
#define DEV_SPECIFIC_CONTROL 0x1001

// Map KSNODE_TYPE GUIDs to Indexes
#define NODE_TYPE_NONE              0
#define NODE_TYPE_STREAMING         1
#define NODE_TYPE_INPUT_TERMINAL    2
#define NODE_TYPE_OUTPUT_TERMINAL   3
#define NODE_TYPE_SELECTOR          4
#define NODE_TYPE_PROCESSING        5
#define NODE_TYPE_CAMERA_TERMINAL   6
#define NODE_TYPE_INPUT_MTT         7
#define NODE_TYPE_OUTPUT_MTT        8
#define NODE_TYPE_DEV_SPEC          9
#define NODE_TYPE_MAX               9

// USB bmRequestType values
#define USBVIDEO_INTERFACE_SET        0x21
#define USBVIDEO_ENDPOINT_SET         0x22
#define USBVIDEO_INTERFACE_GET        0xA1
#define USBVIDEO_ENDPOINT_GET         0xA2

// Video Class-specific specific requests
#define CLASS_SPECIFIC_GET_MASK 0x80

#define RC_UNDEFINED 0x00
#define SET_CUR 0x01
#define GET_CUR 0x81
#define GET_MIN 0x82
#define GET_MAX 0x83
#define GET_RES 0x84
#define GET_LEN 0x85
#define GET_INFO 0x86
#define GET_DEF 0x87

// Power Mode Control constants
#define POWER_MODE_CONTROL_FULL                   0x0
#define POWER_MODE_CONTROL_DEV_DEPENDENT          0x1

// Video Class-specific Processing Unit Controls
#define PU_CONTROL_UNDEFINED                      0x00
#define PU_BACKLIGHT_COMPENSATION_CONTROL         0x01
#define PU_BRIGHTNESS_CONTROL                     0x02
#define PU_CONTRAST_CONTROL                       0x03
#define PU_GAIN_CONTROL                           0x04
#define PU_POWER_LINE_FREQUENCY_CONTROL           0x05
#define PU_HUE_CONTROL                            0x06
#define PU_SATURATION_CONTROL                     0x07
#define PU_SHARPNESS_CONTROL                      0x08
#define PU_GAMMA_CONTROL                          0x09
#define PU_WHITE_BALANCE_TEMPERATURE_CONTROL      0x0A
#define PU_WHITE_BALANCE_TEMPERATURE_AUTO_CONTROL 0x0B
#define PU_WHITE_BALANCE_COMPONENT_CONTROL        0x0C
#define PU_WHITE_BALANCE_COMPONENT_AUTO_CONTROL   0x0D
#define PU_DIGITAL_MULTIPLIER_CONTROL             0x0E
#define PU_DIGITAL_MULTIPLIER_LIMIT_CONTROL       0x0F
#define PU_HUE_AUTO_CONTROL                       0x10
#define PU_ANALOG_VIDEO_STANDARD_CONTROL          0x11
#define PU_ANALOG_LOCK_STATUS_CONTROL             0x12

// Video Class-specific Camera Terminal Controls
#define CT_CONTROL_UNDEFINED                0x00
#define CT_SCANNING_MODE_CONTROL            0x01
#define CT_AE_MODE_CONTROL                  0x02
#define CT_AE_PRIORITY_CONTROL              0x03
#define CT_EXPOSURE_TIME_ABSOLUTE_CONTROL   0x04
#define CT_EXPOSURE_TIME_RELATIVE_CONTROL   0x05
#define CT_FOCUS_ABSOLUTE_CONTROL           0x06
#define CT_FOCUS_RELATIVE_CONTROL           0x07
#define CT_FOCUS_AUTO_CONTROL               0x08
#define CT_IRIS_ABSOLUTE_CONTROL            0x09
#define CT_IRIS_RELATIVE_CONTROL            0x0A
#define CT_ZOOM_ABSOLUTE_CONTROL            0x0B
#define CT_ZOOM_RELATIVE_CONTROL            0x0C
#define CT_PANTILT_ABSOLUTE_CONTROL         0x0D
#define CT_PANTILT_RELATIVE_CONTROL         0x0E
#define CT_ROLL_ABSOLUTE_CONTROL            0x0F
#define CT_ROLL_RELATIVE_CONTROL            0x10
#define CT_PRIVACY_CONTROL                  0x11

#define CT_RELATIVE_INCREASE                0x01
#define CT_RELATIVE_DECREASE                0xff
#define CT_RELATIVE_STOP                    0x00

// Selector Unit Control Selector
#define SU_INPUT_SELECT_CONTROL             0x01

// Media Tape Transport Control Selector
#define MTT_CONTROL_UNDEFINED               0x00
#define MTT_TRANSPORT_CONTROL               0x01
#define MTT_ATN_INFORMATION_CONTROL         0x02
#define MTT_MEDIA_INFORMATION_CONTROL       0x03
#define MTT_TIME_CODE_INFORMATION_CONTROL   0x04

// Media Transport Terminal States
#define MTT_STATE_PLAY_NEXT_FRAME           0x00
#define MTT_STATE_PLAY_FWD_SLOWEST          0x01
#define MTT_STATE_PLAY_SLOW_FWD_4           0x02
#define MTT_STATE_PLAY_SLOW_FWD_3           0x03
#define MTT_STATE_PLAY_SLOW_FWD_2           0x04
#define MTT_STATE_PLAY_SLOW_FWD_1           0x05
#define MTT_STATE_PLAY_X1                   0x06
#define MTT_STATE_PLAY_FAST_FWD_1           0x07
#define MTT_STATE_PLAY_FAST_FWD_2           0x08
#define MTT_STATE_PLAY_FAST_FWD_3           0x09
#define MTT_STATE_PLAY_FAST_FWD_4           0x0A
#define MTT_STATE_PLAY_FASTEST_FWD          0x0B
#define MTT_STATE_PLAY_PREV_FRAME           0x0C
#define MTT_STATE_PLAY_SLOWEST_REV          0x0D
#define MTT_STATE_PLAY_SLOW_REV_4           0x0E
#define MTT_STATE_PLAY_SLOW_REV_3           0x0F
#define MTT_STATE_PLAY_SLOW_REV_2           0x10
#define MTT_STATE_PLAY_SLOW_REV_1           0x11
#define MTT_STATE_PLAY_REV                  0x12
#define MTT_STATE_PLAY_FAST_REV_1           0x13
#define MTT_STATE_PLAY_FAST_REV_2           0x14
#define MTT_STATE_PLAY_FAST_REV_3           0x15
#define MTT_STATE_PLAY_FAST_REV_4           0x16
#define MTT_STATE_PLAY_FASTEST_REV          0x17
#define MTT_STATE_PLAY                      0x18
#define MTT_STATE_PAUSE                     0x19
#define MTT_STATE_PLAY_REVERSE_PAUSE        0x1A


#define MTT_STATE_STOP                      0x40
#define MTT_STATE_FAST_FORWARD              0x41
#define MTT_STATE_REWIND                    0x42
#define MTT_STATE_HIGH_SPEED_REWIND         0x43

#define MTT_STATE_RECORD_START              0x50
#define MTT_STATE_RECORD_PAUSE              0x51

#define MTT_STATE_EJECT                     0x60

#define MTT_STATE_PLAY_SLOW_FWD_X           0x70
#define MTT_STATE_PLAY_FAST_FWD_X           0x71
#define MTT_STATE_PLAY_SLOW_REV_X           0x72
#define MTT_STATE_PLAY_FAST_REV_X           0x73
#define MTT_STATE_STOP_START                0x74
#define MTT_STATE_STOP_END                  0x75
#define MTT_STATE_STOP_EMERGENCY            0x76
#define MTT_STATE_STOP_CONDENSATION         0x77
#define MTT_STATE_UNSPECIFIED               0x7F

// Video Control Interface Control Selectors
#define VC_UNDEFINED_CONTROL            0x00
#define VC_VIDEO_POWER_MODE_CONTROL     0x01
#define VC_REQUEST_ERROR_CODE_CONTROL   0x02

// VideoStreaming Interface Control Selectors
#define VS_CONTROL_UNDEFINED            0x00
#define VS_PROBE_CONTROL                0x01
#define VS_COMMIT_CONTROL               0x02
#define VS_STILL_PROBE_CONTROL          0x03
#define VS_STILL_COMMIT_CONTROL         0x04
#define VS_STILL_IMAGE_TRIGGER_CONTROL  0x05
#define VS_STREAM_ERROR_CODE_CONTROL    0x06
#define VS_GENERATE_KEY_FRAME_CONTROL   0x07
#define VS_UPDATE_FRAME_SEGMENT_CONTROL 0x08
#define VS_SYNC_DELAY_CONTROL           0x09

// Probe commit bitmap framing info
#define VS_PROBE_COMMIT_BIT_FID 0x01
#define VS_PROBE_COMMIT_BIT_EOF 0x02

// Stream payload header Bit Field Header bits
#define BFH_FID 0x01 // Frame ID bit
#define BFH_EOF 0x02 // End of Frame bit
#define BFH_PTS 0x04 // Presentation Time Stamp bit
#define BFH_SCR 0x08 // Source Clock Reference bit
#define BFH_RES 0x10 // Reserved bit
#define BFH_STI 0x20 // Still image bit
#define BFH_ERR 0x40 // Error bit
#define BFH_EOH 0x80 // End of header bit

#define HDR_LENGTH 1 // Length of header length field in bytes
#define BFH_LENGTH 1 // Length of BFH field in bytes
#define PTS_LENGTH 4 // Length of PTS field in bytes
#define SCR_LENGTH 6 // Length of SCR field in bytes

// USB Video Status Codes (Request Error Code Control)
#define USBVIDEO_RE_STATUS_NOERROR          0x00  
#define USBVIDEO_RE_STATUS_NOT_READY        0x01
#define USBVIDEO_RE_STATUS_WRONG_STATE      0x02
#define USBVIDEO_RE_STATUS_POWER            0x03
#define USBVIDEO_RE_STATUS_OUT_OF_RANGE     0x04
#define USBVIDEO_RE_STATUS_INVALID_UNIT     0x05
#define USBVIDEO_RE_STATUS_INVALID_CONTROL  0x06
#define USBVIDEO_RE_STATUS_UNKNOWN          0x07

// USB Video Device Status Codes (Stream Error Code Control)
#define USBVIDEO_SE_STATUS_NOERROR                0x00
#define USBVIDEO_SE_STATUS_PROTECTED_CONTENT      0x01
#define USBVIDEO_SE_STATUS_INPUT_BUFFER_UNDERRUN  0x02
#define USBVIDEO_SE_STATUS_DATA_DICONTINUITY      0x03
#define USBVIDEO_SE_STATUS_OUTPUT_BUFFER_UNDERRUN 0x04
#define USBVIDEO_SE_STATUS_OUTPUT_BUFFER_OVERRUN  0x05
#define USBVIDEO_SE_STATUS_FORMAT_CHANGE          0x06
#define USBVIDEO_SE_STATUS_STILL_IMAGE_ERROR      0x07
#define USBVIDEO_SE_STATUS_UNKNOWN                0x08

// Status Interrupt Types
#define STATUS_INTERRUPT_VC 1
#define STATUS_INTERRUPT_VS 2

// Status Interrupt Attributes
#define STATUS_INTERRUPT_ATTRIBUTE_VALUE          0x00
#define STATUS_INTERRUPT_ATTRIBUTE_INFO           0x01
#define STATUS_INTERRUPT_ATTRIBUTE_FAILURE        0x02

// VideoStreaming interface interrupt types
#define VS_INTERRUPT_EVENT_BUTTON_PRESS         0x00
#define VS_INTERRUPT_VALUE_BUTTON_RELEASE       0x00
#define VS_INTERRUPT_VALUE_BUTTON_PRESS         0x01

// Get Info Values
#define USBVIDEO_ASYNC_CONTROL    0x10
#define USBVIDEO_SETTABLE_CONTROL 0x2

#define MAX_INTERRUPT_PACKET_VALUE_SIZE 8

// Frame descriptor frame interval array offsets
#define MIN_FRAME_INTERVAL_OFFSET  0
#define MAX_FRAME_INTERVAL_OFFSET  1
#define FRAME_INTERVAL_STEP_OFFSET 2

// Still image capture methods
#define STILL_CAPTURE_METHOD_NONE 0
#define STILL_CAPTURE_METHOD_1 1
#define STILL_CAPTURE_METHOD_2 2
#define STILL_CAPTURE_METHOD_3 3

// Still image trigger control states
#define STILL_IMAGE_TRIGGER_NORMAL         0
#define STILL_IMAGE_TRIGGER_TRANSMIT       1
#define STILL_IMAGE_TRIGGER_TRANSMIT_BULK  2
#define STILL_IMAGE_TRIGGER_TRANSMIT_ABORT 3

// Endpoint descriptor masks
#define EP_DESCRIPTOR_TRANSACTION_SIZE_MASK 0x07ff
#define EP_DESCRIPTOR_NUM_TRANSACTION_MASK  0x1800
#define EP_DESCRIPTOR_NUM_TRANSACTION_OFFSET 11


// Copy protection flag defined in the Uncompressed Payload Spec
#define USB_VIDEO_UNCOMPRESSED_RESTRICT_DUPLICATION 1

// Interlace flags
#define INTERLACE_FLAGS_SUPPORTED_MASK         0x01
#define INTERLACE_FLAGS_FIELDS_PER_FRAME_MASK  0x02
#define INTERLACE_FLAGS_FIELDS_PER_FRAME_2     0x00
#define INTERLACE_FLAGS_FIELDS_PER_FRAME_1     0x02
#define INTERLACE_FLAGS_FIELD_1_FIRST_MASK     0x04
#define INTERLACE_FLAGS_FIELD_PATTERN_MASK     0x30
#define INTERLACE_FLAGS_FIELD_PATTERN_FIELD1   0x00
#define INTERLACE_FLAGS_FIELD_PATTERN_FIELD2   0x10
#define INTERLACE_FLAGS_FIELD_PATTERN_REGULAR  0x20
#define INTERLACE_FLAGS_FIELD_PATTERN_RANDOM   0x30
#define INTERLACE_FLAGS_DISPLAY_MODE_MASK      0xC0
#define INTERLACE_FLAGS_DISPLAY_MODE_BOB       0x00
#define INTERLACE_FLAGS_DISPLAY_MODE_WEAVE     0x40
#define INTERLACE_FLAGS_DISPLAY_MODE_BOB_WEAVE 0x80

// Color Matching Flags
#define UVC_PRIMARIES_UNKNOWN            0x0
#define UVC_PRIMARIES_BT709              0x1
#define UVC_PRIMARIES_BT470_2M           0x2
#define UVC_PRIMARIES_BT470_2BG          0x3
#define UVC_PRIMARIES_SMPTE_170M         0x4
#define UVC_PRIMARIES_SMPTE_240M         0x5

#define UVC_GAMMA_UNKNOWN                0x0
#define UVC_GAMMA_BT709                  0x1
#define UVC_GAMMA_BT470_2M               0x2
#define UVC_GAMMA_BT470_2BG              0x3
#define UVC_GAMMA_SMPTE_170M             0x4
#define UVC_GAMMA_SMPTE_240M             0x5
#define UVC_GAMMA_LINEAR                 0x6
#define UVC_GAMMA_sRGB                   0x7

#define UVC_TRANSFER_MATRIX_UNKNOWN      0x0
#define UVC_TRANSFER_MATRIX_BT709        0x1
#define UVC_TRANSFER_MATRIX_FCC          0x2
#define UVC_TRANSFER_MATRIX_BT470_2BG    0x3
#define UVC_TRANSFER_MATRIX_BT601        0x4
#define UVC_TRANSFER_MATRIX_SMPTE_240M   0x5

//
// BEGIN - VDC Descriptor and Control Structures
//
#pragma warning( disable : 4200 ) // Allow zero-sized arrays at end of structs
#pragma pack( push, vdc_descriptor_structs, 1)

// Video Specific Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // descriptor subtype
} VIDEO_SPECIFIC, *PVIDEO_SPECIFIC;

#define SIZEOF_VIDEO_SPECIFIC(pDesc) sizeof(VIDEO_SPECIFIC)


// Video Unit Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // descriptor subtype
    UCHAR bUnitID;              // Constant uniquely identifying the Unit
} VIDEO_UNIT, *PVIDEO_UNIT;

#define SIZEOF_VIDEO_UNIT(pDesc) sizeof(VIDEO_UNIT)

// VideoControl Header Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // VC_HEADER descriptor subtype
    USHORT bcdVideoSpec;        // USB video class spec revision number
    USHORT wTotalLength;        // Total length, including all units and terminals
    ULONG dwClockFreq;          // Device clock frequency in Hz
    UCHAR bInCollection;        // number of video streaming interfaces
    UCHAR baInterfaceNr[];      // interface number array
} VIDEO_CONTROL_HEADER_UNIT, *PVIDEO_CONTROL_HEADER_UNIT;

#define SIZEOF_VIDEO_CONTROL_HEADER_UNIT(pDesc) \
    ((sizeof(VIDEO_CONTROL_HEADER_UNIT) + (pDesc)->bInCollection))


// VideoControl Input Terminal Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // INPUT_TERMINAL descriptor subtype
    UCHAR bTerminalID;          // Constant uniquely identifying the Terminal
    USHORT wTerminalType;       // Constant characterizing the terminal type
    UCHAR bAssocTerminal;       // ID of associated output terminal
    UCHAR iTerminal;            // Index of string descriptor
} VIDEO_INPUT_TERMINAL, *PVIDEO_INPUT_TERMINAL;

#define SIZEOF_VIDEO_INPUT_TERMINAL(pDesc) sizeof(VIDEO_INPUT_TERMINAL)


// VideoControl Output Terminal Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // OUTPUT_TERMINAL descriptor subtype
    UCHAR bTerminalID;          // Constant uniquely identifying the Terminal
    USHORT wTerminalType;       // Constant characterizing the terminal type
    UCHAR bAssocTerminal;       // ID of associated input terminal
    UCHAR bSourceID;            // ID of source unit/terminal
    UCHAR iTerminal;            // Index of string descriptor
} VIDEO_OUTPUT_TERMINAL, *PVIDEO_OUTPUT_TERMINAL;

#define SIZEOF_VIDEO_OUTPUT_TERMINAL(pDesc) sizeof(VIDEO_OUTPUT_TERMINAL)


// VideoControl Camera Terminal Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // INPUT_TERMINAL descriptor subtype
    UCHAR bTerminalID;          // Constant uniquely identifying the Terminal
    USHORT wTerminalType;       // Sensor type
    UCHAR bAssocTerminal;       // ID of associated output terminal
    UCHAR iTerminal;            // Index of string descriptor        
    USHORT wObjectiveFocalLengthMin; // Min focal length for zoom
    USHORT wObjectiveFocalLengthMax; // Max focal length for zoom
    USHORT wOcularFocalLength;  // Ocular focal length for zoom
    UCHAR bControlSize;         // Size of bmControls field
    UCHAR bmControls[];         // Bitmap of controls supported
} VIDEO_CAMERA_TERMINAL, *PVIDEO_CAMERA_TERMINAL;

#define SIZEOF_VIDEO_CAMERA_TERMINAL(pDesc) \
    (sizeof(VIDEO_CAMERA_TERMINAL) + (pDesc)->bControlSize)


// Media Transport Input Terminal Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // INPUT_TERMINAL descriptor subtype
    UCHAR bTerminalID;          // Constant uniquely identifying the Terminal
    USHORT wTerminalType;       // Media Transport type
    UCHAR bAssocTerminal;       // ID of associated output terminal
    UCHAR iTerminal;            // Index of string descriptor    
    UCHAR bControlSize;         // Size of bmControls field
    UCHAR bmControls[];         // Bitmap of controls supported
} VIDEO_INPUT_MTT, *PVIDEO_INPUT_MTT;


__inline size_t SizeOfVideoInputMTT(_In_ PVIDEO_INPUT_MTT pDesc)
{
    UCHAR bTransportModeSize;
    PUCHAR pbCurr;

    pbCurr = pDesc->bmControls + pDesc->bControlSize; 
    bTransportModeSize = *pbCurr;

    return sizeof(VIDEO_INPUT_MTT) + pDesc->bControlSize + 1 + bTransportModeSize;
}

#define SIZEOF_VIDEO_INPUT_MTT(pDesc) SizeOfVideoInputMTT(pDesc)


// Media Transport Output Terminal Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // OUTPUT_TERMINAL descriptor subtype
    UCHAR bTerminalID;          // Constant uniquely identifying the Terminal
    USHORT wTerminalType;       // Media Transport type
    UCHAR bAssocTerminal;       // ID of associated output terminal
    UCHAR bSourceID;            // ID of source unit/terminal    
    UCHAR iTerminal;            // Index of string descriptor    
    UCHAR bControlSize;         // Size of bmControls field
    UCHAR bmControls[];         // Bitmap of controls supported
} VIDEO_OUTPUT_MTT, *PVIDEO_OUTPUT_MTT;


__inline size_t SizeOfVideoOutputMTT(_In_ PVIDEO_OUTPUT_MTT pDesc)
{
    UCHAR bTransportModeSize;
    PUCHAR pbCurr;

    pbCurr = pDesc->bmControls + pDesc->bControlSize; 
    bTransportModeSize = *pbCurr;

    return sizeof(VIDEO_OUTPUT_MTT) + pDesc->bControlSize + 1+ bTransportModeSize;
}

#define SIZEOF_VIDEO_OUTPUT_MTT(pDesc) SizeOfVideoOutputMTT(pDesc)


// VideoControl Selector Unit Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // SELECTOR_UNIT descriptor subtype
    UCHAR bUnitID;              // Constant uniquely identifying the Unit
    UCHAR bNrInPins;            // Number of input pins
    UCHAR baSourceID[];         // IDs of connected units/terminals
} VIDEO_SELECTOR_UNIT, *PVIDEO_SELECTOR_UNIT;

#define SIZEOF_VIDEO_SELECTOR_UNIT(pDesc) \
    (sizeof(VIDEO_SELECTOR_UNIT) + (pDesc)->bNrInPins + 1)


// VideoControl Processing Unit Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // PROCESSING_UNIT descriptor subtype
    UCHAR bUnitID;              // Constant uniquely identifying the Unit
    UCHAR bSourceID;            // ID of connected unit/terminal
    USHORT wMaxMultiplier;      // Maximum digital magnification
    UCHAR bControlSize;         // Size of bmControls field
    UCHAR bmControls[];         // Bitmap of controls supported
} VIDEO_PROCESSING_UNIT, *PVIDEO_PROCESSING_UNIT;

#define SIZEOF_VIDEO_PROCESSING_UNIT(pDesc) \
    (sizeof(VIDEO_PROCESSING_UNIT) + 1 + (pDesc)->bControlSize)
    

// VideoControl Extension Unit Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // EXTENSION_UNIT descriptor subtype
    UCHAR bUnitID;              // Constant uniquely identifying the Unit
    GUID guidExtensionCode;     // Vendor-specific code identifying extension unit
    UCHAR bNumControls;         // Number of controls in Extension Unit
    UCHAR bNrInPins;            // Number of input pins
    UCHAR baSourceID[];         // IDs of connected units/terminals
} VIDEO_EXTENSION_UNIT, *PVIDEO_EXTENSION_UNIT;
// this is followed by bControlSize, bmControls and iExtension (1 byte)

__inline size_t SizeOfVideoExtensionUnit(PVIDEO_EXTENSION_UNIT pDesc)
{
    UCHAR bControlSize;
    PUCHAR pbCurr;

    // baSourceID is an array, and hence understood to be an address
    pbCurr = pDesc->baSourceID + pDesc->bNrInPins; 
    if (((ULONG_PTR) pbCurr < (ULONG_PTR) pDesc->baSourceID) ||
        (ULONG_PTR) pbCurr >= (ULONG_PTR)((UCHAR *) pDesc + pDesc->bLength))
        return 0;

    bControlSize = *pbCurr;
    return 24 + pDesc->bNrInPins + bControlSize;
}

#define SIZEOF_VIDEO_EXTENSION_UNIT(pDesc) SizeOfVideoExtensionUnit(pDesc)
    

// Class-specific Interrupt Endpoint Descriptor
typedef struct {
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_ENDPOINT descriptor type
    UCHAR bDescriptorSubtype;   // EP_INTERRUPT descriptor subtype
    USHORT wMaxTransferSize;    // Max interrupt payload size
} VIDEO_CS_INTERRUPT, *PVIDEO_CS_INTERRUPT;

#define SIZEOF_VIDEO_CS_INTERRUPT(pDesc) sizeof(VIDEO_CS_INTERRUPT)


// VideoStreaming Input Header Descriptor
typedef struct _VIDEO_STREAMING_INPUT_HEADER
{
    UCHAR bLength;              // Size of this descriptor in bytes
    UCHAR bDescriptorType;      // CS_INTERFACE descriptor type
    UCHAR bDescriptorSubtype;   // VS_INPUT_HEADER descriptor subtype
    UCHAR bNumFormats;
    USHORT wTotalLength;    
    UCHAR bEndpointAddress;
    UCHAR bmInfo;
    UCHAR bTerminalLink;
    UCHAR bStillCaptureMethod;
    UCHAR bTriggerSupport;
    UCHAR bTriggerUsage;
    UCHAR bControlSize;    
    UCHAR bmaControls[];
} VIDEO_STREAMING_INPUT_HEADER, *PVIDEO_STREAMING_INPUT_HEADER;

#define SIZEOF_VIDEO_STREAMING_INPUT_HEADER(pDesc) \
    (sizeof(VIDEO_STREAMING_INPUT_HEADER) + (pDesc->bNumFormats * pDesc->bControlSize))


// VideoStreaming Output Header Descriptor
typedef struct _VIDEO_STREAMING_OUTPUT_HEADER
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bNumFormats;
    USHORT wTotalLength;    
    UCHAR bEndpointAddress;
    UCHAR bTerminalLink;
} VIDEO_STREAMING_OUTPUT_HEADER, *PVIDEO_STREAMING_OUTPUT_HEADER;

#define SIZEOF_VIDEO_STREAMING_OUTPUT_HEADER(pDesc) sizeof(VIDEO_STREAMING_OUTPUT_HEADER)


typedef struct _VIDEO_STILL_IMAGE_RECT
{
    USHORT wWidth;
    USHORT wHeight;
} VIDEO_STILL_IMAGE_RECT;

// VideoStreaming Still Image Frame Descriptor
typedef struct _VIDEO_STILL_IMAGE_FRAME
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bEndpointAddress;
    UCHAR bNumImageSizePatterns;    
    VIDEO_STILL_IMAGE_RECT aStillRect[];
} VIDEO_STILL_IMAGE_FRAME, *PVIDEO_STILL_IMAGE_FRAME;

__inline size_t SizeOfVideoStillImageFrame(PVIDEO_STILL_IMAGE_FRAME pDesc)
{
    UCHAR bNumCompressionPatterns;
    PUCHAR pbCurr;

    pbCurr = (PUCHAR) pDesc->aStillRect + (sizeof(VIDEO_STILL_IMAGE_RECT) * pDesc->bNumImageSizePatterns);
    bNumCompressionPatterns = *pbCurr;

    return (sizeof(VIDEO_STILL_IMAGE_FRAME) + 
           (sizeof(VIDEO_STILL_IMAGE_RECT) * pDesc->bNumImageSizePatterns) +
           1 + bNumCompressionPatterns);                   
}

#define SIZEOF_VIDEO_STILL_IMAGE_FRAME(pDesc) SizeOfVideoStillImageFrame(pDesc)


// VideoStreaming Color Matching Descriptor
typedef struct _VIDEO_COLORFORMAT
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bColorPrimaries;
    UCHAR bTransferCharacteristics;
    UCHAR bMatrixCoefficients;
} VIDEO_COLORFORMAT, *PVIDEO_COLORFORMAT;

#define SIZEOF_VIDEO_COLORFORMAT(pDesc) sizeof(VIDEO_COLORFORMAT)


// VideoStreaming Uncompressed Format Descriptor
typedef struct _VIDEO_FORMAT_UNCOMPRESSED
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bNumFrameDescriptors;
    GUID guidFormat;
    UCHAR bBitsPerPixel;
    UCHAR bDefaultFrameIndex;
    UCHAR bAspectRatioX;
    UCHAR bAspectRatioY;
    UCHAR bmInterlaceFlags;
    UCHAR bCopyProtect;
} VIDEO_FORMAT_UNCOMPRESSED, *PVIDEO_FORMAT_UNCOMPRESSED;

#define SIZEOF_VIDEO_FORMAT_UNCOMPRESSED(pDesc) sizeof(VIDEO_FORMAT_UNCOMPRESSED)


// VideoStreaming Uncompressed Frame Descriptor
typedef struct _VIDEO_FRAME_UNCOMPRESSED
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFrameIndex;
    UCHAR bmCapabilities;
    USHORT wWidth;
    USHORT wHeight;
    ULONG dwMinBitRate;
    ULONG dwMaxBitRate;
    ULONG dwMaxVideoFrameBufferSize;
    ULONG dwDefaultFrameInterval;
    UCHAR bFrameIntervalType;
    ULONG adwFrameInterval[];
} VIDEO_FRAME_UNCOMPRESSED, *PVIDEO_FRAME_UNCOMPRESSED;


__inline size_t SizeOfVideoFrameUncompressed(_In_ PVIDEO_FRAME_UNCOMPRESSED pDesc)
{
    if (pDesc->bFrameIntervalType == 0) { // Continuous
        return sizeof(VIDEO_FRAME_UNCOMPRESSED) + (3 * sizeof(ULONG));
    }
    else { // Discrete
        return sizeof(VIDEO_FRAME_UNCOMPRESSED) + (pDesc->bFrameIntervalType * sizeof(ULONG));
    }
}

#define SIZEOF_VIDEO_FRAME_UNCOMPRESSED(pDesc) SizeOfVideoFrameUncompressed(pDesc)


// VideoStreaming MJPEG Format Descriptor
typedef struct _VIDEO_FORMAT_MJPEG
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bNumFrameDescriptors;
    UCHAR bmFlags;
    UCHAR bDefaultFrameIndex;
    UCHAR bAspectRatioX;
    UCHAR bAspectRatioY;
    UCHAR bmInterlaceFlags;
    UCHAR bCopyProtect;
} VIDEO_FORMAT_MJPEG, *PVIDEO_FORMAT_MJPEG;

#define SIZEOF_VIDEO_FORMAT_MJPEG(pDesc) sizeof(VIDEO_FORMAT_MJPEG)


// VideoStreaming MJPEG Frame Descriptor
typedef struct _VIDEO_FRAME_MJPEG
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFrameIndex;
    UCHAR bmCapabilities;
    USHORT wWidth;
    USHORT wHeight;
    ULONG dwMinBitRate;
    ULONG dwMaxBitRate;
    ULONG dwMaxVideoFrameBufferSize;
    ULONG dwDefaultFrameInterval;
    UCHAR bFrameIntervalType;
    ULONG adwFrameInterval[];
} VIDEO_FRAME_MJPEG, *PVIDEO_FRAME_MJPEG;


__inline size_t SizeOfVideoFrameMjpeg(_In_ PVIDEO_FRAME_MJPEG pDesc)
{  
    if (pDesc->bFrameIntervalType == 0) { // Continuous
        return sizeof(VIDEO_FRAME_MJPEG) + (3 * sizeof(ULONG));
    }
    else { // Discrete
        return sizeof(VIDEO_FRAME_MJPEG) + (pDesc->bFrameIntervalType * sizeof(ULONG));
    }
}

#define SIZEOF_VIDEO_FRAME_MJPEG(pDesc) SizeOfVideoFrameMjpeg(pDesc)


// VideoStreaming Vendor Format Descriptor
typedef struct _VIDEO_FORMAT_VENDOR
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bNumFrameDescriptors;
    GUID  guidMajorFormat;
    GUID  guidSubFormat;
    GUID  guidSpecifier;
    UCHAR bPayloadClass;
    UCHAR bDefaultFrameIndex;
    UCHAR bCopyProtect;
} VIDEO_FORMAT_VENDOR, *PVIDEO_FORMAT_VENDOR;

#define SIZEOF_VIDEO_FORMAT_VENDOR(pDesc) sizeof(VIDEO_FORMAT_VENDOR)


// VideoStreaming Vendor Frame Descriptor
typedef struct _VIDEO_FRAME_VENDOR
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFrameIndex;
    UCHAR bmCapabilities;
    USHORT wWidth;
    USHORT wHeight;
    ULONG dwMinBitRate;
    ULONG dwMaxBitRate;
    ULONG dwMaxVideoFrameBufferSize;
    ULONG dwDefaultFrameInterval;
    UCHAR bFrameIntervalType;
    DWORD adwFrameInterval[];
} VIDEO_FRAME_VENDOR, *PVIDEO_FRAME_VENDOR;

__inline size_t SizeOfVideoFrameVendor(_In_ PVIDEO_FRAME_VENDOR pDesc)
{    
    if (pDesc->bFrameIntervalType == 0) { // Continuous
        return sizeof(VIDEO_FRAME_VENDOR) + (3 * sizeof(ULONG));
    }
    else { // Discrete
        return sizeof(VIDEO_FRAME_VENDOR) + (pDesc->bFrameIntervalType * sizeof(ULONG));
    }
}

#define SIZEOF_VIDEO_FRAME_VENDOR(pDesc) SizeOfVideoFrameVendor(pDesc)


// VideoStreaming DV Format Descriptor
typedef struct _VIDEO_FORMAT_DV
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    ULONG dwMaxVideoFrameBufferSize;
    UCHAR bFormatType;    
} VIDEO_FORMAT_DV, *PVIDEO_FORMAT_DV;

#define SIZEOF_VIDEO_FORMAT_DV(pDesc) sizeof(VIDEO_FORMAT_DV)


// VideoStreaming MPEG2-TS Format Descriptor
typedef struct _VIDEO_FORMAT_MPEG2TS
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bDataOffset;
    UCHAR bPacketLength;
    UCHAR bStrideLength;    
} VIDEO_FORMAT_MPEG2TS, *PVIDEO_FORMAT_MPEG2TS;

#define SIZEOF_VIDEO_FORMAT_MPEG2TS(pDesc) sizeof(VIDEO_FORMAT_MPEG2TS)


// VideoStreaming MPEG1 System Stream Format Descriptor
typedef struct _VIDEO_FORMAT_MPEG1SS
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bPacketLength;
    UCHAR bPackLength;
    UCHAR bPackDataType;    
} VIDEO_FORMAT_MPEG1SS, *PVIDEO_FORMAT_MPEG1SS;

#define SIZEOF_VIDEO_FORMAT_MPEG1SS(pDesc) sizeof(VIDEO_FORMAT_MPEG1SS)


// VideoStreaming MPEG2-PS Format Descriptor
typedef struct _VIDEO_FORMAT_MPEG2PS
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bPacketLength;
    UCHAR bPackLength;
    UCHAR bPackDataType;
} VIDEO_FORMAT_MPEG2PS, *PVIDEO_FORMAT_MPEG2PS;

#define SIZEOF_VIDEO_FORMAT_MPEG2PS(pDesc) sizeof(VIDEO_FORMAT_MPEG2PS)


// VideoStreaming MPEG4-SL Format Descriptor
typedef struct _VIDEO_FORMAT_MPEG4SL
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bPacketLength;
} VIDEO_FORMAT_MPEG4SL, *PVIDEO_FORMAT_MPEG4SL;

#define SIZEOF_VIDEO_FORMAT_MPEG4SL(pDesc) sizeof(VIDEO_FORMAT_MPEG4SL)

// VideoStreaming Probe/Commit Control
typedef struct _VS_PROBE_COMMIT_CONTROL
{
    USHORT bmHint;
    UCHAR bFormatIndex;
    UCHAR bFrameIndex;
    ULONG dwFrameInterval;
    USHORT wKeyFrameRate;
    USHORT wPFrameRate;
    USHORT wCompQuality;
    USHORT wCompWindowSize;
    USHORT wDelay;
    ULONG dwMaxVideoFrameSize;
    ULONG dwMaxPayloadTransferSize;
} VS_PROBE_COMMIT_CONTROL, *PVS_PROBE_COMMIT_CONTROL;

// VideoStreaming Still Probe/Commit Control
typedef struct _VS_STILL_PROBE_COMMIT_CONTROL
{
    UCHAR bFormatIndex;
    UCHAR bFrameIndex;
    UCHAR bCompressionIndex;
    ULONG dwMaxVideoFrameSize;
    ULONG dwMaxPayloadTransferSize;
} VS_STILL_PROBE_COMMIT_CONTROL, *PVS_STILL_PROBE_COMMIT_CONTROL;


// Status Interrupt Packet (Video Control)
typedef struct _VC_INTERRUPT_PACKET
{
    UCHAR bStatusType;
    UCHAR bOriginator;
    UCHAR bEvent;
    UCHAR bSelector;
    UCHAR bAttribute;
    UCHAR bValue[1];
} VC_INTERRUPT_PACKET, *PVC_INTERRUPT_PACKET;

// Status Interrupt Packet (Video Control)
typedef struct _VC_INTERRUPT_PACKET_EX
{
    UCHAR bStatusType;
    UCHAR bOriginator;
    UCHAR bEvent;
    UCHAR bSelector;
    UCHAR bAttribute;
    UCHAR bValue[MAX_INTERRUPT_PACKET_VALUE_SIZE];
} VC_INTERRUPT_PACKET_EX, *PVC_INTERRUPT_PACKET_EX;

// Status Interrupt Packet (Video Streaming)
typedef struct _VS_INTERRUPT_PACKET
{
    UCHAR bStatusType;
    UCHAR bOriginator;
    UCHAR bEvent;
    UCHAR bValue[1];
} VS_INTERRUPT_PACKET, *PVS_INTERRUPT_PACKET;

// Status Interrupt Packet (Generic)
typedef struct _VIDEO_INTERRUPT_PACKET
{
    UCHAR bStatusType;
    UCHAR bOriginator;
} VIDEO_INTERRUPT_PACKET, *PVIDEO_INTERRUPT_PACKET;


// Relative property struct
typedef struct _VIDEO_RELATIVE_PROPERTY
{
    UCHAR bValue;
    UCHAR bSpeed;
} VIDEO_RELATIVE_PROPERTY, *PVIDEO_RELATIVE_PROPERTY;

// Relative Zoom control struct
typedef struct _ZOOM_RELATIVE_PROPERTY
{
    UCHAR bZoom;
    UCHAR bDigitalZoom;
    UCHAR bSpeed;
} ZOOM_RELATIVE_PROPERTY, *PZOOM_RELATIVE_PROPERTY;

// Relative pan-tilt struct
typedef struct _PANTILT_RELATIVE_PROPERTY
{
    UCHAR bPanRelative;
    UCHAR bPanSpeed;
    UCHAR bTiltRelative;
    UCHAR bTiltSpeed;
} PANTILT_RELATIVE_PROPERTY, *PPANTILT_RELATIVE_PROPERTY;

typedef struct _MEDIA_INFORMATION_CONTROL
{
    UCHAR bmMediaType;
    UCHAR bmWriteProtect;
} MEDIA_INFORMATION_CONTROL, *PMEDIA_INFORMATION_CONTROL;

typedef struct _TIME_CODE_INFORMATION_CONTROL
{
    UCHAR bcdFrame;
    UCHAR bcdSecond;
    UCHAR bcdMinute;
    UCHAR bcdHour;
} TIME_CODE_INFORMATION_CONTROL, *PTIME_CODE_INFORMATION_CONTROL;

typedef struct _ATN_INFORMATION_CONTROL
{
    UCHAR bmMediaType;
    DWORD dwATN_Data;
} ATN_INFORMATION_CONTROL, *PATN_INFORMATION_CONTROL;

#define VS_FORMAT_FRAME_BASED   0x10
#define VS_FRAME_FRAME_BASED    0x11
#define VS_FORMAT_STREAM_BASED  0x12

// Format Descriptor for UVC 1.1 frame based format
typedef struct _VIDEO_FORMAT_FRAME
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    UCHAR bNumFrameDescriptors;
    GUID guidFormat;
    UCHAR bBitsPerPixel;
    UCHAR bDefaultFrameIndex;
    UCHAR bAspectRatioX;
    UCHAR bAspectRatioY;
    UCHAR bmInterlaceFlags;
    UCHAR bCopyProtect;
    UCHAR bVariableSize;
} VIDEO_FORMAT_FRAME, *PVIDEO_FORMAT_FRAME;

#define SIZEOF_VIDEO_FORMAT_FRAME(pDesc) sizeof(VIDEO_FORMAT_FRAME)


// Frame Descriptor for UVC 1.1 frame based format
typedef struct _VIDEO_FRAME_FRAME
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFrameIndex;
    UCHAR bmCapabilities;
    USHORT wWidth;
    USHORT wHeight;
    ULONG dwMinBitRate;
    ULONG dwMaxBitRate;
    ULONG dwDefaultFrameInterval;
    UCHAR bFrameIntervalType;
    ULONG dwBytesPerLine;
    ULONG adwFrameInterval[];
} VIDEO_FRAME_FRAME, *PVIDEO_FRAME_FRAME;

__inline size_t SizeOfVideoFrameFrame(_In_ PVIDEO_FRAME_FRAME pDesc)
{
    if (pDesc->bFrameIntervalType == 0) { // Continuous
        return sizeof(VIDEO_FRAME_FRAME) + (3 * sizeof(ULONG));
    }
    else { // Discrete
        return sizeof(VIDEO_FRAME_FRAME) + (pDesc->bFrameIntervalType * sizeof(ULONG));
    }
}

#define SIZEOF_VIDEO_FRAME_FRAME(pDesc) SizeOfVideoFrameFrame(pDesc)

// VideoStreaming Stream Based Format Descriptor
typedef struct _VIDEO_FORMAT_STREAM
{
    UCHAR bLength;
    UCHAR bDescriptorType;
    UCHAR bDescriptorSubtype;
    UCHAR bFormatIndex;
    GUID guidFormat;
    ULONG dwPacketLength;
} VIDEO_FORMAT_STREAM, *PVIDEO_FORMAT_STREAM;

#define SIZEOF_VIDEO_FORMAT_STREAM(pDesc) sizeof(VIDEO_FORMAT_STREAM)

// VideoStreaming Probe/Commit Control
typedef struct _VS_PROBE_COMMIT_CONTROL2
{
    USHORT bmHint;
    UCHAR bFormatIndex;
    UCHAR bFrameIndex;
    ULONG dwFrameInterval;
    USHORT wKeyFrameRate;
    USHORT wPFrameRate;
    USHORT wCompQuality;
    USHORT wCompWindowSize;
    USHORT wDelay;
    ULONG dwMaxVideoFrameSize;
    ULONG dwMaxPayloadTransferSize;
    ULONG dwClockFrequency;
    UCHAR bmFramingInfo;
    UCHAR bPreferredVersion;
    UCHAR bMinVersion;
    UCHAR bMaxVersion;
} VS_PROBE_COMMIT_CONTROL2, *PVS_PROBE_COMMIT_CONTROL2;

#pragma pack( pop, vdc_descriptor_structs )
#pragma warning( default : 4200 ) 


//
// END - VDC Descriptor and Control Structures
//

#endif // ___UVCDESC_H___
