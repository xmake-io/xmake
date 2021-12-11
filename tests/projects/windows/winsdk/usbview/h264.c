//*****************************************************************************
// I N C L U D E S
//*****************************************************************************

#include "uvcview.h"
#include "h264.h"

#ifdef H264_SUPPORT

//*****************************************************************************
// G L O B A L S    
//*****************************************************************************
// H.264 format
UCHAR g_expectedNumberOfH264FrameDescriptors = 0;
UCHAR g_numberOfH264FrameDescriptors = 0;

// MJPEG format
UCHAR g_expectedNumberOfMJPEGFrameDescriptors = 0;
UCHAR g_numberOfMJPEGFrameDescriptors = 0;

// Uncompressed frame format
UCHAR g_expectedNumberOfUncompressedFrameFrameDescriptors = 0;
UCHAR g_numberOfUncompressedFrameFrameDescriptors = 0;

//*****************************************************************************
//
// external function prototypes 
//
//*****************************************************************************
extern VOID VDisplayBytes (PUCHAR Data, USHORT Len ); 

//*****************************************************************************
//
// H.264 video format descriptor string tables
//
//*****************************************************************************
STRINGLIST slSliceModes[]=
{
    {1,         "Maximum number of Macroblocks per slice mode",    ""},
    {2,         "Target compressed size per slice mode",           ""},
    {4,         "Number of slices per frame mode",                 ""},
    {8,         "Number of Macroblock rows per slice mode",        ""},
    {0x10,      "Reserved",                                        ""},
    {0x20,      "Reserved",                                        ""},
    {0x40,      "Reserved",                                        ""},
    {0x80,      "Reserved",                                        ""},
};

   
STRINGLIST slSyncFrameTypes[]=
{
    {1,         "Reset"           ,                                                                      ""},
    {2,         "IDR frame with SPS and PPS",                                                            ""},
    {4,         "IDR frame (with SPS and PPS) that is a long-term reference frame",                      ""},
    {8,         "Non-IDR random-access I frame (with SPS and PPS)",                                      ""},
    {0x10,      "Non-IDR random-access I frame (with SPS and PPS) that is a long-term reference frame",  ""},
    {0x20,      "P frame that is a long-term reference frame",                                           ""},
    {0x40,      "Gradual Decoder Refresh frames",                                                        ""},
    {0x80,      "Reserved",                                                                              ""},
};


//*****************************************************************************
//
// H.264 video frame rate descriptor string tables
//
//*****************************************************************************
STRINGLIST slUsage[]=
{
    {0x00000001,    "Real-time/UCConfig mode 0",        ""},  // 0
    {0x00000002,    "Real-time/UCConfig mode 1",        ""},
    {0x00000004,    "Real-time/UCConfig mode 2Q"        ""},
    {0x00000008,    "Real-time/UCConfig mode 2S"        ""},
    {0x00000010,    "Real-time/UCConfig mode 3",        ""},
    {0x00000020,    "Reserved",                         ""},
    {0x00000040,    "Reserved",                         ""},
    {0x00000080,    "Reserved",                         ""},

    {0x00000100,    "Broadcast mode 0",                ""}, // 8
    {0x00000200,    "Broadcast mode 1",                ""},
    {0x00000400,    "Broadcast mode 2",                ""},
    {0x00000800,    "Broadcast mode 3",                ""},
    {0x00001000,    "Broadcast mode 4",                ""},
    {0x00002000,    "Broadcast mode 5",                ""},
    {0x00004000,    "Broadcast mode 6",                ""},
    {0x00008000,    "Broadcast mode 7",                ""},

    {0x00010000,    "File Storage mode with I and P slices (e.g. IPPP)",            ""}, // 16
    {0x00020000,    "File Storage mode with I, P, and B slices (e.g. IB...BP)",     ""}, // 17
    {0x00040000,    "File storage all I frame mode",    ""}, // 18
    {0x00080000,    "Reserved",                         ""}, // 19
    {0x00100000,    "Reserved",                         ""}, // 20
    {0x00200000,    "Reserved",                         ""}, // 21
    {0x00400000,    "Reserved",                         ""}, // 22
    {0x00800000,    "Reserved",                         ""}, // 23

    {0x01000000,    "MVC Stereo High Mode",             ""}, // 24
    {0x02000000,    "MVC Multiview Mode",               ""}, // 25
    {0x04000000,    "Reserved",                         ""}, // 26
    {0x08000000,    "Reserved",                         ""}, // 27
    {0x10000000,    "Reserved",                         ""}, // 28
    {0x20000000,    "Reserved",                         ""}, // 29
    {0x40000000,    "Reserved",                         ""}, // 30
    {0x80000000,    "Reserved",                         ""}, // 31

 };
