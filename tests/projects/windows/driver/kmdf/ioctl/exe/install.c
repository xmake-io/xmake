/*++
Copyright (c) Microsoft Corporation.  All rights reserved.

    THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
    KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
    PURPOSE.

Module Name:

    install.c

Abstract:

    Win32 routines to dynamically load and unload a Windows NT kernel-mode
    driver using the Service Control Manager APIs.

Environment:

    User mode only

--*/


#include <DriverSpecs.h>
_Analysis_mode_(_Analysis_code_type_user_code_)

#include <windows.h>
#include <strsafe.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "public.h"

#include <wdfinstaller.h>

#define ARRAY_SIZE(x)        (sizeof(x) /sizeof(x[0]))

extern
PCHAR
GetCoinstallerVersion(
    VOID
    ) ;

BOOLEAN
InstallDriver(
    IN SC_HANDLE  SchSCManager,
    IN LPCTSTR    DriverName,
    IN LPCTSTR    ServiceExe
    );


BOOLEAN
RemoveDriver(
    IN SC_HANDLE  SchSCManager,
    IN LPCTSTR    DriverName
    );

BOOLEAN
StartDriver(
    IN SC_HANDLE  SchSCManager,
    IN LPCTSTR    DriverName
    );

BOOLEAN
StopDriver(
    IN SC_HANDLE  SchSCManager,
    IN LPCTSTR    DriverName
    );

#define SYSTEM32_DRIVERS "\\System32\\Drivers\\"
#define NONPNP_INF_FILENAME  L"\\nonpnp.inf"
#define WDF_SECTION_NAME L"nonpnp.NT.Wdf"

//----------------------------------------------------------------------------
//
//----------------------------------------------------------------------------
PFN_WDFPREDEVICEINSTALLEX pfnWdfPreDeviceInstallEx;
PFN_WDFPOSTDEVICEINSTALL   pfnWdfPostDeviceInstall;
PFN_WDFPREDEVICEREMOVE     pfnWdfPreDeviceRemove;
PFN_WDFPOSTDEVICEREMOVE   pfnWdfPostDeviceRemove;

//-----------------------------------------------------------------------------
// 4127 -- Conditional Expression is Constant warning
//-----------------------------------------------------------------------------
#define WHILE(a) \
__pragma(warning(suppress:4127)) while(a)

LONG
GetPathToInf(
    _Out_writes_(InfFilePathSize) PWCHAR InfFilePath,
    IN ULONG InfFilePathSize
    )
{
    LONG    error = ERROR_SUCCESS;

    if (GetCurrentDirectoryW(InfFilePathSize, InfFilePath) == 0) {
        error =  GetLastError();
        printf("InstallDriver failed!  Error = %d \n", error);
        return error;
    }
    if (FAILED( StringCchCatW(InfFilePath,
                              InfFilePathSize,
                              NONPNP_INF_FILENAME) )) {
        error = ERROR_BUFFER_OVERFLOW;
        return error;
    }
    return error;

}

//----------------------------------------------------------------------------
//
//----------------------------------------------------------------------------
BOOLEAN
InstallDriver(
    IN SC_HANDLE  SchSCManager,
    IN LPCTSTR    DriverName,
    IN LPCTSTR    ServiceExe
    )
/*++

Routine Description:

Arguments:

Return Value:

--*/
{
    SC_HANDLE   schService;
    DWORD       err;
    WCHAR      infPath[MAX_PATH];
    WDF_COINSTALLER_INSTALL_OPTIONS clientOptions;

    WDF_COINSTALLER_INSTALL_OPTIONS_INIT(&clientOptions);

    //
    // NOTE: This creates an entry for a standalone driver. If this
    //       is modified for use with a driver that requires a Tag,
    //       Group, and/or Dependencies, it may be necessary to
    //       query the registry for existing driver information
    //       (in order to determine a unique Tag, etc.).
    //
    //
    // PRE-INSTALL for WDF support
    //
    err = GetPathToInf(infPath, ARRAY_SIZE(infPath) );
    if (err != ERROR_SUCCESS) {
        return  FALSE;
    }
    err = pfnWdfPreDeviceInstallEx(infPath, WDF_SECTION_NAME, &clientOptions);

    if (err != ERROR_SUCCESS) {
        if (err == ERROR_SUCCESS_REBOOT_REQUIRED) {
            printf("System needs to be rebooted, before the driver installation can proceed.\n");
        }
        
        return  FALSE;
    }

    //
    // Create a new a service object.
    //

    schService = CreateService(SchSCManager,           // handle of service control manager database
                               DriverName,             // address of name of service to start
                               DriverName,             // address of display name
                               SERVICE_ALL_ACCESS,     // type of access to service
                               SERVICE_KERNEL_DRIVER,  // type of service
                               SERVICE_DEMAND_START,   // when to start service
                               SERVICE_ERROR_NORMAL,   // severity if service fails to start
                               ServiceExe,             // address of name of binary file
                               NULL,                   // service does not belong to a group
                               NULL,                   // no tag requested
                               NULL,                   // no dependency names
                               NULL,                   // use LocalSystem account
                               NULL                    // no password for service account
                               );

    if (schService == NULL) {

        err = GetLastError();

        if (err == ERROR_SERVICE_EXISTS) {

            //
            // Ignore this error.
            //

            return TRUE;

        } else {

            printf("CreateService failed!  Error = %d \n", err );

            //
            // Indicate an error.
            //

            return  FALSE;
        }
    }

    //
    // Close the service object.
    //
    CloseServiceHandle(schService);

    //
    // POST-INSTALL for WDF support
    //
    err = pfnWdfPostDeviceInstall( infPath, WDF_SECTION_NAME );

    if (err != ERROR_SUCCESS) {
        return  FALSE;
    }

    //
    // Indicate success.
    //

    return TRUE;

}   // InstallDriver

