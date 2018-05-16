/*++
 
Copyright (C) Microsoft Corporation, All Rights Reserved.

Module Name:

    dllsup.cpp

Abstract:

    This module contains the implementation of the UMDF Skeleton Sample 
    Driver's entry point and its exported functions for providing COM support.

    This module can be copied without modification to a new UMDF driver.  It
    depends on some of the code in comsup.cpp & comsup.h to handle DLL 
    registration and creating the first class factory.

    This module is dependent on the following defines:

        MYDRIVER_TRACING_ID -      A wide string passed to WPP when initializing 
                                   tracing.  For example the skeleton uses 
                                   L"Microsoft\\UMDF\\Skeleton"

        MYDRIVER_CLASS_ID -   A GUID encoded in struct format used to 
                              initialize the driver's ClassID.     

    These are defined in internal.h for the sample.  If you choose
    to use a different primary include file, you should ensure they are 
    defined there as well.

Environment:

    WDF User-Mode Driver Framework (WDF:UMDF)

--*/

#include "internal.h"
#include "dllsup.tmh"

const GUID CLSID_MyDriverCoClass = MYDRIVER_CLASS_ID;

BOOL
WINAPI
DllMain(
    HINSTANCE ModuleHandle,
    DWORD Reason,
    PVOID /* Reserved */
   )
/*++

  Routine Description:

    This is the entry point and exit point for the I/O trace driver.  This 
    does very little as the I/O trace driver has minimal global data.

    This method initializes tracing.

  Arguments:

    ModuleHandle - the DLL handle for this module.

    Reason - the reason this entry point was called.

    Reserved - unused

  Return Value:

    TRUE

--*/
{

    UNREFERENCED_PARAMETER( ModuleHandle );

    if (DLL_PROCESS_ATTACH == Reason)
    {
        //
        // Initialize tracing.
        //

        WPP_INIT_TRACING(MYDRIVER_TRACING_ID);

    }
    else if (DLL_PROCESS_DETACH == Reason)
    {
        //
        // Cleanup tracing.
        //

        WPP_CLEANUP();
    }

    return TRUE;
}

HRESULT
STDAPICALLTYPE
DllGetClassObject(
    _In_ REFCLSID ClassId,
    _In_ REFIID InterfaceId,
    _Outptr_ LPVOID *Interface
    )
/*++

  Routine Description:

    This routine is called by COM in order to instantiate the 
    driver callback object and do an initial query interface on it.

    This method only creates an instance of the driver's class factory, as this
    is the minimum required to support UMDF.

  Arguments:

    ClassId - the CLSID of the object being "gotten"

    InterfaceId - the interface the caller wants from that object.

    Interface - a location to store the referenced interface pointer

  Return Value:

    S_OK if the function succeeds or error indicating the cause of the 
    failure.

--*/
{
    PCClassFactory factory;

    HRESULT hr = S_OK;

    *Interface = NULL;

    //
    // If the CLSID doesn't match that of our "coclass" (defined in the IDL 
    // file) then we can't create the object the caller wants.  This may 
    // indicate that the COM registration is incorrect, and another CLSID 
    // is referencing this drvier.
    //

    if (IsEqualCLSID(ClassId, CLSID_MyDriverCoClass) == false)
    {
        Trace(
            TRACE_LEVEL_ERROR,
            L"ERROR: Called to create instance of unrecognized class (%!GUID!)",
            &ClassId
            );

        return CLASS_E_CLASSNOTAVAILABLE;
    }

    //
    // Create an instance of the class factory for the caller.
    //

    factory = new CClassFactory();

    if (NULL == factory) 
    {
        hr = E_OUTOFMEMORY;
    }

    // 
    // Query the object we created for the interface the caller wants.  After
    // that we release the object.  This will drive the reference count to 
    // 1 (if the QI succeeded an referenced the object) or 0 (if the QI failed).
    // In the later case the object is automatically deleted.
    //

    if (SUCCEEDED(hr)) 
    {
        hr = factory->QueryInterface(InterfaceId, Interface);
        factory->Release();
    }

    return hr;
}
