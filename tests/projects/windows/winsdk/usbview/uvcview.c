/*++

Copyright (c) 1997-2011 Microsoft Corporation

Module Name:

USBVIEW.C

Abstract:

This is the GUI goop for the USBVIEW application.

Environment:

user mode

Revision History:

04-25-97 : created
11-20-02 : minor changes to support more reporting options
04/13/2005 : major bug fixing
07/01/2008 : add UVC 1.1 support and move to Dev branch

--*/

/*****************************************************************************
I N C L U D E S
*****************************************************************************/

#include "resource.h"
#include "uvcview.h"
#include "h264.h"
#include "xmlhelper.h"

#include <commdlg.h>


/*****************************************************************************
D E F I N E S
*****************************************************************************/

// window control defines
//
#define SIZEBAR             0
#define WINDOWSCALEFACTOR   15

/*****************************************************************************
 L O C A L  T Y P E D E F S
*****************************************************************************/
typedef struct _TREEITEMINFO
{
    struct _TREEITEMINFO *Next;
    USHORT Depth;
    PCHAR Name;

} TREEITEMINFO, *PTREEITEMINFO;


/*****************************************************************************
L O C A L    E N U M S
*****************************************************************************/

typedef enum _USBVIEW_SAVE_FILE_TYPE
{
    UsbViewNone = 0,
    UsbViewXmlFile,
    UsbViewTxtFile
} USBVIEW_SAVE_FILE_TYPE;

/*****************************************************************************
L O C A L    F U N C T I O N    P R O T O T Y P E S
*****************************************************************************/

int WINAPI
WinMain (
         _In_ HINSTANCE hInstance,
         _In_opt_ HINSTANCE hPrevInstance,
         _In_ LPSTR lpszCmdLine,
         _In_ int nCmdShow
         );

BOOL
CreateMainWindow (
                  int nCmdShow
                  );

VOID
ResizeWindows (
               BOOL    bSizeBar,
               int     BarLocation
               );

LRESULT CALLBACK
MainDlgProc (
             HWND   hwnd,
             UINT   uMsg,
             WPARAM wParam,
             LPARAM lParam
             );

BOOL
USBView_OnInitDialog (
                      HWND    hWnd,
                      HWND    hWndFocus,
                      LPARAM  lParam
                      );

VOID
USBView_OnClose (
                 HWND hWnd
                 );

VOID
USBView_OnCommand (
                   HWND hWnd,
                   int  id,
                   HWND hwndCtl,
                   UINT codeNotify
                   );

VOID
USBView_OnLButtonDown (
                       HWND hWnd,
                       BOOL fDoubleClick,
                       int  x,
                       int  y,
                       UINT keyFlags
                       );

VOID
USBView_OnLButtonUp (
                     HWND hWnd,
                     int  x,
                     int  y,
                     UINT keyFlags
                     );

VOID
USBView_OnMouseMove (
                     HWND hWnd,
                     int  x,
                     int  y,
                     UINT keyFlags
                     );

VOID
USBView_OnSize (
                HWND hWnd,
                UINT state,
                int  cx,
                int  cy
                );

LRESULT
USBView_OnNotify (
                  HWND    hWnd,
                  int     DlgItem,
                  LPNMHDR lpNMHdr
                  );

BOOL
USBView_OnDeviceChange (
                        HWND  hwnd,
                        UINT  uEvent,
                        DWORD dwEventData
                        );

VOID DestroyTree (VOID);

VOID RefreshTree (VOID);

LRESULT CALLBACK
AboutDlgProc (
              HWND   hwnd,
              UINT   uMsg,
              WPARAM wParam,
              LPARAM lParam
              );

VOID
WalkTree (
          _In_ HTREEITEM        hTreeItem,
          _In_ LPFNTREECALLBACK lpfnTreeCallback,
          _In_opt_ PVOID            pContext
          );

VOID
ExpandItem (
            HWND      hTreeWnd,
            HTREEITEM hTreeItem,
            PVOID     pContext
            );

VOID
AddItemInformationToFile(
            HWND hTreeWnd,
            HTREEITEM hTreeItem,
            PVOID pContext
        );

DWORD
DisplayLastError(
          _Inout_updates_bytes_(count) char    *szString,
          int     count);

VOID AddItemInformationToXmlView(
    HWND hTreeWnd,
    HTREEITEM hTreeItem,
    PVOID pContext
    );
HRESULT InitializeConsole();
VOID UnInitializeConsole();
BOOL IsStdOutFile();
VOID DisplayMessage(DWORD dwMsgId, ...);
VOID PrintString(LPTSTR lpszString);
LPTSTR WStringToAnsiString(LPWSTR lpwszString);
VOID WaitForKeyPress();
BOOL ProcessCommandLine();
HRESULT ProcessCommandSaveFile(LPTSTR szFileName, DWORD dwCreationDisposition, USBVIEW_SAVE_FILE_TYPE fileType);
HRESULT SaveAllInformationAsText(LPTSTR lpstrTextFileName, DWORD dwCreationDisposition);
HRESULT SaveAllInformationAsXml(LPTSTR lpstrTextFileName , DWORD dwCreationDisposition);

/*****************************************************************************
G L O B A L S
*****************************************************************************/
BOOL gDoConfigDesc = TRUE;
BOOL gDoAnnotation = TRUE;
BOOL gLogDebug     = FALSE;
int  TotalHubs     = 0;

extern DEVICE_GUID_LIST gHubList;
extern DEVICE_GUID_LIST gDeviceList;

/*****************************************************************************
G L O B A L S    P R I V A T E    T O    T H I S    F I L E
*****************************************************************************/

HINSTANCE       ghInstance       = NULL;
HWND            ghMainWnd        = NULL;
HWND            ghTreeWnd        = NULL;
HWND            ghEditWnd        = NULL;
HWND            ghStatusWnd      = NULL;
HMENU           ghMainMenu       = NULL;
HTREEITEM       ghTreeRoot       = NULL;
HCURSOR         ghSplitCursor    = NULL;
HDEVNOTIFY      gNotifyDevHandle = NULL;
HDEVNOTIFY      gNotifyHubHandle = NULL;
HANDLE          ghStdOut         = NULL;

BOOL            gbConsoleFile  = FALSE;
BOOL            gbConsoleInitialized = FALSE;
BOOL            gbButtonDown     = FALSE;
BOOL            gDoAutoRefresh   = TRUE;

int             gBarLocation     = 0;
int             giGoodDevice     = 0;
int             giBadDevice      = 0;
int             giComputer       = 0;
int             giHub            = 0;
int             giNoDevice       = 0;
int             giGoodSsDevice   = 0;
int             giNoSsDevice     = 0;


/*****************************************************************************

WinMain()

*****************************************************************************/

