/*++

Copyright (C) Microsoft Corporation, All Rights Reserved

Module Name:

    Device.h

Abstract:

    This module contains the type definitions for the UMDF Skeleton sample
    driver's device callback class.

Environment:

    Windows User-Mode Driver Framework (WUDF)

--*/

#pragma once

//
// Class for the iotrace driver.
//

class CMyDevice : public CUnknown
{

//
// Private data members.
//
private:

    IWDFDevice *m_FxDevice;

//
// Private methods.
//

private:

    CMyDevice(
        VOID
        )
    {
        m_FxDevice = NULL;
    }

    HRESULT
    Initialize(
        _In_ IWDFDriver *FxDriver,
        _In_ IWDFDeviceInitialize *FxDeviceInit
        );

//
// Public methods
//
public:

    //
    // The factory method used to create an instance of this driver.
    //
    
    static
    HRESULT
    CreateInstance(
        _In_ IWDFDriver *FxDriver,
        _In_ IWDFDeviceInitialize *FxDeviceInit,
        _Out_ PCMyDevice *Device
        );

    HRESULT
    Configure(
        VOID
        );

//
// COM methods
//
public:

    //
    // IUnknown methods.
    //

    virtual
    ULONG
    STDMETHODCALLTYPE
    AddRef(
        VOID
        )
    {
        return __super::AddRef();
    }

    _At_(this, __drv_freesMem(object))
    virtual
    ULONG
    STDMETHODCALLTYPE
    Release(
        VOID
       )
    {
        return __super::Release();
    }

    virtual
    HRESULT
    STDMETHODCALLTYPE
    QueryInterface(
        _In_ REFIID InterfaceId,
        _Out_ PVOID *Object
        );

};
