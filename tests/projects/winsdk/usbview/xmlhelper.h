/*++

Copyright (c) 1997-2011 Microsoft Corporation

Module Name:

    XMLHELPER.H

Abstract:

    This helper file declaration for XML helper APIs

Environment:

    user mode

Revision History:

    05-05-11 : created

--*/

#pragma once

/*****************************************************************************
 I N C L U D E S
*****************************************************************************/
#include "uvcview.h"

EXTERN_C HRESULT InitXmlHelper();
EXTERN_C HRESULT ReleaseXmlWriter();
EXTERN_C HRESULT SaveXml(LPTSTR szfileName, DWORD dwCreationDisposition);
EXTERN_C HRESULT XmlAddHostController(
    PSTR hcName,
    PUSBHOSTCONTROLLERINFO hcInfo
    );
EXTERN_C HRESULT XmlAddRootHub(PSTR rhName, PUSBROOTHUBINFO rhInfo);
EXTERN_C HRESULT XmlAddExternalHub(PSTR ehName, PUSBEXTERNALHUBINFO ehInfo);
EXTERN_C HRESULT XmlAddUsbDevice(PSTR devName, PUSBDEVICEINFO deviceInfo);
EXTERN_C VOID XmlNotifyEndOfNodeList(PVOID pContext);