int WINAPI
WinMain (
         _In_ HINSTANCE hInstance,
         _In_opt_ HINSTANCE hPrevInstance,
         _In_ LPSTR lpszCmdLine,
         _In_ int nCmdShow
         )
{
    MSG     msg;
    HACCEL  hAccel;
    int retStatus = 0;

    UNREFERENCED_PARAMETER(hPrevInstance);
    UNREFERENCED_PARAMETER(lpszCmdLine);

    InitXmlHelper();

    ghInstance = hInstance;

    ghSplitCursor = LoadCursor(ghInstance,
        MAKEINTRESOURCE(IDC_SPLIT));

    if (!ghSplitCursor)
    {
        OOPS();
        return retStatus;
    }

    hAccel = LoadAccelerators(ghInstance,
        MAKEINTRESOURCE(IDACCEL));

    if (!hAccel)
    {
        OOPS();
        return retStatus;
    }

    if (!CreateTextBuffer())
    {
        return retStatus;
    }

    if (!ProcessCommandLine())
    {
        // There were no command line flags, open GUI
        if (CreateMainWindow(nCmdShow))
        {
            while (GetMessage(&msg, NULL, 0, 0))
            {
                if (!TranslateAccelerator(ghMainWnd,
                            hAccel,
                            &msg) &&
                        !IsDialogMessage(ghMainWnd,
                            &msg))
                {
                    TranslateMessage(&msg);
                    DispatchMessage(&msg);
                }
            }
            retStatus = 1;
        }
    }

    DestroyTextBuffer();

    ReleaseXmlWriter();

    CHECKFORLEAKS();

    return retStatus;
}


/*****************************************************************************

ProcessCommandLine()

Parses the command line and takes appropriate actions. Returns FALSE If there is no action to
perform
*****************************************************************************/
BOOL ProcessCommandLine()
{
    LPWSTR *szArgList = NULL;
    LPTSTR szArg = NULL;
    LPTSTR szAnsiArg= NULL;
    BOOL quietMode = FALSE;

    HRESULT hr = S_OK;
    DWORD dwCreationDisposition = CREATE_NEW;
    USBVIEW_SAVE_FILE_TYPE fileType = UsbViewNone;

    int nArgs = 0;
    int i = 0;
    BOOL bStatus = FALSE;
    BOOL bStopArgProcessing = FALSE;

    szArgList = CommandLineToArgvW(GetCommandLineW(), &nArgs);

    // If there are no arguments we return false
    bStatus = (nArgs > 1)? TRUE:FALSE;

    if (NULL != szArgList)
    {
        if (nArgs > 1)
        {
            // If there are arguments, initialize console for ouput
            InitializeConsole();
        }

        for (i = 1; (i < nArgs) && (bStopArgProcessing == FALSE); i++)
        {
            // Convert argument to ANSI string for futher processing

            szAnsiArg = WStringToAnsiString(szArgList[i]);

            if(NULL == szAnsiArg)
            {
                DisplayMessage(IDS_USBVIEW_INVALIDARG, szAnsiArg);
                DisplayMessage(IDS_USBVIEW_USAGE);
                break;
            }

            if (0 == _stricmp(szAnsiArg, "/?"))
            {
                DisplayMessage(IDS_USBVIEW_USAGE);
                break;
            }
            else if (NULL != StrStrI(szAnsiArg, "/saveall:"))
            {
                fileType = UsbViewTxtFile;
            }
            else if (NULL != StrStrI(szAnsiArg, "/savexml:"))
            {
                fileType = UsbViewXmlFile;
            }
            else if (0 == _stricmp(szAnsiArg, "/f"))
            {
                dwCreationDisposition = CREATE_ALWAYS;
            }
            else if (0 == _stricmp(szAnsiArg, "/q"))
            {
                quietMode = TRUE;
            }
            else
            {
                DisplayMessage(IDS_USBVIEW_INVALIDARG, szAnsiArg);
                DisplayMessage(IDS_USBVIEW_USAGE);
                bStopArgProcessing = TRUE;
            }

            if (fileType != UsbViewNone)
            {
                // Save view information as to file
                szArg = strchr(szAnsiArg, ':');

                if (NULL == szArg || strlen(szArg) == 1)
                {
                    // No ':' or just a ':'
                    DisplayMessage(IDS_USBVIEW_INVALID_FILENAME, szAnsiArg);
                    DisplayMessage(IDS_USBVIEW_USAGE);
                    bStopArgProcessing = TRUE;
                }
                else
                {
                    hr = ProcessCommandSaveFile(szArg + 1, dwCreationDisposition, fileType);

                    if (FAILED(hr))
                    {
                        // No more processing
                        bStopArgProcessing = TRUE;
                    }

                    fileType = UsbViewNone;
                }
            }

            if (NULL != szAnsiArg)
            {
                LocalFree(szAnsiArg);
            }
        }

        if(!quietMode)
        {
            WaitForKeyPress();
        }

        if (gbConsoleInitialized)
        {
            UnInitializeConsole();
        }

        LocalFree(szArgList);
    }
    return bStatus;
}


/*****************************************************************************

ProcessCommandSaveFile()

Process the save file command line

*****************************************************************************/
HRESULT ProcessCommandSaveFile(LPTSTR szFileName, DWORD dwCreationDisposition, USBVIEW_SAVE_FILE_TYPE fileType)
{
    HRESULT hr = S_OK;
    LPTSTR szErrorBuffer = NULL;

    if (UsbViewNone == fileType || NULL == szFileName)
    {
        hr = E_INVALIDARG;
        // Invalid arguments, return
        return (hr);
    }

    // The UI is not created yet, open the UI, but HIDE it
    CreateMainWindow(SW_HIDE);

    if (UsbViewXmlFile == fileType)
    {
        hr = SaveAllInformationAsXml(szFileName, dwCreationDisposition);
    }

    if (UsbViewTxtFile == fileType)
    {
        hr = SaveAllInformationAsText(szFileName, dwCreationDisposition);
    }

    if (FAILED(hr))
    {
        if (GetLastError() == ERROR_FILE_EXISTS || hr == HRESULT_FROM_WIN32(ERROR_FILE_EXISTS))
        {
            // The operation failed because the file we tried to write to already existed and '/f' option
            // was not present. Display error message to user describing '/f' option
            switch(fileType)
            {
                case UsbViewXmlFile:
                    DisplayMessage(IDS_USBVIEW_FILE_EXISTS_XML, szFileName);
                    break;
                case UsbViewTxtFile:
                    DisplayMessage(IDS_USBVIEW_FILE_EXISTS_TXT, szFileName);
                    break;
                default:
                    DisplayMessage(IDS_USBVIEW_INTERNAL_ERROR);
                    break;
            }
        }
        else
        {
            // Try to obtain system error message
            FormatMessage(
                    FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_IGNORE_INSERTS,
                    NULL,
                    hr,
                    MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
                    (LPTSTR) &szErrorBuffer,        // FormatMessage expects this buffer to be cast as LPTSTR
                    0,
                    NULL);
            PrintString("Unable to save file.\n");
            PrintString(szErrorBuffer);
            LocalFree(szErrorBuffer);
        }
    }
    else
    {
        // Display file saved to message in console
        DisplayMessage(IDS_USBVIEW_SAVED_TO, szFileName);
    }

    return (hr);
}

