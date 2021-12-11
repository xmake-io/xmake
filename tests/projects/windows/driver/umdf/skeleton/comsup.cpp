/*++

Copyright (C) Microsoft Corporation, All Rights Reserved

Module Name:

    ComSup.cpp

Abstract:

    This module contains implementations for the functions and methods 
    used for providing COM support.

Environment:

    Windows User-Mode Driver Framework (WUDF)

--*/

#include "internal.h"

#include "comsup.tmh"

//
// Implementation of CUnknown methods.
//

CUnknown::CUnknown(
    VOID
    ) : m_ReferenceCount(1)
/*++

  Routine Description:

    Constructor for an instance of the CUnknown class.  This simply initializes
    the reference count of the object to 1.  The caller is expected to 
    call Release() if it wants to delete the object once it has been allocated.

  Arguments:

    None

  Return Value:

    None

--*/
{
    // do nothing.
}

HRESULT
STDMETHODCALLTYPE
CUnknown::QueryInterface(
    _In_ REFIID InterfaceId,
    _Out_ PVOID *Object
    )
/*++
 
  Routine Description:

    This method provides the basic support for query interface on CUnknown.
    If the interface requested is IUnknown it references the object and 
    returns an interface pointer.  Otherwise it returns an error.

  Arguments:

    InterfaceId - the IID being requested

    Object - a location to store the interface pointer to return.

  Return Value:

    S_OK or E_NOINTERFACE

--*/
{
    if (IsEqualIID(InterfaceId, __uuidof(IUnknown)))
    {
        *Object = QueryIUnknown();
        return S_OK;
    }
    else
    {
        *Object = NULL;
        return E_NOINTERFACE;
    }
}

IUnknown *
CUnknown::QueryIUnknown(
    VOID
    )
/*++
 
  Routine Description:

    This helper method references the object and returns a pointer to the 
    object's IUnknown interface.

    This allows other methods to convert a CUnknown pointer into an IUnknown
    pointer without a typecast and without calling QueryInterface and dealing
    with the return value.

  Arguments:

    None

  Return Value:

    A pointer to the object's IUnknown interface.

--*/
{
    AddRef();
    return static_cast<IUnknown *>(this);
}

ULONG
STDMETHODCALLTYPE
CUnknown::AddRef(
    VOID
    )
/*++
 
  Routine Description:

    This method adds one to the object's reference count.

  Arguments:

    None

  Return Value:

    The new reference count.   The caller should only use this for debugging
    as the object's actual reference count can change while the caller
    examines the return value.

--*/
{
    return InterlockedIncrement(&m_ReferenceCount);
}

ULONG
STDMETHODCALLTYPE
CUnknown::Release(
    VOID
   )
/*++
 
  Routine Description:

    This method subtracts one to the object's reference count.  If the count
    goes to zero, this method deletes the object.

  Arguments:

    None

  Return Value:

    The new reference count.   If the caller uses this value it should only be
    to check for zero (i.e. this call caused or will cause deletion) or 
    non-zero (i.e. some other call may have caused deletion, but this one 
    didn't).

--*/
{
    ULONG count = InterlockedDecrement(&m_ReferenceCount);

    if (count == 0)
    {
        delete this;
    }
    return count;
}

//
// Implementation of CClassFactory methods.
//

//
// Define storage for the factory's static lock count variable.
//

LONG CClassFactory::s_LockCount = 0;

IClassFactory *
CClassFactory::QueryIClassFactory(
    VOID
    )
/*++
 
  Routine Description:

    This helper method references the object and returns a pointer to the 
    object's IClassFactory interface.

    This allows other methods to convert a CClassFactory pointer into an 
    IClassFactory pointer without a typecast and without dealing with the 
    return value QueryInterface.

  Arguments:

    None

  Return Value:

    A referenced pointer to the object's IClassFactory interface.

--*/
{
    AddRef();
    return static_cast<IClassFactory *>(this);
}

HRESULT
CClassFactory::QueryInterface(
    _In_ REFIID InterfaceId,
    _Out_ PVOID *Object
    )
/*++
 
  Routine Description:

    This method attempts to retrieve the requested interface from the object.

    If the interface is found then the reference count on that interface (and
    thus the object itself) is incremented.

  Arguments:

    InterfaceId - the interface the caller is requesting.

    Object - a location to store the interface pointer.

  Return Value:

    S_OK or E_NOINTERFACE

--*/
{
    //
    // This class only supports IClassFactory so check for that.
    //

    if (IsEqualIID(InterfaceId, __uuidof(IClassFactory)))
    {
        *Object = QueryIClassFactory();
        return S_OK;
    }
    else
    {
        //
        // See if the base class supports the interface.
        //

        return CUnknown::QueryInterface(InterfaceId, Object);
    }
}

HRESULT
STDMETHODCALLTYPE
CClassFactory::CreateInstance(
    _In_opt_ IUnknown * /* OuterObject */,
    _In_ REFIID InterfaceId,
    _Out_ PVOID *Object
    )
/*++
 
  Routine Description:

    This COM method is the factory routine - it creates instances of the driver
    callback class and returns the specified interface on them.

  Arguments:

    OuterObject - only used for aggregation, which our driver callback class
                  does not support.

    InterfaceId - the interface ID the caller would like to get from our 
                  new object.

    Object - a location to store the referenced interface pointer to the new
             object.

  Return Value:

    Status.

--*/
{
    HRESULT hr;

    PCMyDriver driver;

    *Object = NULL;

    hr = CMyDriver::CreateInstance(&driver);

    if (SUCCEEDED(hr)) 
    {
        hr = driver->QueryInterface(InterfaceId, Object);
        driver->Release();
    }

    return hr;
}

HRESULT
STDMETHODCALLTYPE
CClassFactory::LockServer(
    _In_ BOOL Lock
    )
/*++
 
  Routine Description:

    This COM method can be used to keep the DLL in memory.  However since the
    driver's DllCanUnloadNow function always returns false, this has little 
    effect.  Still it tracks the number of lock and unlock operations.

  Arguments:

    Lock - Whether the caller wants to lock or unlock the "server"

  Return Value:

    S_OK

--*/
{
    if (Lock)
    {
        InterlockedIncrement(&s_LockCount);
    } 
    else 
    {
        InterlockedDecrement(&s_LockCount);
    }
    return S_OK;
}

