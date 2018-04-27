/*++

Copyright (c) 1990-2000  Microsoft Corporation

Module Name:

    queue.h

Abstract:

    This is a C version of a very simple sample driver that illustrates
    how to use the driver framework and demonstrates best practices.

--*/

// Set max write length for testing
#define MAX_WRITE_LENGTH 1024*40

// Set timer period in ms
#define TIMER_PERIOD     1000*2

//
// This is the context that can be placed per queue
// and would contain per queue information.
//
typedef struct _QUEUE_CONTEXT {

    // Here we allocate a buffer from a test write so it can be read back
    WDFMEMORY WriteMemory;

    // Timer DPC for this queue
    WDFTIMER   Timer;

    // Virtual I/O
    WDFREQUEST  CurrentRequest;
    NTSTATUS   CurrentStatus;

} QUEUE_CONTEXT, *PQUEUE_CONTEXT;

WDF_DECLARE_CONTEXT_TYPE_WITH_NAME(QUEUE_CONTEXT, QueueGetContext)

NTSTATUS
EchoQueueInitialize(
    WDFDEVICE hDevice
    );

EVT_WDF_IO_QUEUE_CONTEXT_DESTROY_CALLBACK EchoEvtIoQueueContextDestroy;

//
// Events from the IoQueue object
//
EVT_WDF_REQUEST_CANCEL EchoEvtRequestCancel;
EVT_WDF_IO_QUEUE_IO_READ EchoEvtIoRead;
EVT_WDF_IO_QUEUE_IO_WRITE EchoEvtIoWrite;

NTSTATUS
EchoTimerCreate(
    IN WDFTIMER*       pTimer,
    IN WDFQUEUE        Queue
    );

EVT_WDF_TIMER EchoEvtTimerFunc;
