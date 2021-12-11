#pragma once

#ifdef H264_SUPPORT

//*****************************************************************************
//
// external variables 
//
//*****************************************************************************
extern UCHAR g_expectedNumberOfH264FrameDescriptors;
extern UCHAR g_numberOfH264FrameDescriptors;

extern UCHAR g_expectedNumberOfMJPEGFrameDescriptors;
extern UCHAR g_numberOfMJPEGFrameDescriptors;

extern UCHAR g_expectedNumberOfUncompressedFrameFrameDescriptors;
extern UCHAR g_numberOfUncompressedFrameFrameDescriptors;

#endif



//*****************************************************************************
//
// defines
//
//*****************************************************************************

//Version information printed at lower left of UI Window and top of output text window
#define USBVIEW_MAJOR_VERSION   2
#define USBVIEW_MINOR_VERSION   0
#define UVC_SPEC_MAJOR_VERSION  1
#define UVC_SPEC_MINOR_VERSION  5


// definitions take from the proposed UVC 1.5 spec
#define VS_FORMAT_H264  0x13  
#define VS_FRAME_H264   0x14  


// Video Class-Specific VC Interface Descriptor Subtypes
// Note, this needs to be added to the list already in C:\nt\sdpublic\internal\drivers\inc\uvcdesc.h
// Also, note that MAX_TYPE_UNIT needs to be bumped up by 1 to account for this new subtype..
#define H264_ENCODING_UNIT 7

//*****************************************************************************
//
// struct definitions
//
//*****************************************************************************

// VideoStreaming H.264 Format Descriptor
#pragma pack(push, 1)       // pack on a 1 byte boundary
typedef struct _VIDEO_FORMAT_H264
{                                                                   // offset (in bytes):          
    UCHAR bLength;                                                  // 0
    UCHAR bDescriptorType;                                          // 1
    UCHAR bDescriptorSubtype;                                       // 2
    UCHAR bFormatIndex;                                             // 3
    UCHAR bNumFrameDescriptors;                                     // 4
    UCHAR bDefaultFrameIndex;                                       // 5
    UCHAR bMaxCodecConfigDelay;                                     // 6
    UCHAR bmSupportedSliceModes[1];                                 // 7
    UCHAR bmSupportedSyncFrameTypes[1];                             // 8
    UCHAR bResolutionScaling;                                       // 9
    UCHAR bSimulcastSupport;                                        // 10
    UCHAR bmSupportedRateControlModes;                              // 11

    USHORT wMaxMBperSecOneResolutionNoScalability;                  // 12
    USHORT wMaxMBperSecTwoResolutionsNoScalability;                 // 14
    USHORT wMaxMBperSecThreeResolutionsNoScalability;               // 16
    USHORT wMaxMBperSecFourResolutionsNoScalability;                // 18

    USHORT wMaxMBperSecOneResolutionTemporalScalability;             // 20
    USHORT wMaxMBperSecTwoResolutionsTemporalScalability;            // 22
    USHORT wMaxMBperSecThreeResolutionsTemporalScalability;          // 24
    USHORT wMaxMBperSecFourResolutionsTemporalScalability;           // 26

    USHORT wMaxMBperSecOneResolutionTemporalQualityScalability;      // 28
    USHORT wMaxMBperSecTwoResolutionsTemporalQualityScalability;     // 30
    USHORT wMaxMBperSecThreeResolutionsTemporalQualityScalability;   // 32
    USHORT wMaxMBperSecFourResolutionsTemporalQualityScalability;    // 34

    USHORT wMaxMBperSecOneResolutionTemporalSpatialScalability;      // 36
    USHORT wMaxMBperSecTwoResolutionsTemporalSpatialScalability;     // 38
    USHORT wMaxMBperSecThreeResolutionsTemporalSpatialScalability;   // 40
    USHORT wMaxMBperSecFourResolutionsTemporalSpatialScalability;    // 42

    USHORT wMaxMBperSecOneResolutionFullScalability;                 // 44
    USHORT wMaxMBperSecTwoResolutionsFullScalability;                // 46
    USHORT wMaxMBperSecThreeResolutionsFullScalability;              // 48
    USHORT wMaxMBperSecFourResolutionsFullScalability;               // 50
} VIDEO_FORMAT_H264, *PVIDEO_FORMAT_H264;
#pragma pack(pop)


