/*++

Copyright (c) 2002-2008 Microsoft Corporation

Module Name:

DISPVID.C

Abstract:

This source file contains routines which update the edit control
to display information about USB Video descriptors.

Environment:

user mode

Revision History:

11-22-2002 : created
03-28-2003 : major revisions from latest specs.
03-28-2008 : include USB Video Class 1.1

--*/

//*****************************************************************************
// I N C L U D E S
//*****************************************************************************

#include "uvcview.h"
#include "h264.h"

//*****************************************************************************
// G L O B A L S    P R I V A T E    T O    T H I S    F I L E
//*****************************************************************************

int StillMethod = 0;

//
// USB Device Class Definition for Video Devices 0.8b version
//
// 3.6.2.3  Camera Terminal Descriptor
//
STRINGLIST slCameraControl1 [] =
{
    {1,         "Scanning Mode",            ""},
    {2,         "Auto-Exposure Mode",       ""},
    {4,         "Auto-Exposure Priority",   ""},
    {8,         "Exposure Time (Absolute)", ""},
    {0x10,      "Exposure Time (Relative)", ""},
    {0x20,      "Focus (Absolute)",         ""},
    {0x40,      "Focus (Relative)",         ""},
    {0x80,      "Iris (Absolute)",          ""},
};
STRINGLIST slCameraControl2 [] =
{
    {1,         "Iris (Relative)",          ""},
    {2,         "Zoom (Absolute)",          ""},
    {4,         "Zoom (Relative)",          ""},
    {8,         "PanTilt (Absolute)",       ""},
    {0x10,      "PanTilt (Relative)",       ""},
    {0x20,      "Roll (Absolute)",          ""},
    {0x40,      "Roll (Relative)",          ""},
    {0x80,      "Reserved",                 ""},
};
STRINGLIST slCameraControl3 [] =
{
    {1,         "Reserved",                 ""},
    {2,         "Focus, Auto",              ""},
    {4,         "Privacy",                  ""},
    {8,         "Focus, Simple",            ""},
    {0x10,      "Window",                   ""},
    {0x20,      "Region of Interest",       ""},
    {0x40,      "Reserved",                 ""},
    {0x80,      "Reserved",                 ""},
};

// 3.6.2.5  Processing Unit Descriptor
//
STRINGLIST slProcessorControls1 [] =
{
    {1,         "Brightness",                ""},
    {2,         "Contrast",                  ""},
    {4,         "Hue",                       ""},
    {8,         "Saturation",                ""},
    {0x10,      "Sharpness",                 ""},
    {0x20,      "Gamma",                     ""},
    {0x40,      "White Balance Temperature", ""},
    {0x80,      "White Balance Component",   ""},
};
STRINGLIST slProcessorControls2 [] =
{
    {1,         "Backlight Compensation",          ""},
    {2,         "Gain",                            ""},
    {4,         "Power Line Frequency",            ""},
    {8,         "Hue, Auto",                       ""},
    {0x10,      "White Balance Temperature, Auto", ""},
    {0x20,      "White Balance Component, Auto",   ""},
    {0x40,      "Digital Multiplier",              ""},
    {0x80,      "Digital Multiplier Limit",        ""},
};
STRINGLIST slProcessorControls3 [] =
{
    {1,         "Analog Video Standard",           ""},
    {2,         "Analog Video Lock Status",        ""},
    {4,         "Contrast, Auto",                  ""},
    {8,         "Reserved",                        ""},
    {0x10,      "Reserved",                        ""},
    {0x20,      "Reserved",                        ""},
    {0x40,      "Reserved",                        ""},
    {0x80,      "Reserved",                        ""},
};


STRINGLIST slProcessorVideoStandards [] =
{
    {1,         "None",                     ""},
    {2,         "NTSC  - 525/60",           ""},
    {4,         "PAL   - 625/50",           ""},
    {8,         "SECAM - 625/50",           ""},
    {0x10,      "NTSC  - 625/50",           ""},
    {0x20,      "PAL   - 525/60",           ""},
    {0x40,      "Reserved",                 ""},
    {0x80,      "Reserved",                 ""},
};

// 3.8.2.1  Input Header Descriptor
//
STRINGLIST slInputHeaderControls[]=
{
    {1,         "Key Frame Rate"         , ""},
    {2,         "P Frame Rate"           , ""},
    {4,         "Compression Quality"    , ""},
    {8,         "Compression Window Size", ""},
    {0x10,      "Generate Key Frame"     , ""},
    {0x20,      "Update Frame Segment"   , ""},
    {0x40,      "Reserved"               , ""},
    {0x80,      "Reserved"               , ""},
};

STRINGLIST slOutputHeaderControls[]=
{
    {1,         "Key Frame Rate"         , ""},
    {2,         "P Frame Rate"           , ""},
    {4,         "Compression Quality"    , ""},
    {8,         "Compression Window Size", ""},
    {0x10,      "Reserved"               , ""},
    {0x20,      "Reserved"               , ""},
    {0x40,      "Reserved"               , ""},
    {0x80,      "Reserved"               , ""},
};

STRINGLIST slMediaTransportControls[]=
{
    {1,         "Transport Control"            , ""},
    {2,         "Absolute Track Number Control", ""},
    {4,         "Media Information"            , ""},
    {8,         "Time Code Information"        , ""},
    {0x10,      "Reserved"                     , ""},
    {0x20,      "Reserved"                     , ""},
    {0x40,      "Reserved"                     , ""},
    {0x80,      "Reserved"                     , ""},
};

STRINGLIST slMediaTransportModes1[]=
{
    {1,         "Play Forward",         ""},
    {2,         "Pause",                ""},
    {4,         "Rewind",               ""},
    {8,         "Fast Forward",         ""},
    {0x10,      "High Speed Rewind",    ""},
    {0x20,      "Stop",                 ""},
    {0x40,      "Eject",                ""},
    {0x80,      "Play Next Frame",      ""},
};

STRINGLIST slMediaTransportModes2[]=
{
    {1,         "Play Slowest Forward", ""},
    {2,         "Play Slow Forward 4",  ""},
    {4,         "Play Slow Forward 3",  ""},
    {8,         "Play Slow Forward 2",  ""},
    {0x10,      "Play Slow Forward 1",  ""},
    {0x20,      "Play X1",              ""},
    {0x40,      "Play Fast Forward 1",  ""},
    {0x80,      "Play Fast Forward 2",  ""},
};

STRINGLIST slMediaTransportModes3[]=
{
    {1,         "Play Fast Forward 3",  ""},
    {2,         "Play Fast Forward 4",  ""},
    {4,         "Play Fastest Forward", ""},
    {8,         "Play Previous Frame",  ""},
    {0x10,      "Play Slowest Reverse", ""},
    {0x20,      "Play Slow Reverse 4",  ""},
    {0x40,      "Play Slow Reverse 3",  ""},
    {0x80,      "Play Slow Reverse 2",  ""},
};

STRINGLIST slMediaTransportModes4[]=
{
    {1,         "Play Slow Reverse 1",  ""},
    {2,         "Play X1 Reverse",      ""},
    {4,         "Play Fast Reverse 1",  ""},
    {8,         "Play Fast Reverse 2",  ""},
    {0x10,      "Play Fast Reverse 3",  ""},
    {0x20,      "Play Fast Reverse 4",  ""},
    {0x40,      "Play Fastest Reverse", ""},
    {0x80,      "Record StateStart",    ""},
};

STRINGLIST slMediaTransportModes5[]=
{
    {1,         "Record Pause",         ""},
    {2,         "Reserved",             ""},
    {4,         "Reserved",             ""},
    {8,         "Reserved",             ""},
    {0x10,      "Reserved",             ""},
    {0x20,      "Reserved",             ""},
    {0x40,      "Reserved",             ""},
    {0x80,      "Reserved",             ""},
};

STRINGLIST slInputTermTypes[]=
{
    {0x0100,    "TT_VENDOR_SPECIFIC",         "I//O"},
    {0x0101,    "TT_STREAMING",               "I//O"},
    {0x0400,    "EXTERNAL_VENDOR_SPECIFIC",   "I//O"},
    {0x0401,    "COMPOSITE_CONNECTOR",        "I//O"},
    {0x0402,    "SVIDEO_CONNECTOR",           "I//O"},
    {0x0403,    "COMPONENT_CONNECTOR",        "I//O"},
    {0x0200,    "ITT_VENDOR_SPECIFIC",        "I"},
    {0x0201,    "ITT_CAMERA",                 "I"},
    {0x0202,    "ITT_MEDIA_TRANSPORT_INPUT",  "I"},
};
STRINGLIST slOutputTermTypes[]=
{
    {0x0100,    "TT_VENDOR_SPECIFIC",         "I//O"},
    {0x0101,    "TT_STREAMING",               "I//O"},
    {0x0400,    "EXTERNAL_VENDOR_SPECIFIC",   "I//O"},
    {0x0401,    "COMPOSITE_CONNECTOR",        "I//O"},
    {0x0402,    "SVIDEO_CONNECTOR",           "I//O"},
    {0x0403,    "COMPONENT_CONNECTOR",        "I//O"},
    {0x0300,    "OTT_VENDOR_SPECIFIC",        "O"},
    {0x0301,    "OTT_DISPLAY",                "O"},
    {0x0302,    "OTT_MEDIA_TRANSPORT_OUTPUT", "O"},
};

//*****************************************************************************
// L O C A L    F U N C T I O N    P R O T O T Y P E S
//*****************************************************************************

BOOL
DisplayVCHeader (
                 PVIDEO_CONTROL_HEADER_UNIT VCInterfaceDesc
                 );
BOOL
DisplayVCInputTerminal (
    PVIDEO_INPUT_TERMINAL   VidITDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState    
    );

BOOL
DisplayVCOutputTerminal (
    PVIDEO_OUTPUT_TERMINAL  VidOTDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    );

BOOL
DisplayVCCameraTerminal (
                         PVIDEO_CAMERA_TERMINAL CameraDesc
                         );
BOOL
DisplayVCMediaTransInputTerminal (
                                  PVIDEO_INPUT_MTT VCMedTransInDesc
                                  );
BOOL
DisplayVCMediaTransOutputTerminal (
                                   PVIDEO_OUTPUT_MTT VCMedTransOutDesc
                                   );
BOOL
DisplayVCSelectorUnit (
    PVIDEO_SELECTOR_UNIT    VidSelectorDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    );

BOOL
DisplayVCProcessingUnit (
    PVIDEO_PROCESSING_UNIT  VidProcessingDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    );

BOOL
DisplayVCExtensionUnit (
    PVIDEO_EXTENSION_UNIT   VidExtensionDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    );

BOOL
DisplayVidInHeader (
                    PVIDEO_STREAMING_INPUT_HEADER VidInHeaderDesc
                    );
BOOL
DisplayVidOutHeader (
                     PVIDEO_STREAMING_OUTPUT_HEADER VidOutHeaderDesc
                     );
BOOL
DisplayStillImageFrame (
                        PVIDEO_STILL_IMAGE_FRAME StillFrameDesc
                        );
BOOL
DisplayColorMatching (
                      PVIDEO_COLORFORMAT ColorMatchDesc
                      );
BOOL
DisplayUncompressedFormat (
                           PVIDEO_FORMAT_UNCOMPRESSED UnCompFormatDesc
                           );
BOOL
DisplayUncompressedFrameType (
                              PVIDEO_FRAME_UNCOMPRESSED UnCompFrameDesc
                              );
BOOL
DisplayUnComContinuousFrameType(
                                PVIDEO_FRAME_UNCOMPRESSED UContinuousDesc
                                );
BOOL
DisplayUnComDiscreteFrameType(
                              PVIDEO_FRAME_UNCOMPRESSED UDiscreteDesc
                              );
BOOL
DisplayMJPEGFormat (
                    PVIDEO_FORMAT_MJPEG MJPEGFormatDesc
                    );
BOOL
DisplayMJPEGFrameType (
                       PVIDEO_FRAME_MJPEG MJPEGFrameDesc
                       );
BOOL
DisplayMJPEGContinuousFrameType(
                                PVIDEO_FRAME_MJPEG MContinuousDesc
                                );
BOOL
DisplayMJPEGDiscreteFrameType(
                              PVIDEO_FRAME_MJPEG MDiscreteDesc
                              );
BOOL
DisplayMPEG1SSFormat (
                      PVIDEO_FORMAT_MPEG1SS MPEG1SSFormatDesc
                      );
BOOL
DisplayMPEG2PSFormat (
                      PVIDEO_FORMAT_MPEG2PS MPEG2PSFormatDesc
                      );
BOOL
DisplayMPEG2TSFormat (
                      PVIDEO_FORMAT_MPEG2TS MPEG2TSFormatDesc
                      );
BOOL
DisplayMPEG4SLFormat (
                      PVIDEO_FORMAT_MPEG4SL MPEG4SLFormatDesc
                      );
BOOL
DisplayDVFormat (
                 PVIDEO_FORMAT_DV DVFormatDesc
                 );
BOOL
DisplayVendorVidFormat (
                        PVIDEO_FORMAT_VENDOR VendorVidFormatDesc
                        );
BOOL
DisplayVendorVidFrameType (
                           PVIDEO_FRAME_VENDOR VendorVidFrameDesc
                           );
BOOL
DisplayVendorVidContinuousFrameType(
                                    PVIDEO_FRAME_VENDOR VContinuousDesc
                                    );
BOOL
DisplayVendorVidDiscreteFrameType(
                                  PVIDEO_FRAME_VENDOR VDiscreteDesc
                                  );
BOOL
DisplayFramePayloadFormat(
                          PVIDEO_FORMAT_FRAME FramePayloadFormatDesc
                          );
BOOL
DisplayFramePayloadFrame(
                         PVIDEO_FRAME_FRAME FramePayloadFrameDesc
                         );
BOOL
DisplayFramePayloadContinuousFrameType(
                                PVIDEO_FRAME_FRAME FContinuousDesc
                                );
BOOL
DisplayFramePayloadDiscreteFrameType(
                              PVIDEO_FRAME_FRAME FDiscreteDesc
                              );
BOOL
DisplayStreamPayload(
                     PVIDEO_FORMAT_STREAM StreamPayloadDesc
                     );
BOOL
DisplayVSEndpoint (
                   PVIDEO_CS_INTERRUPT VidEndpointDesc
                   );
VOID
VDisplayBytes (
               PUCHAR Data,
               USHORT Len
               );
PCHAR
VidFormatGUIDCodeToName (
                         REFGUID VidFormatGUIDCode
                         );
UINT
GetVCInterfaceSize (
                    PVIDEO_CONTROL_HEADER_UNIT VCInterfaceDesc
                   );
UINT
CheckForColorMatchingDesc (
                           PVIDEO_SPECIFIC FormatDesc,
                           UCHAR bNumFrameDescriptors,
                           UCHAR bDescriptorSubtype
                          );
UINT
GetVSInterfaceSize (
                    PUSB_COMMON_DESCRIPTOR VidInHeaderDesc,
                    USHORT wTotalLength
                   );
BOOL
ValidateTerminalID(
                   UINT uTerminalID
                   );
VOID
VDisplayDescString (
              UINT uControlSize,
              PUCHAR pControl ,
              PSTRINGLIST pslControl
              );

//*****************************************************************************
// L O C A L    F U N C T I O N S
//*****************************************************************************

//*****************************************************************************
//
// DisplayVideoDescriptor() UPDATED
//
// VidCommonDesc - An Video Class Descriptor
//
// bInterfaceSubClass - The SubClass of the Interface containing the descriptor
//
//*****************************************************************************