BOOLEAN
ManageDriver(
    IN LPCTSTR  DriverName,
    IN LPCTSTR  ServiceName,
    IN USHORT   Function
    )
{

    SC_HANDLE   schSCManager;

    BOOLEAN rCode = TRUE;

    //
    // Insure (somewhat) that the driver and service names are valid.
    //

    if (!DriverName || !ServiceName) {

        printf("Invalid Driver or Service provided to ManageDriver() \n");

        return FALSE;
    }

    //
    // Connect to the Service Control Manager and open the Services database.
    //

    schSCManager = OpenSCManager(NULL,                   // local machine
                                 NULL,                   // local database
                                 SC_MANAGER_ALL_ACCESS   // access required
                                 );

    if (!schSCManager) {

        printf("Open SC Manager failed! Error = %d \n", GetLastError());

        return FALSE;
    }

    //
    // Do the requested function.
    //

    switch( Function ) {

        case DRIVER_FUNC_INSTALL:

            //
            // Install the driver service.
            //

            if (InstallDriver(schSCManager,
                              DriverName,
                              ServiceName
                              )) {

                //
                // Start the driver service (i.e. start the driver).
                //

                rCode = StartDriver(schSCManager,
                                    DriverName
                                    );

            } else {

                //
                // Indicate an error.
                //

                rCode = FALSE;
            }

            break;

        case DRIVER_FUNC_REMOVE:

            //
            // Stop the driver.
            //

            StopDriver(schSCManager,
                       DriverName
                       );

            //
            // Remove the driver service.
            //

            RemoveDriver(schSCManager,
                         DriverName
                         );

            //
            // Ignore all errors.
            //

            rCode = TRUE;

            break;

        default:

            printf("Unknown ManageDriver() function. \n");

            rCode = FALSE;

            break;
    }

    //
    // Close handle to service control manager.
    //
    CloseServiceHandle(schSCManager);

    return rCode;

}   // ManageDriver


BOOLEAN
RemoveDriver(
    IN SC_HANDLE    SchSCManager,
    IN LPCTSTR      DriverName
    )
{
    SC_HANDLE   schService;
    BOOLEAN     rCode;
    DWORD       err;
    WCHAR      infPath[MAX_PATH];

    err = GetPathToInf(infPath, ARRAY_SIZE(infPath) );
    if (err != ERROR_SUCCESS) {
        return  FALSE;
    }

    //
    // PRE-REMOVE of WDF support
    //
    err = pfnWdfPreDeviceRemove( infPath, WDF_SECTION_NAME );

    if (err != ERROR_SUCCESS) {
        return  FALSE;
    }

    //
    // Open the handle to the existing service.
    //

    schService = OpenService(SchSCManager,
                             DriverName,
                             SERVICE_ALL_ACCESS
                             );

    if (schService == NULL) {

        printf("OpenService failed!  Error = %d \n", GetLastError());

        //
        // Indicate error.
        //

        return FALSE;
    }

    //
    // Mark the service for deletion from the service control manager database.
    //

    if (DeleteService(schService)) {

        //
        // Indicate success.
        //

        rCode = TRUE;

    } else {

        printf("DeleteService failed!  Error = %d \n", GetLastError());

        //
        // Indicate failure.  Fall through to properly close the service handle.
        //

        rCode = FALSE;
    }

    //
    // Close the service object.
    //
    CloseServiceHandle(schService);

    //
    // POST-REMOVE of WDF support
    //
    err = pfnWdfPostDeviceRemove(infPath, WDF_SECTION_NAME );

    if (err != ERROR_SUCCESS) {
        rCode = FALSE;
    }

    return rCode;

}   // RemoveDriver