// VideoStreaming H.264 Frame Descriptor
#pragma pack(push, 1)       // pack on a 1 byte boundary

// Disable warning on zero sized array in CPP compiler
#pragma warning(push)
#pragma warning(disable:4200) // Zero sized array

typedef struct _VIDEO_FRAME_H264
{                                               // offset (in bytes):          
    UCHAR  bLength;                             // 0
    UCHAR  bDescriptorType;                     // 1
    UCHAR  bDescriptorSubtype;                  // 2
    UCHAR  bFrameIndex;                         // 3
    USHORT wWidth;                              // 4
    USHORT wHeight;                             // 6
    USHORT wSARwidth;                           // 8
    USHORT wSARheight;                          // 10
    USHORT wProfile;                            // 12
    UCHAR  bLevelIDC;                           // 14
    USHORT wConstrainedToolset;                 // 15
    UCHAR  bmSupportedUsages[4];                // 17
    UCHAR  bmCapabilities[2];                   // 21
    UCHAR  bmSVCCapabilities[4];                // 23
    UCHAR  bmMVCCapabilities[4];                // 27
    ULONG  dwMinBitRate;                        // 31
    ULONG  dwMaxBitRate;                        // 35
    ULONG  dwDefaultFrameInterval;              // 39
    UCHAR  bNumFrameIntervals;                  // 43
    ULONG  dwFrameInterval[];                   // 44 variable-length parameter
} VIDEO_FRAME_H264, *PVIDEO_FRAME_H264;
#pragma warning(pop)
#pragma pack(pop)


// VideoControl Encoding Unit Descriptor
#pragma pack(push, 1)       // pack on a 1 byte boundary
#pragma warning(push)
#pragma warning(disable:4200) // Zero sized array
typedef struct //_VIDEO_ENCODING_UNIT
{                                               // offset (in bytes):           
    UCHAR bLength;                              // 0
    UCHAR bDescriptorType;                      // 1
    UCHAR bDescriptorSubtype;                   // 2
    UCHAR bUnitID;                              // 3
    UCHAR bSourceID;                            // 4
    UCHAR iEncoding;                            // 5
    UCHAR bControlSize;                         // 6
    UCHAR bmControls[];                         // 7 - variable-length parameter (bControlSize specifies the size)
} VIDEO_ENCODING_UNIT, *PVIDEO_ENCODING_UNIT;
// after bmControls[] there is also the variable-length parameter (bControlSize specifies the size:
// UCHAR bmControlsRunTime[]
#pragma warning(pop)
#pragma pack(pop)



//*****************************************************************************
//
// function prototypes
//
//*****************************************************************************
BOOL DisplayVCH264Format( _In_reads_(sizeof(VIDEO_FORMAT_H264)) PVIDEO_FORMAT_H264 H264FormatDesc );
BOOL DisplayVCH264FrameType( _In_reads_(sizeof(VIDEO_FRAME_H264)) PVIDEO_FRAME_H264 H264FrameDesc );
BOOL DisplayVCH264EncodingUnit( _In_reads_(sizeof(VIDEO_ENCODING_UNIT))  PVIDEO_ENCODING_UNIT VidEncodingDesc );
void DisplayBitmapData(  _In_reads_(byteCount) PUCHAR pData, UCHAR byteCount,  _In_ char * stringLabel);
void DisplayBitmapDataWithStrings(  _In_reads_(byteCount) PUCHAR pData, UCHAR byteCount,  _In_ char * stringLabel,  _In_ PSTRINGLIST stringList, ULONG numEntriesInTable );
void DoAdditionalErrorChecks();
void ResetErrorCounts();