BOOL
DisplayVideoDescriptor (
    PVIDEO_SPECIFIC VidCommonDesc,
    UCHAR                        bInterfaceSubClass,
    PSTRING_DESCRIPTOR_NODE      StringDescs,
    DEVICE_POWER_STATE           LatestDevicePowerState
    )
{
    //@@DisplayVideoDescriptor -Class-Specific Video Descriptor
    switch (VidCommonDesc->bDescriptorType)
    {
    case CS_INTERFACE:
        //@@DisplayVideoDescriptor -Class-Specific Video Interface Descriptor
        switch (bInterfaceSubClass)
        {
        case VIDEO_SUBCLASS_CONTROL:
            //@@DisplayVideoDescriptor -Class-Specific Video Control Interface Descriptor
            switch (VidCommonDesc->bDescriptorSubtype)
            {
            case VC_HEADER:
                return DisplayVCHeader(
                    (PVIDEO_CONTROL_HEADER_UNIT)VidCommonDesc);

            case INPUT_TERMINAL:
                return DisplayVCInputTerminal(
                    (PVIDEO_INPUT_TERMINAL)VidCommonDesc,
                    StringDescs,
                    LatestDevicePowerState);

            case OUTPUT_TERMINAL:
                return DisplayVCOutputTerminal(
                    (PVIDEO_OUTPUT_TERMINAL)VidCommonDesc,
                    StringDescs,
                    LatestDevicePowerState);

            case SELECTOR_UNIT:
                return DisplayVCSelectorUnit(
                    (PVIDEO_SELECTOR_UNIT)VidCommonDesc,
                    StringDescs,
                    LatestDevicePowerState);

            case PROCESSING_UNIT:
                return DisplayVCProcessingUnit(
                    (PVIDEO_PROCESSING_UNIT)VidCommonDesc,
                    StringDescs,
                    LatestDevicePowerState);

            case EXTENSION_UNIT:
                return DisplayVCExtensionUnit(
                    (PVIDEO_EXTENSION_UNIT)VidCommonDesc,
                    StringDescs,
                    LatestDevicePowerState);

#ifdef H264_SUPPORT
            case H264_ENCODING_UNIT:
                return DisplayVCH264EncodingUnit(
                    (PVIDEO_ENCODING_UNIT)VidCommonDesc
                    );

#endif

#ifdef H264_SUPPORT
            case MAX_TYPE_UNIT+1:   
            // for H.264, the bDescriptorSubtype = 7, which is equal to MAX_TYPE_UNIT
            // so now MAX_TYPE_UNIT needs to be set to 8 
            //(TODO: need to change nt\sdpublic\internal\drivers\inc\uvcdesc.h's define
            // of MAX_TYPE_UNIT from7 to 8, and ad the type for H.264 = 8)
#else
            case MAX_TYPE_UNIT:
#endif
                //@@TestCase B1.1
                //@@CAUTION
                //@@Descriptor Field - bDescriptorSubtype
                //@@An undefined descriptor subtype has been defined
                AppendTextBuffer("*!*CAUTION:  This is an undefined class specific "\
                    "Video Control bDescriptorSubtype\r\n");
                break;

            default:
                //@@TestCase B1.2
                //@@ERROR
                //@@Descriptor Field - bDescriptorSubtype
                //@@An unknown descriptor subtype has been defined
                AppendTextBuffer("*!*ERROR:  unknown bDescriptorSubtype\r\n");
                OOPS();
                break;
            }
            break;

        case VIDEO_SUBCLASS_STREAMING:
            //@@DisplayVideoDescriptor -Class-Specific Video Streaming Interface Descriptor
            switch (VidCommonDesc->bDescriptorSubtype)
            {
            case VS_INPUT_HEADER:
                return DisplayVidInHeader(
                    (PVIDEO_STREAMING_INPUT_HEADER)VidCommonDesc);

            case VS_OUTPUT_HEADER:
                return DisplayVidOutHeader(
                    (PVIDEO_STREAMING_OUTPUT_HEADER)VidCommonDesc);

            case VS_STILL_IMAGE_FRAME:
                return DisplayStillImageFrame(
                    (PVIDEO_STILL_IMAGE_FRAME)VidCommonDesc);

            case VS_FORMAT_UNCOMPRESSED:
#ifdef H264_SUPPORT
                {
                    BOOL retCode = DisplayUncompressedFormat( (PVIDEO_FORMAT_UNCOMPRESSED)VidCommonDesc );
                    g_expectedNumberOfUncompressedFrameFrameDescriptors += ((PVIDEO_FORMAT_UNCOMPRESSED)VidCommonDesc)->bNumFrameDescriptors;
                    return retCode;
                }
#else
                return DisplayUncompressedFormat(
                    (PVIDEO_FORMAT_UNCOMPRESSED)VidCommonDesc);
#endif

            case VS_FRAME_UNCOMPRESSED:
#ifdef H264_SUPPORT
                {
                    BOOL retCode = DisplayUncompressedFrameType( (PVIDEO_FRAME_UNCOMPRESSED)VidCommonDesc );
                    g_numberOfUncompressedFrameFrameDescriptors++;
                    return retCode;
                }
#else
                return DisplayUncompressedFrameType(
                    (PVIDEO_FRAME_UNCOMPRESSED)VidCommonDesc);
#endif

#ifdef H264_SUPPORT
            case VS_FORMAT_H264:
                {
                    BOOL retCode = DisplayVCH264Format( (PVIDEO_FORMAT_H264)VidCommonDesc );
                    g_expectedNumberOfH264FrameDescriptors += ((PVIDEO_FORMAT_H264)VidCommonDesc)->bNumFrameDescriptors;
                    return retCode;
                }

            case VS_FRAME_H264:
                {
                    BOOL  retCode = DisplayVCH264FrameType( (PVIDEO_FRAME_H264)VidCommonDesc );
                    g_numberOfH264FrameDescriptors++;
                    return retCode;
                }
#endif

            case VS_FORMAT_MJPEG:
#ifdef H264_SUPPORT // additional checks
                {
                    BOOL retCode = DisplayMJPEGFormat( (PVIDEO_FORMAT_MJPEG)VidCommonDesc );
                    g_expectedNumberOfMJPEGFrameDescriptors += ((PVIDEO_FORMAT_MJPEG)VidCommonDesc)->bNumFrameDescriptors;
                    return retCode;
                }
#else
                return DisplayMJPEGFormat(
                    (PVIDEO_FORMAT_MJPEG)VidCommonDesc);
#endif

            case VS_FRAME_MJPEG:
#ifdef H264_SUPPORT
                {
                    BOOL  retCode = DisplayMJPEGFrameType( (PVIDEO_FRAME_MJPEG)VidCommonDesc );
                    g_numberOfMJPEGFrameDescriptors++;
                    return retCode;
                }

#else
                return DisplayMJPEGFrameType(
                    (PVIDEO_FRAME_MJPEG)VidCommonDesc);
#endif



            case VS_FORMAT_MPEG1:
            {
                if (UVC10 == g_chUVCversion)
                {
                    return DisplayMPEG1SSFormat(
                        (PVIDEO_FORMAT_MPEG1SS)VidCommonDesc);
                }
                else // this format is obsoleted in UVC version >= 1.1
                {
                    AppendTextBuffer("*!*ERROR:  obsoleted bDescriptorSubtype\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_FORMAT_MPEG2PS:
            {
                if (UVC10 == g_chUVCversion)
                {
                    return DisplayMPEG2PSFormat(
                        (PVIDEO_FORMAT_MPEG2PS)VidCommonDesc);
                }
                else // this format is obsoleted in UVC version >= 1.1
                {
                    AppendTextBuffer("*!*ERROR:  obsoleted bDescriptorSubtype\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_FORMAT_MPEG2TS:
                return DisplayMPEG2TSFormat(
                    (PVIDEO_FORMAT_MPEG2TS)VidCommonDesc);

            case VS_FORMAT_MPEG4SL:
            {
                if (UVC10 == g_chUVCversion)
                {
                    return DisplayMPEG4SLFormat(
                        (PVIDEO_FORMAT_MPEG4SL)VidCommonDesc);
                }
                else // this format is obsoleted in UVC version >= 1.1
                {
                    AppendTextBuffer("*!*ERROR:  obsoleted bDescriptorSubtype\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_FORMAT_DV:
                return DisplayDVFormat(
                    (PVIDEO_FORMAT_DV)VidCommonDesc);

            case VS_COLORFORMAT:
                return DisplayColorMatching(
                    (PVIDEO_COLORFORMAT)VidCommonDesc);

            case VS_FORMAT_VENDOR:
            {
                if (UVC10 == g_chUVCversion)
                {
                     return DisplayVendorVidFormat(
                        (PVIDEO_FORMAT_VENDOR)VidCommonDesc);
                }
                else // this format is obsoleted in UVC version >= 1.1
                {
                    AppendTextBuffer("*!*ERROR:  obsoleted bDescriptorSubtype\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_FRAME_VENDOR:
            {
                if (UVC10 == g_chUVCversion)
                {
                    return DisplayVendorVidFrameType(
                        (PVIDEO_FRAME_VENDOR)VidCommonDesc);
                }
                else // this format is obsoleted in UVC version >= 1.1
                {
                    AppendTextBuffer("*!*ERROR:  obsoleted bDescriptorSubtype\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_FORMAT_FRAME_BASED:
            {
                if (UVC10 != g_chUVCversion)
                {
                    return DisplayFramePayloadFormat(
                        (PVIDEO_FORMAT_FRAME)VidCommonDesc);
                }
                else // this format did not exist in UVC 1.0
                {
                    AppendTextBuffer("*!*ERROR: bDescriptorSubtype did not exist in UVC 1.0\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_FRAME_FRAME_BASED:
            {
                if (UVC10 != g_chUVCversion)
                {
                    return DisplayFramePayloadFrame(
                        (PVIDEO_FRAME_FRAME)VidCommonDesc);
                }
                else // this format did not exist in UVC 1.0
                {
                    AppendTextBuffer("*!*ERROR: bDescriptorSubtype did not exist in UVC 1.0\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_FORMAT_STREAM_BASED:
            {
                if (UVC10 != g_chUVCversion)
                {
                    return DisplayStreamPayload(
                        (PVIDEO_FORMAT_STREAM)VidCommonDesc);
                }
                else // this format did not exist in UVC 1.0
                {
                    AppendTextBuffer("*!*ERROR: bDescriptorSubtype did not exist in UVC 1.0\r\n");
                    OOPS();
                    break;
                }
            }

            case VS_DESCRIPTOR_UNDEFINED:
                //@@TestCase B1.3
                //@@CAUTION
                //@@Descriptor Field - bDescriptorSubtype
                //@@An undefined descriptor subtype has been defined
                AppendTextBuffer("*!*CAUTION:  This is an undefined class specific Video "\
                    "Streaming bDescriptorSubtype\r\n");
                break;

            default:
                //@@TestCase B1.4
                //@@ERROR
                //@@Descriptor Field - bDescriptorSubtype
                //@@An unknown descriptor subtype has been defined
                AppendTextBuffer("*!*ERROR:  unknown bDescriptorSubtype\r\n");
                OOPS();
                break;
            }
            break;

        default:
            //@@TestCase B1.6
            //@@ERROR
            //@@Descriptor Field - bInterfaceSubClass
            //@@An unknown interface sub-class has been defined
            AppendTextBuffer("*!*ERROR:  unknown bInterfaceSubClass\r\n");
            OOPS();
            break;
        }
        break;

    case CS_ENDPOINT:
        //@@DisplayVideoDescriptor -Class-Specific Video Endpoint Descriptor
        switch (VidCommonDesc->bDescriptorSubtype)
        {
            //@@TestCase B1.7
            //@@CAUTION
            //@@Descriptor Field - bInterfaceSubtype
            //@@An undefined descriptor subtype has been defined
        case EP_UNDEFINED:
            AppendTextBuffer("*!*CAUTION:  This is an undefined bDescriptorSubtype\r\n");
            break;
            //@@TestCase B1.8
            //@@Not yet implemented - Priority 3
            //@@Descriptor Field - bDescriptorSubtype
            //@@Question:  How valid are VIDEO_EP_GENERAL and VIDEO_EP_ENDPOINT?  Should we test?
        case EP_GENERAL:
            break;
        case EP_ENDPOINT:
            break;
        case EP_INTERRUPT:
            return DisplayVSEndpoint(
                (PVIDEO_CS_INTERRUPT)VidCommonDesc);
            break;
        default:
            //@@TestCase B1.9
            //@@ERROR
            //@@Descriptor Field - bDescriptorSubtype
            //@@An unknown descriptor subtype has been defined
            AppendTextBuffer("*!*CAUTION:  Unknown bDescriptorSubtype");
            break;
        }
        break;
        //@@DisplayVideoDescriptor -Class-Specific Video Device Descriptor
        //@@DisplayVideoDescriptor -Class-Specific Video Configuration Descriptor
        //@@DisplayVideoDescriptor -Class-Specific Video String Descriptor
        //@@DisplayVideoDescriptor -Class-Specific Video Undefined Descriptor
        //@@TestCase B1.10
        //@@Not yet implemented - Priority 3
        //@@Descriptor -Class-Specific Device, Configuration, String, Undefined
        //@@Descriptor Field - bDescriptorType
        //@@Question:  How valid are these Descriptor Types?  Should we test?

        /*        case USB_VIDEO_CS_DEVICE:
        AppendTextBuffer("USB_VIDEO_CS_DEVICE bDescriptorType\r\n");
        break;

        case USB_VIDEO_CS_CONFIGURATION:
        AppendTextBuffer("USB_VIDEO_CS_CONFIGURATION bDescriptorType\r\n");
        break;

        case USB_VIDEO_CS_STRING:
        AppendTextBuffer("USB_VIDEO_CS_STRING bDescriptorType\r\n");
        break;

        case USB_VIDEO_CS_UNDEFINED:
        AppendTextBuffer("USB_VIDEO_CS_UNDEFINED bDescriptorType\r\n");
        break;
        */
    default:
        //@@TestCase B1.11
        //@@ERROR
        //@@Descriptor Field - bDescriptorType
        //@@An unknown descriptor type has been defined
        AppendTextBuffer("*!*CAUTION:  Unknown bDescriptorSubtype");
        OOPS();
        break;
    }

    return FALSE;
}


//*****************************************************************************
//
// DisplayVCHeader()
//
//*****************************************************************************

BOOL
DisplayVCHeader (
                 PVIDEO_CONTROL_HEADER_UNIT VCInterfaceDesc
                 )
{
    //@@DisplayVCHeader -Video Control Interface Header
    UINT   i = 0;
    UINT   uSize = 0;
    PUCHAR pData = NULL;

    AppendTextBuffer("\r\n          ===>Class-Specific Video Control Interface Header "\
        "Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VCInterfaceDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VCInterfaceDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VCInterfaceDesc->bDescriptorSubtype);
    if ( UVC10 == g_chUVCversion )
    {
        AppendTextBuffer("bcdVDC:                          0x%04X\r\n", VCInterfaceDesc->bcdVideoSpec);
    }
    else
    {
        AppendTextBuffer("bcdUVC:                          0x%04X\r\n", VCInterfaceDesc->bcdVideoSpec);
    }
    AppendTextBuffer("wTotalLength:                    0x%04X", VCInterfaceDesc->wTotalLength);

    // Verify the total interface size (size of this header and all descriptors 
    //   following until and not including the first endpoint)
    uSize = GetVCInterfaceSize(VCInterfaceDesc);
    if (uSize != VCInterfaceDesc->wTotalLength) {
        AppendTextBuffer("\r\n*!*ERROR: Invalid total interface size 0x%02X, should be 0x%02X\r\n",
            VCInterfaceDesc->wTotalLength, uSize);
    } else {
        AppendTextBuffer("  -> Validated\r\n");
    }
    AppendTextBuffer("dwClockFreq:                 0x%08X", 
        VCInterfaceDesc->dwClockFreq);
    if (gDoAnnotation)  
    {
        AppendTextBuffer(" = (%d) Hz", VCInterfaceDesc->dwClockFreq); 
    }
    AppendTextBuffer("\r\nbInCollection:                     0x%02X\r\n", 
        VCInterfaceDesc->bInCollection);

    // baInterfaceNr is a variable length field
    // Size is in bInCollection
    for (i = 1, pData = (PUCHAR) &VCInterfaceDesc->bInCollection; 
        i <= VCInterfaceDesc->bInCollection; i++, pData++)
    {
        AppendTextBuffer("baInterfaceNr[%d]:                  0x%02X\r\n", 
            i, *pData);
    }

    uSize = (sizeof(VIDEO_CONTROL_HEADER_UNIT) + VCInterfaceDesc->bInCollection);
    if (VCInterfaceDesc->bLength != uSize)
    {
        //@@TestCase B2.1 (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is less than required length in 
        //@@  the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            VCInterfaceDesc->bLength, uSize);
        OOPS();
    }

    //@@TestCase B2.2 (also in Descript.c)
    //@@WARNING
    //@@Descriptor Field - bcdVDC
    //@@The bcdVDC version of the device is not the same as the version of used by USBView
    if(VCInterfaceDesc->bcdVideoSpec < BCDVDC)
    {
        AppendTextBuffer("*!*WARNING: This device is set to the old USB Video "\
            "Class spec version 0x%04X\r\n", VCInterfaceDesc->bcdVideoSpec);
        OOPS();
    }

    if (VCInterfaceDesc->dwClockFreq < 1)
    {
        //@@TestCase B2.3 (Descript.c Line 70)
        //@@WARNING
        //@@dwClockFrequency should be greater than 0
        //@@Question should we check that any non-zero value is accurate
        AppendTextBuffer("*!*ERROR:  dwClockFreq must be non-zero\r\n");
        OOPS();
    }

    //@@TestCase B2.4
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - baInterfaceNr
    //@@We should test to verify each interface number is valid?
    //    for (i=0; i<VCInterfaceDesc->bInCollection; i++) 
    //      {AppendTextBuffer("baInterfaceNr[%d]:                  0x%02X\r\n", i+1, 
    //        VCInterfaceDesc->baInterfaceNr[i]);}


    if (gDoAnnotation)
    {
        switch(g_chUVCversion)
        {
        case UVC10:
            AppendTextBuffer("USB Video Class device: spec version 1.0\r\n");
            break;
        case UVC11:
            AppendTextBuffer("USB Video Class device: spec version 1.1\r\n");
            break;
#ifdef H264_SUPPORT
        case UVC15:
            AppendTextBuffer("USB Video Class device: spec version 1.5\r\n");
            break;
#endif

        default:
            break;
        }
    }
    return TRUE;
}


//*****************************************************************************
//
// DisplayVCInputTerminal()
//
//*****************************************************************************

BOOL
DisplayVCInputTerminal (
    PVIDEO_INPUT_TERMINAL   VidITDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    )
{
    //@@DisplayVCInputTerminal -Video Control Input Terminal
    PCHAR pStr = NULL;

    AppendTextBuffer("\r\n          ===>Video Control Input Terminal Descriptor<===\r\n");

    AppendTextBuffer("bLength:                           0x%02X\r\n", VidITDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidITDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidITDesc->bDescriptorSubtype);
    AppendTextBuffer("bTerminalID:                       0x%02X\r\n", VidITDesc->bTerminalID);
    AppendTextBuffer("wTerminalType:                   0x%04X", VidITDesc->wTerminalType);
    if(gDoAnnotation)
    {
        pStr = GetStringFromList(slInputTermTypes, 
                sizeof(slInputTermTypes) / sizeof(STRINGLIST),
                VidITDesc->wTerminalType, 
                "Invalid Input Terminal Type");
        AppendTextBuffer(" = (%s)", pStr); 
    }
    AppendTextBuffer("\r\n");
    
    AppendTextBuffer("bAssocTerminal:                    0x%02X\r\n", VidITDesc->bAssocTerminal);
    AppendTextBuffer("iTerminal:                         0x%02X\r\n", VidITDesc->iTerminal);
    if (gDoAnnotation)
    {
        if (VidITDesc->iTerminal)
        {
            // if executing this code, the configuration descriptor has been 
            // obtained.  If a device is suspended, then its configuration
            // descriptor was not obtained and we do not want errors to be 
            // displayed when string descriptors were not obtained.
            DisplayStringDescriptor(VidITDesc->iTerminal, StringDescs, LatestDevicePowerState); 
        }
    }

    if (VidITDesc->bLength < sizeof(VIDEO_INPUT_TERMINAL))
    {
        //@@TestCase B3.1  (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is less than required length in 
        //@@  the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d is too small\r\n", VidITDesc->bLength);
        OOPS();
    }

    if (VidITDesc->bTerminalID < 1)
    {
        //@@TestCase B3.2 (descript.c  line 133)
        //@@ERROR
        //@@Descriptor Field - bTerminalID
        //@@bTerminalID should be greater than 0
        //@@Question: Should test to verify terminal number is valid
        AppendTextBuffer("*!*ERROR:  bTerminalID of %d is too small\r\n", VidITDesc->bTerminalID);
        OOPS();
    }

    if (!(pStr))
    {
        //@@TestCase B3.3
        //@@CAUTION
        //@@Descriptor Field - wTerminalType
        //@@No valid Terminal Type was found
        AppendTextBuffer("*!*CAUTION:  0x%04X is an unknown wTerminalType for an Input "\
            "Terminal\r\n", VidITDesc->wTerminalType);
        OOPS();
    }

    //@@TestCase B3.4
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bAssocTerminal
    //@@Should test to verify terminal number is valid?
    //    AppendTextBuffer("bAssocTerminal:                    0x%02X\r\n", VidITDesc->bAssocTerminal);

    switch (VidITDesc->wTerminalType)
    {
    case 0x0100:  // TT_VENDOR_SPECIFIC Terminal Type
        break;
    case 0x0101:  // TT_STREAMING Terminal Type
        break;
    case 0x0200:  // ITT_VENDOR_SPECIFIC Terminal Type
        break;
    case 0x0201:  // ITT_CAMERA Terminal Type
        return DisplayVCCameraTerminal(
            (PVIDEO_CAMERA_TERMINAL)VidITDesc);
    case 0x0202:  // ITT_MEDIA_TRANSPORT_INPUT Terminal Type
        return DisplayVCMediaTransInputTerminal(
            (PVIDEO_INPUT_MTT)VidITDesc);
    case 0x0400:  // EXTERNAL_VENDOR_SPECIFIC Terminal Type
        break;
    case 0x0401:  // COMPOSITE_CONNECTOR Terminal Type
        break;
    case 0x0402:  // SVIDEO_CONNECTOR Terminal Type
        break;
    case 0x0403:  // COMPONENT_CONNECTOR Terminal Type
        break;
    default:
        break;
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayVCOutputTerminal()
//
//*****************************************************************************

BOOL
DisplayVCOutputTerminal (
    PVIDEO_OUTPUT_TERMINAL  VidOTDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    )
{
    //@@DisplayVCOutputTerminal -Video Control Output Terminal
    PCHAR pStr = NULL;

    AppendTextBuffer("\r\n          ===>Video Control Output Terminal Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VidOTDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidOTDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidOTDesc->bDescriptorSubtype);
    AppendTextBuffer("bTerminalID:                       0x%02X\r\n", VidOTDesc->bTerminalID);
    AppendTextBuffer("wTerminalType:                   0x%04X", VidOTDesc->wTerminalType);
    if(gDoAnnotation)
    {
        pStr = GetStringFromList(slOutputTermTypes, 
                sizeof(slOutputTermTypes) / sizeof(STRINGLIST),
                VidOTDesc->wTerminalType, 
                "Invalid Output Terminal Type");
        AppendTextBuffer(" = (%s)", pStr); 
    }
    AppendTextBuffer("\r\n");
    AppendTextBuffer("bAssocTerminal:                    0x%02X\r\n", VidOTDesc->bAssocTerminal);
    AppendTextBuffer("bSourceID:                         0x%02X\r\n", VidOTDesc->bSourceID);
    AppendTextBuffer("iTerminal:                         0x%02X\r\n", VidOTDesc->iTerminal);
    if (gDoAnnotation)
    {
        if (VidOTDesc->iTerminal)
        {
            // if executing this code, the configuration descriptor has been 
            // obtained.  If a device is suspended, then its configuration
            // descriptor was not obtained and we do not want errors to be 
            // displayed when string descriptors were not obtained.
            DisplayStringDescriptor(VidOTDesc->iTerminal, StringDescs, LatestDevicePowerState);
        }
    }

    if (VidOTDesc->bLength < sizeof(PVIDEO_OUTPUT_TERMINAL))
    {
        //@@TestCase B4.1  (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is less than required length in 
        //@@  the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d is too small\r\n", VidOTDesc->bLength);
        OOPS();
    }

    if (VidOTDesc->bTerminalID < 1)
    {
        //@@TestCase B4.2  (see Descript.c  line 328)
        //@@ERROR
        //@@Descriptor Field - bTerminalID
        //@@bTerminalID should be greater than 0
        //@@Question: Should test to verify terminal number is valid
        AppendTextBuffer("*!*ERROR:  bTerminalID of %d is too small\r\n", VidOTDesc->bTerminalID);
        OOPS();
    }


    if (!(pStr))
    {
        //@@TestCase B4.3
        //@@ERROR
        //@@Descriptor Field - wTerminalType
        //@@No valid Terminal Type was found
        AppendTextBuffer("*!*ERROR:  0x%04X is an invalid wTerminalType for an Output Terminal\r\n",
            VidOTDesc->wTerminalType);
        OOPS();
    }

    //@@TestCase B4.4
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bAssocTerminal
    //@@We should test to verify terminal number is valid
    //    AppendTextBuffer("bAssocTerminal:                    0x%02X\r\n", VidOTDesc->bAssocTerminal);

    if (VidOTDesc->bSourceID < 1)
    {
        //@@TestCase B4.5  (see Descript.c  line 333)
        //@@ERROR
        //@@Descriptor Field - bSourceID
        //@@bSourceID should be greater than 0
        //@@Question: Should test to verify source number is valid
        AppendTextBuffer("*!*ERROR:  bSourceID of %d is too small\r\n", VidOTDesc->bSourceID);
        OOPS();
    }

    switch (VidOTDesc->wTerminalType)
    {
    case 0x0100:  // TT_VENDOR_SPECIFIC Terminal Type
        break;
    case 0x0101:  // TT_STREAMING Terminal Type
        break;
    case 0x0300:  // OTT_VENDOR_SPECIFIC Terminal Type
        break;
    case 0x0301:  // OTT_DISPLAY Terminal Type
        break;
    case 0x0302:  // OTT_MEDIA_TRANSPORT_OUTPUT Terminal Type
        return DisplayVCMediaTransOutputTerminal(
            (PVIDEO_OUTPUT_MTT)VidOTDesc);
    case 0x0400:  // EXTERNAL_VENDOR_SPECIFIC Terminal Type
        break;
    case 0x0401:  // COMPOSITE_CONNECTOR Terminal Type
        break;
    case 0x0402:  // SVIDEO_CONNECTOR Terminal Type
        break;
    case 0x0403:  // COMPONENT_CONNECTOR Terminal Type
        break;
    default:
        break;
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayVCMediaTransInputTerminal()
//
//*****************************************************************************

BOOL
DisplayVCMediaTransInputTerminal(
                                 PVIDEO_INPUT_MTT MediaTransportInDesc
                                 )
{
    //@@DisplayVCMediaTransInputTerminal -Video Control Media Transport Input Terminal
    UCHAR  p = 0;
    PUCHAR pData = NULL;
    size_t bLength = 0;

    bLength = SizeOfVideoInputMTT(MediaTransportInDesc);

    AppendTextBuffer("===>Additional Media Transport Input Terminal Data\r\n");
    AppendTextBuffer("bControlSize:                      0x%02X\r\n", 
        MediaTransportInDesc->bControlSize);

    // point to bControlSize
    pData = & MediaTransportInDesc->bControlSize;

    // Are there any controls?
    if (0 < * pData)
        {
        UINT  uBitIndex  = 0;
        BYTE  cCheckBit = 0;
        BYTE  cMask = 1; 

        AppendTextBuffer("bmControls : ");
        VDisplayBytes(pData + 1, *pData);
        
        // map the first control    
        for ( ; uBitIndex < 8; uBitIndex++ )
            {
            cCheckBit = cMask & *(pData + 1);

            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                uBitIndex,
                cCheckBit ? 1 : 0,
                cCheckBit ? "yes - " : " no - ",
                GetStringFromList(slMediaTransportControls, 
                    sizeof(slMediaTransportControls) / sizeof(STRINGLIST),
                    cMask, 
                    "Invalid MediaTransportCtrl bmControl value"));

            cMask = cMask << 1;
            }
    }

    // point to bTransportModeSize
    pData = pData + 2 ;

    // Are there any controls?
    if (0 < * pData)
        {
        UINT  uBitIndex  = 0;
        BYTE  cCheckBit = 0;
        BYTE  cMask = 1; 

        AppendTextBuffer("bmControls : ");
        VDisplayBytes(pData + 1, *pData);
        
        // map the first control    
        for ( ; uBitIndex < 8; uBitIndex++ )
            {
            cCheckBit = cMask & *(pData + 1);

            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                uBitIndex,
                cCheckBit ? 1 : 0,
                cCheckBit ? "yes - " : " no - ",
                GetStringFromList(slMediaTransportModes1, 
                    sizeof(slMediaTransportModes1) / sizeof(STRINGLIST),
                    cMask, 
                    "Invalid MediaTransportMode value"));

            cMask = cMask << 1;
            }
        
        // Is there a second control?
        if (1 < * pData)
            {
            // map the second control   
            for ( uBitIndex = 8, cMask = 1; uBitIndex < 16; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 2);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes2, 
                        sizeof(slMediaTransportModes2) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
        // Is there a third control?
        if (2 < * pData)
            {
            // map the third control    
            for ( uBitIndex = 16, cMask = 1; uBitIndex < 24; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 3);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes3, 
                        sizeof(slMediaTransportModes3) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
        // Is there a fourth control?
        if (3 < * pData)
            {
            // map the fourth control   
            for ( uBitIndex = 24, cMask = 1; uBitIndex < 32; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 4);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes4, 
                        sizeof(slMediaTransportModes4) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
        // Is there a fifth control?
        if (4 < * pData)
            {
            // map the fifth control   
            for ( uBitIndex = 32, cMask = 1; uBitIndex < 40; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 5);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes5, 
                        sizeof(slMediaTransportModes5) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
    }

    // The size of a Media Transport Descriptor is 
    //   the size of the Descriptor plus
    //   (bControlSize - 1) plus
    //   IF bmControls & 1 THEN 1 (bTransportModeSize) plus
    //   bTransportModeSize
    //   
//    p = sizeof(VIDEO_INPUT_MTT) + 
//        (MediaTransportInDesc->bControlSize - 1);
//    if (MediaTransportInDesc->bmControls[0] & 1)
//        p += 1 + (*pData);
    if (MediaTransportInDesc->bLength != bLength)
    {
        //@@TestCase B5.1 (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@Invalid Descriptor length
        AppendTextBuffer("*!*ERROR:  Invalid descriptor bLength 0x%02X. "\
            "Should be 0x%02X\r\n",
            MediaTransportInDesc->bLength, p);
        OOPS();
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayVCMediaTransOutputTerminal()
//
//*****************************************************************************

BOOL
DisplayVCMediaTransOutputTerminal(
                                  PVIDEO_OUTPUT_MTT MediaTransportOutDesc
                                  )
{
    //@@DisplayVCMediaTransOutputTerminal -Video Control Media Transport Output Terminal
    UCHAR  p = 0;
    PUCHAR pData = NULL;

    AppendTextBuffer("===>Additional Media Transport Output Terminal Data\r\n");
    AppendTextBuffer("bControlSize:                      0x%02X\r\n", 
        MediaTransportOutDesc->bControlSize);

    // point to bControlSize
    pData = & MediaTransportOutDesc->bControlSize;

    // Are there any controls?
    if (0 < * pData)
        {
        UINT  uBitIndex  = 0;
        BYTE  cCheckBit = 0;
        BYTE  cMask = 1; 

        AppendTextBuffer("bmControls : ");
        VDisplayBytes(pData + 1, *pData);
        
        // map the first control    
        for ( ; uBitIndex < 8; uBitIndex++ )
            {
            cCheckBit = cMask & *(pData + 1);

            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                uBitIndex,
                cCheckBit ? 1 : 0,
                cCheckBit ? "yes - " : " no - ",
                GetStringFromList(slMediaTransportControls, 
                    sizeof(slMediaTransportControls) / sizeof(STRINGLIST),
                    cMask, 
                    "Invalid MediaTransportCtrl bmControl value"));

            cMask = cMask << 1;
            }
    }

    // point to bTransportModeSize
    pData = pData + 2 ;

    // Are there any controls?
    if (0 < * pData)
        {
        UINT  uBitIndex  = 0;
        BYTE  cCheckBit = 0;
        BYTE  cMask = 1; 

        AppendTextBuffer("bmControls : ");
        VDisplayBytes(pData + 1, *pData);
        
        // map the first control    
        for ( ; uBitIndex < 8; uBitIndex++ )
            {
            cCheckBit = cMask & *(pData + 1);

            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                uBitIndex,
                cCheckBit ? 1 : 0,
                cCheckBit ? "yes - " : " no - ",
                GetStringFromList(slMediaTransportModes1, 
                    sizeof(slMediaTransportModes1) / sizeof(STRINGLIST),
                    cMask, 
                    "Invalid MediaTransportMode value"));

            cMask = cMask << 1;
            }
        
        // Is there a second control?
        if (1 < * pData)
            {
            // map the second control   
            for ( uBitIndex = 8, cMask = 1; uBitIndex < 16; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 2);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes2, 
                        sizeof(slMediaTransportModes2) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
        // Is there a third control?
        if (2 < * pData)
            {
            // map the third control    
            for ( uBitIndex = 16, cMask = 1; uBitIndex < 24; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 3);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes3, 
                        sizeof(slMediaTransportModes3) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
        // Is there a fourth control?
        if (3 < * pData)
            {
            // map the fourth control   
            for ( uBitIndex = 24, cMask = 1; uBitIndex < 32; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 4);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes4, 
                        sizeof(slMediaTransportModes4) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
        // Is there a fifth control?
        if (4 < * pData)
            {
            // map the fourth control   
            for ( uBitIndex = 32, cMask = 1; uBitIndex < 40; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 5);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slMediaTransportModes5, 
                        sizeof(slMediaTransportModes5) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid MediaTransportMode value"));

                cMask = cMask << 1;
                }
            }
    }

    // The size of a Media Transport Descriptor is 
    //   the size of the Descriptor plus
    //   (bControlSize - 1) plus
    //   IF bmControls & 1 THEN 1 (bTransportModeSize) plus
    //   bTransportModeSize
    //   
    p = sizeof(VIDEO_OUTPUT_MTT) + 
        (MediaTransportOutDesc->bControlSize - 1);
    if (MediaTransportOutDesc->bmControls[0] & 1)
        p += 1 + (*pData);
    if (MediaTransportOutDesc->bLength != p)
    {
        //@@TestCase B5.1 (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@Invalid Descriptor length
        AppendTextBuffer("*!*ERROR:  Invalid descriptor bLength 0x%02X. "\
            "Should be 0x%02X\r\n",
            MediaTransportOutDesc->bLength, p);
        OOPS();
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayVCCameraTerminal()
//
//*****************************************************************************

BOOL
DisplayVCCameraTerminal(
                        PVIDEO_CAMERA_TERMINAL CameraDesc
                        )
{
    //@@DisplayVCCameraTerminal -Video Control Camera Terminal
    UCHAR  p = 0;
    PUCHAR pData = NULL;

    AppendTextBuffer("===>Camera Input Terminal Data\r\n");
    AppendTextBuffer("wObjectiveFocalLengthMin:        0x%04X\r\n", CameraDesc->wObjectiveFocalLengthMin);
    AppendTextBuffer("wObjectiveFocalLengthMax:        0x%04X\r\n", CameraDesc->wObjectiveFocalLengthMax);
    AppendTextBuffer("wOcularFocalLength:              0x%04X\r\n", CameraDesc->wOcularFocalLength);
    AppendTextBuffer("bControlSize:                      0x%02X\r\n", CameraDesc->bControlSize);

    pData = &CameraDesc->bControlSize;

    // Are there any controls?
    if (0 < * pData)
        {
        UINT  uBitIndex  = 0;
        BYTE  cCheckBit = 0;
        BYTE  cMask = 1; 

        AppendTextBuffer("bmControls : ");
        VDisplayBytes(pData + 1, *pData);
        
        // map the first control    
        for ( ; uBitIndex < 8; uBitIndex++ )
            {
            cCheckBit = cMask & *(pData + 1);

            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                uBitIndex,
                cCheckBit ? 1 : 0,
                cCheckBit ? "yes - " : " no - ",
                GetStringFromList(slCameraControl1, 
                    sizeof(slCameraControl1) / sizeof(STRINGLIST),
                    cMask, 
                    "Invalid CamCtrl bmControl value"));

            cMask = cMask << 1;
            }
        
        // Is there a second control?
        if (1 < * pData)
            {
            // map the second control   
            for ( uBitIndex = 8, cMask = 1; uBitIndex < 16; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 2);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slCameraControl2, 
                        sizeof(slCameraControl2) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid CamCtrl bmControl value"));

                cMask = cMask << 1;
                }
            }
        // Is there a third control?
        if (2 < * pData)
            {
            // map the third control    
            for ( uBitIndex = 16, cMask = 1; uBitIndex < 24; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + 3);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slCameraControl3, 
                        sizeof(slCameraControl3) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid CamCtrl bmControl value"));

                cMask = cMask << 1;
                }
            }
    }

    p = (sizeof(VIDEO_CAMERA_TERMINAL) + CameraDesc->bControlSize);
    if (CameraDesc->bLength != p)
    {
        //@@TestCase B7.1 (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The descriptor should be the size of the descriptor structure 
        //@@  plus the number of controls
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            CameraDesc->bLength, p);
        OOPS();
    }

    //@@TestCase B7.2
    //@@Not yet implemented - Priority 3
    //@@Descriptor Field - wObjectiveFocalLengthMin
    //@@Question - Should we do any checking here?  What are the acceptable boundaries?
    //@@Question - Is zero an acceptable value?
    //    AppendTextBuffer("wObjectiveFocalLengthMin:        0x%04X\r\n", CameraDesc->wObjectiveFocalLengthMin);

    //@@TestCase B7.3
    //@@Not yet implemented - Priority 3
    //@@Descriptor Field - wObjectiveFocalLengthMax
    //@@Question - Should we do any checking here?  What are the acceptable boundaries
    //@@Question - Is zero an acceptable value?
    //    AppendTextBuffer("wObjectiveFocalLengthMax:        0x%04X\r\n", CameraDesc->wObjectiveFocalLengthMax);

    //@@TestCase B7.4
    //@@Not yet implemented - Priority 3
    //@@Descriptor Field - wOcularFocalLength
    //@@Question - Should we do any checking here?  What are the acceptable boundaries
    //@@Question - Is zero an acceptable value?
    //    AppendTextBuffer("wOcularFocalLength:              0x%04X\r\n", CameraDesc->wOcularFocalLength);

    //@@TestCase B7.5
    //@@ERROR
    //@@Descriptor Field - wObjectiveFocalLengthMin and wObjectiveFocalLengthMax
    //@@Verify that wObjectiveFocalLengthMax is greater than wObjectiveFocalLengthMin
    if(CameraDesc->wObjectiveFocalLengthMin > CameraDesc->wObjectiveFocalLengthMax)
    {
        AppendTextBuffer("*!*ERROR:  wObjectiveFocalLengthMin is larger than wObjectiveFocalLengthMax\r\n");
        OOPS();
    }

    //@@TestCase B7.6
    //@@ERROR
    //@@Descriptor Field - bControlSize
    //@@Verify that wObjectiveFocalLengthMax is 3 or less
    if(CameraDesc->bControlSize > 3)
    {
        AppendTextBuffer("*!*ERROR:  bControlSize must be 3 or less\r\n");
        OOPS();
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayVCSelectorUnit()
//
//*****************************************************************************

BOOL
DisplayVCSelectorUnit (
    PVIDEO_SELECTOR_UNIT    VidSelectorDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    )
{
    //@@DisplayVCSelectorUnit -Video Control Selector Unit
    UCHAR  i = 0;
    UCHAR  p = 0;
    PUCHAR pData = NULL;

    AppendTextBuffer("\r\n          ===>Video Control Selector Unit Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VidSelectorDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidSelectorDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidSelectorDesc->bDescriptorSubtype);
    AppendTextBuffer("bUnitID:                           0x%02X\r\n", VidSelectorDesc->bUnitID);
    AppendTextBuffer("bNrInPins:                         0x%02X\r\n", VidSelectorDesc->bNrInPins);
    if (gDoAnnotation) 
    {
        AppendTextBuffer("===>List of Connected Unit and Terminal ID's\r\n");
    }
    // baSourceID is a variable length field
    // Size is in bNrInPins, must be at least 1 (so index starts at 1)
    for (i = 1, pData = (PUCHAR) &VidSelectorDesc->baSourceID; 
        i <= VidSelectorDesc->bNrInPins; i++, pData++)
    {
        AppendTextBuffer("baSourceID[%d]:                     0x%02X\r\n", 
            i, *pData);
    }

    // get address of iSelector, the last field in this descriptor
    pData = (PUCHAR) VidSelectorDesc + (VidSelectorDesc->bLength - 1);
    AppendTextBuffer("iSelector:                         0x%02X\r\n", *pData);
    if (gDoAnnotation)
    {
        if (*pData)
        {
            // if executing this code, the configuration descriptor has been 
            // obtained.  If a device is suspended, then its configuration
            // descriptor was not obtained and we do not want errors to be 
            // displayed when string descriptors were not obtained.
            DisplayStringDescriptor(*pData, StringDescs, LatestDevicePowerState);
        }
    }

    p = (sizeof(VIDEO_SELECTOR_UNIT) + VidSelectorDesc->bNrInPins + 1);
    if (VidSelectorDesc->bLength != p)
    {
        //@@TestCase B8.1 (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The descriptor should be the size of the descriptor structure plus the number of pins
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            VidSelectorDesc->bLength, p);
        OOPS();
    }

    if (VidSelectorDesc->bUnitID < 1)
    {
        //@@TestCase B8.2 (Descript.c   Line 396)
        //@@ERROR
        //@@Descriptor Field - bUnitID
        //@@bUnitID must be greater than 0
        //@@Question: Should we test to verify unit number is unique?
        AppendTextBuffer("*!*ERROR:  bUnitID must be non-zero\r\n");
        OOPS();
    }

    if (VidSelectorDesc->bNrInPins < 1)
    {
        //@@TestCase B8.3
        //@@ERROR
        //@@Descriptor Field - bNrInPins
        //@@bNrInPins should be greater than 0
        //@@Question: Should test to verify total in pins is valid
        AppendTextBuffer("*!*ERROR:  bNrInPins must be non-zero\r\n");
        OOPS();
    }

    // baSourceID is a variable length field
    // Size is in bNrInPins, must be at least 1 (so index starts at 1)
    for (i = 1, pData = (PUCHAR) &VidSelectorDesc->baSourceID; 
        i <= VidSelectorDesc->bNrInPins; i++, pData++)
    {
        if (*pData < 1)
        {
            //@@TestCase B8.4
            //@@ERROR
            //@@Descriptor Field - baSourceID[]
            //@@baSourceID should be greater than 0
            AppendTextBuffer("*!*ERROR:  baSourceID[%d] must be non-zero\r\n", i);
            OOPS();
        } else {
            if (! ValidateTerminalID(*pData)) {
            //@@TestCase B8.5
            //@@ERROR
            //@@Descriptor Field - baSourceID[]
            //@@baSourceID should be a valid terminal ID
            AppendTextBuffer("*!*ERROR:  baSourceID[%d] must be non-zero\r\n", i);
            OOPS();
            }
        }
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayVCProcessingUnit()
//
//*****************************************************************************

BOOL
DisplayVCProcessingUnit (
    PVIDEO_PROCESSING_UNIT  VidProcessingDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    )
{
    //@@DisplayVCProcessingUnit -Video Control Processor Unit
    PUCHAR pData = NULL;
    UCHAR  bLength = 0;

    AppendTextBuffer("\r\n          ===>Video Control Processing Unit Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VidProcessingDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidProcessingDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidProcessingDesc->bDescriptorSubtype);
    AppendTextBuffer("bUnitID:                           0x%02X\r\n", VidProcessingDesc->bUnitID);
    AppendTextBuffer("bSourceID:                         0x%02X\r\n", VidProcessingDesc->bSourceID);
    AppendTextBuffer("wMaxMultiplier:                  0x%04X\r\n", VidProcessingDesc->wMaxMultiplier);
    AppendTextBuffer("bControlSize:                      0x%02X\r\n", VidProcessingDesc->bControlSize);

    pData = &VidProcessingDesc->bControlSize;

    // Are there any controls?
    if (0 < * pData)
    {
        UINT  uBitIndex  = 0;
        BYTE  cCheckBit = 0;
        BYTE  cMask = 1; 

        AppendTextBuffer("bmControls : ");
        VDisplayBytes(pData + 1, *pData);
        
        // map the first control    
        for ( ; uBitIndex < 8; uBitIndex++ )
        {
            cCheckBit = cMask & *(pData + 1);

            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                uBitIndex,
                cCheckBit ? 1 : 0,
                cCheckBit ? "yes - " : " no - ",
                GetStringFromList(slProcessorControls1, 
                    sizeof(slProcessorControls1) / sizeof(STRINGLIST),
                    cMask, 
                    "Invalid PU bmControl value"));

            cMask = cMask << 1;
        }
        
        // Is there a second control?
        if (1 < * pData)
        {
            // map the second control   
            for ( uBitIndex = 8, cMask = 1; uBitIndex < 16; uBitIndex++ )
            {
                cCheckBit = cMask & *(pData + 2);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slProcessorControls2, 
                        sizeof(slProcessorControls2) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid PU bmControl value"));

                cMask = cMask << 1;
            }
        }
        
        // Is there a third control?
        if (2 < * pData)
        {
            // map the third control 
            for ( uBitIndex = 16, cMask = 1; uBitIndex < 24; uBitIndex++ )
            {
                cCheckBit = cMask & *(pData + 3);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex,
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    GetStringFromList(slProcessorControls3, 
                        sizeof(slProcessorControls3) / sizeof(STRINGLIST),
                        cMask, 
                        "Invalid PU bmControl value"));

                cMask = cMask << 1;
            }
        }
    }

    // get address of iProcessing
    if (UVC10 != g_chUVCversion)
    {
        // size of descriptor is struct size plus control size plus 2 if UVC11
        bLength = sizeof(VIDEO_PROCESSING_UNIT) + 2 + VidProcessingDesc->bControlSize;
        pData = (PUCHAR) VidProcessingDesc + (VidProcessingDesc->bLength - 2);
    }
    else // UVC 1.0
    {
        // size of descriptor is struct size plus control size plus 1 if UVC10
        bLength = sizeof(VIDEO_PROCESSING_UNIT) + 1 + VidProcessingDesc->bControlSize;
        pData = (PUCHAR) VidProcessingDesc + (VidProcessingDesc->bLength - 1);
    }
    AppendTextBuffer("iProcessing :                      0x%02X\r\n", *pData);
    if (gDoAnnotation)
    {
        if (*pData)
        {
            // if executing this code, the configuration descriptor has been 
            // obtained.  If a device is suspended, then its configuration
            // descriptor was not obtained and we do not want errors to be 
            // displayed when string descriptors were not obtained.
            DisplayStringDescriptor(*pData, StringDescs, LatestDevicePowerState);
        }
    }

    // check for new UVC 1.1 bmVideoStandards fields
    if (UVC10 != g_chUVCversion)
    {
        UINT  uBitIndex  = 0;
        BYTE  cCheckBit = 0;
        BYTE  cMask = 1; 

        pData = (PUCHAR) VidProcessingDesc + (VidProcessingDesc->bLength - 1);

        AppendTextBuffer("bmVideoStandards :                 ");
        VDisplayBytes(pData, 1);

        // map the first control    
        for ( ; uBitIndex < 8; uBitIndex++ )
        {
            cCheckBit = cMask & *(pData);

            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                uBitIndex,
                cCheckBit ? 1 : 0,
                cCheckBit ? "yes - " : " no - ",
                GetStringFromList(slProcessorVideoStandards, 
                    sizeof(slProcessorVideoStandards) / sizeof(STRINGLIST),
                    cMask, 
                    "Invalid PU bmVideoStandards value"));

            cMask = cMask << 1;
        }
    }

    if (VidProcessingDesc->bLength != bLength)
    {
        //@@TestCase B9.1 (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        AppendTextBuffer("*!*ERROR:  bLength of 0x%02X incorrect, should be 0x%02X\r\n",
            VidProcessingDesc->bLength, bLength);
        OOPS();
    }

    if (VidProcessingDesc->bUnitID < 1)
    {
        //@@TestCase B9.2 (Descript.c   Line 466)
        //@@ERROR
        //@@Descriptor Field - bUnitID
        //@@bUnitID must be greater than 0
        //@@Question: Should we test to verify unit number is unique?
        AppendTextBuffer("*!*ERROR:  bUnitID must be non-zero\r\n");
        OOPS();
    }

    if (VidProcessingDesc->bSourceID < 1)
    {
        //@@TestCase B9.3 (Descript.c   Line 471)
        //@@ERROR
        //@@Descriptor Field - bSourceID
        //@@bSourceID must be non-zero
        //@@Question: Should we test to verify the bSourceID is valid?
        AppendTextBuffer("*!*ERROR:  bSourceID must be non-zero\r\n");
        OOPS();
    }

    //@@TestCase B9.4
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - wMaxMultiplier
    //@@We should test to verify multiplier is valid
    //    AppendTextBuffer("wMaxMultiplier:                  0x%04X\r\n", VidProcessingDesc->wMaxMultiplier);

    return TRUE;
}


//*****************************************************************************
//
// DisplayVCExtensionUnit()
//
//*****************************************************************************

BOOL
DisplayVCExtensionUnit (
    PVIDEO_EXTENSION_UNIT   VidExtensionDesc,
    PSTRING_DESCRIPTOR_NODE StringDescs,
    DEVICE_POWER_STATE      LatestDevicePowerState
    )
{
    //@@DisplayVCExtensionUnit -Video Control Extension Unit
    int     i = 0;
    UCHAR   p = 0;
    UCHAR   bControlSize = 0;
    PUCHAR  pData = NULL;
    OLECHAR szGUID[256];
    size_t  bLength = 0;

    bLength = SizeOfVideoExtensionUnit(VidExtensionDesc);

    memset((LPOLESTR) szGUID, 0, sizeof(OLECHAR) * 256);
    i = StringFromGUID2((REFGUID) &VidExtensionDesc->guidExtensionCode, (LPOLESTR) szGUID, 255);
    i++;

    AppendTextBuffer("\r\n          ===>Video Control Extension Unit Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VidExtensionDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidExtensionDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidExtensionDesc->bDescriptorSubtype);
    AppendTextBuffer("bUnitID:                           0x%02X\r\n", VidExtensionDesc->bUnitID);
    AppendTextBuffer("guidExtensionCode:                 %S\r\n", szGUID);
    AppendTextBuffer("bNumControls:                      0x%02X\r\n", VidExtensionDesc->bNumControls);
    AppendTextBuffer("bNrInPins:                         0x%02X\r\n", VidExtensionDesc->bNrInPins);
    if (gDoAnnotation) 
    { 
        AppendTextBuffer("===>List of Connected Units and Terminal ID's\r\n");
    }
    // baSourceID is a variable length field
    // Size is in bNrInPins, must be at least 1 (so index starts at 1)
    for (i = 1, pData = (PUCHAR) &VidExtensionDesc->baSourceID; 
        i <= VidExtensionDesc->bNrInPins; i++, pData++)
    {
        AppendTextBuffer("baSourceID[%d]:                     0x%02X\r\n", 
            i, *pData);
    }
    // point to bControlSize (address of bNrInPins plus number of fields in bNrInPins
    //   plus 1 for next field)
    pData = &VidExtensionDesc->bNrInPins + VidExtensionDesc->bNrInPins +1;
    bControlSize = *pData;
    AppendTextBuffer("bControlSize:                      0x%02X\r\n", bControlSize);

    // Are there any controls?
    if ( bControlSize > 0)
    {
        AppendTextBuffer("bmControls : ");
        VDisplayBytes(pData + 1, *pData);

        // Map one byte at a time of the bmControls field in the Video Control Extension Unit Descriptor
        for (i = 1; i <= bControlSize; i++)
        {
            UINT  uBitIndex  = 0;
            BYTE  cCheckBit = 0;
            BYTE  cMask = 1; 
            
            // map byte    
            for ( ; uBitIndex < 8; uBitIndex++ )
                {
                cCheckBit = cMask & *(pData + i);

                AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                    uBitIndex + 8 * (i-1),
                    cCheckBit ? 1 : 0,
                    cCheckBit ? "yes - " : " no - ",
                    "Vendor-Specific (Optional)");

                cMask = cMask << 1;
                }        
        }
    }

    // get address of iExtension
    pData = &VidExtensionDesc->bNrInPins + VidExtensionDesc->bNrInPins + bControlSize + 2;
//  pData = (PUCHAR) VidExtensionDesc + (VidExtensionDesc->bLength - 1);
    AppendTextBuffer("iExtension:                        0x%02X\r\n", *pData);
    if (gDoAnnotation)
    {
        if (*pData)
        {
            DisplayStringDescriptor(*pData,StringDescs, LatestDevicePowerState);
        }
    }

    // size of descriptor struct size (23) + bNrInPins + bControlSize + iExtension size
    // 
//  p = (sizeof(VIDEO_EXTENSION_UNIT) 
//      + VidExtensionDesc->bNrInPins + bControlSize + 1);
    if (VidExtensionDesc->bLength != bLength)
    {
        //@@TestCase B10.1 (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the 
        //@@  required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of 0x%02X incorrect, should be 0x%02X\r\n",
            VidExtensionDesc->bLength, p);
        OOPS();
    }

    if (VidExtensionDesc->bUnitID < 1)
    {
        //@@TestCase B10.2 (Descript.c  Line 517)
        //@@ERROR
        //@@Descriptor Field - bUnitID
        //@@bUnitID must be non-zero
        //@@Question: Should we test to verify bUnitID is valid
        AppendTextBuffer("*!*ERROR:  bUnitID must be non-zero\r\n");
        OOPS();
    }

    //bugbug do we need two
    if (VidExtensionDesc->bNrInPins < 1)
    {
        //@@TestCase B10.3 (Descript.c  Line 522)
        //@@ERROR
        //@@Descriptor Field - bNrInPins
        //@@bNrInPins must be non-zero
        //@@Question: Should we test to verify bNrInPins is valid
        AppendTextBuffer("*!*ERROR:  bNrInPins must be non-zero\r\n");
        OOPS();
    }

    for (i = 1, pData = (PUCHAR) &VidExtensionDesc->baSourceID; 
        i <= VidExtensionDesc->bNrInPins; i++, pData++)
    {
        if (*pData == 0)
        {
            //@@TestCase B10.4  (Descript.c  Line 527)
            //@@ERROR
            //@@Descriptor Field - baSourceID[]
            //@@baSourceID[] must be non-zero
            //@@Question: Should we test to verify baSourceID is valid
            AppendTextBuffer("*!*ERROR:  baSourceID[%d] must be non-zero\r\n", *pData);
            OOPS();
        }
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayVidInHeaderl()
//
//*****************************************************************************

BOOL
DisplayVidInHeader (
                    PVIDEO_STREAMING_INPUT_HEADER VidInHeaderDesc
                    )
{
    //@@DisplayVidInHeader -Video Streaming Video Input Header
    UINT   p = 0;
    UINT   uCount = 0;
    PUCHAR pData = NULL;

    AppendTextBuffer("\r\n          ===>Video Class-Specific VS Video Input Header Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VidInHeaderDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidInHeaderDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidInHeaderDesc->bDescriptorSubtype);
    AppendTextBuffer("bNumFormats:                       0x%02X\r\n", VidInHeaderDesc->bNumFormats);
    AppendTextBuffer("wTotalLength:                    0x%04X", VidInHeaderDesc->wTotalLength);

    uCount = GetVSInterfaceSize((PUSB_COMMON_DESCRIPTOR) VidInHeaderDesc, VidInHeaderDesc->wTotalLength);
    if (uCount != VidInHeaderDesc->wTotalLength) {
        AppendTextBuffer("\r\n*!*ERROR:  invalid interface size 0x%02X, should be 0x%02X\r\n",
            VidInHeaderDesc->wTotalLength, uCount);
    } else {
        AppendTextBuffer("  -> Validated\r\n");
    }

    AppendTextBuffer("bEndpointAddress:                  0x%02X", 
        VidInHeaderDesc->bEndpointAddress);
    if (USB_ENDPOINT_DIRECTION_IN(VidInHeaderDesc->bEndpointAddress)) 
    {
        if (gDoAnnotation)
        { 
            AppendTextBuffer("  -> Direction: IN - EndpointID: %d", 
                (VidInHeaderDesc->bEndpointAddress & 0x0F));
        }
        AppendTextBuffer("\r\n");
    }
    AppendTextBuffer("bmInfo:                            0x%02X", VidInHeaderDesc->bmInfo);
    if (gDoAnnotation)
    {
        AppendTextBuffer("  -> Dynamic Format Change %sSupported",
            ! (VidInHeaderDesc->bmInfo & 0x01) ? "not " : " ");
    }
    AppendTextBuffer("\r\nbTerminalLink:                     0x%02X\r\n", 
        VidInHeaderDesc->bTerminalLink);
    AppendTextBuffer("bStillCaptureMethod:               0x%02X", 
        VidInHeaderDesc->bStillCaptureMethod);

    // globally save the StillMethod, then verify value
    StillMethod = VidInHeaderDesc->bStillCaptureMethod;
    if (StillMethod > 3)
    {
        //@@TestCase B11.1 (Descript.c Line 798)
        //@@ERROR
        //@@Descriptor Field - bStillCaptureMethod
        //@@bStillCaptureMethod is greater than 3
        AppendTextBuffer("*!*ERROR:  invalid bStillCaptureMethod 0x%02X\r\n",
            VidInHeaderDesc->bStillCaptureMethod);
        if (gDoAnnotation)
        {
            AppendTextBuffer("  -> Invalid Still Capture Method");
        } 
    }
    else
    {
        if (0 == StillMethod)
        {   
            AppendTextBuffer("  -> No Still Capture");
        }
        else
        {
        AppendTextBuffer("  -> Still Capture Method %d", 
            VidInHeaderDesc->bStillCaptureMethod);
        }
    }

    AppendTextBuffer("\r\nbTriggerSupport:                   0x%02X", 
        VidInHeaderDesc->bTriggerSupport);
    if(gDoAnnotation)
    {
        AppendTextBuffer("  -> ");
        if (! VidInHeaderDesc->bTriggerSupport) 
            AppendTextBuffer("No ");
        AppendTextBuffer("Hardware Triggering Support");
    }
    AppendTextBuffer("\r\n");

    AppendTextBuffer("bTriggerUsage:                     0x%02X", 
        VidInHeaderDesc->bTriggerUsage);
    if (gDoAnnotation) 
    {
        if (VidInHeaderDesc->bTriggerSupport != 0)
            {
            if (VidInHeaderDesc->bTriggerUsage == 0)
                AppendTextBuffer("  -> Host will initiate still image capture");
            if (VidInHeaderDesc->bTriggerUsage == 1)
                AppendTextBuffer("  -> Host will notify client application of button event");
        }
    }

    AppendTextBuffer("\r\nbControlSize:                      0x%02X\r\n", 
        VidInHeaderDesc->bControlSize);

    // are there formats to display?
    if (VidInHeaderDesc->bNumFormats)
    {
        UINT   uFormatIndex  = 1;
        UINT   uBitIndex  = 0;
        BYTE   cCheckBit = 0;
        BYTE   cMask = 1; 

        // There are (bNumFormats) bmaControls fields, each with size (bControlSize)
        pData = (PUCHAR) &(VidInHeaderDesc->bControlSize);

        // VidInHeaderDesc->bNumFormats  -> number of formats
        // VidInHeaderDesc->bControlSize -> size of EACH format control
        // ((PUCHAR) &VidInHeaderDesc->bControlSize) + 1 -> address of first format control
        for ( pData++ ; uFormatIndex <= VidInHeaderDesc->bNumFormats; uFormatIndex++ )
            {
            AppendTextBuffer("Video Payload Format %d             ", uFormatIndex);

            // Handle case of 0 control size
            if (! VidInHeaderDesc->bControlSize)
                {
                AppendTextBuffer("0x00\r\n");
                }
            else
                {
                VDisplayBytes(pData, VidInHeaderDesc->bControlSize);
        
                // map the first control    
                for (uBitIndex  = 0, cMask = 1; uBitIndex < 8; uBitIndex++ )
                    {
                    cCheckBit = cMask & *(pData);

                    AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                        uBitIndex,
                        cCheckBit ? 1 : 0,
                        cCheckBit ? "yes - " : " no - ",
                        GetStringFromList(slInputHeaderControls, 
                            sizeof(slInputHeaderControls) / sizeof(STRINGLIST),
                            cMask, 
                            "Invalid Control value"));

                    cMask = cMask << 1;
                    }
                }
            pData += VidInHeaderDesc->bControlSize;
            }
    }
    
    p = (sizeof(VIDEO_STREAMING_INPUT_HEADER) + 
        (VidInHeaderDesc->bNumFormats * VidInHeaderDesc->bControlSize));
    if (VidInHeaderDesc->bLength != p) 
    {
        //@@TestCase B11.2  (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The descriptor should be the size of the descriptor structure 
        //@@  plus the number of formats times the size of each format 
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            VidInHeaderDesc->bLength, p);
        OOPS();
    }

    if (VidInHeaderDesc->bNumFormats < 1)
    {
        //@@TestCase B11.3 (Descript.c  Line778)
        //@@ERROR
        //@@Descriptor Field - bNumFormats
        //@@bNumFormats must be non-zero
        //@@Question: Should we test to verify the non-zero value for bNumFormats is valid
        AppendTextBuffer("*!*ERROR:  bNumFormats must be non-zero\r\n",
            VidInHeaderDesc->bNumFormats);
        OOPS();
    }

    if (VidInHeaderDesc->bEndpointAddress < 1)
    {
        //@@TestCase B11.4  (Descript.c  Line788)
        //@@ERROR
        //@@Descriptor Field - bEndpointAddress
        //@@bEndpointAddress should be greater than 0
        //@@Question: Should we test to verify the non-zero value for bEndpointAddress is valid
        AppendTextBuffer("*!*ERROR:  bEndpointAddress of %d is too small\r\n",
            VidInHeaderDesc->bEndpointAddress);
        OOPS();
    }

    //@@TestCase B11.5
    //@@ERROR
    //@@Descriptor Field - bEndPointAddress
    //@@The bEndPointAddress is set incorrectly according to the USB Video Device Specification
    if (!USB_ENDPOINT_DIRECTION_IN(VidInHeaderDesc->bEndpointAddress)){
        AppendTextBuffer("\r\n*!*ERROR:  bEndPointAddress needs to have the Direction IN for this header\r\n");
        OOPS();}

    //@@TestCase B11.6
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bmInfo
    //@@We should validate that reserved bits are set to zero.
    //    AppendTextBuffer("bmInfo:                            0x%02X", VidInHeaderDesc->bmInfo);

    if (VidInHeaderDesc->bTerminalLink < 1)
    {
        //@@TestCase B11.7 (Descript.c  Line 793)
        //@@ERROR
        //@@Descriptor Field - bTerminalLink
        //@@bTerminalLink should be greater than 0
        //@@Question: Should we test to verify the non-zero value for bTerminalLink is valid
        AppendTextBuffer("*!*ERROR:  bTerminalLink of %d is too small\r\n",
            VidInHeaderDesc->bTerminalLink);
        OOPS();
    }

    //@@TestCase B11.8
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bTriggerSupport
    //@@We should validate that reserved bits are set to zero.
    //    AppendTextBuffer("bTriggerSupport:                   0x%02X", VidInHeaderDesc->bTriggerSupport);

    //@@TestCase B11.9
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bTriggerUsage
    //@@We should validate that reserved bits are set to zero.
    //    AppendTextBuffer("bTriggerUsage:                     0x%02X", VidInHeaderDesc->bTriggerUsage);

    return TRUE;
}


//*****************************************************************************
//
// DisplayVidOutHeader()
//
//*****************************************************************************

BOOL
DisplayVidOutHeader (
                     PVIDEO_STREAMING_OUTPUT_HEADER VidOutHeaderDesc
                     )
{
    //@@DisplayVidOutHeader -Video Streaming Video Output Header
    UINT  uCount = 0;
    UCHAR bLength = sizeof(VIDEO_STREAMING_OUTPUT_HEADER);

    AppendTextBuffer("\r\n          ===>Video Class-Specific VS Video Output Header Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VidOutHeaderDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidOutHeaderDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidOutHeaderDesc->bDescriptorSubtype);
    AppendTextBuffer("bNumFormats:                       0x%02X\r\n", VidOutHeaderDesc->bNumFormats);
    AppendTextBuffer("wTotalLength:                    0x%04X", VidOutHeaderDesc->wTotalLength);

    uCount = GetVSInterfaceSize((PUSB_COMMON_DESCRIPTOR) VidOutHeaderDesc, VidOutHeaderDesc->wTotalLength);
    if (uCount != VidOutHeaderDesc->wTotalLength) {
        AppendTextBuffer("\r\n*!*ERROR:  invalid interface size 0x%02X, should be 0x%02X\r\n",
            VidOutHeaderDesc->wTotalLength, uCount);
    } else {
        AppendTextBuffer("  -> Validated\r\n");
    }

    AppendTextBuffer("bEndpointAddress:                  0x%02X", VidOutHeaderDesc->bEndpointAddress);
    if(USB_ENDPOINT_DIRECTION_OUT(VidOutHeaderDesc->bEndpointAddress)) {
        if (gDoAnnotation)
        {
            AppendTextBuffer("  -> Direction: OUT - EndpointID: %d",
                (VidOutHeaderDesc->bEndpointAddress & 0x0F));
        }
        AppendTextBuffer("\r\n");
        }
    AppendTextBuffer("bTerminalLink:                     0x%02X\r\n", VidOutHeaderDesc->bTerminalLink);

    // UVC11 Video Output Header has additional fields, larger size
#ifdef H264_SUPPORT
    if (UVC10 != g_chUVCversion)
#else
    if (UVC11 == g_chUVCversion)
#endif
    {
        UCHAR   bControlSize = 0;
        PUCHAR  pControls = NULL;

        // bControlSize field is next after bTerminalLink
        pControls = &(VidOutHeaderDesc->bTerminalLink)+1;
        bControlSize = *(pControls);
        // point to first bmaControls
        pControls++;

        // Size of UVC 1.1 Video Output Header is 1.0 size 
        //  plus 1 (bControlSize field) plus (number of formats * bControlSize)
        bLength += 1 + (VidOutHeaderDesc->bNumFormats * bControlSize);

        // Need new uvcdesc.h to handle new fields
        AppendTextBuffer("bControlSize:                      0x%02X\r\n", bControlSize);

        // are there formats to display?
        if (VidOutHeaderDesc->bNumFormats)
        {
            UINT   uFormatIndex  = 1;
            UINT   uBitIndex  = 0;
            BYTE   cCheckBit = 0;
            BYTE   cMask = 1; 

            // There are (bNumFormats) bmaControls fields, each with size (bControlSize)
            for ( ; uFormatIndex <= VidOutHeaderDesc->bNumFormats; uFormatIndex++, pControls ++)
            {
                AppendTextBuffer("Video Payload Format %d             ", uFormatIndex);

                // Handle case of 0 control size
                if (0 == bControlSize)
                {
                    AppendTextBuffer("0x00\r\n");
                }
                else
                {
                    VDisplayBytes(pControls, bControlSize);
            
                    // map the first control    
                    for (uBitIndex  = 0, cMask = 1; uBitIndex < 8; uBitIndex++ )
                    {
                        cCheckBit = cMask & *(pControls);

                        AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                            uBitIndex,
                            cCheckBit ? 1 : 0,
                            cCheckBit ? "yes - " : " no - ",
                            GetStringFromList(slOutputHeaderControls, 
                                sizeof(slOutputHeaderControls) / sizeof(STRINGLIST),
                                cMask, 
                                "Invalid control value"));

                        cMask = cMask << 1;
                    }
                }
            } // for ( pData++ ; uFormatIndex <= VidOutHeaderDesc->bNumFormats; uFormatIndex++ )
        } // if (VidOutHeaderDesc->bNumFormats)
    } // if (UVC11 == g_chUVCversion)

    if (VidOutHeaderDesc->bLength != bLength)
    {
        //@@TestCase B12.1  (also in Descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the 
        //@@  required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            VidOutHeaderDesc->bLength,
            sizeof(VIDEO_STREAMING_OUTPUT_HEADER));
        OOPS();
    }

    if (VidOutHeaderDesc->bNumFormats < 1)
    {
        //@@TestCase B12.2 (Descript.c  Line 827)
        //@@ERROR
        //@@Descriptor Field - bNumFormats
        //@@bNumFormats should be greater than 0
        //@@Question: Should we test to verify the non-zero value for bNumFormats is valid
        AppendTextBuffer("*!*ERROR:  bNumFormats of %d is too small\r\n",
            VidOutHeaderDesc->bNumFormats);
        OOPS();
    }

    if (VidOutHeaderDesc->wTotalLength < VidOutHeaderDesc->bLength)
    {
        //@@TestCase B12.3 (Descript.c  Line 832)
        //@@ERROR
        //@@Descriptor Field - wTotalLength
        //@@wTotalLength should be greater than bLength
        //@@Question: Should we calculate wTotalLength to verify the value is valid
        AppendTextBuffer("*!*ERROR:  wTotalLength of %d is small than the bLength of %d\r\n",
            VidOutHeaderDesc->wTotalLength,
            VidOutHeaderDesc->bLength);
        OOPS();
    }

    if (VidOutHeaderDesc->bEndpointAddress < 1)
    {
        //@@TestCase B12.4  (Descript.c  Line 837)
        //@@ERROR
        //@@Descriptor Field - bEndpointAddress
        //@@bEndpointAddress should be greater than 0
        //@@Question: Should we test to verify the non-zero value for bEndpointAddress is valid
        AppendTextBuffer("*!*ERROR:  bEndpointAddress of %d is too small\r\n",
            VidOutHeaderDesc->bEndpointAddress);
        OOPS();
    }

    if(!(USB_ENDPOINT_DIRECTION_OUT(VidOutHeaderDesc->bEndpointAddress))) {
        //@@TestCase B12.5
        //@@ERROR
        //@@Descriptor Field - bEndPointAddress
        //@@The bEndPointAddress is set for the wrong direction
        AppendTextBuffer("\r\n*!*ERROR:  bEndPointAddress needs to have the Direction OUT for this header\r\n");
        OOPS();}

    if (VidOutHeaderDesc->bTerminalLink < 1)
    {
        //@@TestCase B12.6 (Descript.c  Line 842)
        //@@ERROR
        //@@Descriptor Field - bTerminalLink
        //@@bTerminalLink should be greater than 0
        //@@Question: Should we test to verify the non-zero value for bTerminalLink is valid
        AppendTextBuffer("*!*ERROR:  bTerminalLink of %d is too small\r\n",
            VidOutHeaderDesc->bTerminalLink);
        OOPS();
    }

    return TRUE;

}


//*****************************************************************************
//
// DisplayStillImageFrame()
//
//*****************************************************************************

BOOL
DisplayStillImageFrame (
                        PVIDEO_STILL_IMAGE_FRAME StillFrameDesc
                        )
{
    //@@DisplayStillImageFrame -Still Image Frame
    VIDEO_STILL_IMAGE_RECT  * pXY;
    PUCHAR      pbCurr = NULL;
    UINT        i = 0;
    UINT        uNumComp = 0;
    UINT        uSize = 0;
    size_t      bLength = 0;

    bLength = SizeOfVideoStillImageFrame(StillFrameDesc);

    AppendTextBuffer("\r\n          ===>Still Image Frame Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", StillFrameDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", StillFrameDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", StillFrameDesc->bDescriptorSubtype);
    AppendTextBuffer("bEndpointAddress:                  0x%02X\r\n", StillFrameDesc->bEndpointAddress);
    AppendTextBuffer("bNumImageSizePatterns:             0x%02X\r\n", 
        StillFrameDesc->bNumImageSizePatterns);
    if (StillFrameDesc->bNumImageSizePatterns < 1)
    {
        //@@TestCase B13.1 (also Descript.c Line 886)
        //@@Not yet implemented - Priority 1
        //@@Descriptor Field - bNumImageSizePatterns
        //@@The bNumImageSizePatterns should be greater than 0
        //@@Question: Should we test to verify the non-zero value for bNumImageSizePatterns is valid
        AppendTextBuffer("*!*ERROR:  bNumImageSizePatterns must be non-zero\r\n");
        OOPS();
    }

    // point to first StillFrameDesc->dwStillImage structure
    pXY = (VIDEO_STILL_IMAGE_RECT *) &StillFrameDesc->aStillRect[0];

    for (i = 1; i <= StillFrameDesc->bNumImageSizePatterns; i++, pXY++) 
    {
        AppendTextBuffer("wWidth[%d]:                       0x%04X\r\n",
            i, pXY->wWidth);
        AppendTextBuffer("wHeight[%d]:                      0x%04X\r\n",
            i, pXY->wHeight);
    }
    // point to bNumCompressionPattern field (after variable count field dwStillImage)
    pbCurr = (PUCHAR) pXY;
    // get number of compression patterns
    uNumComp = *pbCurr;

    AppendTextBuffer("bNumCompressionPattern:            0x%02X\r\n", *pbCurr++);
    for (i = 1; i <= uNumComp; i++) 
    {
        AppendTextBuffer("bCompression[%d]:                   0x%02X\r\n", 
            i, *pbCurr++); 
    }

    switch(StillMethod) {
        case 0:
            //@@TestCase B13.2
            //@@ERROR
            //@@Descriptor Field - Still Image Frame Type Descriptor
            //@@An still method type has been defined that shouldn't use a Still Image Frame
            AppendTextBuffer("*!*ERROR:  VS Video Input Header set to "\
                "No Still Method support\r\n");
            OOPS();
        case 1:
            //@@TestCase B13.3
            //@@ERROR
            //@@Descriptor Field - Still Image Frame Type Descriptor
            //@@An still method type has been defined that shouldn't use a Still Image Frame
            AppendTextBuffer("*!*ERROR:  VS Video Input Header set to "\
                "Still Method One support with a Still Image Frame descriptor\r\n");
            OOPS();
        default:
            break;}

    if (StillFrameDesc->bLength != bLength)
    {
        //@@TestCase B13.4 (Also in descript.c)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is incorrect
        AppendTextBuffer("*!*ERROR:  bLength 0x%02X incorrect, should be 0x%02X\r\n",
            StillFrameDesc->bLength, uSize);
        OOPS();
    }

    //@@TestCase B13.5
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bEndpointAddress
    //@@Should test to verify endpoint validity
    //    AppendTextBuffer("bEndpointAddress:                  0x%02X", StillFrameDesc->bEndpointAddress);

    if(USB_ENDPOINT_DIRECTION_IN(StillFrameDesc->bEndpointAddress) && StillMethod==3){
        if((StillFrameDesc->bEndpointAddress) == 0){
            //@@TestCase B13.6
            //@@ERROR
            //@@Descriptor Field - bEndPointAddress
            //@@bEndPointAddress should be non-zero for 0 when using StillMethod 3
            AppendTextBuffer("\r\n*!*ERROR:  bEndpointAddress is reported as %d.  "\
                "This should be non-zero when using StillMethod 3.\r\n",
                (StillFrameDesc->bEndpointAddress));
            OOPS(); }
        if (gDoAnnotation) 
        {
            AppendTextBuffer("  -> Direction: IN - EndpointID: %d", 
                (StillFrameDesc->bEndpointAddress & 0x0F));
        }
        AppendTextBuffer("\r\n");
        }
    else if(USB_ENDPOINT_DIRECTION_OUT(StillFrameDesc->bEndpointAddress) && StillMethod==2) {
        if((StillFrameDesc->bEndpointAddress & 0x0F) != 0) {
            //@@TestCase B13.7
            //@@ERROR
            //@@Descriptor Field - bEndPointAddress
            //@@The EndpointID of bEndPointAddress should be set for 0 when using StillMethod 2
            AppendTextBuffer("\r\n*!*ERROR:  The EndpointID of the "\
                "bEndpointAddress is reported as %d.  This should be 0.\r\n",
                (StillFrameDesc->bEndpointAddress & 0x0F));
            OOPS(); }
        else {AppendTextBuffer("\r\n");}}
    else if (StillFrameDesc->bEndpointAddress != 0) {
        //@@TestCase B13.8
        //@@ERROR
        //@@Descriptor Field - bEndPointAddress
        //@@The bEndPointAddress should be set for 0 when not using StillMethod 2 or 3
        AppendTextBuffer("\r\n*!*ERROR:  bEndPointAddress should be 0.\r\n");
        OOPS(); }
    else {AppendTextBuffer("\r\n");}

    return TRUE;
}


//*****************************************************************************
//
// DisplayColorMatching()
//
//*****************************************************************************

BOOL
DisplayColorMatching (
                      PVIDEO_COLORFORMAT ColorMatchDesc
                      )
{
    //@@DisplayColorMatching -Color Matching

    AppendTextBuffer("\r\n          ===>Color Matching Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", ColorMatchDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", ColorMatchDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", ColorMatchDesc->bDescriptorSubtype);
    AppendTextBuffer("bColorPrimaries:                   0x%02X\r\n", ColorMatchDesc->bColorPrimaries);
    AppendTextBuffer("bTransferCharacteristics:          0x%02X\r\n", ColorMatchDesc->bTransferCharacteristics);
    AppendTextBuffer("bMatrixCoefficients:               0x%02X\r\n", ColorMatchDesc->bMatrixCoefficients);

    if (ColorMatchDesc->bLength != sizeof(VIDEO_COLORFORMAT))
    {
        //@@TestCase B14.1 (Descript.c Line 1596)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            ColorMatchDesc->bLength,
            sizeof(VIDEO_COLORFORMAT));
        OOPS();
    }

    //@@TestCase B14.2
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bColorPrimaries
    //@@Question - Should we test to verify bColorPrimaries
    //    AppendTextBuffer("bColorPrimaries:                   0x%02X\r\n", ColorMatchDesc->bColorPrimaries);

    //@@TestCase B14.3
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bTransferCharacteristics
    //@@Question - Should we test to verify bTransferCharacteristics
    //    AppendTextBuffer("bTransferCharacteristics:          0x%02X\r\n", ColorMatchDesc->bTransferCharacteristics);

    //@@TestCase B14.4
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bMatrixCoefficients
    //@@Question - Should we test to verify bMatrixCoefficients
    //    AppendTextBuffer("bMatrixCoefficients:               0x%02X\r\n", ColorMatchDesc->bMatrixCoefficients);

    return TRUE;
}


//*****************************************************************************
//
// DisplayUncompressedFormat() 
//
//*****************************************************************************

BOOL
DisplayUncompressedFormat (
                           PVIDEO_FORMAT_UNCOMPRESSED UnCompFormatDesc
                           )
{
    //@@DisplayUncompressedFormat - Uncompressed Format
    int i = 0;
    PCHAR pStr = NULL;
    OLECHAR szGUID[256];

    // Initialize the default Frame
    g_chUNCFrameDefault = UnCompFormatDesc->bDefaultFrameIndex;

    memset((LPOLESTR) szGUID, 0, sizeof(OLECHAR) * 256);
    i = StringFromGUID2((REFGUID) &UnCompFormatDesc->guidFormat, (LPOLESTR) szGUID, 255);
    i++;

    AppendTextBuffer("\r\n          ===>Video Streaming Uncompressed Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", UnCompFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", UnCompFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", UnCompFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", UnCompFormatDesc->bFormatIndex);
    AppendTextBuffer("bNumFrameDescriptors:              0x%02X\r\n", UnCompFormatDesc->bNumFrameDescriptors);
    AppendTextBuffer("guidFormat:                        %S", szGUID);

    pStr = VidFormatGUIDCodeToName((REFGUID) &UnCompFormatDesc->guidFormat);
    if ( pStr )   
    {
        if ( gDoAnnotation )
        {
            AppendTextBuffer(" = %s Format", pStr);
        }
    } 
    AppendTextBuffer("\r\n");
    AppendTextBuffer("bBitsPerPixel:                     0x%02X\r\n", UnCompFormatDesc->bBitsPerPixel);
    AppendTextBuffer("bDefaultFrameIndex:                0x%02X\r\n", UnCompFormatDesc->bDefaultFrameIndex);

    if (UnCompFormatDesc->bLength != sizeof(VIDEO_FORMAT_UNCOMPRESSED))
    {
        //@@TestCase B15.1 (descript.c line 925)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required 
        //@@length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            UnCompFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_UNCOMPRESSED));
        OOPS();
    }

    if (UnCompFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B15.2 (descript.c line 930)
        //@@ERROR
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bFormatIndex = 0, this is a 1 based index\r\n");
        OOPS();
    }

    if (UnCompFormatDesc->bNumFrameDescriptors == 0 )
    {
        //@@TestCase B15.3 (descript.c line 930)
        //@@ERROR
        //@@Descriptor Field - bNumFrameDescriptors
        //@@bNumFrameDescriptors is set to zero which is not in accordance with the 
        //@@USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bNumFrameDescriptors = 0, must have at least 1 Frame descriptor\r\n");
        OOPS();
    }

    if(!(pStr))
    {
        //@@TestCase B15.4
        //@@WARNING
        //@@Descriptor Field - guidFormat
        //@@guidFormat is set to unknown or undefined format
        AppendTextBuffer("\r\n*!*WARNING:  guidFormat is an unknown format\r\n");
        OOPS();
    }

    if (UnCompFormatDesc->bBitsPerPixel == 0 )
    {
        //@@TestCase B15.5 (descript.c line 940)
        //@@ERROR
        //@@Descriptor Field - bBitsPerPixel
        //@@bBitsPerPixel is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bBitsPerPixel = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (UnCompFormatDesc->bDefaultFrameIndex == 0 || UnCompFormatDesc->bDefaultFrameIndex > 
        UnCompFormatDesc->bNumFrameDescriptors)
    {
        //@@TestCase B15.6 (desctipt.c line 945)
        //@@ERROR
        //@@Descriptor Field - bDefaultFrameIndex
        //@@The value for bDefaultFrameIndex is not greater than 0 or less than or equal to bNumFrameDescriptors
        AppendTextBuffer("*!*ERROR:  The value %d for the bDefaultFrameIndex is out of range, this invalidates the descriptor\r\n*!*The proper range is 1 to %d)",
            UnCompFormatDesc->bDefaultFrameIndex,
            UnCompFormatDesc->bNumFrameDescriptors);
        OOPS();
    }

    AppendTextBuffer("bAspectRatioX:                     0x%02X\r\n", 
        UnCompFormatDesc->bAspectRatioX);
    AppendTextBuffer("bAspectRatioY:                     0x%02X", 
        UnCompFormatDesc->bAspectRatioY);

    if (((UnCompFormatDesc->bmInterlaceFlags & 0x01) && 
        (UnCompFormatDesc->bAspectRatioY != 0 && 
        UnCompFormatDesc->bAspectRatioX != 0)))
    {
        if(gDoAnnotation) 
        {
            AppendTextBuffer("  -> Aspect Ratio is set for a %d:%d display",
                (UnCompFormatDesc->bAspectRatioX),(UnCompFormatDesc->bAspectRatioY));   
        } 
        else 
        {
            if (UnCompFormatDesc->bAspectRatioY != 0 || UnCompFormatDesc->bAspectRatioX != 0)
            {
                //@@TestCase B15.7
                //@@ERROR
                //@@Descriptor Field - bAspectRatioX, bAspectRatioY
                //@@Verify that that bAspectRatioX and bAspectRatioY are  set to zero 
                //@@  if stream is non-interlaced
                AppendTextBuffer("\r\n*!*ERROR:  Both bAspectRatioX and bAspectRatioY "\
                    "must equal 0 if stream is non-interlaced");
                OOPS();
            }
        }
    }
    AppendTextBuffer("\r\nbmInterlaceFlags:                  0x%02X\r\n", 
        UnCompFormatDesc->bmInterlaceFlags);

    if (gDoAnnotation) 
    {
        AppendTextBuffer("     D0    = 0x%02X Interlaced stream or variable: %s\r\n", 
            (UnCompFormatDesc->bmInterlaceFlags & 1),
            (UnCompFormatDesc->bmInterlaceFlags & 1) ? "Yes" : "No");
        AppendTextBuffer("     D1    = 0x%02X Fields per frame: %s\r\n", 
            ((UnCompFormatDesc->bmInterlaceFlags >> 1) & 1),
            ((UnCompFormatDesc->bmInterlaceFlags >> 1) & 1) ? "1 field" : "2 fields");
        AppendTextBuffer("     D2    = 0x%02X Field 1 first: %s\r\n", 
            ((UnCompFormatDesc->bmInterlaceFlags >> 2) & 1),
            ((UnCompFormatDesc->bmInterlaceFlags >> 2) & 1) ? "Yes" : "No");
        //@@TestCase B15.9
        //@@Not yet implemented - Priority 1
        //@@Descriptor Field - bmInterlaceFlags
        //@@Validate that reserved bits (D3) are set to zero.
        AppendTextBuffer("     D3    = 0x%02X Reserved%s\r\n", 
            ((UnCompFormatDesc->bmInterlaceFlags >> 3) & 1),
            ((UnCompFormatDesc->bmInterlaceFlags >> 3) & 1) ? 
            "\r\n*!*ERROR: Reserved to 0" : "" );
        AppendTextBuffer("     D4..5 = 0x%02X Field patterns  ->",
            ((UnCompFormatDesc->bmInterlaceFlags >> 4) & 3));
        switch(UnCompFormatDesc->bmInterlaceFlags & 0x30)
        {
        case 0x00:
            AppendTextBuffer(" Field 1 only");
            break;
        case 0x10:
            AppendTextBuffer(" Field 2 only");
            break;
        case 0x20:
            AppendTextBuffer(" Regular Pattern of fields 1 and 2");
            break;
        case 0x30:
            AppendTextBuffer(" Random Pattern of fields 1 and 2");
            break;
        }
        AppendTextBuffer("\r\n     D6..7 = 0x%02X Display Mode  ->",
            ((UnCompFormatDesc->bmInterlaceFlags >> 6) & 3));

        switch(UnCompFormatDesc->bmInterlaceFlags & 0xC0)
        {
        case 0x00:
            AppendTextBuffer(" Bob only");
            break;
        case 0x40:
            AppendTextBuffer(" Weave only");
            break;
        case 0x80:
            AppendTextBuffer(" Bob or weave");
            break;
        case 0xC0:
            //@@TestCase B15.10
            //@@Not yet implemented - Priority 3
            //@@Descriptor Field - bmInterlaceFlags
            //@@Question - Should we validate that reserved bits are set to zero?
            AppendTextBuffer(" Reserved");
            break;
        }
    }

    //@@TestCase B15.11
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bCopyProtect
    //@@Question - Are their reserved bits and should we validate that 
    //@@  reserved bits are set to zero?
    AppendTextBuffer("\r\nbCopyProtect:                      0x%02X", 
        UnCompFormatDesc->bCopyProtect);
    if (gDoAnnotation)  
    {
        if (UnCompFormatDesc->bCopyProtect)
            AppendTextBuffer("  -> Duplication Restricted");
        else
            AppendTextBuffer("  -> Duplication Unrestricted");
    }
    AppendTextBuffer("\r\n");

    //@@TestCase B15.12
    //@@We should check to make sure that a Color Matching Descriptor is included in the device
    // Check that the correct number of Frame Descriptors and one Color Matching
    //  descriptor follow
    CheckForColorMatchingDesc ((PVIDEO_SPECIFIC) UnCompFormatDesc,
        UnCompFormatDesc->bNumFrameDescriptors, VS_FRAME_UNCOMPRESSED);

    return TRUE;
    }


//*****************************************************************************
//
// DisplayUncompressedFrameType()
//
//*****************************************************************************

BOOL
DisplayUncompressedFrameType (
                              PVIDEO_FRAME_UNCOMPRESSED UnCompFrameDesc
                              )
{
    size_t bLength = 0;
    bLength = SizeOfVideoFrameUncompressed(UnCompFrameDesc);

    //@@DisplayUncompressedFrameType -Uncompressed Frame

    AppendTextBuffer("\r\n          ===>Video Streaming Uncompressed Frame Type Descriptor<===\r\n");
    if (gDoAnnotation) 
    {
        if(UnCompFrameDesc->bFrameIndex == g_chUNCFrameDefault)
        { 
            AppendTextBuffer("          --->This is the Default (optimum) Frame index\r\n");
        }
    }
    AppendTextBuffer("bLength:                           0x%02X\r\n", UnCompFrameDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", UnCompFrameDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", UnCompFrameDesc->bDescriptorSubtype);
    AppendTextBuffer("bFrameIndex:                       0x%02X\r\n", UnCompFrameDesc->bFrameIndex);
    AppendTextBuffer("bmCapabilities:                    0x%02X\r\n", UnCompFrameDesc->bmCapabilities);
    AppendTextBuffer("wWidth:                          0x%04X = %d\r\n", UnCompFrameDesc->wWidth, UnCompFrameDesc->wWidth);
    AppendTextBuffer("wHeight:                         0x%04X = %d\r\n", UnCompFrameDesc->wHeight, UnCompFrameDesc->wHeight);
    AppendTextBuffer("dwMinBitRate:                0x%08X\r\n", UnCompFrameDesc->dwMinBitRate);
    AppendTextBuffer("dwMaxBitRate:                0x%08X\r\n", UnCompFrameDesc->dwMaxBitRate);
    AppendTextBuffer("dwMaxVideoFrameBufferSize:   0x%08X\r\n", UnCompFrameDesc->dwMaxVideoFrameBufferSize);
    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse

    AppendTextBuffer("dwDefaultFrameInterval:      0x%08X = %lf mSec (%4.2f Hz)\r\n", 
        UnCompFrameDesc->dwDefaultFrameInterval,
        ((double)UnCompFrameDesc->dwDefaultFrameInterval)/10000.0,
        (10000000.0/((double)UnCompFrameDesc->dwDefaultFrameInterval))
        );
    AppendTextBuffer("bFrameIntervalType:                0x%02X\r\n", UnCompFrameDesc->bFrameIntervalType);

    if (UnCompFrameDesc->bLength != bLength)
    {
        //@@TestCase B15.1 (descript.c line 925)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required 
        //@@length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            UnCompFrameDesc->bLength, bLength);
        OOPS();
    }

    if (UnCompFrameDesc->bFrameIndex == 0 )
    {
        //@@TestCase B16.2 (descript.c line 991)
        //@@ERROR
        //@@Descriptor Field - bFrameIndex
        //@@bFrameIndex must be nonzero 
        AppendTextBuffer("*!*ERROR:  bFrameIndex = 0, this is a 1 based index\r\n");
        OOPS();
    }

    //@@TestCase B16.3
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bmCapabilities
    //@@Question:  Should we try to verify that bmCapabilities is valid?
    //    AppendTextBuffer("bmCapabilities:                    0x%02X\r\n", UnCompFrameDesc->bmCapabilities);

    if (UnCompFrameDesc->wWidth == 0 )
    {
        //@@TestCase B16.4 (descript.c line 996)
        //@@ERROR
        //@@Descriptor Field - wWidth
        //@@wWidth must be nonzero
        AppendTextBuffer("*!*ERROR:  wWidth must be nonzero\r\n");
        OOPS();
    }

    if (UnCompFrameDesc->wHeight == 0 )
    {
        //@@TestCase B16.5 (descript.c line 1001)
        //@@ERROR
        //@@Descriptor Field - wHeight
        //@@wHeight must be nonzero
        AppendTextBuffer("*!*ERROR:  wHeight must be nonzero\r\n");
        OOPS();
    }

    if (UnCompFrameDesc->dwMinBitRate == 0 )
    {
        //@@TestCase B16.6 (descript.c line 1006)
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate
        //@@dwMinBitRate must be nonzero
        AppendTextBuffer("*!*ERROR:  dwMinBitRate must be nonzero\r\n");
        OOPS();
    }

    if (UnCompFrameDesc->dwMaxBitRate == 0 )
    {
        //@@TestCase B16.7 (descript.c line 1011)
        //@@ERROR
        //@@Descriptor Field - dwMaxBitRate
        //@@dwMaxBitRate must be nonzero
        AppendTextBuffer("*!*ERROR:  dwMaxBitRate must be nonzero\r\n");
        OOPS();
    }

    if(UnCompFrameDesc->dwMinBitRate > UnCompFrameDesc->dwMaxBitRate)
    {
        //@@TestCase B16.8
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate and dwMaxBitRate
        //@@Verify that dwMaxBitRate is greater than dwMinBitRate
        AppendTextBuffer("*!*ERROR:  dwMinBitRate should be less than dwMaxBitRate\r\n");
        OOPS();
    }
    else 
    {
        if (UnCompFrameDesc->bFrameIntervalType == 1 && 
            UnCompFrameDesc->dwMinBitRate != UnCompFrameDesc->dwMaxBitRate)
        {
            //@@TestCase B16.9
            //@@WARNING
            //@@Descriptor Field - bFrameIntervalType, dwMinBitRate, and dwMaxBitRate
            //@@Verify that dwMaxBitRate is equal to dwMinBitRate if bFrameIntervalType is 1
            AppendTextBuffer("*!*WARNING:  if bFrameIntervalType is 1 then dwMinBitRate "\
                "should equal dwMaxBitRate\r\n");
            OOPS();
        }
    }

    if (UnCompFrameDesc->dwMaxVideoFrameBufferSize == 0 )
    {
        //@@TestCase B16.10 (descript.c line 1015)
        //@@WARNING
        //@@Descriptor Field - bFrameIndex
        //@@bFrameIndex must be nonzero
        AppendTextBuffer("*!*WARNING:  dwMaxVideoFrameBufferSize must be nonzero\r\n");
        OOPS();
    }

    if (UnCompFrameDesc->dwDefaultFrameInterval == 0 )
    {
        //@@TestCase B16.11 (descript.c line 1020)
        //@@WARNING
        //@@Descriptor Field - dwDefaultFrameInterval
        //@@dwDefaultFrameInterval must be nonzero
        AppendTextBuffer("*!*WARNING:  dwDefaultFrameInterval must be nonzero\r\n");
        OOPS();
    }
    if (0 == UnCompFrameDesc->bFrameIntervalType)
    {
        DisplayUnComContinuousFrameType(UnCompFrameDesc);
    }
    else
    {
        DisplayUnComDiscreteFrameType(UnCompFrameDesc);
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayUnComContinuousFrameType()
//
//*****************************************************************************

BOOL
DisplayUnComContinuousFrameType(
                                PVIDEO_FRAME_UNCOMPRESSED UContinuousDesc
                                )
{
    //@@DisplayUnComContinuousFrameType -Uncompressed Continuous Frame
    ULONG dwMinFrameInterval  = UContinuousDesc->adwFrameInterval[0];
    ULONG dwMaxFrameInterval  = UContinuousDesc->adwFrameInterval[1];
    ULONG dwFrameIntervalStep = UContinuousDesc->adwFrameInterval[2];

    AppendTextBuffer("===>Additional Continuous Frame Type Data\r\n");
    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse


    AppendTextBuffer("dwMinFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMinFrameInterval,
        ((double)dwMinFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMinFrameInterval) + 0.5));
    
    AppendTextBuffer("dwMaxFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMaxFrameInterval,
        ((double)dwMaxFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMaxFrameInterval) + 0.5));

    AppendTextBuffer("dwFrameIntervalStep:         0x%08X\r\n", dwFrameIntervalStep);

    if (dwMinFrameInterval == 0 )
    {
        //@@TestCase B17.2 (descript.c line 1025)
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval
        //@@dwMinFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (dwMaxFrameInterval == 0 )
    {
        //@@TestCase B17.3 (descript.c line 1025)
        //@@ERROR
        //@@Descriptor Field - dwMaxFrameInterval
        //@@dwMaxFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMaxFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if(dwMinFrameInterval  > dwMaxFrameInterval)
    {
        //@@TestCase B17.4  (descript.c 1043)
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval is larger that dwMaxFrameInterval, this invalidates the descriptor\r\n");
        OOPS();
    }
    else if ((dwMinFrameInterval + dwFrameIntervalStep) > dwMaxFrameInterval)
    {
        //@@TestCase B17.5
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval combined with dwFrameIntervalStep
        AppendTextBuffer("*!*WARNING:  dwMinFrameInterval + dwFrameIntervalStep is greater than dwMaxFrameInterval, this could cause problems\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) == 0 )
    {
        //@@TestCase B17.6
        //@@CAUTION
        //@@Descriptor Field - dwFrameIntervalStep
        //@@Suggestion to use descrite frames if dwFrameIntervalStep is zero
        AppendTextBuffer("*!*CAUTION:  dwFrameIntervalStep equals zero, consider using discrete frames\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) % dwFrameIntervalStep )
    {
        //@@TestCase B17.7 (descript.c 1052)
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the difference between dwMaxFrameInterval and dwMinFrameInterval is evenly divisible by dwFrameIntervalStep
        AppendTextBuffer("*!*WARNING:  dwMaxFrameInterval minus dwMinFrameInterval  is not evenly divisible by dwFrameIntervalStep, this could cause problems\r\n");
        OOPS();
    }

    if (dwFrameIntervalStep == 0 && (dwMaxFrameInterval - dwMinFrameInterval))
    {
        //@@TestCase B17.8 (descript.c line 1032)
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the dwFrameIntervalStep is not zero if there is a difference between dwMaxFrameInterval and dwMinFrameInterval
        AppendTextBuffer("*!*WARNING:  dwFrameIntervalStep = 0, this invalidates the descriptor when there is a difference between dwMinFrameInterval and dwMaxFrameInterval\r\n");
        OOPS();
    }

    return TRUE;
}

//*****************************************************************************
//
// DisplayUnComDiscreteFrameType()
//
//*****************************************************************************

BOOL
DisplayUnComDiscreteFrameType(
                              PVIDEO_FRAME_UNCOMPRESSED UDiscreteDesc
                              )
{
    //@@DisplayUnComDiscreteFrameType -Uncompressed Discrete Frame
    UINT    iNdex = 1;
    UINT    iCurFrame = 0;
    ULONG   * ulFrameInterval = NULL;

    AppendTextBuffer("===>Additional Discrete Frame Type Data\r\n");

    // There are (UDiscreteDesc->bFrameIntervalType) dwFrameIntervals (1 based index)
    for (; iNdex <= UDiscreteDesc->bFrameIntervalType; iNdex++, iCurFrame++)
    {
        ulFrameInterval = &UDiscreteDesc->adwFrameInterval[iCurFrame];
        // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
        // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
        // = 1/10,000 milliseconds


        // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse
        AppendTextBuffer("dwFrameInterval[%d]:          0x%08X = %lf mSec (%4.2f Hz)\r\n", 
            iNdex, *ulFrameInterval,
            ((double)*ulFrameInterval)/10000.0,
            (10000000.0/((double)*ulFrameInterval))
            );
        if (0 == *ulFrameInterval)
        {
            //@@TestCase B18.1 (descript.c line 1061)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[x] must be non-zero
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[%d] must be non-zero\r\n", iNdex);
            OOPS();
        }
        if ((iNdex > 1)&&(*ulFrameInterval <= UDiscreteDesc->adwFrameInterval[iCurFrame - 1]))
        {
            //@@TestCase B18.2 (descript.c line 1067)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[n] must be greater than dwFrameInterval[n - 1]
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[0x%02X] must be "\
                "greater than preceding dwFrameInterval[0x%02X]\r\n", iNdex, iNdex - 1);
            OOPS();
        }
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayMJPEGFormat()
//
//*****************************************************************************

BOOL
DisplayMJPEGFormat (
                    PVIDEO_FORMAT_MJPEG MJPEGFormatDesc
                    )
{
    //@@DisplayMJPEGFormat - MJPEG Format
    // Initialize the default Frame
    g_chMJPEGFrameDefault = MJPEGFormatDesc->bDefaultFrameIndex;

    AppendTextBuffer("\r\n          ===>Video Streaming MJPEG Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", MJPEGFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", MJPEGFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", MJPEGFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", MJPEGFormatDesc->bFormatIndex);
    AppendTextBuffer("bNumFrameDescriptors:              0x%02X\r\n", MJPEGFormatDesc->bNumFrameDescriptors);

    if (MJPEGFormatDesc->bLength != sizeof(VIDEO_FORMAT_MJPEG))
    {
        //@@TestCase B19.1 (descript.c line 1098)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the 
        //@@  required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            MJPEGFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_MJPEG));
        OOPS();
    }

    if (MJPEGFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B19.2 (descript.c line 1103)
        //@@ERROR
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with 
        //@@  the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bFormatIndex must be non-zero\r\n");
        OOPS();
    }

    if (MJPEGFormatDesc->bNumFrameDescriptors == 0 )
    {
        //@@TestCase B19.3 (descript.c line 1108)
        //@@ERROR
        //@@Descriptor Field - bNumFrameDescriptors
        //@@bNumFrameDescriptors is set to zero which is not in accordance 
        //@@  with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bNumFrameDescriptors must be non-zero\r\n");
        OOPS();
    }

    AppendTextBuffer("bmFlags:                           0x%02X", 
        (MJPEGFormatDesc->bmFlags & 0x01));

    //@@TestCase B19.4
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bmFlags
    //@@We should validate that reserved bits are set to zero.
    if (gDoAnnotation) 
    {
        if(MJPEGFormatDesc->bmFlags & 0x01)
        { 
            AppendTextBuffer("  -> Sample Size is Fixed");
        }
        else
        { 
            AppendTextBuffer("  -> Sample Size is Not Fixed");
        }
    }
    AppendTextBuffer("\r\nbDefaultFrameIndex:                0x%02X\r\n", 
        MJPEGFormatDesc->bDefaultFrameIndex);

    if (MJPEGFormatDesc->bDefaultFrameIndex == 0 || 
        MJPEGFormatDesc->bDefaultFrameIndex > 
        MJPEGFormatDesc->bNumFrameDescriptors)
    {
        //@@TestCase B19.5  (descript.c line 1113)
        //@@ERROR
        //@@Descriptor Field - bDefaultFrameIndex
        //@@bDefaultFrameIndex is not in the domain of constrained by 
        //@@  bNumFrameDescriptors
        AppendTextBuffer("*!*ERROR:  bDefaultFrameIndex 0x%02X invalid, should "\
            "be between 1 and 0x%02x/r/n",
            MJPEGFormatDesc->bDefaultFrameIndex,
            MJPEGFormatDesc->bNumFrameDescriptors);
        OOPS();
    }

    AppendTextBuffer("bAspectRatioX:                     0x%02X\r\n", 
        MJPEGFormatDesc->bAspectRatioX);
    AppendTextBuffer("bAspectRatioY:                     0x%02X", 
        MJPEGFormatDesc->bAspectRatioY);

    if(((MJPEGFormatDesc->bmInterlaceFlags & 0x01) && 
        ((MJPEGFormatDesc->bAspectRatioY != 0) && 
        (MJPEGFormatDesc->bAspectRatioX != 0))))    
    {
        if (gDoAnnotation)
        {
            AppendTextBuffer("  -> Aspect Ratio is set for a %d:%d display", 
                (MJPEGFormatDesc->bAspectRatioX), (MJPEGFormatDesc->bAspectRatioY));
        }
    }
    else 
    {
        if (MJPEGFormatDesc->bAspectRatioY != 0 || MJPEGFormatDesc->bAspectRatioX != 0)
        {
            //@@TestCase B19.6
            //@@ERROR
            //@@Descriptor Field - bAspectRatioX and bAspectRatioY
            //@@Verify that that bAspectRatioX and bAspectRatioY are  set to zero 
            //@@  if stream is non-interlaced
            AppendTextBuffer("\r\n*!*ERROR:  bAspectRatioX and bAspectRatioY must "\
                "be 0 if stream non-Interlaced");
            OOPS();
        }
    }
    AppendTextBuffer("\r\nbmInterlaceFlags:                  0x%02X\r\n", 
        MJPEGFormatDesc->bmInterlaceFlags);

    if (gDoAnnotation)
    {
        AppendTextBuffer("     D00   = %x %sInterlaced stream or variable\r\n", 
            (MJPEGFormatDesc->bmInterlaceFlags & 1),
            (MJPEGFormatDesc->bmInterlaceFlags & 1) ? "" : " non-");
        AppendTextBuffer("     D01   = %x %s per frame\r\n", 
            ((MJPEGFormatDesc->bmInterlaceFlags >> 1) & 1),
            ((MJPEGFormatDesc->bmInterlaceFlags >> 1) & 1) ? " 1 field" : " 2 fields");
        AppendTextBuffer("     D02   = %x  Field 1 %sfirst\r\n", 
            ((MJPEGFormatDesc->bmInterlaceFlags >> 2) & 1),
            ((MJPEGFormatDesc->bmInterlaceFlags >> 2) & 1) ? "" : "not ");
        //@@TestCase B19.7
        //@@Not yet implemented - Priority 1
        //@@Descriptor Field - bmInterlaceFlags
        //@@Validate that reserved bits (D3) are set to zero.
        AppendTextBuffer("     D03   = %x  Reserved%s\r\n", 
            ((MJPEGFormatDesc->bmInterlaceFlags >> 3) & 1),
            ((MJPEGFormatDesc->bmInterlaceFlags >> 3) & 1) ? 
            "\r\n*!*ERROR: non zero" : "" );
        AppendTextBuffer("     D4..5 = %x  Field patterns  ->",
            ((MJPEGFormatDesc->bmInterlaceFlags >> 4) & 3));
        switch (MJPEGFormatDesc->bmInterlaceFlags & 0x30)
        {
        case 0x00:
            AppendTextBuffer(" Field 1 only");
            break;
        case 0x10:
            AppendTextBuffer(" Field 2 only");
            break;
        case 0x20:
            AppendTextBuffer(" Regular Pattern of fields 1 and 2");
            break;
        case 0x30:
            AppendTextBuffer(" Random Pattern of fields 1 and 2");
            break;
        }
        AppendTextBuffer("\r\n     D6..7 = %x  Display Mode  ->",
            ((MJPEGFormatDesc->bmInterlaceFlags >> 6) & 3));
        switch(MJPEGFormatDesc->bmInterlaceFlags & 0xC0)
        {
        case 0x00:
            AppendTextBuffer(" Bob only");
            break;
        case 0x40:
            AppendTextBuffer(" Weave only");
            break;
        case 0x80:
            AppendTextBuffer(" Bob or weave");
            break;
        case 0xC0:
            //@@TestCase B19.8
            //@@Not yet implemented - Priority 3
            //@@Descriptor Field - bmInterlaceFlags
            //@@Question - Should we validate that reserved bits are set to zero?
            AppendTextBuffer(" Reserved");
            break;
        }
    }

    //@@TestCase B19.9
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bCopyProtect
    //@@Question - Are their reserved bits and should we validate that 
    //@@  reserved bits are set to zero?
    AppendTextBuffer("\r\nbCopyProtect:                      0x%02X", 
        MJPEGFormatDesc->bCopyProtect);
    if (gDoAnnotation) 
    {
        if (MJPEGFormatDesc->bCopyProtect)
            AppendTextBuffer("  -> Duplication Restricted");
        else
            AppendTextBuffer("  -> Duplication Unrestricted");
    }
    AppendTextBuffer("\r\n");

    // Check that the correct number of Frame Descriptors and one Color Matching
    //  descriptor follow
    CheckForColorMatchingDesc ((PVIDEO_SPECIFIC) MJPEGFormatDesc,
        MJPEGFormatDesc->bNumFrameDescriptors, VS_FRAME_MJPEG);

    return TRUE;
}

//*****************************************************************************
//
// DisplayMJPEGFrameType()
//
//*****************************************************************************

BOOL
DisplayMJPEGFrameType (
                       PVIDEO_FRAME_MJPEG MJPEGFrameDesc
                       )
{
    //@@DisplayMJPEGFrameType -MJPEG Frame
    size_t bLength = 0;
    bLength = SizeOfVideoFrameMjpeg(MJPEGFrameDesc);

    AppendTextBuffer("\r\n          ===>Video Streaming MJPEG Frame Type Descriptor<===\r\n");
    if (gDoAnnotation) 
    {
        if(MJPEGFrameDesc->bFrameIndex == g_chMJPEGFrameDefault)
        { 
            AppendTextBuffer("          --->This is the Default (optimum) Frame index\r\n");
        }
    }
    AppendTextBuffer("bLength:                           0x%02X\r\n", MJPEGFrameDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", MJPEGFrameDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", MJPEGFrameDesc->bDescriptorSubtype);
    AppendTextBuffer("bFrameIndex:                       0x%02X\r\n", MJPEGFrameDesc->bFrameIndex);
    AppendTextBuffer("bmCapabilities:                    0x%02X\r\n", MJPEGFrameDesc->bmCapabilities);
    AppendTextBuffer("wWidth:                          0x%04X = %d\r\n", MJPEGFrameDesc->wWidth, MJPEGFrameDesc->wWidth);
    AppendTextBuffer("wHeight:                         0x%04X = %d\r\n", MJPEGFrameDesc->wHeight, MJPEGFrameDesc->wHeight);
    AppendTextBuffer("dwMinBitRate:                0x%08X\r\n", MJPEGFrameDesc->dwMinBitRate);
    AppendTextBuffer("dwMaxBitRate:                0x%08X\r\n", MJPEGFrameDesc->dwMaxBitRate);
    AppendTextBuffer("dwMaxVideoFrameBufferSize:   0x%08X\r\n", MJPEGFrameDesc->dwMaxVideoFrameBufferSize);

    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse

    AppendTextBuffer("dwDefaultFrameInterval:      0x%08X = %lf mSec (%4.2f Hz)\r\n", 
        MJPEGFrameDesc->dwDefaultFrameInterval,
        ((double)MJPEGFrameDesc->dwDefaultFrameInterval)/10000.0,
        (10000000.0/((double)MJPEGFrameDesc->dwDefaultFrameInterval))
        );
    AppendTextBuffer("bFrameIntervalType:                0x%02X\r\n", MJPEGFrameDesc->bFrameIntervalType);

    if (MJPEGFrameDesc->bLength != bLength)
    {
        //@@TestCase B20.1 (descript.c line 1154)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is less than required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d is incorrect, should be %d\r\n",
            MJPEGFrameDesc->bLength, bLength);
        OOPS();
    }

    if (MJPEGFrameDesc->bFrameIndex == 0 )
    {
        //@@TestCase B20.2  (descript.c line 1159)
        //@@WARNING
        //@@Descriptor Field - bFrameIndex
        //@@bFrameIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*WARNING:  bFrameIndex = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    //@@TestCase B20.3
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bmCapabilities
    //@@Question:  Should we try to verify that bmCapabilities is valid?
    //    AppendTextBuffer("bmCapabilities:                    0x%02X\r\n", MJPEGFrameDesc->bmCapabilities);

    if (MJPEGFrameDesc->wWidth == 0 )
    {
        //@@TestCase B20.4 (descript.c line 1164)
        //@@ERROR
        //@@Descriptor Field - wWidth
        //@@wWidth is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  wWidth = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (MJPEGFrameDesc->wHeight == 0 )
    {
        //@@TestCase B20.5 (descript.c line 1169)
        //@@ERROR
        //@@Descriptor Field - wHeight
        //@@wHeight is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  wHeight = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (MJPEGFrameDesc->dwMinBitRate == 0 )
    {
        //@@TestCase B20.6 (descript.c line 1174)
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate
        //@@dwMinBitRate is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMinBitRate = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (MJPEGFrameDesc->dwMaxBitRate == 0 )
    {
        //@@TestCase B20.7 (descript.c line 1179)
        //@@ERROR
        //@@Descriptor Field - dwMaxBitRate
        //@@dwMaxBitRate is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMaxBitRate = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if(MJPEGFrameDesc->dwMinBitRate > MJPEGFrameDesc->dwMaxBitRate)
    {
        //@@TestCase B20.8
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate and dwMaxBitRate
        //@@Verify that dwMaxBitRate is greater than dwMinBitRate
        AppendTextBuffer("*!*ERROR:  dwMinBitRate > dwMaxBitRate, this invalidates the descriptor\r\n");
        OOPS();
    }
    else if(MJPEGFrameDesc->bFrameIntervalType == 1 && MJPEGFrameDesc->dwMinBitRate != MJPEGFrameDesc->dwMaxBitRate)
    {
        //@@TestCase B20.9
        //@@WARNING
        //@@Descriptor Field - bFrameIntervalType, dwMinBitRate, and dwMaxBitRate
        //@@Verify that dwMaxBitRate is equal to dwMinBitRate if bFrameIntervalType is 1
        AppendTextBuffer("*!*WARNING:  if bFrameIntervalType is 1 then dwMinBitRate should equal dwMaxBitRate\r\n");
        OOPS();
    }

    if (MJPEGFrameDesc->dwMaxVideoFrameBufferSize == 0 )
    {
        //@@TestCase B20.10  (descript.c line 1183)
        //@@ERROR
        //@@Descriptor Field - dwMaxVideoFrameBufferSize
        //@@dwMaxVideoFrameBufferSize is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMaxVideoFrameBufferSize = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (MJPEGFrameDesc->dwMaxVideoFrameBufferSize == 0 )
    {
        //@@TestCase B20.11  (descript.c line 1188)
        //@@ERROR
        //@@Descriptor Field - dwDefaultFrameInterval
        //@@dwDefaultFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwDefaultFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (0 == MJPEGFrameDesc->bFrameIntervalType)
    {
        DisplayMJPEGContinuousFrameType(MJPEGFrameDesc);
    }
    else
    {
        DisplayMJPEGDiscreteFrameType(MJPEGFrameDesc);
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayMJPEGContinuousFrameType()
//
//*****************************************************************************

BOOL
DisplayMJPEGContinuousFrameType(
                                PVIDEO_FRAME_MJPEG MContinuousDesc
                                )
{
    //@@DisplayMJPEGContinuousFrameType - MJPEG Continuous Frame
    ULONG dwMinFrameInterval  = MContinuousDesc->adwFrameInterval[0];
    ULONG dwMaxFrameInterval  = MContinuousDesc->adwFrameInterval[1];
    ULONG dwFrameIntervalStep = MContinuousDesc->adwFrameInterval[2];

    AppendTextBuffer("===>Additional Continuous Frame Type Data\r\n");
    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse


    AppendTextBuffer("dwMinFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMinFrameInterval,
        ((double)dwMinFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMinFrameInterval) + 0.5));
    
    AppendTextBuffer("dwMaxFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMaxFrameInterval,
        ((double)dwMaxFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMaxFrameInterval) + 0.5));

    AppendTextBuffer("dwFrameIntervalStep:         0x%08X\r\n", dwFrameIntervalStep);

    if (dwMinFrameInterval == 0 )
    {
        //@@TestCase B21.2   (descript.c line 1188)
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval
        //@@dwMinFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (dwMaxFrameInterval == 0 )
    {
        //@@TestCase B21.3  (descript.c line 1188)
        //@@ERROR
        //@@Descriptor Field - dwMaxFrameInterval
        //@@dwMaxFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMaxFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if(dwMinFrameInterval > dwMaxFrameInterval)
    {
        //@@TestCase B21.4  (descript.c line 1211)
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval is larger that dwMaxFrameInterval, this invalidates the descriptor\r\n");
        OOPS();
    }
    else if ((dwMinFrameInterval + dwFrameIntervalStep) > dwMaxFrameInterval)
    {
        //@@TestCase B21.5
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval combined with dwFrameIntervalStep
        AppendTextBuffer("*!*WARNING:  dwMinFrameInterval + dwFrameIntervalStep is greater than dwMaxFrameInterval, this could cause problems\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) == 0 )
    {
        //@@TestCase B21.6
        //@@CAUTION
        //@@Descriptor Field - dwFrameIntervalStep
        //@@Suggestion to use descrite frames if dwFrameIntervalStep is zero
        AppendTextBuffer("*!*CAUTION:  dwFrameIntervalStep equals zero, consider using discrete frames\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) % dwFrameIntervalStep )
    {
        //@@TestCase B21.7  (descript.c line 1220)
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the difference between dwMaxFrameInterval and dwMinFrameInterval is evenly divisible by dwFrameIntervalStep
        AppendTextBuffer("*!*WARNING:  dwMaxFrameInterval minus dwMinFrameInterval is not evenly divisible by dwFrameIntervalStep, this could cause problems\r\n");
        OOPS();
    }

    if (dwFrameIntervalStep == 0 && (dwMaxFrameInterval - dwMinFrameInterval))
    {
        //@@TestCase B21.8 (descript.c line 1200)
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the dwFrameIntervalStep is not zero if there is a difference between dwMaxFrameInterval and dwMinFrameInterval
        AppendTextBuffer("*!*WARNING:  dwFrameIntervalStep = 0, this invalidates the descriptor when there is a difference between \r\n          *!*dwMinFrameInterval and dwMaxFrameInterval\r\n");
        OOPS();
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayMJPEGDiscreteFrameType()
//
//*****************************************************************************

BOOL
DisplayMJPEGDiscreteFrameType(
                              PVIDEO_FRAME_MJPEG MDiscreteDesc
                              )
{
    //@@DisplayMJPEGDiscreteFrameType -MJPEG Discrete Frame
    UINT    iNdex = 1;
    UINT    iCurFrame = 0;
    ULONG   * ulFrameInterval = NULL;

    AppendTextBuffer("===>Additional Discrete Frame TypeData\r\n");

    // There are (MDiscreteDesc->bFrameIntervalType) dwFrameIntervals (1 based index)
    for (; iNdex <= MDiscreteDesc->bFrameIntervalType; iNdex++, iCurFrame++)
    {
        ulFrameInterval = &MDiscreteDesc->adwFrameInterval[iCurFrame];
        // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
        // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
        // = 1/10,000 milliseconds


        // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse
        AppendTextBuffer("dwFrameInterval[%d]:          0x%08X = %lf mSec (%4.2f Hz)\r\n", 
            iNdex, *ulFrameInterval,
            ((double)*ulFrameInterval)/10000.0,
            (10000000.0/((double)*ulFrameInterval))
            );
        if (0 == *ulFrameInterval)
        {
            //@@TestCase B22.1 (descript.c line 1229)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[x] must be non-zero
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[%d] must be non-zero\r\n", iNdex);
            OOPS();
        }
        if ((iNdex > 1)&&(*ulFrameInterval <= MDiscreteDesc->adwFrameInterval[iCurFrame - 1]))
        {
            //@@TestCase B22.2 (descript.c line 1235)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[n] must be greater than dwFrameInterval[n - 1]
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[0x%02X] must be "\
                "greater than preceding dwFrameInterval[0x%02X]\r\n",  iNdex, iNdex - 1);
            OOPS();
        }
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayMPEG1SSFormat()
//
//*****************************************************************************

BOOL
DisplayMPEG1SSFormat (
                      PVIDEO_FORMAT_MPEG1SS MPEG1SSFormatDesc
                      )
{
    //@@DisplayMPEG1SSFormat -MPEG1 SS Format
    AppendTextBuffer("\r\n          ===>Video Streaming MPEG1-SS Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", MPEG1SSFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", MPEG1SSFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", MPEG1SSFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", MPEG1SSFormatDesc->bFormatIndex);
    AppendTextBuffer("wPacketLength:                     0x%02X\r\n", MPEG1SSFormatDesc->bPacketLength);
    AppendTextBuffer("wPackLength:                       0x%02X\r\n", MPEG1SSFormatDesc->bPackLength);
    AppendTextBuffer("bPackdataType:                     0x%02X", (MPEG1SSFormatDesc->bPackDataType));
    if(gDoAnnotation) {
        if(MPEG1SSFormatDesc->bPackDataType & 0x01){AppendTextBuffer("  -> Pack data size fixed\r\n");}
        else    {AppendTextBuffer("  -> Pack data size variable\r\n");  }}
    else {AppendTextBuffer("\r\n");}


    if (MPEG1SSFormatDesc->bLength != sizeof(VIDEO_FORMAT_MPEG1SS))
    {
        //@@TestCase B23.1 (descript.c line 1514)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d.  USBView cannot correctly display descriptor\r\n",
            MPEG1SSFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_MPEG1SS));
        OOPS();
    }

    if (MPEG1SSFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B23.2 (descript.c line 1519)
        //@@WARNING
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*WARNING:  bFormatIndex = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    //@@TestCase B23.3
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bPackdataType
    //@@Question - Should we validate that reserved bits are set to zero?
    //    AppendTextBuffer("bPackdataType:                     0x%02X", (MPEG1SSFormatDesc->bPackdataType & 0x01));

    // This descriptor is deprecated for UVC 1.1
#ifdef H264_SUPPORT
    if (UVC10 != g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC version >= 1.1 devices\r\n");
    }
#else
    if (UVC11 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.1 devices\r\n");
    }
#endif

    return TRUE;
}


//*****************************************************************************
//
// DisplayMPEG2PSFormat()
//
//*****************************************************************************

BOOL
DisplayMPEG2PSFormat (
                      PVIDEO_FORMAT_MPEG2PS MPEG2PSFormatDesc
                      )
{
    //@@DisplayMPEG2PSFormat -MPEG2 PS Format
    AppendTextBuffer("\r\n          ===>Video Streaming MPEG2-PS Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", MPEG2PSFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", MPEG2PSFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", MPEG2PSFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", MPEG2PSFormatDesc->bFormatIndex);
    AppendTextBuffer("bPacketLength:                     0x%02X\r\n", MPEG2PSFormatDesc->bPacketLength);
    AppendTextBuffer("bPackLength:                       0x%02X\r\n", MPEG2PSFormatDesc->bPackLength);
    AppendTextBuffer("bPackDataType:                     0x%02X", (MPEG2PSFormatDesc->bPackDataType));

    if (MPEG2PSFormatDesc->bLength != sizeof(VIDEO_FORMAT_MPEG2PS))
    {
        //@@TestCase B24.1 (descript.c line 1542)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d.  USBView cannot correctly display descriptor\r\n",
            MPEG2PSFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_MPEG2PS));
        OOPS();
        AppendTextBuffer("*!*USBView will try to display the rest of the descriptor but results may not be accurate\r\n");
    }

    if (MPEG2PSFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B24.2 (descript.c line 1547)
        //@@WARNING
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*WARNING:  bFormatIndex = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    //@@TestCase B24.3
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bPackdataType
    //@@Question - Should we validate that reserved bits are set to zero?
    //    AppendTextBuffer("bPackdataType:                     0x%02X", (MPEG2PSFormatDesc->bPackdataType & 0x01));

    // This descriptor is deprecated for UVC 1.1
#ifdef H264_SUPPORT
    if (UVC10 != g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC version >= 1.1 devices\r\n");
    }
#else
    if (UVC11 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.1 devices\r\n");
    }
#endif

    return TRUE;

}


//*****************************************************************************
//
// DisplayMPEG2TSFormat()
//
//*****************************************************************************

BOOL
DisplayMPEG2TSFormat (
                      PVIDEO_FORMAT_MPEG2TS MPEG2TSFormatDesc
                      )
{
    //@@DisplayMPEG2TSFormat -MPEG2 TS Format
    UCHAR bLength = sizeof(VIDEO_FORMAT_MPEG2TS);

    AppendTextBuffer("\r\n          ===>Video Streaming MPEG2-TS Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", MPEG2TSFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", MPEG2TSFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", MPEG2TSFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", MPEG2TSFormatDesc->bFormatIndex);
    AppendTextBuffer("bDataOffset:                       0x%02X\r\n", MPEG2TSFormatDesc->bDataOffset);
    AppendTextBuffer("bPacketLength:                     0x%02X\r\n", MPEG2TSFormatDesc->bPacketLength);
    AppendTextBuffer("bStrideLength:                     0x%02X\r\n", MPEG2TSFormatDesc->bStrideLength);

#ifdef H264_SUPPORT
    if (UVC10 != g_chUVCversion)
#else
    if (UVC11 == g_chUVCversion)
#endif
    {
        int     i = 0;
        PCHAR   pStr = NULL;
        OLECHAR szGUID[256];
        GUID    * pStrideGuid = NULL;

        pStrideGuid = (GUID *) (&MPEG2TSFormatDesc->bStrideLength + 1);

        memset((LPOLESTR) szGUID, 0, sizeof(OLECHAR) * 256);
        i = StringFromGUID2((REFGUID) pStrideGuid, (LPOLESTR) szGUID, 255);
        i++;
        AppendTextBuffer("guidStrideFormat:                  %S", szGUID);
        pStr = VidFormatGUIDCodeToName((REFGUID) pStrideGuid);
        if(gDoAnnotation)   
        {
            if (pStr)
            {
                AppendTextBuffer(" = %s Format", pStr);
            }
        } 
        AppendTextBuffer("\r\n");
        bLength = sizeof(VIDEO_FORMAT_MPEG2TS) + sizeof(GUID);
    }

    if (MPEG2TSFormatDesc->bLength != bLength)
    {
        //@@TestCase B25.1 (descript.c line 1486)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            MPEG2TSFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_MPEG2TS));
        OOPS();
    }

    if (MPEG2TSFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B25.2 (descript.c line 1491)
        //@@WARNING
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*WARNING:  bFormatIndex = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    //@@TestCase B25.3
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bDataOffset, wPacket and wStride
    //@@Question - Should we check that if bDataOffset is 0 that wPacket and wStride should equal each other
    //    AppendTextBuffer("bDataOffset:                       0x%02X\r\n", MPEG2TSFormatDesc->bDataOffset);

    return TRUE;
}


//*****************************************************************************
//
// DisplayMPEG4SLFormat()
//
//*****************************************************************************

BOOL
DisplayMPEG4SLFormat (
                      PVIDEO_FORMAT_MPEG4SL MPEG4SLFormatDesc
                      )
{
    //@@DisplayMPEG4SLFormat -MPEG4 SL Format

    AppendTextBuffer("\r\n          ===>Video Streaming MPEG4-SL Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", MPEG4SLFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", MPEG4SLFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", MPEG4SLFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", MPEG4SLFormatDesc->bFormatIndex);
    AppendTextBuffer("bPacketLength:                     0x%02X\r\n", MPEG4SLFormatDesc->bPacketLength);

    if (MPEG4SLFormatDesc->bLength != sizeof(VIDEO_FORMAT_MPEG4SL))
    {
        //@@TestCase B26.1 (descript.c line 1568)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d.  USBView cannot correctly display descriptor\r\n",
            MPEG4SLFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_MPEG4SL));
        OOPS();
    }

    if (MPEG4SLFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B26.2 (descript.c line 1573)
        //@@WARNING
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*WARNING:  bFormatIndex = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    // This descriptor is deprecated for UVC 1.1
#ifdef H264_SUPPORT
    if (UVC10 != g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC version >= 1.1 devices\r\n");
    }
#else
    if (UVC11 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.1 devices\r\n");
    }
#endif
    return TRUE;
}


//*****************************************************************************
//
// DisplayStreamPayload()
//
//*****************************************************************************

BOOL
DisplayStreamPayload (
                      PVIDEO_FORMAT_STREAM StreamPayloadDesc
                      )
{
    //@@DisplayStreamPayload -Stream Based Payload Format
    PCHAR pStr = NULL;
    OLECHAR szGUID[256];
    int i = 0;

    memset((LPOLESTR) szGUID, 0, sizeof(OLECHAR) * 256);
    i = StringFromGUID2((REFGUID) &StreamPayloadDesc->guidFormat, (LPOLESTR) szGUID, 255);
    i++;

    AppendTextBuffer("\r\n          ===>Video Streaming Stream Based Payload Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", StreamPayloadDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", StreamPayloadDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", StreamPayloadDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", StreamPayloadDesc->bFormatIndex);
    AppendTextBuffer("guidFormat:                        %S", szGUID);

    pStr = VidFormatGUIDCodeToName((REFGUID) &StreamPayloadDesc->guidFormat);
    if(gDoAnnotation)   
    {
        if (pStr)
        {
            AppendTextBuffer(" = %s Format", pStr);
        }
    } 
    AppendTextBuffer("\r\n");
    AppendTextBuffer("dwPacketLength:                    0x%02X\r\n", StreamPayloadDesc->dwPacketLength);

    if (StreamPayloadDesc->bLength != sizeof(VIDEO_FORMAT_STREAM))
    {
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            StreamPayloadDesc->bLength,
            sizeof(PVIDEO_FORMAT_STREAM));
        OOPS();
    }

    if (StreamPayloadDesc->bFormatIndex == 0 )
    {
        //@@WARNING
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*WARNING:  bFormatIndex = 0, this is a 1 based index\r\n");
        OOPS();
    }

    // This descriptor is new for UVC 1.1
    if (UVC10 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.0 devices\r\n");
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayDVFormat()
//
//*****************************************************************************

BOOL
DisplayDVFormat (
                 PVIDEO_FORMAT_DV DVFormatDesc
                 )
{
    //@@DisplayDVFormat -Digital Video Format

    AppendTextBuffer("\r\n          ===>Video Streaming DV Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", DVFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", DVFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", DVFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", DVFormatDesc->bFormatIndex);
    AppendTextBuffer("dwMaxVideoFrameBufferSize:   0x%08X\r\n", DVFormatDesc->dwMaxVideoFrameBufferSize);
    AppendTextBuffer("bFormatType:                       0x%02X\r\n", DVFormatDesc->bFormatType);
    if (gDoAnnotation)  
    {
        AppendTextBuffer("     D0..6 = Format Type  ->");
        switch(DVFormatDesc->bFormatType & 0x03) 
        {
           case 0x00:
               AppendTextBuffer(" SD-DV\r\n");
               break;
           case 0x01:
               AppendTextBuffer(" SDL-DV\r\n");
               break;
           case 0x02:
               AppendTextBuffer(" HD-DV\r\n");
               break;
           default:
               AppendTextBuffer(" Unknown Format\r\n");
               break;
        }
        if (DVFormatDesc->bFormatType & 0x80)
            AppendTextBuffer("     D7    = 60Hz");
        else
            AppendTextBuffer("     D7    = 50Hz");
        AppendTextBuffer("\r\n");}

    if (DVFormatDesc->bLength != sizeof(VIDEO_FORMAT_DV))
    {
        //@@TestCase B27.1 (descript.c line 1453)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            DVFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_DV));
        OOPS();
    }

    if (DVFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B27.2 (descript.c line 1458)
        //@@ERROR
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex invalid
        AppendTextBuffer("*!*ERROR:  bFormatIndex of 0x%02X is invalid\r\n", 
            DVFormatDesc->bFormatIndex);
        OOPS();
    }

    if (DVFormatDesc->dwMaxVideoFrameBufferSize == 0 )
    {
        //@@TestCase B27.3 (descript.c line 1463)
        //@@ERROR
        //@@Descriptor Field - dwMaxVideoFrameBufferSize
        //@@dwMaxVideoFrameBufferSize invalid
        AppendTextBuffer("*!*ERROR:  dwMaxVideoFrameBufferSize of 0x%02X is invalid\r\n", 
            DVFormatDesc->dwMaxVideoFrameBufferSize);
        OOPS();
    }

    //@@TestCase B27.4
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bFormatType
    //@@Question - Should we validate that reserved bits are set to zero?

    return TRUE;
}


//*****************************************************************************
//
// DisplayVidVendorFormat()
//
//*****************************************************************************

BOOL
DisplayVendorVidFormat (
                        PVIDEO_FORMAT_VENDOR VendorVidFormatDesc
                        )
{
    //@@DisplayVendorVidFormat -Vendor Video Format
    OLECHAR szGUID[256];
    int i = 0;

    // Initialize the default Frame
    g_chVendorFrameDefault = VendorVidFormatDesc->bDefaultFrameIndex;

    memset((LPOLESTR) szGUID, 0, sizeof(OLECHAR) * 256);
    i = StringFromGUID2((REFGUID) &VendorVidFormatDesc->guidMajorFormat, (LPOLESTR) szGUID, 255);
    i++;

    AppendTextBuffer("\r\n          ===>Video Streaming Vendor Video Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", VendorVidFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VendorVidFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VendorVidFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", VendorVidFormatDesc->bFormatIndex);
    AppendTextBuffer("bNumFrameDescriptors:              0x%02X\r\n", VendorVidFormatDesc->bNumFrameDescriptors);
    AppendTextBuffer("guidMajorFormat:                   %S\r\n", szGUID);
    i = StringFromGUID2((REFGUID) &VendorVidFormatDesc->guidSubFormat, (LPOLESTR) szGUID, 255);
    i++;
    AppendTextBuffer("guidSubFormat:                     %S\r\n", szGUID);
    i = StringFromGUID2((REFGUID) &VendorVidFormatDesc->guidSpecifier, (LPOLESTR) szGUID, 255);
    i++;
    AppendTextBuffer("guidSpecifier:                     %S\r\n", szGUID);
    AppendTextBuffer("bPayloadClass:                     0x%02X\r\n", VendorVidFormatDesc->bPayloadClass);
    AppendTextBuffer("bDefaultFrameIndex:                0x%02X\r\n", VendorVidFormatDesc->bDefaultFrameIndex);
    AppendTextBuffer("bCopyProtect:                      0x%02X", VendorVidFormatDesc->bCopyProtect);
    if(gDoAnnotation) {
        if(VendorVidFormatDesc->bCopyProtect) { AppendTextBuffer("  -> Duplication Restricted\r\n");}
        else {AppendTextBuffer("  -> Duplication Unrestricted\r\n");}}
    else {AppendTextBuffer("\r\n");}

    if (VendorVidFormatDesc->bLength != sizeof(VIDEO_FORMAT_VENDOR))
    {
        //@@TestCase B28.1 (descript.c line 1297)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d.  USBView cannot correctly display descriptor\r\n",
            VendorVidFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_VENDOR));
        OOPS();
    }

    if (VendorVidFormatDesc->bFormatIndex == 0 )
    {
        //@@TestCase B28.2 (descript.c line 1302)
        //@@ERROR
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bFormatIndex = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (VendorVidFormatDesc->bNumFrameDescriptors == 0 )
    {
        //@@TestCase B28.3 (descript.c line 1307)
        //@@ERROR
        //@@Descriptor Field - bNumFrameDescriptors
        //@@bNumFrameDescriptors is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bNumFrameDescriptors = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if(VendorVidFormatDesc->bPayloadClass > 1)
    {
        //@@TestCase B28.4
        //@@WARNING
        //@@Descriptor Field - bPayloadClass
        //@@bPayloadClass is using reserved space
        AppendTextBuffer("*!*WARNING:  bPayloadClass is incorrectly using reserved space\r\n");
        OOPS();
    }
    else
    {
        if (gDoAnnotation)
        {
            if(VendorVidFormatDesc->bPayloadClass == 1) { AppendTextBuffer("  -> Using a Frame Based Payload\r\n");}
            else { AppendTextBuffer("  -> Using a Stream Based Payload\r\n");}
        }
        else {AppendTextBuffer("\r\n");}
    }

    if (VendorVidFormatDesc->bDefaultFrameIndex == 0 )
    {
        //@@TestCase B28.5 (descript.c line 1312)
        //@@ERROR
        //@@Descriptor Field - bDefaultFrameIndex
        //@@bDefaultFrameIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bDefaultFrameIndex = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (VendorVidFormatDesc->bDefaultFrameIndex == 0 || VendorVidFormatDesc->bDefaultFrameIndex > VendorVidFormatDesc->bNumFrameDescriptors)
    {
        //@@TestCase B28.6
        //@@WARNING
        //@@Descriptor Field - bDefaultFrameIndex
        //@@bDefaultFrameIndex is out of range
        AppendTextBuffer("*!*WARNING:  The value %d for the bDefaultFrameIndex is out of range this invalidates the descriptor\r\n*!* The proper range is 1 to %d)",
            VendorVidFormatDesc->bDefaultFrameIndex,
            VendorVidFormatDesc->bNumFrameDescriptors);
        OOPS();
    }

    //@@TestCase B28.7
    //@@Not yet implemented - Priority 1
    //@@Descriptor Field - bCopyProtect
    //@@Question - Are their reserved bits and should we validate that reserved bits are set to zero?
    //    AppendTextBuffer("bCopyProtect:                      0x%02X", VendorVidFormatDesc->bCopyProtect);

    // Check that the correct number of Frame Descriptors and one Color Matching
    //  descriptor follow
    CheckForColorMatchingDesc ((PVIDEO_SPECIFIC) VendorVidFormatDesc,
        VendorVidFormatDesc->bNumFrameDescriptors, VS_FRAME_VENDOR);

    // This descriptor is deprecated for UVC 1.1
#ifdef H264_SUPPORT
    if (UVC10 != g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC version >= 1.1 devices\r\n");
    }
#else
    if (UVC11 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.1 devices\r\n");
    }
#endif
    return TRUE;
}


//*****************************************************************************
//
// DisplayVendorVidFrameType()
//
//*****************************************************************************

BOOL
DisplayVendorVidFrameType (
                           PVIDEO_FRAME_VENDOR VendorVidFrameDesc
                           )
{
    //@@DisplayVendorVidFrameType -Vendor Video Frame
    size_t bLength = 0;
    bLength = SizeOfVideoFrameVendor(VendorVidFrameDesc);

    AppendTextBuffer("\r\n          ===>Video Streaming Vendor Video Frame Type Descriptor<===\r\n");
    if (gDoAnnotation) 
    {
        if(VendorVidFrameDesc->bFrameIndex == g_chVendorFrameDefault)
        { 
            AppendTextBuffer("          --->This is the Default (optimum) Frame index\r\n");
        }
    }
    AppendTextBuffer("bLength:                           0x%02X\r\n", VendorVidFrameDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VendorVidFrameDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VendorVidFrameDesc->bDescriptorSubtype);
    AppendTextBuffer("bFrameIndex:                       0x%02X\r\n", VendorVidFrameDesc->bFrameIndex);

    if (VendorVidFrameDesc->bLength != bLength)
    {
        //@@TestCase B29.1 (descript.c line 1352)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is less than required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            VendorVidFrameDesc->bLength, bLength);
        OOPS();
    }

    if (VendorVidFrameDesc->bFrameIndex == 0 )
    {
        //@@TestCase B29.2 (descript.c line 1357)
        //@@ERROR
        //@@Descriptor Field - bFrameIndex
        //@@bFrameIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bFrameIndex = 0, this is a 1 based index\r\n");
        OOPS();
    }

    AppendTextBuffer("bmCapabilities:                    0x%02X", VendorVidFrameDesc->bmCapabilities);

    if(VendorVidFrameDesc->bmCapabilities & 0x01){
        if(gDoAnnotation) { AppendTextBuffer("  -> Still Images are supported\r\n");}
        else {AppendTextBuffer("\r\n");} }
    else if (VendorVidFrameDesc->bmCapabilities & 0xFF)
    {
        //@@TestCase B29.3
        //@@WARNING
        //@@Descriptor Field - bmCapabilities
        //@@bmCapabilities has a bit using reserved areas that should be set to zero
        AppendTextBuffer("\r\n*!*WARNING:  bmCapabilities is using reserved areas.\r\n");
        OOPS(); }
    else {AppendTextBuffer("\r\n");}
    AppendTextBuffer("wWidth:                          0x%04X = %d\r\n", VendorVidFrameDesc->wWidth, VendorVidFrameDesc->wWidth);
    AppendTextBuffer("wHeight:                         0x%04X = %d\r\n", VendorVidFrameDesc->wHeight, VendorVidFrameDesc->wHeight);
    AppendTextBuffer("dwMinBitRate:                0x%08X\r\n", VendorVidFrameDesc->dwMinBitRate);
    AppendTextBuffer("dwMaxBitRate:                0x%08X\r\n", VendorVidFrameDesc->dwMaxBitRate);
    AppendTextBuffer("dwMaxVideoFrameBufferSize:   0x%08X\r\n", VendorVidFrameDesc->dwMaxVideoFrameBufferSize);
    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse

    AppendTextBuffer("dwDefaultFrameInterval:      0x%08X = %lf mSec (%4.2f Hz)\r\n", 
        VendorVidFrameDesc->dwDefaultFrameInterval,
        ((double)VendorVidFrameDesc->dwDefaultFrameInterval)/10000.0,
        (10000000.0/((double)VendorVidFrameDesc->dwDefaultFrameInterval))
        );
    AppendTextBuffer("bFrameIntervalType:                0x%02X\r\n", VendorVidFrameDesc->bFrameIntervalType);

    if (VendorVidFrameDesc->wWidth == 0 )
    {
        //@@TestCase B29.4 (descript.c line 1362)
        //@@ERROR
        //@@Descriptor Field - wWidth
        //@@wWidth is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  wWidth must be nonzero\r\n");
        OOPS();
    }

    if (VendorVidFrameDesc->wHeight == 0 )
    {
        //@@TestCase B29.5 (descript.c line 1367)
        //@@ERROR
        //@@Descriptor Field - wHeight
        //@@wHeight is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  wHeight must be nonzero\r\n");
        OOPS();
    }

    if (VendorVidFrameDesc->dwMinBitRate == 0 )
    {
        //@@TestCase B29.6 (descript.c line 1372)
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate
        //@@dwMinBitRate is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMinBitRate must be nonzero\r\n");
        OOPS();
    }

    if (VendorVidFrameDesc->dwMaxBitRate == 0 )
    {
        //@@TestCase B29.7 (descript.c line 1377)
        //@@ERROR
        //@@Descriptor Field - dwMaxBitRate
        //@@dwMaxBitRate is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMaxBitRate must be nonzero\r\n");
        OOPS();
    }

    if(VendorVidFrameDesc->dwMinBitRate > VendorVidFrameDesc->dwMaxBitRate)
    {
        //@@TestCase B29.8
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate and dwMaxBitRate
        //@@Verify that dwMaxBitRate is greater than dwMinBitRate
        AppendTextBuffer("*!*ERROR:  dwMinBitRate should be less than dwMaxBitRate\r\n");
        OOPS();
    }
    else
    {
        if (VendorVidFrameDesc->bFrameIntervalType == 1 && 
            VendorVidFrameDesc->dwMinBitRate != VendorVidFrameDesc->dwMaxBitRate)
        {
            //@@TestCase B29.9
            //@@WARNING
            //@@Descriptor Field - bFrameIntervalType, dwMinBitRate, and dwMaxBitRate
            //@@Verify that dwMaxBitRate is equal to dwMinBitRate if bFrameIntervalType is 1
            AppendTextBuffer("*!*WARNING:  if bFrameIntervalType is 1 then dwMinBitRate "\
                "should equal dwMaxBitRate\r\n");
            OOPS();
        }
    }

    if (VendorVidFrameDesc->dwMaxVideoFrameBufferSize == 0 )
    {
        //@@TestCase B29.10 (descript.c line 1382)
        //@@WARNING
        //@@Descriptor Field - dwMaxVideoFrameBufferSize
        //@@dwMaxVideoFrameBufferSize is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*WARNING:  dwMaxVideoFrameBufferSize must be nonzero\r\n");
        OOPS();
    }
    if (VendorVidFrameDesc->dwDefaultFrameInterval == 0 )
    {
        //@@TestCase B29.11 (descript.c line 1020)
        //@@WARNING
        //@@Descriptor Field - dwDefaultFrameInterval
        //@@dwDefaultFrameInterval must be nonzero
        AppendTextBuffer("*!*WARNING:  dwDefaultFrameInterval must be nonzero\r\n");
        OOPS();
    }

    if (VendorVidFrameDesc->bFrameIntervalType == 0)
    {
        DisplayVendorVidContinuousFrameType(VendorVidFrameDesc);
    }
    else
    {
        DisplayVendorVidDiscreteFrameType(VendorVidFrameDesc);
    }
    // This descriptor is deprecated for UVC 1.1
#ifdef H264_SUPPORT
    if (UVC10 != g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC  version >= 1.1 devices\r\n");
    }
#else
    if (UVC11 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.1 devices\r\n");
    }
#endif
    return TRUE;
}


//*****************************************************************************
//
// DisplayVendorVidContinuousFrameType()
//
//*****************************************************************************

BOOL
DisplayVendorVidContinuousFrameType(
                                    PVIDEO_FRAME_VENDOR VContinuousDesc
                                    )
{
    //@@DisplayVendorVidContinuousFrameType -Vendor Video Continuous Frame
    ULONG dwMinFrameInterval  = VContinuousDesc->adwFrameInterval[0];
    ULONG dwMaxFrameInterval  = VContinuousDesc->adwFrameInterval[1];
    ULONG dwFrameIntervalStep = VContinuousDesc->adwFrameInterval[2];

    AppendTextBuffer("===>Additional Continuous Frame Type Data\r\n");
    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse


    AppendTextBuffer("dwMinFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMinFrameInterval,
        ((double)dwMinFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMinFrameInterval) + 0.5));
    
    AppendTextBuffer("dwMaxFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMaxFrameInterval,
        ((double)dwMaxFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMaxFrameInterval) + 0.5));
    AppendTextBuffer("dwFrameIntervalStep:         0x%08X\r\n", dwFrameIntervalStep);

    if (dwMinFrameInterval == 0 )
    {
        //@@TestCase B30.2  (descript.c line 1388)
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval
        //@@dwMinFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (dwMaxFrameInterval == 0 )
    {
        //@@TestCase B30.3 (descript.c line 1388)
        //@@ERROR
        //@@Descriptor Field - dwMaxFrameInterval
        //@@dwMaxFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMaxFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if(dwMinFrameInterval  > dwMaxFrameInterval)
    {
        //@@TestCase B30.4  (descript.c line 1405)
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval is larger that dwMaxFrameInterval, this invalidates the descriptor\r\n");
        OOPS();
    }
    else if ((dwMinFrameInterval + dwFrameIntervalStep) > dwMaxFrameInterval)
    {
        //@@TestCase B30.5
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval combined with dwFrameIntervalStep
        AppendTextBuffer("*!*WARNING:  dwMinFrameInterval + dwFrameIntervalStep is greater than dwMaxFrameInterval, this could cause problems\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) == 0 )
    {
        //@@TestCase B30.6
        //@@CAUTION
        //@@Descriptor Field - dwFrameIntervalStep
        //@@Suggestion to use descrite frames if dwFrameIntervalStep is zero
        AppendTextBuffer("*!*CAUTION:  dwFrameIntervalStep equals zero, consider using discrete frames\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) % dwFrameIntervalStep )
    {
        //@@TestCase B30.7  (descript.c line 1414)
        //@@ERROR
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the difference between dwMaxFrameInterval and dwMinFrameInterval is evenly divisible by dwFrameIntervalStep
        AppendTextBuffer("*!*ERROR:  dwMaxFrameInterval minus dwMinFrameInterval  is not evenly divisible by dwFrameIntervalStep, this could cause problems\r\n");
        OOPS();
    }

    if (dwFrameIntervalStep == 0 && (dwMaxFrameInterval - dwMinFrameInterval))
    {
        //@@TestCase B30.8  (descript.c line 1394)
        //@@ERROR
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the dwFrameIntervalStep is not zero if there is a difference between dwMaxFrameInterval and dwMinFrameInterval
        AppendTextBuffer("*!*ERROR:  dwFrameIntervalStep = 0, this invalidates the descriptor when there is a difference between \r\n          dwMinFrameInterval and dwMaxFrameInterval\r\n");
        OOPS();
    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayVendorVidDiscreteFrameType()
//
//*****************************************************************************

BOOL
DisplayVendorVidDiscreteFrameType(
                                  PVIDEO_FRAME_VENDOR VDiscreteDesc
                                  )
{
    //@@DisplayVendorVidDiscreteFrameType -Vendor Video Discrete Frame
    UINT    iNdex = 1;
    UINT    iCurFrame = 0;
    ULONG   * ulFrameInterval = NULL;

    AppendTextBuffer("===>Additional Discrete Frame TypeData\r\n");

    // There are (VDiscreteDesc->bFrameIntervalType) dwFrameIntervals
    for (; iNdex <= VDiscreteDesc->bFrameIntervalType; iNdex++, iCurFrame++)
    {
        ulFrameInterval = &VDiscreteDesc->adwFrameInterval[iCurFrame];
        // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
        // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
        // = 1/10,000 milliseconds


        // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse
        AppendTextBuffer("dwFrameInterval[%d]:          0x%08X = %lf mSec (%4.2f Hz)\r\n", 
            iNdex, *ulFrameInterval,
            ((double)*ulFrameInterval)/10000.0,
            (10000000.0/((double)*ulFrameInterval))
            );
        if (0 == *ulFrameInterval)
        {
            //@@TestCase B31.1 (descript.c line 1061)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[x] must be non-zero
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[%d] must be non-zero\r\n", iNdex);
            OOPS();
        }
        if ((iNdex > 1)&&(*ulFrameInterval <= VDiscreteDesc->adwFrameInterval[iCurFrame - 1]))
        {
            //@@TestCase B31.2 (descript.c line 1067)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[n] must be greater than dwFrameInterval[n - 1]
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[0x%02X] must be "\
                "greater than preceding dwFrameInterval[0x%02X]\r\n", iNdex, iNdex - 1);
            OOPS();
        }
    }

    return TRUE;
}

//*****************************************************************************
//
// DisplayFramePayloadFormat() 
//
//*****************************************************************************

BOOL
DisplayFramePayloadFormat (
                           PVIDEO_FORMAT_FRAME FramePayloadFormatDesc
                           )
{
    //@@DisplayFramePayloadFormat - FrameBased Payload Format
    PCHAR pStr = NULL;
    OLECHAR szGUID[256];
    int i = 0;

    // Initialize the default Frame
    g_chFrameBasedFrameDefault = FramePayloadFormatDesc->bDefaultFrameIndex;

    memset((LPOLESTR) szGUID, 0, sizeof(OLECHAR) * 256);
    i = StringFromGUID2((REFGUID) &FramePayloadFormatDesc->guidFormat, (LPOLESTR) szGUID, 255);
    i++;

    AppendTextBuffer("\r\n          ===>Video Streaming Frame Based Payload Format Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X\r\n", FramePayloadFormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", FramePayloadFormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", FramePayloadFormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X\r\n", FramePayloadFormatDesc->bFormatIndex);
    AppendTextBuffer("bNumFrameDescriptors:              0x%02X\r\n", FramePayloadFormatDesc->bNumFrameDescriptors);
    AppendTextBuffer("guidFormat:                        %S", szGUID);

    pStr = VidFormatGUIDCodeToName((REFGUID) &FramePayloadFormatDesc->guidFormat);
    if ( pStr )   
    {
        if ( gDoAnnotation )
        {
            AppendTextBuffer(" = %s Format", pStr);
        }
    } 
    AppendTextBuffer("\r\n");
    AppendTextBuffer("bBitsPerPixel:                     0x%02X\r\n", FramePayloadFormatDesc->bBitsPerPixel);
    AppendTextBuffer("bDefaultFrameIndex:                0x%02X\r\n", FramePayloadFormatDesc->bDefaultFrameIndex);

    if (FramePayloadFormatDesc->bLength != sizeof(VIDEO_FORMAT_FRAME))
    {
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required 
        //@@length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            FramePayloadFormatDesc->bLength,
            sizeof(VIDEO_FORMAT_FRAME));
        OOPS();
    }

    if (FramePayloadFormatDesc->bFormatIndex == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - bFormatIndex
        //@@bFormatIndex is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bFormatIndex = 0, this is a 1 based index\r\n");
        OOPS();
    }

    if (FramePayloadFormatDesc->bNumFrameDescriptors == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - bNumFrameDescriptors
        //@@bNumFrameDescriptors is set to zero which is not in accordance with the 
        //@@USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bNumFrameDescriptors = 0, must have at least 1 Frame descriptor\r\n");
        OOPS();
    }

    if(!(pStr))
    {
        //@@WARNING
        //@@Descriptor Field - guidFormat
        //@@guidFormat is set to unknown or undefined format
        AppendTextBuffer("\r\n*!*WARNING:  guidFormat is an unknown format\r\n");
        OOPS();
    }

    if (FramePayloadFormatDesc->bBitsPerPixel == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - bBitsPerPixel
        //@@bBitsPerPixel is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bBitsPerPixel = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (FramePayloadFormatDesc->bDefaultFrameIndex == 0 || FramePayloadFormatDesc->bDefaultFrameIndex > 
        FramePayloadFormatDesc->bNumFrameDescriptors)
    {
        //@@ERROR
        //@@Descriptor Field - bDefaultFrameIndex
        //@@The value for bDefaultFrameIndex is not greater than 0 or less than or equal to bNumFrameDescriptors
        AppendTextBuffer("*!*ERROR:  The value %d for the bDefaultFrameIndex is out of range, this invalidates the descriptor\r\n*!*The proper range is 1 to %d)",
            FramePayloadFormatDesc->bDefaultFrameIndex,
            FramePayloadFormatDesc->bNumFrameDescriptors);
        OOPS();
    }

    AppendTextBuffer("bAspectRatioX:                     0x%02X\r\n", 
        FramePayloadFormatDesc->bAspectRatioX);
    AppendTextBuffer("bAspectRatioY:                     0x%02X", 
        FramePayloadFormatDesc->bAspectRatioY);

    if (((FramePayloadFormatDesc->bmInterlaceFlags & 0x01) && 
        (FramePayloadFormatDesc->bAspectRatioY != 0 && 
        FramePayloadFormatDesc->bAspectRatioX != 0)))
    {
        if(gDoAnnotation) 
        {
            AppendTextBuffer("  -> Aspect Ratio is set for a %d:%d display",
                (FramePayloadFormatDesc->bAspectRatioX),(FramePayloadFormatDesc->bAspectRatioY));   
        } 
        else 
        {
            if (FramePayloadFormatDesc->bAspectRatioY != 0 || FramePayloadFormatDesc->bAspectRatioX != 0)
            {
                //@@ERROR
                //@@Descriptor Field - bAspectRatioX, bAspectRatioY
                //@@Verify that that bAspectRatioX and bAspectRatioY are  set to zero 
                //@@  if stream is non-interlaced
                AppendTextBuffer("\r\n*!*ERROR:  Both bAspectRatioX and bAspectRatioY "\
                    "must equal 0 if stream is non-interlaced");
                OOPS();
            }
        }
    }
    AppendTextBuffer("\r\nbmInterlaceFlags:                  0x%02X\r\n", 
        FramePayloadFormatDesc->bmInterlaceFlags);

    if (gDoAnnotation) 
    {
        AppendTextBuffer("     D0    = 0x%02X Interlaced stream or variable: %s\r\n", 
            (FramePayloadFormatDesc->bmInterlaceFlags & 1),
            (FramePayloadFormatDesc->bmInterlaceFlags & 1) ? "Yes" : "No");
        AppendTextBuffer("     D1    = 0x%02X Fields per frame: %s\r\n", 
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 1) & 1),
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 1) & 1) ? "1 field" : "2 fields");
        AppendTextBuffer("     D2    = 0x%02X Field 1 first: %s\r\n", 
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 2) & 1),
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 2) & 1) ? "Yes" : "No");
        //@@Descriptor Field - bmInterlaceFlags
        //@@Validate that reserved bits (D3) are set to zero.
        AppendTextBuffer("     D3    = 0x%02X Reserved%s\r\n", 
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 3) & 1),
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 3) & 1) ? 
            "\r\n*!*ERROR: Reserved to 0" : "" );
        AppendTextBuffer("     D4..5 = 0x%02X Field patterns  ->",
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 4) & 3));
        switch(FramePayloadFormatDesc->bmInterlaceFlags & 0x30)
        {
        case 0x00:
            AppendTextBuffer(" Field 1 only");
            break;
        case 0x10:
            AppendTextBuffer(" Field 2 only");
            break;
        case 0x20:
            AppendTextBuffer(" Regular Pattern of fields 1 and 2");
            break;
        case 0x30:
            AppendTextBuffer(" Random Pattern of fields 1 and 2");
            break;
        }
        AppendTextBuffer("\r\n     D6..7 = 0x%02X Display Mode  ->",
            ((FramePayloadFormatDesc->bmInterlaceFlags >> 6) & 3));

        switch(FramePayloadFormatDesc->bmInterlaceFlags & 0xC0)
        {
        case 0x00:
            AppendTextBuffer(" Bob only");
            break;
        case 0x40:
            AppendTextBuffer(" Weave only");
            break;
        case 0x80:
            AppendTextBuffer(" Bob or weave");
            break;
        case 0xC0:
            //@@Descriptor Field - bmInterlaceFlags
            //@@Question - Should we validate that reserved bits are set to zero?
            AppendTextBuffer(" Reserved");
            break;
        }
    }

    //@@Descriptor Field - bCopyProtect
    //@@Question - Are their reserved bits and should we validate that 
    //@@  reserved bits are set to zero?
    AppendTextBuffer("\r\nbCopyProtect:                      0x%02X", 
        FramePayloadFormatDesc->bCopyProtect);
    if (gDoAnnotation)  
    {
        if (FramePayloadFormatDesc->bCopyProtect)
            AppendTextBuffer("  -> Duplication Restricted");
        else
            AppendTextBuffer("  -> Duplication Unrestricted");
    }

    //@@Descriptor Field - bVariableSize
    AppendTextBuffer("\r\nbVariableSize:                     0x%02X", 
        FramePayloadFormatDesc->bVariableSize);
    if (gDoAnnotation)  
    {
        if (FramePayloadFormatDesc->bVariableSize)
            AppendTextBuffer("  -> Variable Size");
        else
            AppendTextBuffer("  -> Fixed Size");
    }
    AppendTextBuffer("\r\n");

    // Check that the correct number of Frame Descriptors and one Color Matching
    //  descriptor follow
    CheckForColorMatchingDesc ((PVIDEO_SPECIFIC) FramePayloadFormatDesc,
        FramePayloadFormatDesc->bNumFrameDescriptors, VS_FRAME_FRAME_BASED);

    // This descriptor is new for UVC 1.1
    if (UVC10 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.0 devices\r\n");
    }
    return TRUE;
    }


//*****************************************************************************
//
// DisplayFramePayloadFrame()
//
//*****************************************************************************

BOOL
DisplayFramePayloadFrame (
                              PVIDEO_FRAME_FRAME FramePayloadFrameDesc
                              )
{
    size_t bLength = 0;
    bLength = SizeOfVideoFrameFrame(FramePayloadFrameDesc);

    //@@DisplayFramePayloadFrame -Frame Based Payload Frame

    AppendTextBuffer("\r\n          ===>Video Streaming Frame Based Payload Frame Type Descriptor<===\r\n");
    if (gDoAnnotation) 
    {
        if(FramePayloadFrameDesc->bFrameIndex == g_chFrameBasedFrameDefault)
        { 
            AppendTextBuffer("          --->This is the Default (optimum) Frame index\r\n");
        }
    }
    AppendTextBuffer("bLength:                           0x%02X\r\n", FramePayloadFrameDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", FramePayloadFrameDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", FramePayloadFrameDesc->bDescriptorSubtype);
    AppendTextBuffer("bFrameIndex:                       0x%02X\r\n", FramePayloadFrameDesc->bFrameIndex);
    AppendTextBuffer("bmCapabilities:                    0x%02X\r\n", FramePayloadFrameDesc->bmCapabilities);
    AppendTextBuffer("wWidth:                          0x%04X = %d\r\n", FramePayloadFrameDesc->wWidth, FramePayloadFrameDesc->wWidth);
    AppendTextBuffer("wHeight:                         0x%04X = %d\r\n", FramePayloadFrameDesc->wHeight, FramePayloadFrameDesc->wHeight);
    AppendTextBuffer("dwMinBitRate:                0x%08X\r\n", FramePayloadFrameDesc->dwMinBitRate);
    AppendTextBuffer("dwMaxBitRate:                0x%08X\r\n", FramePayloadFrameDesc->dwMaxBitRate);
    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse

    AppendTextBuffer("dwDefaultFrameInterval:      0x%08X = %lf mSec (%4.2f Hz)\r\n", 
        FramePayloadFrameDesc->dwDefaultFrameInterval,
        ((double)FramePayloadFrameDesc->dwDefaultFrameInterval)/10000.0,
        (10000000.0/((double)FramePayloadFrameDesc->dwDefaultFrameInterval))
        );
    AppendTextBuffer("bFrameIntervalType:                0x%02X\r\n", FramePayloadFrameDesc->bFrameIntervalType);

    if (FramePayloadFrameDesc->bLength != bLength)
    {
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required 
        //@@length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d\r\n",
            FramePayloadFrameDesc->bLength, bLength);
        OOPS();
    }

    if (FramePayloadFrameDesc->bFrameIndex == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - bFrameIndex
        //@@bFrameIndex must be nonzero 
        AppendTextBuffer("*!*ERROR:  bFrameIndex = 0, this is a 1 based index\r\n");
        OOPS();
    }

    //@@Descriptor Field - bmCapabilities
    //@@Question:  Should we try to verify that bmCapabilities is valid?
    //    AppendTextBuffer("bmCapabilities:                    0x%02X\r\n", UnCompFrameDesc->bmCapabilities);

    if (FramePayloadFrameDesc->wWidth == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - wWidth
        //@@wWidth must be nonzero
        AppendTextBuffer("*!*ERROR:  wWidth must be nonzero\r\n");
        OOPS();
    }

    if (FramePayloadFrameDesc->wHeight == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - wHeight
        //@@wHeight must be nonzero
        AppendTextBuffer("*!*ERROR:  wHeight must be nonzero\r\n");
        OOPS();
    }

    if (FramePayloadFrameDesc->dwMinBitRate == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate
        //@@dwMinBitRate must be nonzero
        AppendTextBuffer("*!*ERROR:  dwMinBitRate must be nonzero\r\n");
        OOPS();
    }

    if (FramePayloadFrameDesc->dwMaxBitRate == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - dwMaxBitRate
        //@@dwMaxBitRate must be nonzero
        AppendTextBuffer("*!*ERROR:  dwMaxBitRate must be nonzero\r\n");
        OOPS();
    }

    if(FramePayloadFrameDesc->dwMinBitRate > FramePayloadFrameDesc->dwMaxBitRate)
    {
        //@@ERROR
        //@@Descriptor Field - dwMinBitRate and dwMaxBitRate
        //@@Verify that dwMaxBitRate is greater than dwMinBitRate
        AppendTextBuffer("*!*ERROR:  dwMinBitRate should be less than dwMaxBitRate\r\n");
        OOPS();
    }
    else 
    {
        if (FramePayloadFrameDesc->bFrameIntervalType == 1 && 
            FramePayloadFrameDesc->dwMinBitRate != FramePayloadFrameDesc->dwMaxBitRate)
        {
            //@@WARNING
            //@@Descriptor Field - bFrameIntervalType, dwMinBitRate, and dwMaxBitRate
            //@@Verify that dwMaxBitRate is equal to dwMinBitRate if bFrameIntervalType is 1
            AppendTextBuffer("*!*WARNING:  if bFrameIntervalType is 1 then dwMinBitRate "\
                "should equal dwMaxBitRate\r\n");
            OOPS();
        }
    }

    if (FramePayloadFrameDesc->dwDefaultFrameInterval == 0 )
    {
        //@@TestCase B16.11 (descript.c line 1020)
        //@@WARNING
        //@@Descriptor Field - dwDefaultFrameInterval
        //@@dwDefaultFrameInterval must be nonzero
        AppendTextBuffer("*!*WARNING:  dwDefaultFrameInterval must be nonzero\r\n");
        OOPS();
    }

    if (0 == FramePayloadFrameDesc->bFrameIntervalType)
    {
        DisplayFramePayloadContinuousFrameType(FramePayloadFrameDesc);
    }
    else
    {
        DisplayFramePayloadDiscreteFrameType(FramePayloadFrameDesc);
    }
    // This descriptor is new for UVC 1.1
    if (UVC10 == g_chUVCversion)
    {
        AppendTextBuffer("*!*ERROR: This format is NOT ALLOWED for UVC 1.0 devices\r\n");
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayFramePayloadContinuousFrameType()
//
//*****************************************************************************

BOOL
DisplayFramePayloadContinuousFrameType(
                                PVIDEO_FRAME_FRAME FContinuousDesc
                                )
{
    //@@DisplayFramePayloadContinuousFrameType -Frame Payload Continuous Frame
    ULONG dwMinFrameInterval  = FContinuousDesc->adwFrameInterval[0];
    ULONG dwMaxFrameInterval  = FContinuousDesc->adwFrameInterval[1];
    ULONG dwFrameIntervalStep = FContinuousDesc->adwFrameInterval[2];

    AppendTextBuffer("===>Additional Continuous Frame Type Data\r\n");
    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds


    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse


    AppendTextBuffer("dwMinFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMinFrameInterval,
        ((double)dwMinFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMinFrameInterval) + 0.5));
    
    AppendTextBuffer("dwMaxFrameInterval:          0x%08X = %lf mSec (%d Hz)\r\n", 
        dwMaxFrameInterval,
        ((double)dwMaxFrameInterval)/10000.0,
        (ULONG)(10000000.0/((double)dwMaxFrameInterval) + 0.5));

    AppendTextBuffer("dwFrameIntervalStep:         0x%08X\r\n", dwFrameIntervalStep);

    if (dwMinFrameInterval == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval
        //@@dwMinFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if (dwMaxFrameInterval == 0 )
    {
        //@@ERROR
        //@@Descriptor Field - dwMaxFrameInterval
        //@@dwMaxFrameInterval is set to zero which is not in accordance with the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  dwMaxFrameInterval = 0, this invalidates the descriptor\r\n");
        OOPS();
    }

    if(dwMinFrameInterval  > dwMaxFrameInterval)
    {
        //@@ERROR
        //@@Descriptor Field - dwMinFrameInterval and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval
        AppendTextBuffer("*!*ERROR:  dwMinFrameInterval is larger that dwMaxFrameInterval, this invalidates the descriptor\r\n");
        OOPS();
    }
    else if ((dwMinFrameInterval + dwFrameIntervalStep) > dwMaxFrameInterval)
    {
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that dwMaxFrameInterval is greater than dwMinFrameInterval combined with dwFrameIntervalStep
        AppendTextBuffer("*!*WARNING:  dwMinFrameInterval + dwFrameIntervalStep is greater than dwMaxFrameInterval, this could cause problems\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) == 0 )
    {
        //@@CAUTION
        //@@Descriptor Field - dwFrameIntervalStep
        //@@Suggestion to use descrite frames if dwFrameIntervalStep is zero
        AppendTextBuffer("*!*CAUTION:  dwFrameIntervalStep equals zero, consider using discrete frames\r\n");
        OOPS();
    }
    else if ((dwMaxFrameInterval - dwMinFrameInterval) % dwFrameIntervalStep )
    {
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the difference between dwMaxFrameInterval and dwMinFrameInterval is evenly divisible by dwFrameIntervalStep
        AppendTextBuffer("*!*WARNING:  dwMaxFrameInterval minus dwMinFrameInterval  is not evenly divisible by dwFrameIntervalStep, this could cause problems\r\n");
        OOPS();
    }

    if (dwFrameIntervalStep == 0 && (dwMaxFrameInterval - dwMinFrameInterval))
    {
        //@@WARNING
        //@@Descriptor Field - dwFrameIntervalStep, dwMinFrameInterval, and dwMaxFrameInterval
        //@@Verify that the dwFrameIntervalStep is not zero if there is a difference between dwMaxFrameInterval and dwMinFrameInterval
        AppendTextBuffer("*!*WARNING:  dwFrameIntervalStep = 0, this invalidates the descriptor when there is a difference between dwMinFrameInterval and dwMaxFrameInterval\r\n");
        OOPS();
    }

    return TRUE;
}

//*****************************************************************************
//
// DisplayFramePayloadDiscreteFrameType()
//
//*****************************************************************************

BOOL
DisplayFramePayloadDiscreteFrameType(
                              PVIDEO_FRAME_FRAME FDiscreteDesc
                              )
{
    //@@DisplayFramePayloadDiscreteFrameType -Frame Based Payload Discrete Frame
    UINT    iNdex = 1;
    UINT    iCurFrame = 0;
    ULONG   * ulFrameInterval = NULL;

    AppendTextBuffer("===>Additional Discrete Frame Type Data\r\n");

    // There are (UDiscreteDesc->bFrameIntervalType) dwFrameIntervals (1 based index)
    for (; iNdex <= FDiscreteDesc->bFrameIntervalType; iNdex++, iCurFrame++)
    {
        ulFrameInterval = &FDiscreteDesc->adwFrameInterval[iCurFrame];
        // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
        // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
        // = 1/10,000 milliseconds


        // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse
        AppendTextBuffer("dwFrameInterval[%d]:          0x%08X = %lf mSec (%4.2f Hz)\r\n", 
            iNdex, *ulFrameInterval,
            ((double)*ulFrameInterval)/10000.0,
            (10000000.0/((double)*ulFrameInterval))
            );
        if (0 == *ulFrameInterval)
        {
            //@@TestCase B18.1 (descript.c line 1061)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[x] must be non-zero
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[%d] must be non-zero\r\n", iNdex);
            OOPS();
        }
        if ((iNdex > 1)&&(*ulFrameInterval <= FDiscreteDesc->adwFrameInterval[iCurFrame - 1]))
        {
            //@@TestCase B18.2 (descript.c line 1067)
            //@@ERROR
            //@@Descriptor Field - dwFrameInterval[x]
            //@@dwFrameInterval[n] must be greater than dwFrameInterval[n - 1]
            AppendTextBuffer("*!*ERROR:  dwFrameInterval[0x%02X] must be "\
                "greater than preceding dwFrameInterval[0x%02X]\r\n", iNdex, iNdex - 1);
            OOPS();
        }
    }
    return TRUE;
}

//*****************************************************************************
//
// DisplayVSEndpoint()
//
//*****************************************************************************

BOOL
DisplayVSEndpoint (
                   PVIDEO_CS_INTERRUPT VidEndpointDesc
                   )
{
    //@@DisplayVSEndpoint - Video Streaming Endpoint
    AppendTextBuffer("\r\n          ===>Class-specific VC Interrupt Endpoint Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X \r\n", VidEndpointDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X\r\n", VidEndpointDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X\r\n", VidEndpointDesc->bDescriptorSubtype);
    AppendTextBuffer("wMaxTransferSize:                0x%04X", VidEndpointDesc->wMaxTransferSize);
    if(gDoAnnotation) {
        AppendTextBuffer(" = (%d) Bytes\r\n", VidEndpointDesc->wMaxTransferSize);}
    else {AppendTextBuffer("\r\n");}

    if (VidEndpointDesc->bLength != sizeof(VIDEO_CS_INTERRUPT))
    {
        //@@TestCase B32.1 (descript.c line 1616)
        //@@ERROR
        //@@Descriptor Field - bLength
        //@@The declared length in the device descriptor is not equal to the required length in the USB Video Device Specification
        AppendTextBuffer("*!*ERROR:  bLength of %d incorrect, should be %d.  USBView cannot correctly display descriptor\r\n",
            VidEndpointDesc->bLength,
            sizeof(VIDEO_CS_INTERRUPT));
        OOPS();
    }

    return TRUE;
}

//*****************************************************************************
//
// VDisplayBytes()
//
//*****************************************************************************

VOID
VDisplayBytes (
               PUCHAR Data,
               USHORT Len
               )
{
    USHORT i = 0;

    for (i = 0; i < Len; i++)
    {
        AppendTextBuffer("0x%02X ", Data[i]);

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

//*****************************************************************************
//
// VidFormatGUIDCodeToName()
//
//*****************************************************************************


PCHAR
VidFormatGUIDCodeToName (
                         REFGUID VidFormatGUIDCode
                         )
{
    //  GUID pYUY2 = YUY2_Format;
    //  GUID pNV12 = NV12_Format;
    if (IsEqualGUID(VidFormatGUIDCode, (REFGUID) &YUY2_Format))
    {
        return (PCHAR) &"YUY2";
    } 
    if (IsEqualGUID(VidFormatGUIDCode, (REFGUID) &NV12_Format))
    {
        return (PCHAR) &"NV12";
    } 
#ifdef H264_SUPPORT
    //  GUID pH264 = H264_Format;
    if (IsEqualGUID(VidFormatGUIDCode, (REFGUID) &H264_Format))
    {
        return (PCHAR) &"H.264";
    } 
#endif

    return FALSE;
}

/*****************************************************************************

GetVCInterfaceSize()

*****************************************************************************/

UINT
GetVCInterfaceSize (
                    PVIDEO_CONTROL_HEADER_UNIT VCInterfaceDesc
                   )
{
    PUSB_COMMON_DESCRIPTOR commonDesc = (PUSB_COMMON_DESCRIPTOR) VCInterfaceDesc;
    PUCHAR descEnd = (PUCHAR) VCInterfaceDesc + VCInterfaceDesc->wTotalLength;
    UINT  uCount = 0;

    // return this interface's sum of descriptor lengths
    //   starting from this header until (and not including) the first endpoint
    while ((PUCHAR)commonDesc + sizeof(USB_COMMON_DESCRIPTOR) < descEnd &&
        (PUCHAR)commonDesc + commonDesc->bLength <= descEnd)
    {
        if (commonDesc->bDescriptorType == USB_ENDPOINT_DESCRIPTOR_TYPE)
            break;
        uCount += commonDesc->bLength;
        commonDesc = (PUSB_COMMON_DESCRIPTOR) ((PUCHAR) commonDesc + commonDesc->bLength);
    }
    return (uCount);
}

/*****************************************************************************

CheckForColorMatchingDesc ()

Given starting address of format descriptor;
number of frame descriptors;
subtype of frame to look for;

1) walk through each descriptor
= if desc is frame of given subtype, update counter
= if desc is still frame, update counter
= if desc is color matching descriptor, update counter
! if frame is something else, break (all these frames should be consecutive)
! if next frame is beyond ending address of configuration, break

PASS
frame count == numframes passed in
color match == 1
still frames are handled in the video stream input header and the frame displays

*****************************************************************************/

UINT
CheckForColorMatchingDesc (
                           PVIDEO_SPECIFIC pFormatDesc,
                           UCHAR bNumFrameDescriptors,
                           UCHAR bDescriptorSubtype
                          )
{
    UINT  uFrameCount = 0;
    UINT  uStillFrameCount = 0;
    UINT  uColorCount = 0;

    // DONE if the descriptor address is beyond the configuration range
    for ( ; ValidateDescAddress ((PUSB_COMMON_DESCRIPTOR) pFormatDesc); )
    {
        // DONE if it's not an interface desc
        if (CS_INTERFACE != pFormatDesc->bDescriptorType)
        {
            break;
        }
        switch (pFormatDesc->bDescriptorSubtype)
        {
            case VS_STILL_IMAGE_FRAME:
                uStillFrameCount++;
                break;
            case VS_COLORFORMAT:
                uColorCount++;
                break;
            default:
                if (bDescriptorSubtype == pFormatDesc->bDescriptorSubtype)
                {
                    uFrameCount++;
                }
                break;
        }
        pFormatDesc = (PVIDEO_SPECIFIC) ((PUCHAR) pFormatDesc + pFormatDesc->bLength);
    }
    if (uFrameCount != bNumFrameDescriptors)
    {
        AppendTextBuffer("*!*ERROR:  Found %d frame descriptors (should be %d)\r\n",
            uFrameCount, bNumFrameDescriptors);
    }
    // We already check Still Frames in the Video Info Header and Still Frames displays
    if (0 == uColorCount)
    {
        AppendTextBuffer("*!*ERROR:  no Color Matching Descriptor for this format\r\n");
    }
    return (uColorCount);
}

/*****************************************************************************

GetVSInterfaceSize()

*****************************************************************************/

UINT
GetVSInterfaceSize (
                    PUSB_COMMON_DESCRIPTOR VidInHeaderDesc,
                    USHORT wTotalLength
                   )
{
    PUSB_COMMON_DESCRIPTOR commonDesc = (PUSB_COMMON_DESCRIPTOR) VidInHeaderDesc;
    PUCHAR descEnd = (PUCHAR) VidInHeaderDesc + wTotalLength;
    UINT  uCount = 0;

    // return this interface's sum of descriptor lengths
    //   starting from this header until (and not including) the first endpoint
    while ((PUCHAR)commonDesc + sizeof(USB_COMMON_DESCRIPTOR) < descEnd &&
        (PUCHAR)commonDesc + commonDesc->bLength <= descEnd)
    {
        if (commonDesc->bDescriptorType == USB_ENDPOINT_DESCRIPTOR_TYPE)
            break;
        uCount += commonDesc->bLength;
        commonDesc = (PUSB_COMMON_DESCRIPTOR) ((PUCHAR) commonDesc + commonDesc->bLength);
    }
    return (uCount);
}

/*****************************************************************************

ValidateTerminalID()

*****************************************************************************/

BOOL
ValidateTerminalID(
                   UINT uTerminalID
                   )
{
    UNREFERENCED_PARAMETER(uTerminalID);
    return (TRUE);
}
