/*++

Copyright (c) 2003-2008 Microsoft Corporation

Module Name:

    LANGIDLIST.H

Abstract:

    This file LANGIDLIST.H contains content from USB.org, and was reviewed
    by LCA in June 2011. Per discussion with USB consortium counsel their
    material is "free to any use".

    This header file contains a list of all currently known USB Language IDs
    and the language name associated with each Language ID.



Source:
    http://www.usb.org

Environment:

    Kernel & user mode

Revision History:

    03-28-03 : created

--*/

#ifndef   __LANGIDLIST_H__
#define   __LANGIDLIST_H__

//
// Language ID structure
//
typedef struct {
    USHORT  usLangID;
    PCHAR   szLanguage;
} USBLANGID, *PUSBLANGID;

//
// This list built from information obtained on Nov-30-2000 from
// http://www.usb.org
//
// This information has not been independently verified and no claims
// are made here as to its accuracy.
//

USBLANGID USBLangIDs[] =
{
    {1078   , /*    0x0436  */ "Afrikaans"},
    {1052   , /*    0x041c  */ "Albanian"},
    {1025   , /*    0x0401  */ "Arabic (Saudi Arabia)"},
    {2049   , /*    0x0801  */ "Arabic (Iraq)"},
    {3073   , /*    0x0c01  */ "Arabic (Egypt)"},
    {4097   , /*    0x1001  */ "Arabic (Libya)"},
    {5121   , /*    0x1401  */ "Arabic (Algeria)"},
    {6145   , /*    0x1801  */ "Arabic (Morocco)"},
    {7169   , /*    0x1c01  */ "Arabic (Tunisia)"},
    {8193   , /*    0x2001  */ "Arabic (Oman)"},
    {9217   , /*    0x2401  */ "Arabic (Yemen)"},
    {10241  , /*    0x2801  */ "Arabic (Syria)"},
    {11265  , /*    0x2c01  */ "Arabic (Jordan)"},
    {12289  , /*    0x3001  */ "Arabic (Lebanon)"},
    {13313  , /*    0x3401  */ "Arabic (Kuwait)"},
    {14337  , /*    0x3801  */ "Arabic (U.A.E.)"},
    {15361  , /*    0x3c01  */ "Arabic (Bahrain)"},
    {16385  , /*    0x4001  */ "Arabic (Qatar)  "},
    {1067   , /*    0x042b  */ "Armenian"},
    {1101   , /*    0x044d  */ "Assamese"},
    {1068   , /*    0x042c  */ "Azeri (Latin)"},
    {2092   , /*    0x082c  */ "Azeri (Cyrillic)"},
    {1069   , /*    0x042d  */ "Basque"},
    {1059   , /*    0x0423  */ "Belarussian"},
    {1093   , /*    0x0445  */ "Bengali"},
    {1026   , /*    0x0402  */ "Bulgarian"},
    {1109   , /*    0x0455  */ "Burmese"},
    {1027   , /*    0x0403  */ "Catalan"},
    {1028   , /*    0x0404  */ "Chinese (Taiwan)"},
    {2052   , /*    0x0804  */ "Chinese (PRC)"},
    {3076   , /*    0x0c04  */ "Chinese (Hong Kong SAR, PRC)"},
    {4100   , /*    0x1004  */ "Chinese (Singapore)"},
    {5124   , /*    0x1404  */ "Chinese (MACAO SAR)"},
    {1050   , /*    0x041a  */ "Croatian"},
    {1029   , /*    0x0405  */ "Czech"},
    {1030   , /*    0x0406  */ "Danish"},
    {1043   , /*    0x0413  */ "Dutch (Netherlands)"},
    {2067   , /*    0x0813  */ "Dutch (Belgium)"},
    {1033   , /*    0x0409  */ "English (United States)"},
    {2057   , /*    0x0809  */ "English (United Kingdom)"},
    {3081   , /*    0x0c09  */ "English (Australian)"},
    {4105   , /*    0x1009  */ "English (Canadian)"},
    {5129   , /*    0x1409  */ "English (New Zealand)"},
    {6153   , /*    0x1809  */ "English (Ireland)"},
    {7177   , /*    0x1c09  */ "English (South Africa)"},
    {8201   , /*    0x2009  */ "English (Jamaica)"},
    {9225   , /*    0x2409  */ "English (Caribbean)"},
    {10249  , /*    0x2809  */ "English (Belize)"},
    {11273  , /*    0x2c09  */ "English (Trinidad)"},
    {12297  , /*    0x3009  */ "English (Zimbabwe)"},
    {13321  , /*    0x3409  */ "English (Philippines)"},
    {1061   , /*    0x0425  */ "Estonian"},
    {1080   , /*    0x0438  */ "Faeroese"},
    {1065   , /*    0x0429  */ "Farsi   "},
    {1035   , /*    0x040b  */ "Finnish"},
    {1036   , /*    0x040c  */ "French (Standard)"},
    {2060   , /*    0x080c  */ "French (Belgian)"},
    {3084   , /*    0x0c0c  */ "French (Canadian)"},
    {4108   , /*    0x100c  */ "French (Switzerland)"},
    {5132   , /*    0x140c  */ "French (Luxembourg)"},
    {6156   , /*    0x180c  */ "French (Monaco)"},
    {1079   , /*    0x0437  */ "Georgian"},
    {1031   , /*    0x0407  */ "German (Standard)"},
    {2055   , /*    0x0807  */ "German (Switzerland)"},
    {3079   , /*    0x0c07  */ "German (Austria)"},
    {4103   , /*    0x1007  */ "German (Luxembourg)"},
    {5127   , /*    0x1407  */ "German (Liechtenstein)"},
    {1032   , /*    0x0408  */ "Greek"},
    {1095   , /*    0x0447  */ "Gujarati"},
    {1037   , /*    0x040d  */ "Hebrew"},
    {1081   , /*    0x0439  */ "Hindi"},
    {1038   , /*    0x040e  */ "Hungarian"},
    {1039   , /*    0x040f  */ "Icelandic"},
    {1057   , /*    0x0421  */ "Indonesian"},
    {1040   , /*    0x0410  */ "Italian (Standard)"},
    {2064   , /*    0x0810  */ "Italian (Switzerland)"},
    {1041   , /*    0x0411  */ "Japanese"},
    {1099   , /*    0x044b  */ "Kannada"},
    {2144   , /*    0x0860  */ "Kashmiri (India)"},
    {1087   , /*    0x043f  */ "Kazakh"},
    {1111   , /*    0x0457  */ "Konkani"},
    {1042   , /*    0x0412  */ "Korean"},
    {2066   , /*    0x0812  */ "Korean (Johab)"},
    {1062   , /*    0x0426  */ "Latvian"},
    {1063   , /*    0x0427  */ "Lithuanian"},
    {2087   , /*    0x0827  */ "Lithuanian (Classic)"},
    {1071   , /*    0x042f  */ "Macedonia, Former Yugoslav Republic of"},
    {1086   , /*    0x043e  */ "Malay (Malaysian)"},
    {2110   , /*    0x083e  */ "Malay (Brunei Darussalam)"},
    {1100   , /*    0x044c  */ "Malayalam"},
    {1112   , /*    0x0458  */ "Manipuri"},
    {1102   , /*    0x044e  */ "Marathi"},
    {2145   , /*    0x0861  */ "Nepali (India)"},
    {1044   , /*    0x0414  */ "Norwegian (Bokmal)"},
    {2068   , /*    0x0814  */ "Norwegian (Nynorsk)"},
    {1096   , /*    0x0448  */ "Odia"},
    {1045   , /*    0x0415  */ "Polish"},
    {1046   , /*    0x0416  */ "Portuguese (Brazil)"},
    {2070   , /*    0x0816  */ "Portuguese (Portugal)"},
    {1094   , /*    0x0446  */ "Punjabi"},
    {1048   , /*    0x0418  */ "Romanian"},
    {1049   , /*    0x0419  */ "Russian"},
    {1103   , /*    0x044f  */ "Sanskrit"},
    {3098   , /*    0x0c1a  */ "Serbian (Cyrillic)"},
    {2074   , /*    0x081a  */ "Serbian (Latin)"},
    {1113   , /*    0x0459  */ "Sindhi"},
    {1051   , /*    0x041b  */ "Slovak"},
    {1060   , /*    0x0424  */ "Slovenian"},
    {1034   , /*    0x040a  */ "Spanish (Traditional Sort)"},
    {2058   , /*    0x080a  */ "Spanish (Mexican)"},
    {3082   , /*    0x0c0a  */ "Spanish (Modern Sort)"},
    {4106   , /*    0x100a  */ "Spanish (Guatemala)"},
    {5130   , /*    0x140a  */ "Spanish (Costa Rica)"},
    {6154   , /*    0x180a  */ "Spanish (Panama)"},
    {7178   , /*    0x1c0a  */ "Spanish (Dominican Republic)"},
    {8202   , /*    0x200a  */ "Spanish (Venezuela)"},
    {9226   , /*    0x240a  */ "Spanish (Colombia)"},
    {10250  , /*    0x280a  */ "Spanish (Peru)"},
    {11274  , /*    0x2c0a  */ "Spanish (Argentina)"},
    {12298  , /*    0x300a  */ "Spanish (Ecuador)"},
    {13322  , /*    0x340a  */ "Spanish (Chile)"},
    {14346  , /*    0x380a  */ "Spanish (Uruguay)"},
    {15370  , /*    0x3c0a  */ "Spanish (Paraguay)"},
    {16394  , /*    0x400a  */ "Spanish (Bolivia)"},
    {17418  , /*    0x440a  */ "Spanish (El Salvador)"},
    {18442  , /*    0x480a  */ "Spanish (Honduras)"},
    {19466  , /*    0x4c0a  */ "Spanish (Nicaragua)"},
    {20490  , /*    0x500a  */ "Spanish (Puerto Rico)"},
    {1072   , /*    0x0430  */ "Sutu"},
    {1089   , /*    0x0441  */ "Swahili (Kenya)"},
    {1053   , /*    0x041d  */ "Swedish"},
    {2077   , /*    0x081d  */ "Swedish (Finland)"},
    {1097   , /*    0x0449  */ "Tamil"},
    {1092   , /*    0x0444  */ "Tatar (Tatarstan)"},
    {1098   , /*    0x044a  */ "Telugu"},
    {1054   , /*    0x041e  */ "Thai"},
    {1055   , /*    0x041f  */ "Turkish"},
    {1058   , /*    0x0422  */ "Ukrainian"},
    {1056   , /*    0x0420  */ "Urdu (Pakistan)"},
    {2080   , /*    0x0820  */ "Urdu (India)"},
    {1091   , /*    0x0443  */ "Uzbek (Latin)"},
    {2115   , /*    0x0843  */ "Uzbek (Cyrillic)"},
    {1066   , /*    0x042a  */ "Vietnamese"},
    {1279   , /*    0x04ff  */ "HID (Usage Data Descriptor)"},
    {61695  , /*    0xf0ff  */ "HID (Vendor Defined 1)"},
    {62719  , /*    0xf4ff  */ "HID (Vendor Defined 2)"},
    {63743  , /*    0xf8ff  */ "HID (Vendor Defined 3)"},
    {64767  , /*    0xfcff  */ "HID (Vendor Defined 4)"},
    { 0x00, "End"}
};

#endif /* __LANGIDLIST_H__ */

