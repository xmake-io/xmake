/*++

Copyright (c) Microsoft Corporation

Module Name:

    EchoApp.cpp

Abstract:

    An application to exercise the WDF "echo" sample driver.


Environment:

    user mode only

--*/


#include <DriverSpecs.h>
_Analysis_mode_(_Analysis_code_type_user_code_)

#define INITGUID

#include <windows.h>
#include <strsafe.h>
#include <cfgmgr32.h>
#include <stdio.h>
#include <stdlib.h>
#include "public.h"

#define NUM_ASYNCH_IO   100
#define BUFFER_SIZE     (40*1024)

#define READER_TYPE   1
#define WRITER_TYPE   2

#define MAX_DEVPATH_LENGTH                       256

BOOLEAN G_PerformAsyncIo;
BOOLEAN G_LimitedLoops;
ULONG G_AsyncIoLoopsNum;
WCHAR G_DevicePath[MAX_DEVPATH_LENGTH];


ULONG
AsyncIo(
    PVOID   ThreadParameter
    );

BOOLEAN
PerformWriteReadTest(
    IN HANDLE hDevice,
    IN ULONG TestLength
    );

BOOL
GetDevicePath(
    IN  LPGUID InterfaceGuid,
    _Out_writes_(BufLen) PWCHAR DevicePath,
    _In_ size_t BufLen
    );


int __cdecl
main(
    _In_ int argc,
    _In_reads_(argc) char* argv[]
    )
{
    HANDLE hDevice = INVALID_HANDLE_VALUE;
    HANDLE  th1 = NULL;
    BOOLEAN result = TRUE;


    if (argc > 1)  {
        if(!_strnicmp (argv[1], "-Async", 6) ) {
            G_PerformAsyncIo = TRUE;
            if (argc > 2) {
                G_AsyncIoLoopsNum = atoi(argv[2]);
                G_LimitedLoops = TRUE;
            }
            else {
                G_LimitedLoops = FALSE;
            }

        } else {
            printf("Usage:\n");
            printf("    Echoapp.exe         --- Send single write and read request synchronously\n");
            printf("    Echoapp.exe -Async  --- Send reads and writes asynchronously without terminating\n");
            printf("    Echoapp.exe -Async <number> --- Send <number> reads and writes asynchronously\n");
            printf("Exit the app anytime by pressing Ctrl-C\n");
            result = FALSE;
            goto exit;
        }
    }

    if ( !GetDevicePath(
            (LPGUID) &GUID_DEVINTERFACE_ECHO,
            G_DevicePath,
            sizeof(G_DevicePath)/sizeof(G_DevicePath[0])) )
    {
        result = FALSE;
        goto exit;
    }

    printf("DevicePath: %ws\n", G_DevicePath);

    hDevice = CreateFile(G_DevicePath,
                         GENERIC_READ|GENERIC_WRITE,
                         FILE_SHARE_READ | FILE_SHARE_WRITE,
                         NULL,
                         OPEN_EXISTING,
                         0,
                         NULL );

    if (hDevice == INVALID_HANDLE_VALUE) {
        printf("Failed to open device. Error %d\n",GetLastError());
        result = FALSE;
        goto exit;
    }

    printf("Opened device successfully\n");

    if(G_PerformAsyncIo) {

        printf("Starting AsyncIo\n");

        //
        // Create a reader thread
        //
        th1 = CreateThread( NULL,                   // Default Security Attrib.
                            0,                      // Initial Stack Size,
                            (LPTHREAD_START_ROUTINE) AsyncIo, // Thread Func
                            (LPVOID)READER_TYPE,
                            0,                      // Creation Flags
                            NULL );                 // Don't need the Thread Id.

        if (th1 == NULL) {
            printf("Couldn't create reader thread - error %d\n", GetLastError());
            result = FALSE;
            goto exit;
        }

        //
        // Use this thread for peforming write.
        //
        result = (BOOLEAN)AsyncIo((PVOID)WRITER_TYPE);

    }else {
        //
        // Write pattern buffers and read them back, then verify them
        //
        result = PerformWriteReadTest(hDevice, 512);
        if(!result) {
            goto exit;
        }

        result = PerformWriteReadTest(hDevice, 30*1024);
        if(!result) {
            goto exit;
        }

    }

exit:

    if (th1 != NULL) {
        WaitForSingleObject(th1, INFINITE);
        CloseHandle(th1);
    }

    if (hDevice != INVALID_HANDLE_VALUE) {
        CloseHandle(hDevice);
    }

    return ((result == TRUE) ? 0 : 1);

}