BOOLEAN
StartDriver(
    IN SC_HANDLE    SchSCManager,
    IN LPCTSTR      DriverName
    )
{
    SC_HANDLE   schService;
    DWORD       err;
    BOOL        ok;

    //
    // Open the handle to the existing service.
    //
    schService = OpenService(SchSCManager,
                             DriverName,
                             SERVICE_ALL_ACCESS
                             );

    if (schService == NULL) {
        //
        // Indicate failure.
        //
        printf("OpenService failed!  Error = %d\n", GetLastError());
        return FALSE;
    }

    //
    // Start the execution of the service (i.e. start the driver).
    //
    ok = StartService( schService, 0, NULL );

    if (!ok) {

        err = GetLastError();

        if (err == ERROR_SERVICE_ALREADY_RUNNING) {
            //
            // Ignore this error.
            //
            return TRUE;

        } else {
            //
            // Indicate failure.
            // Fall through to properly close the service handle.
            //
            printf("StartService failure! Error = %d\n", err );
            return FALSE;
        }
    }

    //
    // Close the service object.
    //
    CloseServiceHandle(schService);

    return TRUE;

}   // StartDriver



BOOLEAN
StopDriver(
    IN SC_HANDLE    SchSCManager,
    IN LPCTSTR      DriverName
    )
{
    BOOLEAN         rCode = TRUE;
    SC_HANDLE       schService;
    SERVICE_STATUS  serviceStatus;

    //
    // Open the handle to the existing service.
    //

    schService = OpenService(SchSCManager,
                             DriverName,
                             SERVICE_ALL_ACCESS
                             );

    if (schService == NULL) {

        printf("OpenService failed!  Error = %d \n", GetLastError());

        return FALSE;
    }

    //
    // Request that the service stop.
    //

    if (ControlService(schService,
                       SERVICE_CONTROL_STOP,
                       &serviceStatus
                       )) {

        //
        // Indicate success.
        //

        rCode = TRUE;

    } else {

        printf("ControlService failed!  Error = %d \n", GetLastError() );

        //
        // Indicate failure.  Fall through to properly close the service handle.
        //

        rCode = FALSE;
    }

    //
    // Close the service object.
    //
    CloseServiceHandle (schService);

    return rCode;

}   //  StopDriver


//
// Caller must free returned pathname string.
//
PCHAR
BuildDriversDirPath(
    _In_ PSTR DriverName
    )
{
    size_t  remain;
    size_t  len;
    PCHAR   dir;

    if (!DriverName || strlen(DriverName) == 0) {
        return NULL;
    }

    remain = MAX_PATH;

    //
    // Allocate string space
    //
    dir = (PCHAR) malloc( remain + 1 );

    if (!dir) {
        return NULL;
    }

    //
    // Get the base windows directory path.
    //
    len = GetWindowsDirectory( dir, (UINT) remain );

    if (len == 0 ||
        (remain - len) < sizeof(SYSTEM32_DRIVERS)) {
        free(dir);
        return NULL;
    }
    remain -= len;

    //
    // Build dir to have "%windir%\System32\Drivers\<DriverName>".
    //
    if (FAILED( StringCchCat(dir, remain, SYSTEM32_DRIVERS) )) {
        free(dir);
        return NULL;
    }

    remain -= sizeof(SYSTEM32_DRIVERS);
    len    += sizeof(SYSTEM32_DRIVERS);
    len    += strlen(DriverName);

    if (remain < len) {
        free(dir);
        return NULL;
    }

    if (FAILED( StringCchCat(dir, remain, DriverName) )) {
        free(dir);
        return NULL;
    }

    dir[len] = '\0';  // keeps prefast happy

    return dir;
}


