/*++

Copyright (c) Microsoft Corporation.  All rights reserved.

    THIS CODE AND INFORMATION IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
    KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
    PURPOSE.


Module Name:

    testapp.c

Abstract:

    Purpose of this app to test the NONPNP sample driver. The app
    makes four different ioctl calls to test all the buffer types, write
    some random buffer content to a file created by the driver in \SystemRoot\Temp
    directory, and reads the same file and matches the content.
    If -l option is specified, it does the write and read operation in a loop
    until the app is terminated by pressing ^C.

    Make sure you have the \SystemRoot\Temp directory exists before you run the test.

Environment:

    Win32 console application.

--*/

        
#include <DriverSpecs.h>
_Analysis_mode_(_Analysis_code_type_user_code_)  

#include <windows.h>

#pragma warning(disable:4201)  // nameless struct/union
#include <winioctl.h>
#pragma warning(default:4201)

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <limits.h>
#include <strsafe.h>
#include "public.h"


BOOLEAN
ManageDriver(
    IN LPCTSTR  DriverName,
    IN LPCTSTR  ServiceName,
    IN USHORT   Function
    );

HMODULE
LoadWdfCoInstaller(
    VOID
    );

VOID
UnloadWdfCoInstaller(
    HMODULE Library
    );

BOOLEAN
SetupDriverName(
    _Inout_updates_all_(BufferLength) PCHAR DriverLocation,
    _In_ ULONG BufferLength
    );

BOOLEAN
DoFileReadWrite(
    HANDLE HDevice
    );

VOID
DoIoctls(
    HANDLE hDevice
    );

// for example, WDF 1.9 is "01009". the size 6 includes the ending NULL marker
//
#define MAX_VERSION_SIZE 6

CHAR G_coInstallerVersion[MAX_VERSION_SIZE] = {0};
BOOLEAN  G_fLoop = FALSE;
BOOL G_versionSpecified = FALSE;



//-----------------------------------------------------------------------------
// 4127 -- Conditional Expression is Constant warning
//-----------------------------------------------------------------------------
#define WHILE(constant) \
__pragma(warning(disable: 4127)) while(constant); __pragma(warning(default: 4127))


#define USAGE  \
"Usage: nonpnpapp <-V version> <-l> \n" \
       " -V version  {if no version is specified the version specified in the build environment will be used.}\n" \
       "    The version is the version of the KMDF coinstaller to use \n"  \
       "    The format of version  is MMmmm where MM -- major #, mmm - serial# \n" \
       " -l  { option to continuously read & write to the file} \n"

BOOL
ValidateCoinstallerVersion(
    _In_ PSTR Version
    )
{   BOOL ok = FALSE;
    INT i;

    for(i= 0; i<MAX_VERSION_SIZE ;i++){
        if( ! IsCharAlphaNumericA(Version[i])) {
            break;
        }
    }
    if (i == (MAX_VERSION_SIZE -sizeof(CHAR))) {
        ok = TRUE;
    }
    return ok;
}

LONG
Parse(
    _In_ int argc,
    _In_reads_(argc) char *argv[]
    )
/*++
Routine Description:

    Called by main() to parse command line parms

Arguments:

    argc and argv that was passed to main()

Return Value:

    Sets global flags as per user function request

--*/
{
    int i;
    BOOL ok;
    LONG error = ERROR_SUCCESS;

    for (i=0; i<argc; i++) {
        if (argv[i][0] == '-' ||
            argv[i][0] == '/') {
            switch(argv[i][1]) {
            case 'V':
            case 'v':
                if (( (i+1 < argc ) &&
                      ( argv[i+1][0] != '-' && argv[i+1][0] != '/'))) {
                    //
                    // use version in commandline
                    //
                    i++;
                    ok = ValidateCoinstallerVersion(argv[i]);
                    if (!ok) {
                        printf("Not a valid format for coinstaller version\n"
                               "It should be characters between A-Z, a-z , 0-9\n"
                               "The version format is MMmmm where MM -- major #, mmm - serial#");
                        error = ERROR_INVALID_PARAMETER;
                        break;
                    }
                    if (FAILED( StringCchCopy(G_coInstallerVersion,
                                              MAX_VERSION_SIZE,
                                              argv[i]) )) {
                        break;
                    }
                    G_versionSpecified = TRUE;

                }
                else{
                    printf(USAGE);
                    error = ERROR_INVALID_PARAMETER;
                }
                break;
            case 'l':
            case 'L':
                G_fLoop = TRUE;
                break;
            default:
                printf(USAGE);
                error = ERROR_INVALID_PARAMETER;

            }
        }
    }
    return error;
}

