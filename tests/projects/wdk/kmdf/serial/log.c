/*++

Copyright (c) Microsoft Corporation

Module Name:

    log.c

Abstract:

    Debug log Code for serial.

Environment:

    kernel mode only

--*/

#include "precomp.h"

extern ULONG DebugLevel;
extern ULONG DebugFlag;

#if !defined(EVENT_TRACING)

VOID
SerialDbgPrintEx    (
    IN ULONG   TraceEventsLevel,
    IN ULONG   TraceEventsFlag,
    IN PCCHAR  DebugMessage,
    ...
    )

/*++

Routine Description:

    Debug print for the sample driver.

Arguments:

    TraceEventsLevel - print level between 0 and 3, with 3 the most verbose

Return Value:

    None.

 --*/
 {
#if DBG

#define     TEMP_BUFFER_SIZE        1024

    va_list    list;
    CHAR      debugMessageBuffer [TEMP_BUFFER_SIZE];
    NTSTATUS   status;

    va_start(list, DebugMessage);

    if (DebugMessage) {

        //
        // Using new safe string functions instead of _vsnprintf.
        // This function takes care of NULL terminating if the message
        // is longer than the buffer.
        //
        status = RtlStringCbVPrintfA( debugMessageBuffer,
                                      sizeof(debugMessageBuffer),
                                      DebugMessage,
                                      list );
        if(!NT_SUCCESS(status)) {

            KdPrint((_DRIVER_NAME_": RtlStringCbVPrintfA failed %x\n", status));
            return;
        }
        if (TraceEventsLevel < TRACE_LEVEL_INFORMATION ||
            (TraceEventsLevel <= DebugLevel &&
             ((TraceEventsFlag & DebugFlag) == TraceEventsFlag))) {

            KdPrint((debugMessageBuffer));
        }
    }
    va_end(list);

    return;

#else

    UNREFERENCED_PARAMETER(TraceEventsLevel);
    UNREFERENCED_PARAMETER(TraceEventsFlag);
    UNREFERENCED_PARAMETER(DebugMessage);

#endif
}

#endif