/*****************************************************************************

InitializeConsole()

Initializes the std output in console

*****************************************************************************/
HRESULT InitializeConsole()
{
    HRESULT hr = S_OK;

    SetLastError(0);

    // Find if STD_OUTPUT is a console or has been redirected to a File
    gbConsoleFile = IsStdOutFile();

    if (!gbConsoleFile)
    {
        // Output is not redirected and GUI application do not have console by default, create a console
        if(AllocConsole())
        {
#pragma warning(disable:4996) // We don' need the FILE * returned by freopen
            // Reopen STDOUT , STDIN and STDERR
            if((freopen("conout$", "w", stdout) != NULL) &&
                    (freopen("conin$", "r", stdin)  != NULL) &&
                    (freopen("conout$","w", stderr) != NULL))
            {
                gbConsoleInitialized = TRUE;
                ghStdOut = GetStdHandle(STD_OUTPUT_HANDLE);
            }
#pragma warning(default:4996)
        }
    }

    if (INVALID_HANDLE_VALUE == ghStdOut || FALSE == gbConsoleInitialized)
    {
        hr = HRESULT_FROM_WIN32(GetLastError());
        OOPS();
    }
    return hr;
}

/*****************************************************************************

UnInitializeConsole()

UnInitializes the console

*****************************************************************************/
VOID UnInitializeConsole()
{
    gbConsoleInitialized = FALSE;
    FreeConsole();
}

/*****************************************************************************

IsStdOutFile()

Finds if the STD_OUTPUT has been redirected to a file
*****************************************************************************/
BOOL IsStdOutFile()
{
    unsigned htype;
    HANDLE hFile;

    // 1 = STDOUT
    hFile = (HANDLE) _get_osfhandle(1);
    htype = GetFileType(hFile);
    htype &= ~FILE_TYPE_REMOTE;


    // Check if file type is character file
    if (FILE_TYPE_DISK == htype)
    {
        return TRUE;
    }

    return FALSE;
}


/*****************************************************************************

DisplayMessage()

Displays a message to standard output
*****************************************************************************/
VOID DisplayMessage(DWORD dwResId, ...)
{
    CHAR szFormat[4096];
    HRESULT hr = S_OK;
    LPTSTR lpszMessage = NULL;
    DWORD dwLen = 0;
    va_list ap;

    va_start(ap, dwResId);

    // Initialize console if needed
    if (!gbConsoleInitialized)
    {
        hr = InitializeConsole();
        if (FAILED(hr))
        {
            OOPS();
            return;
        }
    }

    // Load the string resource
    dwLen = LoadString(GetModuleHandle(NULL),
            dwResId,
            szFormat,
            ARRAYSIZE(szFormat)
            );

    if(0 == dwLen)
    {
        PrintString("Unable to find message for given resource ID");

        // Return if resource ID could not be found
        return;
    }

    dwLen = FormatMessage(
                FORMAT_MESSAGE_FROM_STRING | FORMAT_MESSAGE_ALLOCATE_BUFFER,
                szFormat,
                dwResId,
                0,
                (LPTSTR) &lpszMessage,
                ARRAYSIZE(szFormat),
                &ap);

    if (dwLen > 0)
    {
        PrintString(lpszMessage);
        LocalFree(lpszMessage);
    }
    else
    {
        PrintString("Unable to find message for given ID");
    }

    va_end(ap);
    return;
}

/*****************************************************************************

WStringToAnsiString()

Converts the Wide char string to ANSI string and returns the allocated ANSI string.
*****************************************************************************/
LPTSTR WStringToAnsiString(LPWSTR lpwszString)
{
    int strLen = 0;
    LPTSTR szAnsiBuffer = NULL;

    szAnsiBuffer = LocalAlloc(LPTR, (MAX_PATH + 1) * sizeof(CHAR));

    // Convert string from from WCHAR to ANSI
    if (NULL != szAnsiBuffer)
    {
        strLen = WideCharToMultiByte(
                CP_ACP,
                0,
                lpwszString,
                -1,
                szAnsiBuffer,
                MAX_PATH + 1,
                NULL,
                NULL);

        if (strLen > 0)
        {
            return szAnsiBuffer;
        }
    }
    return NULL;
}

/*****************************************************************************

PrintString()

Displays a string to standard output
*****************************************************************************/
VOID PrintString(LPTSTR lpszString)
{
    DWORD dwBytesWritten = 0;
    size_t Len = 0;
    LPSTR lpOemString = NULL;

    if (INVALID_HANDLE_VALUE == ghStdOut || NULL == lpszString)
    {
        OOPS();
        // Return if invalid inputs
        return;
    }

    if (FAILED(StringCchLength(lpszString, OUTPUT_MESSAGE_MAX_LENGTH, &Len)))
    {
        OOPS();
        // Return if string is too long
        return;
    }

    if (gbConsoleFile)
    {
        // Console has been redirected to a file, ex: `usbview /savexml:xx > test.txt`. We need to use WriteFile instead of
        // WriteConsole for text output.
        lpOemString = (LPSTR) LocalAlloc(LPTR, (Len + 1) * sizeof(CHAR));
        if (lpOemString != NULL)
        {
            if (CharToOemBuff(lpszString, lpOemString, (DWORD) Len))
            {
                WriteFile(ghStdOut, (LPVOID) lpOemString, (DWORD) Len, &dwBytesWritten, NULL);
            }
            else
            {
                OOPS();
            }
        }
    }
    else
    {
        // Write to std out in console
        WriteConsole(ghStdOut, (LPVOID) lpszString, (DWORD) Len, &dwBytesWritten, NULL);
    }

    return;
}

/*****************************************************************************

WaitForKeyPress()

Waits for key press in case of console
*****************************************************************************/
VOID WaitForKeyPress()
{
    // Wait for key press if console
    if (!gbConsoleFile && gbConsoleInitialized)
    {
        DisplayMessage(IDS_USBVIEW_PRESSKEY);
        (VOID) _getch();
    }
    return;
}

/*****************************************************************************

CreateMainWindow()

*****************************************************************************/

BOOL
CreateMainWindow (
                  int nCmdShow
                  )
{
    RECT rc;

    InitCommonControls();

    ghMainWnd = CreateDialog(ghInstance,
        MAKEINTRESOURCE(IDD_MAINDIALOG),
        NULL,
        (DLGPROC) MainDlgProc);

    if (ghMainWnd == NULL)
    {
        OOPS();
        return FALSE;
    }

    GetWindowRect(ghMainWnd, &rc);

    gBarLocation = (rc.right - rc.left) / 3;

    ResizeWindows(FALSE, 0);

    ShowWindow(ghMainWnd, nCmdShow);

    UpdateWindow(ghMainWnd);

    return TRUE;
}