PUCHAR
CreatePatternBuffer(
    IN ULONG Length
    )
{
    unsigned int i;
    PUCHAR p, pBuf;

    pBuf = (PUCHAR)malloc(Length);
    if( pBuf == NULL ) {
        printf("Could not allocate %d byte buffer\n",Length);
        return NULL;
    }

    p = pBuf;

    for(i=0; i < Length; i++ ) {
        *p = (UCHAR)i;
        p++;
    }

    return pBuf;
}

BOOLEAN
VerifyPatternBuffer(
    _In_reads_bytes_(Length) PUCHAR pBuffer,
    _In_ ULONG Length
    )
{
    unsigned int i;
    PUCHAR p = pBuffer;

    for( i=0; i < Length; i++ ) {

        if( *p != (UCHAR)(i & 0xFF) ) {
            printf("Pattern changed. SB 0x%x, Is 0x%x\n",
                   (UCHAR)(i & 0xFF), *p);
            return FALSE;
        }

        p++;
    }

    return TRUE;
}

BOOLEAN
PerformWriteReadTest(
    IN HANDLE hDevice,
    IN ULONG TestLength
    )
/*
*/
{
    ULONG  bytesReturned =0;
    PUCHAR WriteBuffer = NULL,
                   ReadBuffer = NULL;
    BOOLEAN result = TRUE;

    WriteBuffer = CreatePatternBuffer(TestLength);
    if( WriteBuffer == NULL ) {

        result = FALSE;
        goto Cleanup;
    }

    ReadBuffer = (PUCHAR)malloc(TestLength);
    if( ReadBuffer == NULL ) {

        printf("PerformWriteReadTest: Could not allocate %d "
               "bytes ReadBuffer\n",TestLength);

         result = FALSE;
         goto Cleanup;

    }

    //
    // Write the pattern to the device
    //
    bytesReturned = 0;

    if (!WriteFile ( hDevice,
            WriteBuffer,
            TestLength,
            &bytesReturned,
            NULL)) {

        printf ("PerformWriteReadTest: WriteFile failed: "
                "Error %d\n", GetLastError());

        result = FALSE;
        goto Cleanup;

    } else {

        if( bytesReturned != TestLength ) {

            printf("bytes written is not test length! Written %d, "
                   "SB %d\n",bytesReturned, TestLength);

            result = FALSE;
            goto Cleanup;
        }

        printf ("%d Pattern Bytes Written successfully\n",
                bytesReturned);
    }

    bytesReturned = 0;

    if ( !ReadFile (hDevice,
            ReadBuffer,
            TestLength,
            &bytesReturned,
            NULL)) {

        printf ("PerformWriteReadTest: ReadFile failed: "
                "Error %d\n", GetLastError());

        result = FALSE;
        goto Cleanup;

    } else {

        if( bytesReturned != TestLength ) {

            printf("bytes Read is not test length! Read %d, "
                   "SB %d\n",bytesReturned, TestLength);

             //
             // Note: Is this a Failure Case??
             //
            result = FALSE;
            goto Cleanup;
        }

        printf ("%d Pattern Bytes Read successfully\n",bytesReturned);
    }

    //
    // Now compare
    //
    if( !VerifyPatternBuffer(ReadBuffer, TestLength) ) {

        printf("Verify failed\n");

        result = FALSE;
        goto Cleanup;
    }

    printf("Pattern Verified successfully\n");

Cleanup:

    //
    // Free WriteBuffer if non NULL.
    //
    if (WriteBuffer) {
        free (WriteBuffer);
    }

    //
    // Free ReadBuffer if non NULL
    //
    if (ReadBuffer) {
        free (ReadBuffer);
    }

    return result;
}