PCHAR
GetCoinstallerVersion(
    VOID
    )
{
    if (!G_versionSpecified &&
        FAILED( StringCchPrintf(G_coInstallerVersion,
                                MAX_VERSION_SIZE,
                                "%02d%03d",    // for example, "01009"
                                KMDF_VERSION_MAJOR,
                                KMDF_VERSION_MINOR)))
    {
        printf("StringCchCopy failed with error \n");
    }

    return (PCHAR)&G_coInstallerVersion;
}

VOID __cdecl
main(
    _In_ ULONG argc,
    _In_reads_(argc) PCHAR argv[]
    )
{
    HANDLE   hDevice;
    DWORD    errNum = 0;
    CHAR     driverLocation [MAX_PATH];
    BOOL     ok;
    HMODULE  library = NULL;
    LONG     error;
    PCHAR    coinstallerVersion;

    //
    // Parse command line args
    //   -l     -- loop option
    //
    if ( argc > 1 ) {// give usage if invoked with no parms
        error = Parse(argc, argv);
        if (error != ERROR_SUCCESS) {
            return;
        }
    }

    if (!G_versionSpecified ) {
        coinstallerVersion = GetCoinstallerVersion();

        //
        // if no version is specified or an invalid one is specified use default version
        //
        printf("No version specified. Using default version:%s\n",
               coinstallerVersion);

    } else {
        coinstallerVersion = (PCHAR)&G_coInstallerVersion;
    }

    //
    // open the device
    //
    hDevice = CreateFile(DEVICE_NAME,
                         GENERIC_READ | GENERIC_WRITE,
                         0,
                         NULL,
                         CREATE_ALWAYS,
                         FILE_ATTRIBUTE_NORMAL,
                         NULL);

    if(hDevice == INVALID_HANDLE_VALUE) {

        errNum = GetLastError();

        if (!(errNum == ERROR_FILE_NOT_FOUND ||
                errNum == ERROR_PATH_NOT_FOUND)) {

            printf("CreateFile failed!  ERROR_FILE_NOT_FOUND = %d\n",
                   errNum);
            return ;
        }

        //
        // Load WdfCoInstaller.dll.
        //
        library = LoadWdfCoInstaller();

        if (library == NULL) {
            printf("The WdfCoInstaller%s.dll library needs to be "
                   "in same directory as nonpnpapp.exe\n", coinstallerVersion);
            return;
        }

        //
        // The driver is not started yet so let us the install the driver.
        // First setup full path to driver name.
        //
        ok = SetupDriverName( driverLocation, MAX_PATH );

        if (!ok) {
            return ;
        }

        ok = ManageDriver( DRIVER_NAME,
                           driverLocation,
                           DRIVER_FUNC_INSTALL );

        if (!ok) {

            printf("Unable to install driver. \n");

            //
            // Error - remove driver.
            //
            ManageDriver( DRIVER_NAME,
                          driverLocation,
                          DRIVER_FUNC_REMOVE );
            return;
        }

        hDevice = CreateFile( DEVICE_NAME,
                              GENERIC_READ | GENERIC_WRITE,
                              0,
                              NULL,
                              CREATE_ALWAYS,
                              FILE_ATTRIBUTE_NORMAL,
                              NULL );

        if (hDevice == INVALID_HANDLE_VALUE) {
            printf ( "Error: CreatFile Failed : %d\n", GetLastError());
            return;
        }
    }

    DoIoctls(hDevice);

    do {

        if(!DoFileReadWrite(hDevice)) {
            break;
        }

        if(!G_fLoop) {
            break;
        }
        Sleep(1000); // sleep for 1 sec.

    } WHILE (TRUE);

    //
    // Close the handle to the device before unloading the driver.
    //
    CloseHandle ( hDevice );

    //
    // Unload the driver.  Ignore any errors.
    //
    ManageDriver( DRIVER_NAME,
                  driverLocation,
                  DRIVER_FUNC_REMOVE );

    //
    // Unload WdfCoInstaller.dll
    //
    if ( library ) {
        UnloadWdfCoInstaller( library );
    }
    return;
}