STRINGLIST slCapabilities[]=
{
    {0x0001,    "CAVLC only",                       ""},
    {0x0002,    "CABAC only",                       ""},
    {0x0004,    "Constant frame rate",              ""},
    {0x0008,    "Separate QP for luma/chroma",      ""},
    {0x0010,    "Separate QP for Cb/Cr",            ""},
    {0x0020,    "No picture reordering",            ""},
    {0x0040,    "Long-term reference frame",        ""},
    {0x0080,    "Reserved",                         ""},
    {0x0100,    "Reserved",                         ""},
    {0x0200,    "Reserved",                         ""},
    {0x0400,    "Reserved",                         ""},
    {0x0800,    "Reserved",                         ""},
    {0x1000,    "Reserved",                         ""},
    {0x2000,    "Reserved",                         ""},
    {0x4000,    "Reserved",                         ""},
    {0x8000,    "Reserved",                         ""},
 };



STRINGLIST slRateControlModes[]=
{
    {1,         "Variable Bit Rate (VBR) with underflow allowed (H.264 low_delay_hrd_flag = 1)",    ""},
    {2,         "Constant Bit Rate (CBR) (H.264 low_delay_hrd_flag = 0)",                           ""},
    {4,         "Constant QP",                                                                      ""},
    {8,         "Global VBR with underflow allowed (H.264 low_delay_hrd_flag = 1)",                 ""},
    {0x10,      "VBR without underflow (H.264 low_delay_hrd_flag = 0)",                             ""},
    {0x20,      "Global VBR without underflow (H.264 low_delay_hrd_flag = 0)",                      ""},
    {0x40,      "Reserved",                                                                         ""},
    {0x80,      "Reserved",                                                                         ""},
};


STRINGLIST slProfiles[]=
{
    {0x4200,    "Baseline Profile",                                 ""},
    {0x4240,    "Constrained Baseline Profile",                     ""},
    {0x4D00,    "Main Profile",                                     ""},
    {0x5300,    "Scalable Baseline Profile",                        ""},
    {0x5304,    "Scalable Constrained Baseline Profile",            ""},
    {0x5600,    "Scalable High Profile",                            ""},
    {0x5604,    "Scalable Constrained High Profile",                ""},
    {0x6400,    "High Profile",                                     ""},
    {0x640C,    "Constrained High Profile",                         ""},
    {0x7600,    "Multiview High Profile",                           ""},
    {0x8000,    "Stereo High Profile",                              ""},
 };

//*****************************************************************************
//
// H.264 video encoding unit descriptor string tables
//
//*****************************************************************************

STRINGLIST slEncodingUnitControls[]=
{
    {0x000001,    "Select Layer",                                     ""}, // D0
    {0x000002,    "Profile and Toolset",                              ""}, // D1
    {0x000004,    "Video Resolution",                                 ""}, // D2
    {0x000008,    "Minimum Frame Interval",                           ""}, // D3
    {0x000010,    "Slice Mode",                                       ""}, // D4
    {0x000020,    "Rate Control Mode",                                ""}, // D5
    {0x000040,    "Average Bit Rate",                                 ""}, // D6
    {0x000080,    "CPB Size        ",                                 ""}, // D7
    {0x000100,    "Peak Bit Rate",                                    ""}, // D8
    {0x000200,    "Quantization Parameter",                           ""}, // D9
    {0x000400,    "Synchronization and Long-Term Reference Frame",    ""}, // D10
    {0x000800,    "Long-Term Buffer Size",                            ""}, // D11
    {0x001000,    "Picture Long-Term Reference",                      ""}, // D12
    {0x002000,    "Valid LTR",                                        ""}, // D13
    {0x004000,    "Level IDC",                                        ""}, // D14
    {0x008000,    "SEI Message",                                      ""}, // D15
    {0x010000,    "QP Range",                                         ""}, // D16
    {0x020000,    "Priority ID",                                      ""}, // D17
    {0x040000,    "Start or Stop Layer/View",                         ""}, // D18
    {0x080000,    "Error Resiliency",                                 ""}, // D19
    {0x100000,    "Reserved",                                         ""}, // D20
    {0x200000,    "Reserved",                                         ""}, // D21
    {0x400000,    "Reserved",                                         ""}, // D22
    {0x800000,    "Reserved",                                         ""}, // D23
 };

//*****************************************************************************
//
// commaPrintNumber()
//
//*****************************************************************************
char * commaPrintNumber( ULONG number )
{
    static char comma = ',';
    static char retbuf[30];
    int digitCount = 0;

    // null-terminate the string
    char * pOutputString = &retbuf[ sizeof(retbuf)-1 ];
    *pOutputString = '\0';

    do 
    {
        // for every 3rd digit, add a comma to the output string
        if ( ( digitCount%3 ) == 0 && ( digitCount != 0 ) )
        {
            *--pOutputString = comma;
        }
        *--pOutputString = '0' + number % 10;
        number /= 10;
        digitCount++;
    } 
    while( number != 0 );

    return pOutputString;
}

