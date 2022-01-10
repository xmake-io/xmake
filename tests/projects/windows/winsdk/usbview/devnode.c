/*++

  Copyright (c) 1998-2011 Microsoft Corporation

  Module Name:

  DEVNODE.C

  --*/

/*****************************************************************************
  I N C L U D E S
 *****************************************************************************/

#include "uvcview.h"

/*****************************************************************************

  DriverNameToDeviceInst()

  Finds the Device instance of the DevNode with the matching DriverName.
  Returns FALSE if the matching DevNode is not found and TRUE if found

 *****************************************************************************/
BOOL 
DriverNameToDeviceInst(
    _In_reads_bytes_(cbDriverName) PCHAR DriverName,
    _In_ size_t cbDriverName,
    _Out_ HDEVINFO *pDevInfo,
    _Out_writes_bytes_(sizeof(SP_DEVINFO_DATA)) PSP_DEVINFO_DATA pDevInfoData
    )
{
    HDEVINFO         deviceInfo = INVALID_HANDLE_VALUE;
    BOOL             status = TRUE;
    ULONG            deviceIndex;
    SP_DEVINFO_DATA  deviceInfoData;
    BOOL             bResult = FALSE;
    PCHAR            pDriverName = NULL;
    PSTR             buf = NULL;
    BOOL             done = FALSE;

    if (pDevInfo == NULL)
    {
        return FALSE;
    }

    if (pDevInfoData == NULL)
    {
        return FALSE;
    }

    memset(pDevInfoData, 0, sizeof(SP_DEVINFO_DATA));

    *pDevInfo = INVALID_HANDLE_VALUE;

    // Use local string to guarantee zero termination
    pDriverName = (PCHAR) ALLOC((DWORD) cbDriverName + 1);
    if (NULL == pDriverName)
    {
        status = FALSE;
        goto Done;
    }
    StringCbCopyN(pDriverName, cbDriverName + 1, DriverName, cbDriverName);

    //
    // We cannot walk the device tree with CM_Get_Sibling etc. unless we assume
    // the device tree will stabilize. Any devnode removal (even outside of USB)
    // would force us to retry. Instead we use Setup API to snapshot all
    // devices.
    //

    // Examine all present devices to see if any match the given DriverName
    //
    deviceInfo = SetupDiGetClassDevs(NULL,
            NULL,
            NULL,
            DIGCF_ALLCLASSES | DIGCF_PRESENT);

    if (deviceInfo == INVALID_HANDLE_VALUE)
    {
        status = FALSE;
        goto Done;
    }

    deviceIndex = 0;
    deviceInfoData.cbSize = sizeof(deviceInfoData);

    while (done == FALSE)
    {
        //
        // Get devinst of the next device
        //

        status = SetupDiEnumDeviceInfo(deviceInfo,
                                       deviceIndex,
                                       &deviceInfoData);

        deviceIndex++;

        if (!status)
        {
            //
            // This could be an error, or indication that all devices have been
            // processed. Either way the desired device was not found.
            //
            
            done = TRUE;
            break;
        }

        //
        // Get the DriverName value
        //

        bResult = GetDeviceProperty(deviceInfo,
                                    &deviceInfoData,
                                    SPDRP_DRIVER,
                                    &buf);
        
        // If the DriverName value matches, return the DeviceInstance
        //
        if (bResult == TRUE && buf != NULL && _stricmp(pDriverName, buf) == 0)
        {
            done = TRUE;
            *pDevInfo = deviceInfo;
            CopyMemory(pDevInfoData, &deviceInfoData, sizeof(deviceInfoData));
            FREE(buf);
            break;
        }

        if(buf != NULL)
        {
            FREE(buf);
            buf = NULL;
        }
    }

Done:

    if (bResult == FALSE)
    {
        if (deviceInfo != INVALID_HANDLE_VALUE)
        {
            SetupDiDestroyDeviceInfoList(deviceInfo);
        }
    }

    if (pDriverName != NULL)
    {
        FREE(pDriverName);
    }

    return status;
}

/*****************************************************************************

  DriverNameToDeviceProperties()

  Returns the Device properties of the DevNode with the matching DriverName.
  Returns NULL if the matching DevNode is not found.

  The caller should free the returned structure using FREE() macro

 *****************************************************************************/