VOID
DoIoctls(
    HANDLE hDevice
    )
{
    char OutputBuffer[100];
    char InputBuffer[200];
    BOOL bRc;
    ULONG bytesReturned;

    //
    // Printing Input & Output buffer pointers and size
    //

    printf("InputBuffer Pointer = %p, BufLength = %Id\n", InputBuffer,
                        sizeof(InputBuffer));
    printf("OutputBuffer Pointer = %p BufLength = %Id\n", OutputBuffer,
                                sizeof(OutputBuffer));
    //
    // Performing METHOD_BUFFERED
    //

    if(FAILED(StringCchCopy(InputBuffer, sizeof(InputBuffer),
        "this String is from User Application; using METHOD_BUFFERED"))){
        return;
    }

    printf("\nCalling DeviceIoControl METHOD_BUFFERED:\n");

    memset(OutputBuffer, 0, sizeof(OutputBuffer));

    bRc = DeviceIoControl ( hDevice,
                            (DWORD) IOCTL_NONPNP_METHOD_BUFFERED,
                            InputBuffer,
                            (DWORD) strlen( InputBuffer )+1,
                            OutputBuffer,
                            sizeof( OutputBuffer),
                            &bytesReturned,
                            NULL
                            );

    if ( !bRc )
    {
        printf ( "Error in DeviceIoControl : %d", GetLastError());
        return;

    }
    printf("    OutBuffer (%d): %s\n", bytesReturned, OutputBuffer);


    //
    // Performing METHOD_NIETHER
    //

    printf("\nCalling DeviceIoControl METHOD_NEITHER\n");

    if(FAILED(StringCchCopy(InputBuffer, sizeof(InputBuffer),
               "this String is from User Application; using METHOD_NEITHER"))) {
        return;
    }

    memset(OutputBuffer, 0, sizeof(OutputBuffer));

    bRc = DeviceIoControl ( hDevice,
                            (DWORD) IOCTL_NONPNP_METHOD_NEITHER,
                            InputBuffer,
                            (DWORD) strlen( InputBuffer )+1,
                            OutputBuffer,
                            sizeof( OutputBuffer),
                            &bytesReturned,
                            NULL
                            );

    if ( !bRc )
    {
        printf ( "Error in DeviceIoControl : %d\n", GetLastError());
        return;

    }

    printf("    OutBuffer (%d): %s\n", bytesReturned, OutputBuffer);

    //
    // Performing METHOD_IN_DIRECT
    //

    printf("\nCalling DeviceIoControl METHOD_IN_DIRECT\n");

    if(FAILED(StringCchCopy(InputBuffer, sizeof(InputBuffer),
               "this String is from User Application; using METHOD_IN_DIRECT"))) {
        return;
    }

    if(FAILED(StringCchCopy(OutputBuffer, sizeof(OutputBuffer),
               "This String is from User Application in OutBuffer; using METHOD_IN_DIRECT"))) {
        return;
    }

    bRc = DeviceIoControl ( hDevice,
                            (DWORD) IOCTL_NONPNP_METHOD_IN_DIRECT,
                            InputBuffer,
                            (DWORD) strlen( InputBuffer )+1,
                            OutputBuffer,
                            sizeof( OutputBuffer),
                            &bytesReturned,
                            NULL
                            );

    if ( !bRc )
    {
        printf ( "Error in DeviceIoControl : : %d", GetLastError());
        return;
    }

    printf("    Number of bytes transfered from OutBuffer: %d\n",
                                    bytesReturned);

    //
    // Performing METHOD_OUT_DIRECT
    //

    printf("\nCalling DeviceIoControl METHOD_OUT_DIRECT\n");
    if(FAILED(StringCchCopy(InputBuffer, sizeof(InputBuffer),
               "this String is from User Application; using METHOD_OUT_DIRECT"))){
        return;
    }

    memset(OutputBuffer, 0, sizeof(OutputBuffer));

    bRc = DeviceIoControl ( hDevice,
                            (DWORD) IOCTL_NONPNP_METHOD_OUT_DIRECT,
                            InputBuffer,
                            (DWORD) strlen( InputBuffer )+1,
                            OutputBuffer,
                            sizeof( OutputBuffer),
                            &bytesReturned,
                            NULL
                            );

    if ( !bRc )
    {
        printf ( "Error in DeviceIoControl : : %d", GetLastError());
        return;
    }

    printf("    OutBuffer (%d): %s\n", bytesReturned, OutputBuffer);

    return;

}


