/*++

Copyright (C) Microsoft Corporation, All Rights Reserved

Module Name:

    ComSup.h

Abstract:

    This module contains classes and functions use for providing COM support
    code.

Environment:

    Windows User-Mode Driver Framework (WUDF)

--*/

#pragma once

//
// Forward type declarations.  They are here rather than in internal.h as
// you only need them if you choose to use these support classes.
//

typedef class CUnknown *PCUnknown;
typedef class CClassFactory *PCClassFactory;

//
// Base class to implement IUnknown.  You can choose to derive your COM
// classes from this class, or simply implement IUnknown in each of your
// classes.
//

class CUnknown : public IUnknown 
{

//
// Private data members and methods.  These are only accessible by the methods 
// of this class.
//
private:

    //
    // The reference count for this object.  Initialized to 1 in the
    // constructor.
    //

    LONG m_ReferenceCount;

//
// Protected data members and methods.  These are accessible by the subclasses 
// but not by other classes.
//
protected:

    //
    // The constructor and destructor are protected to ensure that only the 
    // subclasses of CUnknown can create and destroy instances.
    //

    CUnknown(
        VOID
        );

    //
    // The destructor MUST be virtual.  Since any instance of a CUnknown 
    // derived class should only be deleted from within CUnknown::Release, 
    // the destructor MUST be virtual or only CUnknown::~CUnknown will get
    // invoked on deletion.
    //
    // If you see that your CMyDevice specific destructor is never being
    // called, make sure you haven't deleted the virtual destructor here.
    //

    virtual 
    ~CUnknown(
        VOID
        )
    {
        // Do nothing
    }

//
// Public Methods.  These are accessible by any class.
//
public:

    IUnknown *
    QueryIUnknown(
        VOID
        );

//
// COM Methods.
//
public:

    //
    // IUnknown methods
    //

    virtual
    ULONG
    STDMETHODCALLTYPE
    AddRef(
        VOID
        );
    
    virtual
    ULONG
    STDMETHODCALLTYPE
    Release(
        VOID
       );

    virtual
    HRESULT
    STDMETHODCALLTYPE
    QueryInterface(
        _In_ REFIID InterfaceId,
        _Out_ PVOID *Object
        );
};

//
// Class factory support class.  Create an instance of this from your 
// DllGetClassObject method and modify the implementation to create 
// an instance of your driver event handler class.
//

class CClassFactory : public CUnknown, public IClassFactory 
{
//
// Private data members and methods.  These are only accessible by the methods 
// of this class.
//
private:

    //
    // The lock count.  This is shared across all instances of IClassFactory
    // and can be queried through the public IsLocked method.
    //

    static LONG s_LockCount;

//
// Public Methods.  These are accessible by any class.
//
public:

    IClassFactory *
    QueryIClassFactory(
        VOID
        );

//
// COM Methods.
//
public:

    //
    // IUnknown methods
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

    //
    // IClassFactory methods.
    //

    virtual
    HRESULT
    STDMETHODCALLTYPE
    CreateInstance(
        _In_opt_ IUnknown *OuterObject,
        _In_ REFIID InterfaceId,
        _Out_ PVOID *Object
        );

    virtual
    HRESULT
    STDMETHODCALLTYPE
    LockServer(
        _In_ BOOL Lock
        );
};
