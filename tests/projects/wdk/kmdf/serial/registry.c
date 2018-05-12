/*++

Copyright (c) Microsoft Corporation

Module Name:

    registry.c

Abstract:

    This module contains the code that is used to get values from the
    registry and to manipulate entries in the registry.

Environment:

    Kernel mode

--*/

#include "precomp.h"

#if defined(EVENT_TRACING)
#include "registry.tmh"
#endif

#ifdef ALLOC_PRAGMA
#pragma alloc_text(INIT,SerialGetConfigDefaults)
#pragma alloc_text(PAGESRP0,SerialGetRegistryKeyValue)
#pragma alloc_text(PAGESRP0,SerialPutRegistryKeyValue)
#pragma alloc_text(PAGESRP0,SerialGetFdoRegistryKeyValue)
#endif // ALLOC_PRAGMA


#define PARAMATER_NAME_LEN 80


NTSTATUS
SerialGetConfigDefaults(
    IN PSERIAL_FIRMWARE_DATA    DriverDefaultsPtr,
    IN WDFDRIVER          Driver
    )

/*++

Routine Description:

    This routine reads the default configuration data from the
    registry for the serial driver.

    It also builds fields in the registry for several configuration
    options if they don't exist.

Arguments:

    DriverDefaultsPtr - Pointer to a structure that will contain
                        the default configuration values.

    RegistryPath - points to the entry for this driver in the
                   current control set of the registry.

Return Value:

    STATUS_SUCCESS if we got the defaults, otherwise we failed.
    The only way to fail this call is if the  STATUS_INSUFFICIENT_RESOURCES.

--*/

{

    NTSTATUS status = STATUS_SUCCESS;    // return value
    WDFKEY hKey;
    DECLARE_UNICODE_STRING_SIZE(valueName,PARAMATER_NAME_LEN);

    status = WdfDriverOpenParametersRegistryKey(Driver,
                                  STANDARD_RIGHTS_ALL,
                                  WDF_NO_OBJECT_ATTRIBUTES,
                                  &hKey);
    if (!NT_SUCCESS (status)) {
        return status;
    }

    status = RtlUnicodeStringPrintf(&valueName,L"BreakOnEntry");
    if (!NT_SUCCESS (status)) {
             goto End;

    }

    status = WdfRegistryQueryULong (hKey,
                              &valueName,
                              &DriverDefaultsPtr->ShouldBreakOnEntry);

    if (!NT_SUCCESS (status)) {
        DriverDefaultsPtr->ShouldBreakOnEntry = 0;
    }

    status = RtlUnicodeStringPrintf(&valueName,L"DebugLevel");
    if (!NT_SUCCESS (status)) {
            goto End;
    }

    status = WdfRegistryQueryULong (hKey,
                              &valueName,
                              &DriverDefaultsPtr->DebugLevel);

    if (!NT_SUCCESS (status)) {
        DriverDefaultsPtr->DebugLevel = 0;
    }


    status = RtlUnicodeStringPrintf(&valueName,L"ForceFifoEnable");
    if (!NT_SUCCESS (status)) {
            goto End;
    }

    status = WdfRegistryQueryULong (hKey,
              &valueName,
              &DriverDefaultsPtr->ForceFifoEnableDefault);

    if (!NT_SUCCESS (status)) {

        //
        // If it isn't then write out values so that it could
        // be adjusted later.
        //
        DriverDefaultsPtr->ForceFifoEnableDefault = SERIAL_FORCE_FIFO_DEFAULT;

        status = WdfRegistryAssignULong(hKey,
                            &valueName,
                            DriverDefaultsPtr->ForceFifoEnableDefault
                            );
        if (!NT_SUCCESS (status)) {
            goto End;
        }

    }

    status = RtlUnicodeStringPrintf(&valueName,L"RxFIFO");
    if (!NT_SUCCESS (status)) {
            goto End;
    }

    status = WdfRegistryQueryULong (hKey,
              &valueName,
              &DriverDefaultsPtr->RxFIFODefault);

    if (!NT_SUCCESS (status)) {

        DriverDefaultsPtr->RxFIFODefault = SERIAL_RX_FIFO_DEFAULT;

        status = WdfRegistryAssignULong(hKey,
                            &valueName,
                            DriverDefaultsPtr->RxFIFODefault
                            );
        if (!NT_SUCCESS (status)) {
            goto End;
        }

    }

    status = RtlUnicodeStringPrintf(&valueName,L"TxFIFO");
    if (!NT_SUCCESS (status)) {
            goto End;
    }

    status = WdfRegistryQueryULong (hKey,
              &valueName,
              &DriverDefaultsPtr->TxFIFODefault);

    if (!NT_SUCCESS (status)) {

        DriverDefaultsPtr->TxFIFODefault = SERIAL_TX_FIFO_DEFAULT;

        status = WdfRegistryAssignULong(hKey,
                            &valueName,
                            DriverDefaultsPtr->TxFIFODefault
                            );
        if (!NT_SUCCESS (status)) {
            goto End;
        }

    }

    status = RtlUnicodeStringPrintf(&valueName,L"PermitShare");
    if (!NT_SUCCESS (status)) {
            goto End;
    }

    status = WdfRegistryQueryULong (hKey,
              &valueName,
              &DriverDefaultsPtr->PermitShareDefault);

    if (!NT_SUCCESS (status)) {

        DriverDefaultsPtr->PermitShareDefault = SERIAL_PERMIT_SHARE_DEFAULT;

        status = WdfRegistryAssignULong(hKey,
                            &valueName,
                            DriverDefaultsPtr->PermitShareDefault
                            );
        if (!NT_SUCCESS (status)) {
            goto End;
        }

    }

    status = RtlUnicodeStringPrintf(&valueName,L"LogFifo");
    if (!NT_SUCCESS (status)) {
            goto End;
    }

    status = WdfRegistryQueryULong (hKey,
              &valueName,
              &DriverDefaultsPtr->LogFifoDefault);

    if (!NT_SUCCESS (status)) {

        DriverDefaultsPtr->LogFifoDefault = SERIAL_LOG_FIFO_DEFAULT;

        status = WdfRegistryAssignULong(hKey,
                            &valueName,
                            DriverDefaultsPtr->LogFifoDefault
                            );
        if (!NT_SUCCESS (status)) {
            goto End;
        }

            DriverDefaultsPtr->LogFifoDefault = 1;
    }


    status = RtlUnicodeStringPrintf(&valueName,L"UartRemovalDetect");
    if (!NT_SUCCESS (status)) {
            goto End;
    }

    status = WdfRegistryQueryULong (hKey,
              &valueName,
              &DriverDefaultsPtr->UartRemovalDetect);

    if (!NT_SUCCESS (status)) {
        DriverDefaultsPtr->UartRemovalDetect = 0;
    }


End:
       WdfRegistryClose(hKey);
    return (status);
}