/*****************************************************************************

ResizeWindows()

Handles resizing the two child windows of the main window.  If
bSizeBar is true, then the sizing is happening because the user is
moving the bar.  If bSizeBar is false, the sizing is happening
because of the WM_SIZE or something like that.

*****************************************************************************/

VOID
ResizeWindows (
               BOOL    bSizeBar,
               int     BarLocation
               )
{
    RECT    MainClientRect;
    RECT    MainWindowRect;
    RECT    TreeWindowRect;
    RECT    StatusWindowRect;
    int     right;

    // Is the user moving the bar?
    //
    if (!bSizeBar)
    {
        BarLocation = gBarLocation;
    }

    GetClientRect(ghMainWnd, &MainClientRect);

    GetWindowRect(ghStatusWnd, &StatusWindowRect);

    // Make sure the bar is in a OK location
    //
    if (bSizeBar)
    {
        if (BarLocation <
            GetSystemMetrics(SM_CXSCREEN)/WINDOWSCALEFACTOR)
        {
            return;
        }

        if ((MainClientRect.right - BarLocation) <
            GetSystemMetrics(SM_CXSCREEN)/WINDOWSCALEFACTOR)
        {
            return;
        }
    }

    // Save the bar location
    //
    gBarLocation = BarLocation;

    // Move the tree window
    //
    MoveWindow(ghTreeWnd,
        0,
        0,
        BarLocation,
        MainClientRect.bottom - StatusWindowRect.bottom + StatusWindowRect.top,
        TRUE);

    // Get the size of the window (in case move window failed
    //
    GetWindowRect(ghTreeWnd, &TreeWindowRect);
    GetWindowRect(ghMainWnd, &MainWindowRect);

    right = TreeWindowRect.right - MainWindowRect.left;

    // Move the edit window with respect to the tree window
    //
    MoveWindow(ghEditWnd,
        right+SIZEBAR,
        0,
        MainClientRect.right-(right+SIZEBAR),
        MainClientRect.bottom - StatusWindowRect.bottom + StatusWindowRect.top,
        TRUE);

    // Move the Status window with respect to the tree window
    //
    MoveWindow(ghStatusWnd,
        0,
        MainClientRect.bottom - StatusWindowRect.bottom + StatusWindowRect.top,
        MainClientRect.right,
        StatusWindowRect.bottom - StatusWindowRect.top,
        TRUE);
}


/*****************************************************************************

MainWndProc()

*****************************************************************************/

LRESULT CALLBACK
MainDlgProc (
             HWND   hWnd,
             UINT   uMsg,
             WPARAM wParam,
             LPARAM lParam
             )
{

    switch (uMsg)
    {

        HANDLE_MSG(hWnd, WM_INITDIALOG,     USBView_OnInitDialog);
        HANDLE_MSG(hWnd, WM_CLOSE,          USBView_OnClose);
        HANDLE_MSG(hWnd, WM_COMMAND,        USBView_OnCommand);
        HANDLE_MSG(hWnd, WM_LBUTTONDOWN,    USBView_OnLButtonDown);
        HANDLE_MSG(hWnd, WM_LBUTTONUP,      USBView_OnLButtonUp);
        HANDLE_MSG(hWnd, WM_MOUSEMOVE,      USBView_OnMouseMove);
        HANDLE_MSG(hWnd, WM_SIZE,           USBView_OnSize);
        HANDLE_MSG(hWnd, WM_NOTIFY,         USBView_OnNotify);
        HANDLE_MSG(hWnd, WM_DEVICECHANGE,   USBView_OnDeviceChange);
    }

    return 0;
}

/*****************************************************************************

USBView_OnInitDialog()

*****************************************************************************/

BOOL
USBView_OnInitDialog (
                      HWND    hWnd,
                      HWND    hWndFocus,
                      LPARAM  lParam
                      )
{
    HFONT                           hFont;
    HIMAGELIST                      himl;
    HICON                           hicon;
    DEV_BROADCAST_DEVICEINTERFACE   broadcastInterface;

    UNREFERENCED_PARAMETER(lParam);
    UNREFERENCED_PARAMETER(hWndFocus);

    // Register to receive notification when a USB device is plugged in.
    broadcastInterface.dbcc_size = sizeof(DEV_BROADCAST_DEVICEINTERFACE);
    broadcastInterface.dbcc_devicetype = DBT_DEVTYP_DEVICEINTERFACE;

    memcpy( &(broadcastInterface.dbcc_classguid),
        &(GUID_DEVINTERFACE_USB_DEVICE),
        sizeof(struct _GUID));

    gNotifyDevHandle = RegisterDeviceNotification(hWnd,
        &broadcastInterface,
        DEVICE_NOTIFY_WINDOW_HANDLE);

    // Now register for Hub notifications.
    memcpy( &(broadcastInterface.dbcc_classguid),
        &(GUID_CLASS_USBHUB),
        sizeof(struct _GUID));

    gNotifyHubHandle = RegisterDeviceNotification(hWnd,
        &broadcastInterface,
        DEVICE_NOTIFY_WINDOW_HANDLE);

    gHubList.DeviceInfo = INVALID_HANDLE_VALUE;
    InitializeListHead(&gHubList.ListHead);
    gDeviceList.DeviceInfo = INVALID_HANDLE_VALUE;
    InitializeListHead(&gDeviceList.ListHead);

    //end add

    ghTreeWnd = GetDlgItem(hWnd, IDC_TREE);

    //added
    if ((himl = ImageList_Create(15, 15,
        FALSE, 2, 0)) == NULL)
    {
        OOPS();
    }

    if(himl != NULL)
    {
        hicon = LoadIcon(ghInstance, MAKEINTRESOURCE(IDI_ICON));
        giGoodDevice = ImageList_AddIcon(himl, hicon);

        hicon = LoadIcon(ghInstance, MAKEINTRESOURCE(IDI_BADICON));
        giBadDevice = ImageList_AddIcon(himl, hicon);

        hicon = LoadIcon(ghInstance, MAKEINTRESOURCE(IDI_COMPUTER));
        giComputer = ImageList_AddIcon(himl, hicon);

        hicon = LoadIcon(ghInstance, MAKEINTRESOURCE(IDI_HUB));
        giHub = ImageList_AddIcon(himl, hicon);

        hicon = LoadIcon(ghInstance, MAKEINTRESOURCE(IDI_NODEVICE));
        giNoDevice = ImageList_AddIcon(himl, hicon);

        hicon = LoadIcon(ghInstance, MAKEINTRESOURCE(IDI_SSICON));
        giGoodSsDevice = ImageList_AddIcon(himl, hicon);

        hicon = LoadIcon(ghInstance, MAKEINTRESOURCE(IDI_NOSSDEVICE));
        giNoSsDevice = ImageList_AddIcon(himl, hicon);

        TreeView_SetImageList(ghTreeWnd, himl, TVSIL_NORMAL);
        // end add
    }

    ghEditWnd = GetDlgItem(hWnd, IDC_EDIT);

#ifdef H264_SUPPORT
    // set the edit control to have a max text limit size
    SendMessage(ghEditWnd, EM_LIMITTEXT, 0 /* USE DEFAULT MAX*/, 0);
#endif

    ghStatusWnd = GetDlgItem(hWnd, IDC_STATUS);
    ghMainMenu = GetMenu(hWnd);
    if (ghMainMenu == NULL)
    {
        OOPS();
    }
    {
        CHAR pszFont[256];
        CHAR pszHeight[8];

        memset(pszFont, 0, sizeof(pszFont));
        LoadString(ghInstance, IDS_STANDARD_FONT, pszFont, sizeof(pszFont) - 1);
        memset(pszHeight, 0, sizeof(pszHeight));
        LoadString(ghInstance, IDS_STANDARD_FONT_HEIGHT, pszHeight, sizeof(pszHeight) - 1);

        hFont  = CreateFont((int) pszHeight[0],  0, 0, 0,
            400, 0, 0, 0,
            0,   1, 2, 1,
            49, pszFont);
    }
    SendMessage(ghEditWnd,
        WM_SETFONT,
        (WPARAM) hFont,
        0);

    RefreshTree();

    return FALSE;
}