PUSB_DEVICE_PNP_STRINGS 
DriverNameToDeviceProperties( 
        _In_reads_bytes_(cbDriverName) PCHAR  DriverName, 
        _In_ size_t cbDriverName
        )
{
    HDEVINFO        deviceInfo = INVALID_HANDLE_VALUE;
    SP_DEVINFO_DATA deviceInfoData = {0};
    ULONG           len;
    BOOL            status;
    PUSB_DEVICE_PNP_STRINGS DevProps = NULL;
    DWORD           lastError;

    // Allocate device propeties structure
    DevProps = (PUSB_DEVICE_PNP_STRINGS) ALLOC(sizeof(USB_DEVICE_PNP_STRINGS));

    if(NULL == DevProps)
    {
        status = FALSE;
        goto Done;
    }

    // Get device instance
    status = DriverNameToDeviceInst(DriverName, cbDriverName, &deviceInfo, &deviceInfoData);
    if (status == FALSE)
    {
        goto Done;
    }

    len = 0;
    status = SetupDiGetDeviceInstanceId(deviceInfo,
                                        &deviceInfoData,
                                        NULL,
                                        0,
                                        &len);
    lastError = GetLastError();

    
    if (status != FALSE && lastError != ERROR_INSUFFICIENT_BUFFER)
    {
        status = FALSE;
        goto Done;
    }
    
    //
    // An extra byte is required for the terminating character
    //
    
    len++;
    DevProps->DeviceId = ALLOC(len);

    if (DevProps->DeviceId == NULL)
    {
        status = FALSE;
        goto Done;
    }

    status = SetupDiGetDeviceInstanceId(deviceInfo,
                                        &deviceInfoData,
                                        DevProps->DeviceId,
                                        len,
                                        &len);
    if (status == FALSE)
    {
        goto Done;
    }

    status = GetDeviceProperty(deviceInfo,
                               &deviceInfoData,
                               SPDRP_DEVICEDESC,
                               &DevProps->DeviceDesc);
    
    if (status == FALSE)
    {
        goto Done;
    }
    

    //    
    // We don't fail if the following registry query fails as these fields are additional information only
    //

    GetDeviceProperty(deviceInfo,
                      &deviceInfoData,
                      SPDRP_HARDWAREID,
                      &DevProps->HwId);

    GetDeviceProperty(deviceInfo,
                      &deviceInfoData,
                      SPDRP_SERVICE,
                      &DevProps->Service);

    GetDeviceProperty(deviceInfo,
                       &deviceInfoData,
                       SPDRP_CLASS,
                       &DevProps->DeviceClass);
Done:

    if (deviceInfo != INVALID_HANDLE_VALUE)
    {
        SetupDiDestroyDeviceInfoList(deviceInfo);
    }

    if (status == FALSE)
    {
        if (DevProps != NULL)
        {
            FreeDeviceProperties(&DevProps);
        }
    }
    return DevProps;
}

/*****************************************************************************

  FreeDeviceProperties()

  Free the device properties structure

 *****************************************************************************/
VOID FreeDeviceProperties(_In_ PUSB_DEVICE_PNP_STRINGS *ppDevProps)
{
    if(ppDevProps == NULL)
    {
        return;
    }

    if(*ppDevProps == NULL)
    {
        return;
    }

    if ((*ppDevProps)->DeviceId != NULL)
    {
        FREE((*ppDevProps)->DeviceId);
    }

    if ((*ppDevProps)->DeviceDesc != NULL)
    {
        FREE((*ppDevProps)->DeviceDesc);
    }

    //
    // The following are not necessary, but left in case
    // in the future there is a later failure where these
    // pointer fields would be allocated.
    //

    if ((*ppDevProps)->HwId != NULL)
    {
        FREE((*ppDevProps)->HwId);
    }

    if ((*ppDevProps)->Service != NULL)
    {
        FREE((*ppDevProps)->Service);
    }

    if ((*ppDevProps)->DeviceClass != NULL)
    {
        FREE((*ppDevProps)->DeviceClass);
    }

    if ((*ppDevProps)->PowerState != NULL)
    {
        FREE((*ppDevProps)->PowerState);
    }

    FREE(*ppDevProps);
    *ppDevProps = NULL;
}