ULONG
AsyncIo(
    PVOID  ThreadParameter
    )
{
    HANDLE hDevice = INVALID_HANDLE_VALUE;
    HANDLE hCompletionPort = NULL;
    OVERLAPPED *pOvList = NULL;
    PUCHAR      buf = NULL;
    ULONG     numberOfBytesTransferred;
    OVERLAPPED *completedOv;
    ULONG_PTR    i;
    ULONG   ioType = (ULONG)(ULONG_PTR)ThreadParameter;
    ULONG_PTR   key;
    ULONG   error;
    BOOLEAN result = TRUE;
    ULONG maxPendingRequests = NUM_ASYNCH_IO;
    ULONG remainingRequestsToSend = 0;
    ULONG remainingRequestsToReceive = 0;

    hDevice = CreateFile(G_DevicePath,
                     GENERIC_WRITE|GENERIC_READ,
                     FILE_SHARE_READ | FILE_SHARE_WRITE,
                     NULL,
                     OPEN_EXISTING,
                     FILE_FLAG_OVERLAPPED,
                     NULL );


    if (hDevice == INVALID_HANDLE_VALUE) {
        printf("Cannot open %ws error %d\n", G_DevicePath, GetLastError());
        result = FALSE;
        goto Error;
    }

    hCompletionPort = CreateIoCompletionPort(hDevice, NULL, 1, 0);
    if (hCompletionPort == NULL) {
        printf("Cannot open completion port %d \n",GetLastError());
        result = FALSE;
        goto Error;
    }

    //
    // We will only have NUM_ASYNCH_IO or G_AsyncIoLoopsNum pending at any
    // time (whichever is less)
    //
    if (G_LimitedLoops == TRUE) {
        remainingRequestsToReceive = G_AsyncIoLoopsNum;
        if (G_AsyncIoLoopsNum > NUM_ASYNCH_IO) {
            //
            // After we send the initial NUM_ASYNCH_IO, we will have additional
            // (G_AsyncIoLoopsNum - NUM_ASYNCH_IO) I/Os to send
            //
            maxPendingRequests = NUM_ASYNCH_IO;
            remainingRequestsToSend = G_AsyncIoLoopsNum - NUM_ASYNCH_IO;
        }
        else {
            maxPendingRequests = G_AsyncIoLoopsNum;
            remainingRequestsToSend = 0;

        }
    }

    pOvList = (OVERLAPPED *)malloc(maxPendingRequests * sizeof(OVERLAPPED));
    if (pOvList == NULL) {
        printf("Cannot allocate overlapped array \n");
        result = FALSE;
        goto Error;
    }

    buf = (PUCHAR)malloc(maxPendingRequests * BUFFER_SIZE);
    if (buf == NULL) {
        printf("Cannot allocate buffer \n");
        result = FALSE;
        goto Error;
    }

    ZeroMemory(pOvList, maxPendingRequests * sizeof(OVERLAPPED));
    ZeroMemory(buf, maxPendingRequests * BUFFER_SIZE);

    //
    // Issue asynch I/O
    //

    for (i = 0; i < maxPendingRequests; i++) {
        if (ioType == READER_TYPE) {
            if ( ReadFile( hDevice,
                      buf + (i* BUFFER_SIZE),
                      BUFFER_SIZE,
                      NULL,
                      &pOvList[i]) == 0) {

                error = GetLastError();
                if (error != ERROR_IO_PENDING) {
                    printf(" %dth Read failed %d \n", (ULONG) i, GetLastError());
                    result = FALSE;
                    goto Error;
                }
            }

        } else {
            if ( WriteFile( hDevice,
                      buf + (i* BUFFER_SIZE),
                      BUFFER_SIZE,
                      NULL,
                      &pOvList[i]) == 0) {
                error = GetLastError();
                if (error != ERROR_IO_PENDING) {
                    printf(" %dth Write failed %d \n", (ULONG) i, GetLastError());
                    result = FALSE;
                    goto Error;
                }
            }
        }
    }

    //
    // Wait for the I/Os to complete. If one completes then reissue the I/O
    //

    WHILE (1) {

        if ( GetQueuedCompletionStatus(hCompletionPort, &numberOfBytesTransferred, &key, &completedOv, INFINITE) == 0) {
            printf("GetQueuedCompletionStatus failed %d\n", GetLastError());
            result = FALSE;
            goto Error;
        }

        //
        // Read successfully completed. If we're doing unlimited I/Os then Issue another one.
        //

        if (ioType == READER_TYPE) {

            i = completedOv - pOvList;
            printf("Number of bytes read by request number %Id is %d\n", i, numberOfBytesTransferred);

            //
            // If we're done with the I/Os, then exit
            //
            if (G_LimitedLoops == TRUE) {
                if ((--remainingRequestsToReceive) == 0) {
                    break;
                }

                if (remainingRequestsToSend == 0) {
                    continue;
                }
                else {
                    remainingRequestsToSend--;
                }
            }


            if ( ReadFile( hDevice,
                      buf + (i * BUFFER_SIZE),
                      BUFFER_SIZE,
                      NULL,
                      completedOv) == 0) {
                error = GetLastError();
                if (error != ERROR_IO_PENDING) {
                    printf("%Idth Read failed %d \n", i, GetLastError());
                    result = FALSE;
                    goto Error;
                }
            }
        } else {

            i = completedOv - pOvList;

            printf("Number of bytes written by request number %Id is %d\n", i, numberOfBytesTransferred);

            //
            // If we're done with the I/Os, then exit
            //
            if (G_LimitedLoops == TRUE) {
                if ((--remainingRequestsToReceive) == 0) {
                    break;
                }

                if (remainingRequestsToSend == 0) {
                    continue;
                }
                else {
                    remainingRequestsToSend--;
                }
            }


            if ( WriteFile( hDevice,
                      buf + (i * BUFFER_SIZE),
                      BUFFER_SIZE,
                      NULL,
                      completedOv) == 0) {
                error = GetLastError();
                if (error != ERROR_IO_PENDING) {

                    printf("%Idth write failed %d \n", i, GetLastError());
                    result = FALSE;
                    goto Error;
                }
            }
        }
    }

Error:
    if(hDevice != INVALID_HANDLE_VALUE) {
        CloseHandle(hDevice);
    }

    if(hCompletionPort) {
        CloseHandle(hCompletionPort);
    }

    if(buf) {
        free(buf);
    }
    if(pOvList) {
        free(pOvList);
    }

    return (ULONG)result;

}