/*****************************************************************************

USBView_OnClose()

*****************************************************************************/

VOID
USBView_OnClose (
                 HWND hWnd
                 )
{

    UNREFERENCED_PARAMETER(hWnd);

    DestroyTree();

    PostQuitMessage(0);
}


/*****************************************************************************

AddItemInformationToFile()

Saves the information about the current item to the list
*****************************************************************************/
VOID
AddItemInformationToFile(
            HWND hTreeWnd,
            HTREEITEM hTreeItem,
            PVOID pContext
        )
{
    HRESULT hr = S_OK;
    HANDLE hf = NULL;
    DWORD dwBytesWritten = 0;

    hf = *((PHANDLE) pContext);

    ResetTextBuffer();

    hr = UpdateTreeItemDeviceInfo(hTreeWnd, hTreeItem);

    if (FAILED(hr))
    {
        OOPS();
    }
    else
    {
        WriteFile(hf, GetTextBuffer(), GetTextBufferPos()*sizeof(CHAR), &dwBytesWritten, NULL);
    }

    ResetTextBuffer();
}



/*****************************************************************************

SaveAllInformationAsText()

Saves the entire USB tree as a text file
*****************************************************************************/
HRESULT
SaveAllInformationAsText(
        LPTSTR lpstrTextFileName,
        DWORD dwCreationDisposition
        )
{
    HRESULT hr = S_OK;
    HANDLE hf = NULL;

    hf = CreateFile(lpstrTextFileName,
            GENERIC_WRITE,
            0,
            NULL,
            dwCreationDisposition,
            FILE_ATTRIBUTE_NORMAL,
            NULL);

    if (hf == INVALID_HANDLE_VALUE)
    {
        hr = HRESULT_FROM_WIN32(GetLastError());
        OOPS();
    }
    else
    {
        if (GetLastError() == ERROR_ALREADY_EXISTS)
        {
            // CreateFile() sets this error if we are overwriting an existing file
            // Reset this error to avoid false alarms
            SetLastError(0);
        }

        if (ghTreeRoot == NULL)
        {
            // If tree has not been populated yet, try a refresh
            RefreshTree();
        }

        if (ghTreeRoot)
        {

            LockFile(hf, 0, 0, 0, 0);
            WalkTreeTopDown(ghTreeRoot, AddItemInformationToFile, &hf, NULL);
            UnlockFile(hf, 0, 0, 0, 0);
            CloseHandle(hf);

            hr = S_OK;
        }
        else
        {
            hr = HRESULT_FROM_WIN32(GetLastError());
            OOPS();
        }
    }

    ResetTextBuffer();
    return hr;
}


/*****************************************************************************

USBView_OnCommand()

*****************************************************************************/