BOOLEAN
DoFileReadWrite(
    HANDLE HDevice
    )
{
    ULONG bufLength, index;
    PUCHAR readBuf = NULL;
    PUCHAR writeBuf = NULL;
    BOOLEAN ret;
    ULONG   bytesWritten, bytesRead;

    //
    // Seed the random-number generator with current time so that
    // the numbers will be different every time we run.
    //
    srand( (unsigned)time( NULL ) );

    //
    // rand function returns a pseudorandom integer in the range 0 to RAND_MAX
    // (0x7fff)
    //
    bufLength = rand();
    //
    // Try until the bufLength is not zero.
    //
    while(bufLength == 0) {
        bufLength = rand();
    }

    //
    // Allocate a buffer of that size to use for write operation.
    //
    writeBuf = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, bufLength);
    if(!writeBuf) {
        ret = FALSE;
        goto End;
    }
    //
    // Fill the buffer with randon number less than UCHAR_MAX.
    //
    index = bufLength;
    while(index){
        writeBuf[index-1] = (UCHAR) rand() % UCHAR_MAX;
        index--;
    }

    printf("Write %d bytes to file\n", bufLength);

    //
    // Tell the driver to write the buffer content to the file from the
    // begining of the file.
    //

    if (!WriteFile(HDevice,
                  writeBuf,
                  bufLength,
                  &bytesWritten,
                  NULL)) {

        printf("ReadFile failed with error 0x%x\n", GetLastError());

        ret = FALSE;
        goto End;

    }

    //
    // Allocate another buffer of same size.
    //
    readBuf = HeapAlloc(GetProcessHeap(), HEAP_ZERO_MEMORY, bufLength);
    if(!readBuf) {

        ret = FALSE;
        goto End;
    }

    printf("Read %d bytes from the same file\n", bufLength);

    //
    // Tell the driver to read the file from the begining.
    //
    if (!ReadFile(HDevice,
                  readBuf,
                  bufLength,
                  &bytesRead,
                  NULL)) {

        printf("Error: ReadFile failed with error 0x%x\n", GetLastError());

        ret = FALSE;
        goto End;

    }

    //
    // Now compare the readBuf and writeBuf content. They should be the same.
    //

    if(bytesRead != bytesWritten) {
        printf("bytesRead(%d) != bytesWritten(%d)\n", bytesRead, bytesWritten);
        ret = FALSE;
        goto End;
    }

    if(memcmp(readBuf, writeBuf, bufLength) != 0){
        printf("Error: ReadBuf and WriteBuf contents are not the same\n");
        ret = FALSE;
        goto End;
    }

    ret = TRUE;

End:

    if(readBuf){
        HeapFree (GetProcessHeap(), 0, readBuf);
    }

    if(writeBuf){
        HeapFree (GetProcessHeap(), 0, writeBuf);
    }

    return ret;


}