//*****************************************************************************
//
// DisplayBitmapData()
//
// Note that USB is always oriented Little Endian (least significant byte
// at the lowest address).
//
// Inputs: 
// PUCHAR pData - pointer to least significant byte of the data 
// UCHAR  byteCount - number of bytes to print in the pData data buffer
// char * stringLabel - string label to print for user's to identify the data type  
//
//*****************************************************************************
void DisplayBitmapData(_In_reads_(byteCount) PUCHAR pData, UCHAR byteCount,  _In_ char * stringLabel)
{
    UCHAR byteIndex;
    UCHAR data;
    UCHAR mask;
    UCHAR bitIndex;
    UCHAR checkBit = 0; // the bit we want to print

    // print the label and all the bytes on the first line
    AppendTextBuffer("%s : ", stringLabel);
    VDisplayBytes( pData, byteCount );

    for ( byteIndex = 0; byteIndex < byteCount; byteIndex++ )
    {
        data = pData[ byteIndex ];
        checkBit = 0; // the control bit value we are going to print
        for ( mask = 1, bitIndex = 0; bitIndex < 8; bitIndex++ )
        {
            checkBit =  data & mask;
            AppendTextBuffer("     D%02d = %d  %s\r\n",
                bitIndex + 8 * byteIndex,   // increment bit count
                checkBit ? 1 : 0,
                checkBit ? "yes" : " no");
            mask = mask << 1;
        }

    }
}

//*****************************************************************************
//
// DisplayBitmapDataWithStrings()
//
// Note that USB is always oriented Little Endian (least significant byte
// at the lowest address).
//
// This calls GetSTringFromList() to insert a string that corresonds to
// the bit value being print.
//
// Inputs: 
// PUCHAR pData - pointer to least significant byte of the data 
// UCHAR  byteCount - number of bytes to print in the pData data buffer
// char * stringLabel - string label to print for user's to identify the data type  
// STRINGLIST stringList - string table in which to look up bitmap strings
// ULONG numEntriesInTable - number of entrys (strings) in the table
//*****************************************************************************
void DisplayBitmapDataWithStrings( _In_reads_(byteCount) PUCHAR pData, UCHAR byteCount,
                                   _In_ char * stringLabel,  _In_ PSTRINGLIST stringList,
                                   ULONG numEntriesInTable)
{

    UCHAR byteIndex;
    UCHAR data;
    UCHAR byteMask;
    ULONGLONG stringMask;
    UCHAR bitIndex;
    UCHAR checkBit = 0; // the bit we want to print

    // print the label and all the bytes on the first line
    AppendTextBuffer("%s : ", stringLabel);
    VDisplayBytes( pData, byteCount );

    for ( stringMask = 1, byteIndex = 0; byteIndex < byteCount; byteIndex++ )
    {
        data = pData[ byteIndex ];
        checkBit = 0; // the control bit value we are going to print
        for ( byteMask = 1, bitIndex = 0; bitIndex < 8; bitIndex++ )
        {
            checkBit =  data & byteMask;
            AppendTextBuffer("     D%02d = %d  %s %s\r\n",
                bitIndex + 8 * byteIndex, // increment bit count
                checkBit ? 1 : 0,
                checkBit ? "yes - " : " no - ",
                   GetStringFromList(stringList, 
                        numEntriesInTable,
                        stringMask, 
                        "Reserved"));

            byteMask = byteMask << 1;
            stringMask = stringMask << 1;
        }

    }
}