BOOLEAN
SerialGetRegistryKeyValue(
    IN WDFDEVICE  WdfDevice,
    _In_ PCWSTR   Name,
    OUT PULONG    Value
    )
/*++

Routine Description:

    Can be used to read any REG_DWORD registry value stored
    under Device Parameter.

Arguments:

    FdoData - pointer to the device extension
    Name - Name of the registry value
    Value -


Return Value:

   TRUE if successful
   FALSE if not present/error in reading registry

--*/
{
    WDFKEY      hKey = NULL;
    NTSTATUS    status;
    BOOLEAN     retValue = FALSE;
    UNICODE_STRING valueName;

    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_PNP, ">SerialGetRegistryKeyValue(XXX)\n");

    *Value = 0;

    status = WdfDeviceOpenRegistryKey(WdfDevice,
                                  PLUGPLAY_REGKEY_DEVICE,
                                  STANDARD_RIGHTS_ALL,
                                  WDF_NO_OBJECT_ATTRIBUTES,
                                  &hKey);

    if (NT_SUCCESS (status)) {

        RtlInitUnicodeString(&valueName,Name);

        status = WdfRegistryQueryULong (hKey,
                                  &valueName,
                                  Value);

        if (NT_SUCCESS (status)) {
            retValue = TRUE;
        }

        WdfRegistryClose(hKey);
    }

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_PNP, "<--SerialGetRegistryKeyValue %ws %d \n",
                            Name, *Value);

    return retValue;
}

#define PARAMATER_NAME_LEN 80

BOOLEAN
SerialPutRegistryKeyValue(
    IN WDFDEVICE  WdfDevice,
    _In_ PCWSTR   Name,
    IN ULONG      Value
    )
/*++

Routine Description:

    Can be used to write any REG_DWORD registry value stored
    under Device Parameter.

Arguments:


Return Value:

   TRUE - if write is successful
   FALSE - otherwise

--*/
{
    WDFKEY          hKey = NULL;
    NTSTATUS        status;
    BOOLEAN         retValue = FALSE;
    UNICODE_STRING valueName;

    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_PNP,  "Entered PciDrvWriteRegistryValue\n");

    //
    // write the value out to the registry
    //
    status = WdfDeviceOpenRegistryKey(WdfDevice,
                                      PLUGPLAY_REGKEY_DEVICE,
                                      STANDARD_RIGHTS_ALL,
                                      WDF_NO_OBJECT_ATTRIBUTES,
                                      &hKey);

    if (NT_SUCCESS (status)) {

        RtlInitUnicodeString(&valueName,Name);

        status = WdfRegistryAssignULong (hKey,
                                  &valueName,
                                  Value
                                );

        if (NT_SUCCESS (status)) {
            retValue = TRUE;
        }

        WdfRegistryClose(hKey);
    }

    return retValue;

}

BOOLEAN
SerialGetFdoRegistryKeyValue(
    IN PWDFDEVICE_INIT  DeviceInit,
    _In_ PCWSTR         Name,
    OUT PULONG          Value
    )
/*++

Routine Description:

    Can be used to read any REG_DWORD registry value stored
    under Device Parameter.

Arguments:

    FdoData - pointer to the device extension
    Name - Name of the registry value
    Value -


Return Value:

   TRUE if successful
   FALSE if not present/error in reading registry

--*/
{
    WDFKEY      hKey = NULL;
    NTSTATUS    status;
    BOOLEAN     retValue = FALSE;
    UNICODE_STRING valueName;

    PAGED_CODE();

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_PNP,
                     "-->SerialGetFdoRegistryKeyValue\n");

    *Value = 0;

    status = WdfFdoInitOpenRegistryKey(DeviceInit,
                                  PLUGPLAY_REGKEY_DEVICE,
                                  STANDARD_RIGHTS_ALL,
                                  WDF_NO_OBJECT_ATTRIBUTES,
                                  &hKey);

    if (NT_SUCCESS (status)) {

        RtlInitUnicodeString(&valueName,Name);

        status = WdfRegistryQueryULong (hKey, &valueName, Value);

        if (NT_SUCCESS (status)) {
            retValue = TRUE;
        }

        WdfRegistryClose(hKey);
    }

    SerialDbgPrintEx(TRACE_LEVEL_VERBOSE, DBG_PNP,
                     "<--SerialGetFdoRegistryKeyValue %ws %d \n",
                            Name, *Value);

    return retValue;
}


