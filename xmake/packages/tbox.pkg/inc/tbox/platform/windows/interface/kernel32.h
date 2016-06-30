/*!The Treasure Box Library
 * 
 * TBox is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation; either version 2.1 of the License, or
 * (at your option) any later version.
 * 
 * TBox is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License
 * along with TBox; 
 * If not, see <a href="http://www.gnu.org/licenses/"> http://www.gnu.org/licenses/</a>
 * 
 * Copyright (C) 2009 - 2015, ruki All rights reserved.
 *
 * @author      ruki
 * @file        kernel32.h
 *
 */
#ifndef TB_PLATFORM_WINDOWS_INTERFACE_KERNEL32_H
#define TB_PLATFORM_WINDOWS_INTERFACE_KERNEL32_H

/* //////////////////////////////////////////////////////////////////////////////////////
 * includes
 */
#include "prefix.h"

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_enter__

/* //////////////////////////////////////////////////////////////////////////////////////
 * types
 */

// the OVERLAPPED_ENTRY type
typedef struct _tb_OVERLAPPED_ENTRY_t
{
    ULONG_PTR    lpCompletionKey;
    LPOVERLAPPED lpOverlapped;
    ULONG_PTR    Internal;
    DWORD        dwNumberOfBytesTransferred;

}tb_OVERLAPPED_ENTRY_t, *tb_LPOVERLAPPED_ENTRY_t;

// the GetQueuedCompletionStatusEx func type 
typedef BOOL (WINAPI* tb_kernel32_GetQueuedCompletionStatusEx_t)(HANDLE CompletionPort, tb_LPOVERLAPPED_ENTRY_t lpCompletionPortEntries, ULONG ulCount, PULONG ulNumEntriesRemoved, DWORD dwMilliseconds, BOOL fAlertable);

// the CancelIoEx func type
typedef BOOL (WINAPI* tb_kernel32_CancelIoEx_t)(HANDLE hFile, LPOVERLAPPED lpOverlapped);

// the RtlCaptureStackBackTrace func type
typedef USHORT (WINAPI* tb_kernel32_RtlCaptureStackBackTrace_t)(ULONG FramesToSkip, ULONG FramesToCapture, PVOID *BackTrace, PULONG BackTraceHash);

// the GetFileSizeEx func type
typedef BOOL (WINAPI* tb_kernel32_GetFileSizeEx_t)(HANDLE hFile, PLARGE_INTEGER lpFileSize);

// the InterlockedCompareExchange64 func type
typedef LONGLONG (WINAPI* tb_kernel32_InterlockedCompareExchange64_t)(LONGLONG __tb_volatile__* Destination, LONGLONG Exchange, LONGLONG Comparand);

// the GetEnvironmentVariableW func type
typedef DWORD (WINAPI* tb_kernel32_GetEnvironmentVariableW_t)(LPCWSTR lpName, LPWSTR lpBuffer, DWORD nSize);

// the SetEnvironmentVariableW func type
typedef BOOL (WINAPI* tb_kernel32_SetEnvironmentVariableW_t)(LPCWSTR lpName, LPCWSTR lpValue);

// the CreateProcessW func type
typedef BOOL (WINAPI* tb_kernel32_CreateProcessW_t)(LPCWSTR lpApplicationName, LPCWSTR lpCommandLine, LPSECURITY_ATTRIBUTES lpProcessAttributes, LPSECURITY_ATTRIBUTES lpThreadAttributes, BOOL bInheritHandles, DWORD dwCreationFlags, LPVOID lpEnvironment, LPCWSTR lpCurrentDirectory, LPSTARTUPINFO lpStartupInfo, LPPROCESS_INFORMATION lpProcessInformation);

// the CloseHandle func type
typedef BOOL (WINAPI* tb_kernel32_CloseHandle_t)(HANDLE hObject);

// the WaitForSingleObject func type
typedef DWORD (WINAPI* tb_kernel32_WaitForSingleObject_t)(HANDLE hHandle, DWORD dwMilliseconds);

// the GetExitCodeProcess func type
typedef BOOL (WINAPI* tb_kernel32_GetExitCodeProcess_t)(HANDLE hProcess, LPDWORD lpExitCode);

// the TerminateProcess func type
typedef BOOL (WINAPI* tb_kernel32_TerminateProcess_t)(HANDLE hProcess, UINT uExitCode);

// the SuspendThread func type
typedef DWORD (WINAPI* tb_kernel32_SuspendThread_t)(HANDLE hThread);

// the ResumeThread func type
typedef DWORD (WINAPI* tb_kernel32_ResumeThread_t)(HANDLE hThread);

// the GetEnvironmentStringsW func type
typedef LPWCH (WINAPI* tb_kernel32_GetEnvironmentStringsW_t)(tb_void_t);

// the FreeEnvironmentStringsW func type
typedef DWORD (WINAPI* tb_kernel32_FreeEnvironmentStringsW_t)(LPWCH lpszEnvironmentBlock);

// the SetHandleInformation func type
typedef BOOL (WINAPI* tb_kernel32_SetHandleInformation_t)(HANDLE hObject, DWORD dwMask, DWORD dwFlags);

// the kernel32 interfaces type
typedef struct __tb_kernel32_t
{
    // CancelIoEx
//    tb_kernel32_CancelIoEx_t                    CancelIoEx;

    // CaptureStackBackTrace
    tb_kernel32_RtlCaptureStackBackTrace_t      RtlCaptureStackBackTrace;

    // GetFileSizeEx
    tb_kernel32_GetFileSizeEx_t                 GetFileSizeEx;

    // GetQueuedCompletionStatusEx
    tb_kernel32_GetQueuedCompletionStatusEx_t   GetQueuedCompletionStatusEx;

    // InterlockedCompareExchange64
    tb_kernel32_InterlockedCompareExchange64_t  InterlockedCompareExchange64;

    // GetEnvironmentVariableW
    tb_kernel32_GetEnvironmentVariableW_t       GetEnvironmentVariableW;

    // SetEnvironmentVariableW
    tb_kernel32_SetEnvironmentVariableW_t       SetEnvironmentVariableW;

    // CreateProcessW
    tb_kernel32_CreateProcessW_t                CreateProcessW;

    // CloseHandle
    tb_kernel32_CloseHandle_t                   CloseHandle;

    // WaitForSingleObject
    tb_kernel32_WaitForSingleObject_t           WaitForSingleObject;

    // GetExitCodeProcess
    tb_kernel32_GetExitCodeProcess_t            GetExitCodeProcess;

    // TerminateProcess
    tb_kernel32_TerminateProcess_t              TerminateProcess;

    // SuspendThread
    tb_kernel32_SuspendThread_t                 SuspendThread;

    // ResumeThread
    tb_kernel32_ResumeThread_t                  ResumeThread;

    // GetEnvironmentStringsW
    tb_kernel32_GetEnvironmentStringsW_t        GetEnvironmentStringsW;

    // FreeEnvironmentStringsW
    tb_kernel32_FreeEnvironmentStringsW_t       FreeEnvironmentStringsW;

    // SetHandleInformation
    tb_kernel32_SetHandleInformation_t          SetHandleInformation;

}tb_kernel32_t, *tb_kernel32_ref_t;

/* //////////////////////////////////////////////////////////////////////////////////////
 * interfaces
 */

/* the kernel32 interfaces
 *
 * @return          the kernel32 interfaces pointer
 */
tb_kernel32_ref_t   tb_kernel32(tb_noarg_t);

/* //////////////////////////////////////////////////////////////////////////////////////
 * extern
 */
__tb_extern_c_leave__


#endif