VOID
USBView_OnCommand (
                   HWND hWnd,
                   int  id,
                   HWND hwndCtl,
                   UINT codeNotify
                   )
{
    MENUITEMINFO menuInfo;
    char            szFile[MAX_PATH + 1];
    OPENFILENAME    ofn;
    HANDLE          hf = NULL;
    DWORD           dwBytesWritten = 0;
    int             nTextLength = 0;
    size_t          lengthToNull = 0;
    HRESULT         hr = S_OK;

    UNREFERENCED_PARAMETER(hwndCtl);
    UNREFERENCED_PARAMETER(codeNotify);

    //initialize save dialog variables
    memset(szFile, 0, sizeof(szFile));
    memset(&ofn, 0, sizeof(OPENFILENAME));

    ofn.lStructSize     = sizeof(OPENFILENAME);
    ofn.hwndOwner       = hWnd;
    ofn.nFilterIndex    = 1;
    ofn.lpstrFile       = szFile;
    ofn.nMaxFile        = MAX_PATH;
    ofn.lpstrFileTitle  = NULL;
    ofn.nMaxFileTitle   = 0;
    ofn.lpstrInitialDir = 0;
    ofn.lpstrTitle      = NULL;
    ofn.Flags           = OFN_OVERWRITEPROMPT | OFN_PATHMUSTEXIST;


    switch (id)
    {
    case ID_AUTO_REFRESH:
        gDoAutoRefresh = !gDoAutoRefresh;
        menuInfo.cbSize = sizeof(menuInfo);
        menuInfo.fMask  = MIIM_STATE;
        menuInfo.fState = gDoAutoRefresh ? MFS_CHECKED : MFS_UNCHECKED;
        SetMenuItemInfo(ghMainMenu,
            id,
            FALSE,
            &menuInfo);
        break;

    case ID_SAVE:
        {
            // initialize the save file name
            StringCchCopy(szFile, MAX_PATH, "USBView.txt");
            ofn.lpstrFilter     = "Text\0*.TXT\0\0";
            ofn.lpstrDefExt     = "txt";

            //call dialog box
            if (! GetSaveFileName(&ofn))
            {
                OOPS();
                break;
            }

            //create new file
            hf = CreateFile((LPTSTR)ofn.lpstrFile,
                GENERIC_WRITE,
                0,
                NULL,
                CREATE_ALWAYS,
                FILE_ATTRIBUTE_NORMAL,
                NULL);
            if (hf == INVALID_HANDLE_VALUE)
            {
                OOPS();
            }
            else
            {
                char *szText = NULL;

                //get data from display window to transfer to file
                nTextLength = GetWindowTextLength(ghEditWnd);
                nTextLength++;

                szText = ALLOC((DWORD)nTextLength);
                if (NULL != szText)
                {
                    GetWindowText(ghEditWnd, (LPSTR) szText, nTextLength);

                    //
                    // Constrain length to the first null, which should be at
                    // the end of the window text. This prevents writing extra
                    // null characters.
                    //
                    if (StringCchLength(szText, nTextLength, &lengthToNull) == S_OK)
                    {
                        nTextLength = (int) lengthToNull;

                        //lock the file, write to the file, unlock file
                        LockFile(hf, 0, 0, 0, 0);

                        WriteFile(hf, szText, nTextLength, &dwBytesWritten, NULL);

                        UnlockFile(hf, 0, 0, 0, 0);
                    }
                    else
                    {
                        OOPS();
                    }
                    CloseHandle(hf);
                    FREE(szText);
                }
                else
                {
                    OOPS();
                }
            }

           break;
        }

    case ID_SAVEALL:
        {
            // initialize the save file name
            StringCchCopy(szFile, MAX_PATH, "USBViewAll.txt");
            ofn.lpstrFilter     = "Text\0*.txt\0\0";
            ofn.lpstrDefExt     = "txt";

            //call dialog box
            if (! GetSaveFileName(&ofn))
            {
                OOPS();
                break;
            }

            // Save the file, overwrite in case of UI since UI gives popup for confirmation
            hr = SaveAllInformationAsText(ofn.lpstrFile, CREATE_ALWAYS);
            if (FAILED(hr))
            {
                OOPS();
            }

            break;
        }

    case ID_SAVEXML:
        {
            // initialize the save file name
            StringCchCopy(szFile, MAX_PATH, "USBViewAll.xml");
            ofn.lpstrFilter     = "Xml\0*.xml\0\0";
            ofn.lpstrDefExt     = "xml";

            //call dialog box
            if (! GetSaveFileName(&ofn))
            {
                OOPS();
                break;
            }

            // Save the file, overwrite in case of UI since UI gives popup for confirmation
            hr = SaveAllInformationAsXml(ofn.lpstrFile, CREATE_ALWAYS);
            if (FAILED(hr))
            {
                OOPS();
            }

            break;
        }

    case ID_CONFIG_DESCRIPTORS:
        gDoConfigDesc = !gDoConfigDesc;
        menuInfo.cbSize = sizeof(menuInfo);
        menuInfo.fMask  = MIIM_STATE;
        menuInfo.fState = gDoConfigDesc ? MFS_CHECKED : MFS_UNCHECKED;
        SetMenuItemInfo(ghMainMenu,
            id,
            FALSE,
            &menuInfo);
        break;

    case ID_ANNOTATION:
        gDoAnnotation = !gDoAnnotation;
        menuInfo.cbSize = sizeof(menuInfo);
        menuInfo.fMask  = MIIM_STATE;
        menuInfo.fState = gDoAnnotation ? MFS_CHECKED : MFS_UNCHECKED;
        SetMenuItemInfo(ghMainMenu,
            id,
            FALSE,
            &menuInfo);
        break;

    case ID_LOG_DEBUG:
        gLogDebug       = !gLogDebug;
        menuInfo.cbSize = sizeof(menuInfo);
        menuInfo.fMask  = MIIM_STATE;
        menuInfo.fState = gLogDebug ? MFS_CHECKED : MFS_UNCHECKED;
        SetMenuItemInfo(ghMainMenu,
            id,
            FALSE,
            &menuInfo);
        break;

    case ID_ABOUT:
        DialogBox(ghInstance,
            MAKEINTRESOURCE(IDD_ABOUT),
            ghMainWnd,
            (DLGPROC) AboutDlgProc);
        break;

    case ID_EXIT:
        UnregisterDeviceNotification(gNotifyDevHandle);
        UnregisterDeviceNotification(gNotifyHubHandle);
        DestroyTree();
        PostQuitMessage(0);
        break;

    case ID_REFRESH:
        RefreshTree();
        break;
    }
}

/*****************************************************************************

USBView_OnLButtonDown()

*****************************************************************************/

VOID
USBView_OnLButtonDown (
                       HWND hWnd,
                       BOOL fDoubleClick,
                       int  x,
                       int  y,
                       UINT keyFlags
                       )
{

    UNREFERENCED_PARAMETER(fDoubleClick);
    UNREFERENCED_PARAMETER(x);
    UNREFERENCED_PARAMETER(y);
    UNREFERENCED_PARAMETER(keyFlags);

    gbButtonDown = TRUE;
    SetCapture(hWnd);
}

/*****************************************************************************

USBView_OnLButtonUp()

*****************************************************************************/

VOID
USBView_OnLButtonUp (
                     HWND hWnd,
                     int  x,
                     int  y,
                     UINT keyFlags
                     )
{

    UNREFERENCED_PARAMETER(hWnd);
    UNREFERENCED_PARAMETER(x);
    UNREFERENCED_PARAMETER(y);
    UNREFERENCED_PARAMETER(keyFlags);

    gbButtonDown = FALSE;
    ReleaseCapture();
}

/*****************************************************************************

USBView_OnMouseMove()

*****************************************************************************/

VOID
USBView_OnMouseMove (
                     HWND hWnd,
                     int  x,
                     int  y,
                     UINT keyFlags
                     )
{
    UNREFERENCED_PARAMETER(hWnd);
    UNREFERENCED_PARAMETER(y);
    UNREFERENCED_PARAMETER(keyFlags);

    SetCursor(ghSplitCursor);

    if (gbButtonDown)
    {
        ResizeWindows(TRUE, x);
    }
}

/*****************************************************************************

USBView_OnSize();

*****************************************************************************/

VOID
USBView_OnSize (
                HWND hWnd,
                UINT state,
                int  cx,
                int  cy
                )
{
    UNREFERENCED_PARAMETER(hWnd);
    UNREFERENCED_PARAMETER(state);
    UNREFERENCED_PARAMETER(cx);
    UNREFERENCED_PARAMETER(cy);

    ResizeWindows(FALSE, 0);
}

/*****************************************************************************

USBView_OnNotify()

*****************************************************************************/

LRESULT
USBView_OnNotify (
                  HWND    hWnd,
                  int     DlgItem,
                  LPNMHDR lpNMHdr
                  )
{
    UNREFERENCED_PARAMETER(hWnd);
    UNREFERENCED_PARAMETER(DlgItem);

    if (lpNMHdr->code == TVN_SELCHANGED)
    {
        HTREEITEM hTreeItem;

        hTreeItem = ((NM_TREEVIEW *)lpNMHdr)->itemNew.hItem;

        if (hTreeItem)
        {
            UpdateEditControl(ghEditWnd,
                ghTreeWnd,
                hTreeItem);
        }
    }

    return 0;
}


/*****************************************************************************

USBView_OnDeviceChange()

*****************************************************************************/