BOOL
GetDevicePath(
    _In_ LPGUID InterfaceGuid,
    _Out_writes_(BufLen) PWCHAR DevicePath,
    _In_ size_t BufLen
    )
{
    CONFIGRET cr = CR_SUCCESS;
    PWSTR deviceInterfaceList = NULL;
    ULONG deviceInterfaceListLength = 0;
    PWSTR nextInterface;
    HRESULT hr = E_FAIL;
    BOOL bRet = TRUE;

    cr = CM_Get_Device_Interface_List_Size(
                &deviceInterfaceListLength,
                InterfaceGuid,
                NULL,
                CM_GET_DEVICE_INTERFACE_LIST_PRESENT);
    if (cr != CR_SUCCESS) {
        printf("Error 0x%x retrieving device interface list size.\n", cr);
        goto clean0;
    }

    if (deviceInterfaceListLength <= 1) {
        bRet = FALSE;
        printf("Error: No active device interfaces found.\n"
            " Is the sample driver loaded?");
        goto clean0;
    }

    deviceInterfaceList = (PWSTR)malloc(deviceInterfaceListLength * sizeof(WCHAR));
    if (deviceInterfaceList == NULL) {
        printf("Error allocating memory for device interface list.\n");
        goto clean0;
    }
    ZeroMemory(deviceInterfaceList, deviceInterfaceListLength * sizeof(WCHAR));

    cr = CM_Get_Device_Interface_List(
                InterfaceGuid,
                NULL,
                deviceInterfaceList,
                deviceInterfaceListLength,
                CM_GET_DEVICE_INTERFACE_LIST_PRESENT);
    if (cr != CR_SUCCESS) {
        printf("Error 0x%x retrieving device interface list.\n", cr);
        goto clean0;
    }

    nextInterface = deviceInterfaceList + wcslen(deviceInterfaceList) + 1;
    if (*nextInterface != UNICODE_NULL) {
        printf("Warning: More than one device interface instance found. \n"
            "Selecting first matching device.\n\n");
    }

    hr = StringCchCopy(DevicePath, BufLen, deviceInterfaceList);
    if (FAILED(hr)) {
        bRet = FALSE;
        printf("Error: StringCchCopy failed with HRESULT 0x%x", hr);
        goto clean0;
    }

clean0:
    if (deviceInterfaceList != NULL) {
        free(deviceInterfaceList);
    }
    if (CR_SUCCESS != cr) {
        bRet = FALSE;
    }

    return bRet;
}