//*****************************************************************************
//
// DisplayVCH264Format()
//
//*****************************************************************************
BOOL DisplayVCH264Format( _In_reads_(sizeof(VIDEO_FORMAT_H264)) PVIDEO_FORMAT_H264 H264FormatDesc )
{
    if ( H264FormatDesc->bSimulcastSupport == 0 )
    {
        AppendTextBuffer("\r\n          ===>Video Streaming H.264 Format Type Descriptor<===\r\n");
    }
    else
    {
        AppendTextBuffer("\r\n          ===>Video Streaming H.264 Simulcast Format Type Descriptor<===\r\n");
    }
    AppendTextBuffer("bLength:                           0x%02X = %d\r\n", H264FormatDesc->bLength,               H264FormatDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X \r\n",     H264FormatDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X \r\n",     H264FormatDesc->bDescriptorSubtype);
    AppendTextBuffer("bFormatIndex:                      0x%02X = %d\r\n", H264FormatDesc->bFormatIndex,          H264FormatDesc->bFormatIndex);
    AppendTextBuffer("bNumFrameDescriptors:              0x%02X = %d\r\n", H264FormatDesc->bNumFrameDescriptors,  H264FormatDesc->bNumFrameDescriptors);
    AppendTextBuffer("bDefaultFrameIndex:                0x%02X = %d\r\n", H264FormatDesc->bDefaultFrameIndex,    H264FormatDesc->bDefaultFrameIndex);
    AppendTextBuffer("bMaxCodecConfigDelay:              0x%02X = %d frames\r\n", H264FormatDesc->bMaxCodecConfigDelay,  H264FormatDesc->bMaxCodecConfigDelay);
    DisplayBitmapDataWithStrings( H264FormatDesc->bmSupportedSliceModes,     sizeof(H264FormatDesc->bmSupportedSliceModes),     "bmSupportedSliceModes",    slSliceModes,     sizeof(slSliceModes)/sizeof(STRINGLIST) );
    DisplayBitmapDataWithStrings( H264FormatDesc->bmSupportedSyncFrameTypes,  sizeof(H264FormatDesc->bmSupportedSyncFrameTypes),  "bmSupportedSyncFrameTypes", slSyncFrameTypes, sizeof(slSyncFrameTypes)/sizeof(STRINGLIST) );

    // handle bResolutionScaling
    if (  H264FormatDesc->bResolutionScaling == 0 )
    {
         AppendTextBuffer("bResolutionScaling:         0x%02X = %d, Not Supported\r\n", 
            H264FormatDesc->bResolutionScaling, 
            H264FormatDesc->bResolutionScaling );
    }
    else if ( H264FormatDesc->bResolutionScaling == 1 )
     {
         AppendTextBuffer("bResolutionScaling:         0x%02X = %d, Limited to 1.5 or 2.0 scaling in both directions, while maintaining the aspect ratio.\r\n", 
            H264FormatDesc->bResolutionScaling, 
            H264FormatDesc->bResolutionScaling );
    }
    else if ( H264FormatDesc->bResolutionScaling == 2 )
     {
         AppendTextBuffer("bResolutionScaling:         0x%02X = %d, Limited to 1.0, 1.5 or 2.0 scaling in either direction.\r\n", 
            H264FormatDesc->bResolutionScaling, 
            H264FormatDesc->bResolutionScaling );
    }
    else if ( H264FormatDesc->bResolutionScaling == 3 )
     {
         AppendTextBuffer("bResolutionScaling:         0x%02X = %d, Limited to resolutions reported by the associated Frame Descriptors\r\n", 
            H264FormatDesc->bResolutionScaling, 
            H264FormatDesc->bResolutionScaling );
    }
    else if ( H264FormatDesc->bResolutionScaling == 4 )
     {
         AppendTextBuffer("bResolutionScaling:         0x%02X = %d, Arbitrary scaling\r\n", 
            H264FormatDesc->bResolutionScaling, 
            H264FormatDesc->bResolutionScaling );
    }
    else // 5 ... 255
    {
         AppendTextBuffer("bResolutionScaling:         0x%02X = %d, Reserved \r\n", 
            H264FormatDesc->bResolutionScaling, 
            H264FormatDesc->bResolutionScaling );
    }
 
     // handle bSimulcastSupport 
    if ( H264FormatDesc->bSimulcastSupport == 0 )
    {
        AppendTextBuffer("bSimulcastSupport:                 0x%02X = %d, one stream\r\n",
            H264FormatDesc->bSimulcastSupport,
            H264FormatDesc->bSimulcastSupport );
    }
    else if ( H264FormatDesc->bSimulcastSupport == 1 )
    {
        AppendTextBuffer("bSimulcastSupport:                 0x%02X = %d, multiple streams\r\n",
            H264FormatDesc->bSimulcastSupport,
            H264FormatDesc->bSimulcastSupport );
    }
    else // ( H264FormatDesc->bSimulcastSupport > 1 )
    {
        AppendTextBuffer("bSimulcastSupport:                 0x%02X = %d *!*ERROR:  unknown bSimulcastSupport \r\n",
            H264FormatDesc->bSimulcastSupport,
            H264FormatDesc->bSimulcastSupport,
            H264FormatDesc->bSimulcastSupport );
    }

    
    DisplayBitmapDataWithStrings( &(H264FormatDesc->bmSupportedRateControlModes), sizeof(H264FormatDesc->bmSupportedRateControlModes), "bmSupportedRateControlModes",   slRateControlModes, sizeof(slRateControlModes)/sizeof(STRINGLIST) );
   
    // Note that USB is Little Endian according to the UVC 2.0 spec


    // Resolutions with no scalability
    AppendTextBuffer("wMaxMBperSecOneResolutionNoScalability:                 0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecOneResolutionNoScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecOneResolutionNoScalability) );

    AppendTextBuffer("wMaxMBperSecTwoResolutionsNoScalability:                0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecTwoResolutionsNoScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecTwoResolutionsNoScalability) );

    AppendTextBuffer("wMaxMBperSecThreeResolutionsNoScalability:              0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecThreeResolutionsNoScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecThreeResolutionsNoScalability) );

    AppendTextBuffer("wMaxMBperSecFourResolutionsNoScalability:               0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecFourResolutionsNoScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecFourResolutionsNoScalability) );

    // Resolutions with temporal scalability
    AppendTextBuffer("wMaxMBperSecOneResolutionTemporalScalability:           0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecOneResolutionTemporalScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecOneResolutionTemporalScalability) );

    AppendTextBuffer("wMaxMBperSecTwoResolutionsTemporalScalability:          0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecTwoResolutionsTemporalScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecTwoResolutionsTemporalScalability) );

    AppendTextBuffer("wMaxMBperSecThreeResolutionsTemporalScalability:        0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecThreeResolutionsTemporalScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecThreeResolutionsTemporalScalability) );

    AppendTextBuffer("wMaxMBperSecFourResolutionsTemporalScalability:         0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecFourResolutionsTemporalScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecFourResolutionsTemporalScalability) );

    // Resolutions with temporal and quality scalability
    AppendTextBuffer("wMaxMBperSecOneResolutionTemporalQualityScalability:    0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecOneResolutionTemporalQualityScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecOneResolutionTemporalQualityScalability) );

    AppendTextBuffer("wMaxMBperSecTwoResolutionsTemporalQualityScalability:   0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecTwoResolutionsTemporalQualityScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecTwoResolutionsTemporalQualityScalability) );


    AppendTextBuffer("wMaxMBperSecThreeResolutionsTemporalQualityScalability: 0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecThreeResolutionsTemporalQualityScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecThreeResolutionsTemporalQualityScalability) );

    AppendTextBuffer("wMaxMBperSecFourResolutionsTemporalQualityScalability:  0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecFourResolutionsTemporalQualityScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecFourResolutionsTemporalQualityScalability) );

    // Resolutions with temporal and spatial scalability
    AppendTextBuffer("wMaxMBperSecOneResolutionTemporalSpatialScalability:    0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecOneResolutionTemporalSpatialScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecOneResolutionTemporalSpatialScalability) );

    AppendTextBuffer("wMaxMBperSecTwoResolutionsTemporalSpatialScalability:   0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecTwoResolutionsTemporalSpatialScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecTwoResolutionsTemporalSpatialScalability) );


    AppendTextBuffer("wMaxMBperSecThreeResolutionsTemporalSpatialScalability: 0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecThreeResolutionsTemporalSpatialScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecThreeResolutionsTemporalSpatialScalability) );

    AppendTextBuffer("wMaxMBperSecFourResolutionsTemporalSpatialScalability:  0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecFourResolutionsTemporalSpatialScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecFourResolutionsTemporalSpatialScalability) );

   // Resolutions with full scalability
    AppendTextBuffer("wMaxMBperSecOneResolutionFullScalability:               0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecOneResolutionFullScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecOneResolutionFullScalability) );

    AppendTextBuffer("wMaxMBperSecTwoResolutionsFullScalability:              0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecTwoResolutionsFullScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecTwoResolutionsFullScalability) );

    AppendTextBuffer("wMaxMBperSecThreeResolutionsFullScalability:            0x%04X (%s MB/sec)\r\n",
        H264FormatDesc->wMaxMBperSecThreeResolutionsFullScalability,
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecThreeResolutionsFullScalability) );

    AppendTextBuffer("wMaxMBperSecFourResolutionsFullScalability:             0x%04X (%s MB/sec)\r\n", 
        H264FormatDesc->wMaxMBperSecFourResolutionsFullScalability, 
        commaPrintNumber(1000*H264FormatDesc->wMaxMBperSecFourResolutionsFullScalability) );


    return TRUE;
}

//*****************************************************************************
//
// DisplayVCH264FrameType()
//
//*****************************************************************************
BOOL DisplayVCH264FrameType( _In_reads_(sizeof(VIDEO_FRAME_H264)) PVIDEO_FRAME_H264 H264FrameDesc )
{

    ULONG frameIntervalIndex;
    ULONG value;
    ULONG i;

    AppendTextBuffer("\r\n          ===>Video Streaming H.264 Frame Type Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X = %d\r\n", H264FrameDesc->bLength,            H264FrameDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X \r\n",     H264FrameDesc->bDescriptorType);
    AppendTextBuffer("bDescriptorSubtype:                0x%02X \r\n",     H264FrameDesc->bDescriptorSubtype);
    AppendTextBuffer("bFrameIndex:                       0x%02X = %d\r\n", H264FrameDesc->bFrameIndex,        H264FrameDesc->bFrameIndex);
    AppendTextBuffer("wWidth:                          0x%04X = %d\r\n", H264FrameDesc->wWidth,               H264FrameDesc->wWidth);
    AppendTextBuffer("wHeight:                         0x%04X = %d\r\n", H264FrameDesc->wHeight,              H264FrameDesc->wHeight);
    AppendTextBuffer("wSARwidth:                       0x%04X = %d\r\n", H264FrameDesc->wSARwidth,            H264FrameDesc->wSARwidth);
    AppendTextBuffer("wSARheight:                      0x%04X = %d\r\n", H264FrameDesc->wSARheight,           H264FrameDesc->wSARheight);
    AppendTextBuffer("wProfile:                        0x%04X - %s\r\n", H264FrameDesc->wProfile,
        GetStringFromList( slProfiles,                                  // string table                                    
                           sizeof(slProfiles)/sizeof(STRINGLIST),       // number of strings in the table
                           H264FrameDesc->wProfile,                     // index of string we want to look up in the string table
                           "Unknown profile" ) );                       // string to use if the lookup fails
   
    AppendTextBuffer("bLevelIDC:                       0x%02X = %d = Level %01.01lf \r\n", 
        H264FrameDesc->bLevelIDC, H264FrameDesc->bLevelIDC, H264FrameDesc->bLevelIDC/10.0 );
    
    AppendTextBuffer("wConstrainedToolset:             0x%04X %s\r\n", H264FrameDesc->wConstrainedToolset,
        ((H264FrameDesc->wConstrainedToolset == 0) ? "- Reserved" : "*!*ERROR: field is reserved and should be zero"));

    DisplayBitmapDataWithStrings( H264FrameDesc->bmSupportedUsages, sizeof(H264FrameDesc->bmSupportedUsages), "bmSupportedUsages", slUsage, sizeof(slUsage)/sizeof(STRINGLIST) );
    DisplayBitmapDataWithStrings( H264FrameDesc->bmCapabilities, sizeof(H264FrameDesc->bmCapabilities), "bmCapabilities",         slCapabilities, sizeof(slCapabilities)/sizeof(STRINGLIST) );
    

    // bmSVCCapabilities[4]      
    AppendTextBuffer("%s : ", "bmSVCCapabilities");
    VDisplayBytes( &(H264FrameDesc->bmSVCCapabilities[0]), sizeof(H264FrameDesc->bmSVCCapabilities)  );
    AppendTextBuffer("     D2..D0   = %d  Maximum number of temporal layers = %d\r\n", 
        H264FrameDesc->bmSVCCapabilities[0] & 0x7, 
        (H264FrameDesc->bmSVCCapabilities[0] & 0x7) + 1 );
    AppendTextBuffer("     D3       = %d %s - Rewrite Support\r\n", (H264FrameDesc->bmSVCCapabilities[0] & 0x8) >> 3,
        ((H264FrameDesc->bmSVCCapabilities[0] & 0x8) >> 3) ? "yes" : " no" );
    AppendTextBuffer("     D6..D4   = %d  Maximum number of CGS layers = %d\r\n", 
        (H264FrameDesc->bmSVCCapabilities[0] & 0x70) >> 4, 
        ((H264FrameDesc->bmSVCCapabilities[0] & 0x70) >> 4) + 1 );

    value = ( H264FrameDesc->bmSVCCapabilities[1] << 8 ) | H264FrameDesc->bmSVCCapabilities[0];
    value >>= 7;    // shift bit 7 right so that it ends up in the lsb of value
    value &= 0x7;
    AppendTextBuffer("     D9..D7   = %d  Number of MGS sublayers\r\n", value );

    AppendTextBuffer("     D10      = %d %s - Additional SNR scalability support in spatial enhancement layers\r\n",
        (H264FrameDesc->bmSVCCapabilities[1] & 0x4) >> 2,
        ((H264FrameDesc->bmSVCCapabilities[1] & 0x4) >> 2) ? "yes" : " no");
    AppendTextBuffer("     D13..D11 = %d  Maximum number of spatial layers = %d\r\n", 
        (H264FrameDesc->bmSVCCapabilities[1] & 0x38) >> 3, 
        ((H264FrameDesc->bmSVCCapabilities[1] & 0x38) >> 3) + 1 );

    value = ( H264FrameDesc->bmSVCCapabilities[3] << 16 ) | ( H264FrameDesc->bmSVCCapabilities[2] << 8 ) | H264FrameDesc->bmSVCCapabilities[1];
    value >>= 6; // get bit 14 at LSB
    for ( i = 0; i < 18; i++ )   // bits 31...14
    {    
        AppendTextBuffer("     D%02d      = %d %s - Reserved \r\n", 14 + i, value & 0x1, (value & 0x1) ? "yes" : " no"  );
        value >>= 1;
    }

    // bmMVCCapabilities[4]
    AppendTextBuffer("%s : ", "bmMVCCapabilities");
    VDisplayBytes( &(H264FrameDesc->bmMVCCapabilities[0]), sizeof(H264FrameDesc->bmMVCCapabilities)  );
    AppendTextBuffer("     D2..D0   = %d  Maximum number of temporal layers = %d\r\n", 
        H264FrameDesc->bmMVCCapabilities[0] & 0x7, 
        ((H264FrameDesc->bmMVCCapabilities[0] & 0x7) + 1) );

     value =  (H264FrameDesc->bmMVCCapabilities[1] << 8) |  H264FrameDesc->bmMVCCapabilities[0];
     value >>= 3;    // shift bit 3 right so that it ends up in the lsb of value
     value &= 0xff;
     AppendTextBuffer("     D10..D3  = %d  Maximum number of view components = %d\r\n", 
        value, value + 1);

     value = (  (H264FrameDesc->bmMVCCapabilities[3] << 16) | (H264FrameDesc->bmMVCCapabilities[2] << 8) |  H264FrameDesc->bmMVCCapabilities[1] );
     value >>= 3;    // shift bit 11 right so that it ends up in the lsb of value
     for ( i = 0; i < 21; i++ )   // bits 31...11
    {                    
        AppendTextBuffer("     D%02d      = %d %s - Reserved \r\n", 11 + i, value & 0x1, (value & 0x1) ? "yes" : " no" );
        value >>= 1;
    }


    AppendTextBuffer("dwMinBitRate:                    0x%08X  = %s bps\r\n", H264FrameDesc->dwMinBitRate, commaPrintNumber(H264FrameDesc->dwMinBitRate));
    AppendTextBuffer("dwMaxBitRate:                    0x%08X  = %s bps\r\n", H264FrameDesc->dwMaxBitRate, commaPrintNumber(H264FrameDesc->dwMaxBitRate));

    // To convert the default frame interval, which is in 100 ns units,  to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds

    AppendTextBuffer("dwDefaultFrameInterval:          0x%08X  = %lf mSec (%4.2f Hz) \r\n",
        H264FrameDesc->dwDefaultFrameInterval, ((double)H264FrameDesc->dwDefaultFrameInterval)/10000.0, (10000000.0/((double)H264FrameDesc->dwDefaultFrameInterval)));
    AppendTextBuffer("bNumFrameIntervals:              0x%02X = %d\r\n", H264FrameDesc->bNumFrameIntervals, H264FrameDesc->bNumFrameIntervals);


    // frame interval 100 ns units.  
    
    //To convert the frame interval to seconds we would divide by 10,000,000.
    // 100 ns = 10^(-7) seconds = 1/10,000,000 

    // To convert the frame interval to Hz, we divide by 10,000,000 and then take the inverse

    // To convert the frame interval to  milliseconds, we divide by 10,000.
    // 100 ns = 10^(-7) seconds = 10^(-7) sec * 1000 msec/sec = 10^(-7) * 10^3 milleseconds = 10^(-4) seconds
    // = 1/10,000 milliseconds

    for ( frameIntervalIndex = 0; frameIntervalIndex < H264FrameDesc->bNumFrameIntervals; frameIntervalIndex++ )
    {
        value = (ULONG)H264FrameDesc->dwFrameInterval[ frameIntervalIndex ];
        AppendTextBuffer("dwFrameInterval[%d]: 0x%08x = %lf mSec (%4.2f Hz)\r\n", frameIntervalIndex, value, ((double)value)/10000.0, (10000000.0/((double)value)) );

    }

    return TRUE;
}


//*****************************************************************************
//
// DisplayVCH264EncodingUnit()
//
//*****************************************************************************
BOOL DisplayVCH264EncodingUnit(
                        _In_reads_(sizeof(VIDEO_ENCODING_UNIT)) PVIDEO_ENCODING_UNIT VidEncodingDesc
        )
{

    PUCHAR pControlsRunTimeData = NULL;

    AppendTextBuffer("\r\n          ===>Video Control Encoding Unit Descriptor<===\r\n");
    AppendTextBuffer("bLength:                           0x%02X = %d\r\n", VidEncodingDesc->bLength,        VidEncodingDesc->bLength);
    AppendTextBuffer("bDescriptorType:                   0x%02X \r\n",     VidEncodingDesc->bDescriptorType );
    AppendTextBuffer("bDescriptorSubtype:                0x%02X \r\n",     VidEncodingDesc->bDescriptorSubtype );
    AppendTextBuffer("bUnitID:                           0x%02X = %d\r\n", VidEncodingDesc->bUnitID,        VidEncodingDesc->bUnitID);
    AppendTextBuffer("bSourceID:                         0x%02X = %d\r\n", VidEncodingDesc->bSourceID,      VidEncodingDesc->bSourceID);
    AppendTextBuffer("iEncoding:                         0x%02X = %d\r\n", VidEncodingDesc->iEncoding,      VidEncodingDesc->iEncoding);
    AppendTextBuffer("bControlSize:                      0x%02X = %d\r\n", VidEncodingDesc->bControlSize,   VidEncodingDesc->bControlSize);

    if ( VidEncodingDesc->bControlSize > 0)
    {
        // Encoding Unit Descriptor bmControls field
        DisplayBitmapDataWithStrings( VidEncodingDesc->bmControls, VidEncodingDesc->bControlSize /* print bControlSize bytes worth of bitmap info */,
            "bmControls", slEncodingUnitControls, sizeof(slEncodingUnitControls)/sizeof(STRINGLIST) );

        // Encoding Unit Descriptor bmControlsRuntime field
        pControlsRunTimeData = ((UCHAR *)(&VidEncodingDesc->bmControls)) + VidEncodingDesc->bControlSize;
        DisplayBitmapDataWithStrings( pControlsRunTimeData, VidEncodingDesc->bControlSize /* print bControlSize bytes worth of bitmap info */,
            "bmControlsRuntime", slEncodingUnitControls, sizeof(slEncodingUnitControls)/sizeof(STRINGLIST) );
    }
    return TRUE;
}

//*****************************************************************************
//
// DoAdditionalErrorChecks()
//
// Currently this function only checks to see that the number of frame
// descriptors actually found equals the number specified in the corresponding
// format descriptor.
//
// Because this potentially involves parsing multiple frame descriptors, we
// call this routine after the video descriptor has been parsed and displayed.
//
//*****************************************************************************
void DoAdditionalErrorChecks()
{
    if( g_expectedNumberOfH264FrameDescriptors > 0 || g_numberOfH264FrameDescriptors > 0
        || g_expectedNumberOfUncompressedFrameFrameDescriptors > 0 || g_numberOfUncompressedFrameFrameDescriptors > 0
        || g_expectedNumberOfMJPEGFrameDescriptors > 0 || g_numberOfMJPEGFrameDescriptors > 0)
    {
        AppendTextBuffer("\r\n          ===>Additional Error Checking<===\r\n");

        // H.264 frame descriptor
        if( g_expectedNumberOfH264FrameDescriptors > 0 || g_numberOfH264FrameDescriptors > 0)
        {
            if ( g_expectedNumberOfH264FrameDescriptors == g_numberOfH264FrameDescriptors )
            {
                AppendTextBuffer("PASS: number of H.264 frame descriptors (%d) == number of frame descriptors (%d) specified in H.264 format descriptor(s)\r\n",
                    g_expectedNumberOfH264FrameDescriptors, g_numberOfH264FrameDescriptors );
            }
            else
            {
                AppendTextBuffer("FAIL: number of H.264 frame descriptors (%d) != number of frame descriptors (%d) specified in H.264 format descriptor(s)\r\n",
                    g_expectedNumberOfH264FrameDescriptors, g_numberOfH264FrameDescriptors );
            }
        }

        // uncompressed frame descriptor
        if( g_expectedNumberOfUncompressedFrameFrameDescriptors > 0 || g_numberOfUncompressedFrameFrameDescriptors > 0)
        {

            if ( g_expectedNumberOfUncompressedFrameFrameDescriptors == g_numberOfUncompressedFrameFrameDescriptors )
            {
                AppendTextBuffer("PASS: number of uncompressed-frame frame descriptors (%d) == number of frame descriptors (%d) specified in uncompressed format descriptor(s)\r\n",
                    g_expectedNumberOfUncompressedFrameFrameDescriptors, g_numberOfUncompressedFrameFrameDescriptors );
            }
            else
            {
                AppendTextBuffer("FAIL: number of uncompressed-frame frame descriptors (%d) != number of frame descriptors (%d) specified in uncompressed format descriptor(s)\r\n",
                    g_expectedNumberOfUncompressedFrameFrameDescriptors, g_numberOfUncompressedFrameFrameDescriptors );
            }
        }

        // MJPEG frame descriptor
        if( g_expectedNumberOfMJPEGFrameDescriptors > 0 || g_numberOfMJPEGFrameDescriptors > 0)
        {
            if ( g_expectedNumberOfMJPEGFrameDescriptors == g_numberOfMJPEGFrameDescriptors )
            {
                AppendTextBuffer("PASS: number of MJPEG frame descriptors (%d) == number of frame descriptors (%d) specified in MJPEG format descriptor(s)\r\n",
                    g_expectedNumberOfMJPEGFrameDescriptors, g_numberOfMJPEGFrameDescriptors );
            }
            else
            {
                AppendTextBuffer("FAIL: number of MJPEG frame descriptors (%d) != number of frame descriptors (%d) specified in MJPEG format descriptor(s)\r\n",
                    g_expectedNumberOfMJPEGFrameDescriptors, g_numberOfMJPEGFrameDescriptors );
            }
        }
    }
}

//*****************************************************************************
//
// ResetErrorCounts()
//
//*****************************************************************************
void ResetErrorCounts()
{

    // H.264 format
    g_expectedNumberOfH264FrameDescriptors = 0;
    g_numberOfH264FrameDescriptors = 0;

    // MJPEG format
    g_expectedNumberOfMJPEGFrameDescriptors = 0;
    g_numberOfMJPEGFrameDescriptors = 0;

    // Uncompressed frame format
    g_expectedNumberOfUncompressedFrameFrameDescriptors = 0;
    g_numberOfUncompressedFrameFrameDescriptors = 0;
}

#endif //H264_SUPPORT