BOOL
USBView_OnDeviceChange (
                        HWND  hwnd,
                        UINT  uEvent,
                        DWORD dwEventData
                        )
{
    UNREFERENCED_PARAMETER(hwnd);
    UNREFERENCED_PARAMETER(dwEventData);

    if (gDoAutoRefresh)
    {
        switch (uEvent)
        {
        case DBT_DEVICEARRIVAL:
        case DBT_DEVICEREMOVECOMPLETE:
            RefreshTree();
            break;
        }
    }

    return TRUE;
}



/*****************************************************************************

DestroyTree()

*****************************************************************************/

VOID DestroyTree (VOID)
{
    // Clear the selection of the TreeView, so that when the tree is
    // destroyed, the control won't try to constantly "shift" the
    // selection to another item.
    //
    TreeView_SelectItem(ghTreeWnd, NULL);

    // Destroy the current contents of the TreeView
    //
    if (ghTreeRoot)
    {
        WalkTree(ghTreeRoot, CleanupItem, NULL);

        TreeView_DeleteAllItems(ghTreeWnd);

        ghTreeRoot = NULL;
    }

    ClearDeviceList(&gDeviceList);
    ClearDeviceList(&gHubList);
}

/*****************************************************************************

RefreshTree()

*****************************************************************************/

VOID RefreshTree (VOID)
{
    CHAR  statusText[128];
    ULONG devicesConnected;

    // Clear the edit control
    //
    SetWindowText(ghEditWnd, "");

    // Destroy the current contents of the TreeView
    //
    DestroyTree();

    // Create the root tree node
    //
    ghTreeRoot = AddLeaf(TVI_ROOT, 0, "My Computer", ComputerIcon);

    if (ghTreeRoot != NULL)
    {
        // Enumerate all USB buses and populate the tree
        //
        EnumerateHostControllers(ghTreeRoot, &devicesConnected);

        //
        // Expand all tree nodes
        //
        WalkTree(ghTreeRoot, ExpandItem, NULL);

        // Update Status Line with number of devices connected
        //
        memset(statusText, 0, sizeof(statusText));
        StringCchPrintf(statusText, sizeof(statusText),
#ifdef H264_SUPPORT
        "UVC Spec Version: %d.%d Version: %d.%d Devices Connected: %d   Hubs Connected: %d",
        UVC_SPEC_MAJOR_VERSION, UVC_SPEC_MINOR_VERSION, USBVIEW_MAJOR_VERSION, USBVIEW_MINOR_VERSION,
        devicesConnected, TotalHubs);
#else
        "Devices Connected: %d   Hubs Connected: %d",
        devicesConnected, TotalHubs);
#endif

        SetWindowText(ghStatusWnd, statusText);
    }
    else
    {
        OOPS();
    }

}

/*****************************************************************************

AboutDlgProc()

*****************************************************************************/

LRESULT CALLBACK
AboutDlgProc (
              HWND   hwnd,
              UINT   uMsg,
              WPARAM wParam,
              LPARAM lParam
              )
{
    UNREFERENCED_PARAMETER(lParam);

    switch (uMsg)
    {
    case WM_INITDIALOG:
        {
            HRESULT hr;
            char TextBuffer[TEXT_ITEM_LENGTH];
            HWND hItem;

            hItem = GetDlgItem(hwnd, IDC_VERSION);

            if (hItem != NULL)
            {
                hr = StringCbPrintfA(TextBuffer,
                                     sizeof(TextBuffer),
                                     "USBView version: %d.%d",
                                     USBVIEW_MAJOR_VERSION,
                                     USBVIEW_MINOR_VERSION);
                if (SUCCEEDED(hr))
                {
                    SetWindowText(hItem,TextBuffer);
                }
            }

            hItem = GetDlgItem(hwnd, IDC_UVCVERSION);

            if (hItem != NULL)
            {
                hr = StringCbPrintfA(TextBuffer,
                                     sizeof(TextBuffer),
                                     "USB Video Class Spec version: %d.%d",
                                     UVC_SPEC_MAJOR_VERSION,
                                     UVC_SPEC_MINOR_VERSION);
                if (SUCCEEDED(hr))
                {
                    SetWindowText(hItem,TextBuffer);
                }
            }
        }
        break;
    case WM_COMMAND:

        switch (LOWORD(wParam))
        {
        case IDOK:
        case IDCANCEL:

            EndDialog (hwnd, 0);
            break;
        }
        break;

    }

    return FALSE;
}


/*****************************************************************************

AddLeaf()

*****************************************************************************/

HTREEITEM
AddLeaf (
         HTREEITEM hTreeParent,
         LPARAM    lParam,
         _In_ LPTSTR    lpszText,
         TREEICON  TreeIcon
         )
{
    TV_INSERTSTRUCT tvins;
    HTREEITEM       hti;

    memset(&tvins, 0, sizeof(tvins));

    // Set the parent item
    //
    tvins.hParent = hTreeParent;

    tvins.hInsertAfter = TVI_LAST;

    // pszText and lParam members are valid
    //
    tvins.item.mask = TVIF_TEXT | TVIF_PARAM;

    // Set the text of the item.
    //
    tvins.item.pszText = lpszText;

    // Set the user context item
    //
    tvins.item.lParam = lParam;

    // Add the item to the tree-view control.
    //
    hti = TreeView_InsertItem(ghTreeWnd, &tvins);

    // added
    tvins.item.mask = TVIF_IMAGE | TVIF_SELECTEDIMAGE;
    tvins.item.hItem = hti;

    // Determine which icon to display for the device
    //
    switch (TreeIcon)
    {
        case ComputerIcon:
            tvins.item.iImage = giComputer;
            tvins.item.iSelectedImage = giComputer;
            break;

        case HubIcon:
            tvins.item.iImage = giHub;
            tvins.item.iSelectedImage = giHub;
            break;

        case NoDeviceIcon:
            tvins.item.iImage = giNoDevice;
            tvins.item.iSelectedImage = giNoDevice;
            break;

        case GoodDeviceIcon:
            tvins.item.iImage = giGoodDevice;
            tvins.item.iSelectedImage = giGoodDevice;
            break;

        case GoodSsDeviceIcon:
            tvins.item.iImage = giGoodSsDevice;
            tvins.item.iSelectedImage = giGoodSsDevice;
            break;

        case NoSsDeviceIcon:
            tvins.item.iImage = giNoSsDevice;
            tvins.item.iSelectedImage = giNoSsDevice;
            break;

        case BadDeviceIcon:
        default:
            tvins.item.iImage = giBadDevice;
            tvins.item.iSelectedImage = giBadDevice;
            break;
    }
    TreeView_SetItem(ghTreeWnd, &tvins.item);

    return hti;
}


/*****************************************************************************

WalkTreeTopDown()

*****************************************************************************/

