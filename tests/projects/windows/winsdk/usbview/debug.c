/*++

Copyright (c) 1997-2008 Microsoft Corporation

Module Name:

    DEBUG.C

Abstract:

    This source file contains debug routines.

Environment:

    user mode

Revision History:

    07-08-97 : created

--*/

/*****************************************************************************
 I N C L U D E S
*****************************************************************************/

#include "uvcview.h"

#if DBG

/*****************************************************************************
 T Y P E D E F S
*****************************************************************************/

typedef struct _ALLOCHEADER
{
    LIST_ENTRY  ListEntry;

    PCHAR       File;

    ULONG       Line;

} ALLOCHEADER, *PALLOCHEADER;


/*****************************************************************************
 G L O B A L S
*****************************************************************************/

LIST_ENTRY AllocListHead =
{
    &AllocListHead,
    &AllocListHead
};


/*****************************************************************************

 MyAlloc()

*****************************************************************************/
_Success_(return != NULL)
_Post_writable_byte_size_(dwBytes)
HGLOBAL
MyAlloc (
    _In_    PCHAR   File,
    ULONG   Line,
    DWORD   dwBytes
)
{
    PALLOCHEADER header;
    DWORD dwRequest = dwBytes;

    if (0 == dwBytes)
    {
        return NULL;
    }

    dwBytes += sizeof(ALLOCHEADER);
    // check for integer overflow
    if (dwBytes > dwRequest)
    {
        header = (PALLOCHEADER)GlobalAlloc(GPTR, dwBytes);

        if (header != NULL)
        {
            InsertTailList(&AllocListHead, &header->ListEntry);

            header->File = File;
            header->Line = Line;

            return (HGLOBAL)(header + 1);
        }
    }
    return NULL;
}

/*****************************************************************************

 MyReAlloc()

*****************************************************************************/

_Success_(return != NULL)
_Post_writable_byte_size_(dwBytes)
HGLOBAL
MyReAlloc (
    HGLOBAL hMem,
    DWORD   dwBytes
)
{
    PALLOCHEADER header;
    PALLOCHEADER headerNew;

    if ((NULL == hMem) || (0 == dwBytes))
    {
        return NULL;
    }

    header = (PALLOCHEADER)hMem;
    header--;

    // Remove the old address from the allocation list
    //
    RemoveEntryList(&header->ListEntry);

    if (dwBytes < (dwBytes + (DWORD) sizeof(ALLOCHEADER)))
        {
        dwBytes += sizeof(ALLOCHEADER);
        headerNew = GlobalReAlloc((HGLOBAL)header, dwBytes, GMEM_MOVEABLE|GMEM_ZEROINIT);

        if (NULL == headerNew)
        {
            // If GlobalReAlloc fails, the original memory is not freed,
            // and the original handle and pointer are still valid.
            // Add the old address back to the allocation list.
            //
            #pragma prefast(suppress:__WARNING_USING_UNINIT_VAR, "SAL noise")
            InsertTailList(&AllocListHead, &header->ListEntry);
        }
        else
        {
            // Add the new address to the allocation list
            //
            InsertTailList(&AllocListHead, &headerNew->ListEntry);

            return (HGLOBAL)(headerNew + 1);
        }
    }
    return NULL;
}


/*****************************************************************************

 MyFree()

*****************************************************************************/

HGLOBAL
MyFree (
    HGLOBAL hMem
)
{
    PALLOCHEADER header;

    if (hMem)
    {
        header = (PALLOCHEADER)hMem;

        header--;

        RemoveEntryList(&header->ListEntry);

        return GlobalFree((HGLOBAL)header);
    }

    return GlobalFree(hMem);
}

/*****************************************************************************

 MyCheckForLeaks()

*****************************************************************************/

VOID
MyCheckForLeaks (
    VOID
)
{
    PALLOCHEADER header;
    CHAR         buf[128];

    memset(buf, 0, sizeof(buf));

    while (!IsListEmpty(&AllocListHead))
    {
        header = (PALLOCHEADER)RemoveHeadList(&AllocListHead);

        StringCbPrintf(buf, sizeof(buf),
                 "File: %s, Line: %d\r\n",
                 header->File,
                 header->Line);

        OutputDebugString(buf);
    }
}

#endif