BOOLEAN
SetupDriverName(
    _Inout_updates_all_(BufferLength) PCHAR DriverLocation,
    _In_ ULONG BufferLength
    )
{
    HANDLE fileHandle;
    DWORD  driverLocLen = 0;
    BOOL   ok;
    PCHAR  driversDir;

    //
    // Setup path name to driver file.
    //
    driverLocLen =
        GetCurrentDirectory(BufferLength, DriverLocation);

    if (!driverLocLen) {

        printf("GetCurrentDirectory failed!  Error = %d \n",
               GetLastError());

        return FALSE;
    }

    if (FAILED( StringCchCat(DriverLocation, BufferLength, "\\" DRIVER_NAME ".sys") )) {
        return FALSE;
    }

    //
    // Insure driver file is in the specified directory.
    //
    fileHandle = CreateFile( DriverLocation,
                             GENERIC_READ,
                             FILE_SHARE_READ,
                             NULL,
                             OPEN_EXISTING,
                             FILE_ATTRIBUTE_NORMAL,
                             NULL );

    if (fileHandle == INVALID_HANDLE_VALUE) {
        //
        // Indicate failure.
        //
        printf("Driver: %s.SYS is not in the %s directory. \n",
               DRIVER_NAME, DriverLocation );
        return FALSE;
    }

    //
    // Build %windir%\System32\Drivers\<DRIVER_NAME> path.
    // Copy the driver to %windir%\system32\drivers
    //
    driversDir = BuildDriversDirPath( DRIVER_NAME ".sys" );

    if (!driversDir) {
        printf("BuildDriversDirPath failed!\n");
        return FALSE;
    }

    ok = CopyFile( DriverLocation, driversDir, FALSE );

    if(!ok) {
        printf("CopyFile failed: error(%d) - \"%s\"\n",
               GetLastError(), driversDir );
        free(driversDir);
        return FALSE;
    }

    if (FAILED( StringCchCopy(DriverLocation, BufferLength, driversDir) )) {
        free(driversDir);
        return FALSE;
    }

    free(driversDir);

    //
    // Close open file handle.
    //
    if (fileHandle) {
        CloseHandle(fileHandle);
    }

    //
    // Indicate success.
    //
    return TRUE;

}   // SetupDriverName


HMODULE
LoadWdfCoInstaller(
    VOID
    )
{
    HMODULE library = NULL;
    DWORD   error = ERROR_SUCCESS;
    CHAR   szCurDir[MAX_PATH];
    CHAR   tempCoinstallerName[MAX_PATH];
    PCHAR  coinstallerVersion;

    do {

        if (GetCurrentDirectory(MAX_PATH, szCurDir) == 0) {

            printf("GetCurrentDirectory failed!  Error = %d \n", GetLastError());
            break;
        }
        coinstallerVersion = GetCoinstallerVersion();
        if (FAILED( StringCchPrintf(tempCoinstallerName,
                                  MAX_PATH,
                                  "\\WdfCoInstaller%s.dll",
                                  coinstallerVersion) )) {
            break;
        }
        if (FAILED( StringCchCat(szCurDir, MAX_PATH, tempCoinstallerName) )) {
            break;
        }
        
        library = LoadLibrary(szCurDir);

        if (library == NULL) {
            error = GetLastError();
            printf("LoadLibrary(%s) failed: %d\n", szCurDir, error);
            break;
        }

        pfnWdfPreDeviceInstallEx =
            (PFN_WDFPREDEVICEINSTALLEX) GetProcAddress( library, "WdfPreDeviceInstallEx" );

        if (pfnWdfPreDeviceInstallEx == NULL) {
            error = GetLastError();
            printf("GetProcAddress(\"WdfPreDeviceInstallEx\") failed: %d\n", error);
            return NULL;
        }

        pfnWdfPostDeviceInstall =
            (PFN_WDFPOSTDEVICEINSTALL) GetProcAddress( library, "WdfPostDeviceInstall" );

        if (pfnWdfPostDeviceInstall == NULL) {
            error = GetLastError();
            printf("GetProcAddress(\"WdfPostDeviceInstall\") failed: %d\n", error);
            return NULL;
        }

        pfnWdfPreDeviceRemove =
            (PFN_WDFPREDEVICEREMOVE) GetProcAddress( library, "WdfPreDeviceRemove" );

        if (pfnWdfPreDeviceRemove == NULL) {
            error = GetLastError();
            printf("GetProcAddress(\"WdfPreDeviceRemove\") failed: %d\n", error);
            return NULL;
        }

        pfnWdfPostDeviceRemove =
            (PFN_WDFPREDEVICEREMOVE) GetProcAddress( library, "WdfPostDeviceRemove" );

        if (pfnWdfPostDeviceRemove == NULL) {
            error = GetLastError();
            printf("GetProcAddress(\"WdfPostDeviceRemove\") failed: %d\n", error);
            return NULL;
        }

    } WHILE (0);

    if (error != ERROR_SUCCESS) {
        if (library) {
            FreeLibrary( library );
        }
        library = NULL;
    }

    return library;
}


VOID
UnloadWdfCoInstaller(
    HMODULE Library
    )
{
    if (Library) {
        FreeLibrary( Library );
    }
}

