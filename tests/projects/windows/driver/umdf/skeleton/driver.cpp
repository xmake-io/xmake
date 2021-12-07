/*++
 
Copyright (C) Microsoft Corporation, All Rights Reserved.

Module Name:

    Driver.cpp

Abstract:

    This module contains the implementation of the UMDF Skeleton Sample's 
    core driver callback object.

Environment:

   Windows User-Mode Driver Framework (WUDF)

--*/

#include "internal.h"
#include "driver.tmh"

HRESULT
CMyDriver::CreateInstance(
    _Out_ PCMyDriver *Driver
    )
/*++
 
  Routine Description:

    This static method is invoked in order to create and initialize a new 
    instance of the driver class.  The caller should arrange for the object
    to be released when it is no longer in use.

  Arguments:

    Driver - a location to store a referenced pointer to the new instance

  Return Value:

    S_OK if successful, or error otherwise.

--*/
{
    PCMyDriver driver;
    HRESULT hr;

    //
    // Allocate the callback object.
    //

    driver = new CMyDriver();

    if (NULL == driver)
    {
        return E_OUTOFMEMORY;
    }
        
    //
    // Initialize the callback object.
    //

    hr = driver->Initialize();

    if (SUCCEEDED(hr)) 
    {
        //
        // Store a pointer to the new, initialized object in the output 
        // parameter.
        //

        *Driver = driver;
    }
    else 
    {

        //
        // Release the reference on the driver object to get it to delete 
        // itself.
        //

        driver->Release();
    }

    return hr;
}

HRESULT
CMyDriver::Initialize(
    VOID
    )
/*++
 
  Routine Description:

    This method is called to initialize a newly created driver callback object
    before it is returned to the creator.  Unlike the constructor, the 
    Initialize method contains operations which could potentially fail.

  Arguments:

    None

  Return Value:

    None

--*/
{
    return S_OK;
}

HRESULT
CMyDriver::QueryInterface(
    _In_ REFIID InterfaceId,
    _Out_ PVOID *Interface
    )
/*++
 
  Routine Description:

    This method returns a pointer to the requested interface on the callback
    object..

  Arguments:

    InterfaceId - the IID of the interface to query/reference

    Interface - a location to store the interface pointer.

  Return Value:

    S_OK if the interface is supported.
    E_NOINTERFACE if it is not supported.

--*/
{
    if (IsEqualIID(InterfaceId, __uuidof(IDriverEntry)))
    {
        *Interface = QueryIDriverEntry();
        return S_OK;
    }
    else
    {
        return CUnknown::QueryInterface(InterfaceId, Interface);
    }
}

HRESULT
CMyDriver::OnDeviceAdd(
    _In_ IWDFDriver *FxWdfDriver,
    _In_ IWDFDeviceInitialize *FxDeviceInit
    )
/*++
 
  Routine Description:

    The FX invokes this method when it wants to install our driver on a device
    stack.  This method creates a device callback object, then calls the Fx
    to create an Fx device object and associate the new callback object with
    it.

  Arguments:

    FxWdfDriver - the Fx driver object.

    FxDeviceInit - the initialization information for the device.

  Return Value:

    status

--*/
{
    HRESULT hr;

    PCMyDevice device = NULL;

    //
    // TODO: Do any per-device initialization (reading settings from the 
    //       registry for example) that's necessary before creating your 
    //       device callback object here.  Otherwise you can leave such 
    //       initialization to the initialization of the device event 
    //       handler.
    //

    //
    // Create a new instance of our device callback object 
    //

    hr = CMyDevice::CreateInstance(FxWdfDriver, FxDeviceInit, &device);

    //
    // TODO: Change any per-device settings that the object exposes before
    //       calling Configure to let it complete its initialization.
    //

    //
    // If that succeeded then call the device's construct method.  This 
    // allows the device to create any queues or other structures that it
    // needs now that the corresponding fx device object has been created.
    //

    if (SUCCEEDED(hr)) 
    {
        hr = device->Configure();
    }

    // 
    // Release the reference on the device callback object now that it's been
    // associated with an fx device object.
    //

    if (NULL != device)
    {
        device->Release();
    }

    return hr;
}