VOID
WalkTreeTopDown(
          _In_ HTREEITEM        hTreeItem,
          _In_ LPFNTREECALLBACK lpfnTreeCallback,
          _In_opt_ PVOID            pContext,
          _In_opt_ LPFNTREENOTIFYCALLBACK lpfnTreeNotifyCallback
          )
{
    if (hTreeItem)
    {
        HTREEITEM hTreeChild = TreeView_GetChild(ghTreeWnd, hTreeItem);
        HTREEITEM hTreeSibling = TreeView_GetNextSibling(ghTreeWnd, hTreeItem);

        //
        // Call the lpfnCallBack on the node itself.
        //
        (*lpfnTreeCallback)(ghTreeWnd, hTreeItem, pContext);

        //
        // Recursively call WalkTree on the node's first child.
        //

        if (hTreeChild)
        {
            WalkTreeTopDown(hTreeChild,
                    lpfnTreeCallback,
                    pContext,
                    lpfnTreeNotifyCallback);
        }

        //
        // Recursively call WalkTree on the node's first sibling.
        //
        if (hTreeSibling)
        {
            WalkTreeTopDown(hTreeSibling,
                    lpfnTreeCallback,
                    pContext,
                    lpfnTreeNotifyCallback);
        }
        else
        {
            // If there are no more siblings, we have reached the end of
            // list of child nodes. Call notify function
            if (lpfnTreeNotifyCallback != NULL)
            {
                (*lpfnTreeNotifyCallback)(pContext);
            }
        }
    }
}

/*****************************************************************************

WalkTree()

*****************************************************************************/

VOID
WalkTree (
          _In_ HTREEITEM        hTreeItem,
          _In_ LPFNTREECALLBACK lpfnTreeCallback,
          _In_opt_ PVOID            pContext
          )
{
    if (hTreeItem)
    {
        // Recursively call WalkTree on the node's first child.
        //
        WalkTree(TreeView_GetChild(ghTreeWnd, hTreeItem),
            lpfnTreeCallback,
            pContext);

        //
        // Call the lpfnCallBack on the node itself.
        //
        (*lpfnTreeCallback)(ghTreeWnd, hTreeItem, pContext);

        //
        //
        // Recursively call WalkTree on the node's first sibling.
        //
        WalkTree(TreeView_GetNextSibling(ghTreeWnd, hTreeItem),
            lpfnTreeCallback,
            pContext);
    }
}

/*****************************************************************************

ExpandItem()

*****************************************************************************/

VOID
ExpandItem (
            HWND      hTreeWnd,
            HTREEITEM hTreeItem,
            PVOID     pContext
            )
{
    //
    // Make this node visible.
    //
    UNREFERENCED_PARAMETER(pContext);

    TreeView_Expand(hTreeWnd, hTreeItem, TVE_EXPAND);
}

/*****************************************************************************

SaveAllInformationAsXML()

Saves the entire USB tree as an XML file
*****************************************************************************/
HRESULT
SaveAllInformationAsXml(
        LPTSTR lpstrTextFileName,
        DWORD dwCreationDisposition
        )
{
    HRESULT hr = S_OK;

    if (ghTreeRoot == NULL)
    {
        // If tree has not been populated yet, try a refresh
        RefreshTree();
    }
    if (ghTreeRoot)
    {
        WalkTreeTopDown(ghTreeRoot, AddItemInformationToXmlView, NULL, XmlNotifyEndOfNodeList);

        hr = SaveXml(lpstrTextFileName, dwCreationDisposition);
    }
    else
    {
        hr = E_FAIL;
        OOPS();
    }
    ResetTextBuffer();
    return hr;
}

//*****************************************************************************
//
//  AddItemInformationToXmlView
//
//  hTreeItem - Handle of selected TreeView item for which information should
//  be added to the XML View
//
//*****************************************************************************
VOID
AddItemInformationToXmlView(
        HWND hTreeWnd,
        HTREEITEM hTreeItem,
        PVOID pContext
        )
{
    TV_ITEM tvi;
    PVOID   info;
    PCHAR tviName = NULL;

    UNREFERENCED_PARAMETER(pContext);

#ifdef H264_SUPPORT
    ResetErrorCounts();
#endif

    tviName = (PCHAR) ALLOC(256);

    if (NULL == tviName)
    {
        return;
    }

    //
    // Get the name of the TreeView item, along with the a pointer to the
    // info we stored about the item in the item's lParam.
    //

    tvi.mask = TVIF_HANDLE | TVIF_TEXT | TVIF_PARAM;
    tvi.hItem = hTreeItem;
    tvi.pszText = (LPSTR) tviName;
    tvi.cchTextMax = 256;

    TreeView_GetItem(hTreeWnd,
            &tvi);

    info = (PVOID)tvi.lParam;

    if (NULL != info)
    {
        //
        // Add Item to XML object
        //
        switch (*(PUSBDEVICEINFOTYPE)info)
        {
            case HostControllerInfo:
                XmlAddHostController(tviName, (PUSBHOSTCONTROLLERINFO) info);
                break;

            case RootHubInfo:
                XmlAddRootHub(tviName, (PUSBROOTHUBINFO) info);
                break;

            case ExternalHubInfo:
                XmlAddExternalHub(tviName, (PUSBEXTERNALHUBINFO) info);
                break;

            case DeviceInfo:
                XmlAddUsbDevice(tviName, (PUSBDEVICEINFO) info);
                break;
        }

    }
    return;
}

/*****************************************************************************

DisplayLastError()

*****************************************************************************/

DWORD
DisplayLastError(
          _Inout_updates_bytes_(count) char *szString,
          int count)
{
    LPVOID lpMsgBuf;

    // get the last error code
    DWORD dwError = GetLastError();

    // get the system message for this error code
    if (FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dwError,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
        (LPTSTR) &lpMsgBuf,
        0,
        NULL ))
    {
        StringCchPrintf(szString, count, "Error: %s", (LPTSTR)lpMsgBuf );
    }

    // Free the local buffer
    LocalFree( lpMsgBuf );

    // return the error
    return dwError;
}

#if DBG

/*****************************************************************************

Oops()

*****************************************************************************/

VOID
Oops
(
    _In_ PCHAR  File,
    ULONG       Line
 )
{
    char szBuf[1024];
    LPTSTR lpMsgBuf;
    DWORD dwGLE = GetLastError();

    memset(szBuf, 0, sizeof(szBuf));

    // get the system message for this error code
    if (FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM,
        NULL,
        dwGLE,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT), // Default language
        (LPTSTR) &lpMsgBuf,
        0,
        NULL))
    {
        StringCchPrintf(szBuf, sizeof(szBuf),
            "File: %s, Line %d\r\nGetLastError 0x%x %u %s\n",
            File, Line, dwGLE, dwGLE, lpMsgBuf);
    }
    else
    {
        StringCchPrintf(szBuf, sizeof(szBuf),
            "File: %s, Line %d\r\nGetLastError 0x%x %u\r\n",
            File, Line, dwGLE, dwGLE);
    }
    OutputDebugString(szBuf);

    // Free the system allocated local buffer
    LocalFree(lpMsgBuf);

    return;
}

#endif
