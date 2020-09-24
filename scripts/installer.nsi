; xmake.nsi
;
; This script is perhaps one of the simplest NSIs you can make. All of the
; optional settings are left to their default settings. The installer simply 
; prompts the user asking them where to install, and drops a copy of xmake.nsi
; there. 

;--------------------------------
; includes
!include "MUI2.nsh"
!include "WordFunc.nsh"
!include "WinMessages.nsh"
!include FileFunc.nsh
!include UAC.nsh

; xmake version Information
!ifndef MAJOR
  !error 'xmake major version is not defined!'
!endif
!ifndef MINOR
  !error 'xmake minor version is not defined!'
!endif
!ifndef ALTER
  !error 'xmake alter version is not defined!'
!endif
!ifndef BUILD
  !error 'xmake build version is not defined!'
!endif

!define VERSION ${MAJOR}.${MINOR}.${ALTER}
!define VERSION_FULL ${VERSION}+${BUILD}

!ifdef x64
  !define ARCH x64
!else
  !define ARCH x86
!endif

;--------------------------------

; The name of the installer
Name "XMake - v${VERSION}"

; The file to write
OutFile "xmake.exe"

; Use unicode
Unicode true

; Use best compressor
SetCompressor /FINAL /SOLID lzma

; The default installation directory
!ifdef x64
  !define PROGRAMFILES $PROGRAMFILES64
  !define HKLM HKLM64
  !define HKCU HKCU64
!else
  !define PROGRAMFILES $PROGRAMFILES
  !define HKLM HKLM
  !define HKCU HKCU
!endif

; Request application privileges for Windows Vista
RequestExecutionLevel user

; Set DPI Aware
ManifestDPIAware true

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING

;--------------------------------
; Icon
!define MUI_ICON "..\core\src\demo\xmake.ico"

;--------------------------------
; UAC helper

!macro Init thing
  uac_tryagain:
  !insertmacro UAC_RunElevated
  ${Switch} $0
  ${Case} 0
    ${IfThen} $1 = 1 ${|} Quit ${|} ;we are the outer process, the inner process has done its work, we are done
    ${IfThen} $3 <> 0 ${|} ${Break} ${|} ;we are admin, let the show go on
    ${If} $1 = 3 ;RunAs completed successfully, but with a non-admin user
      MessageBox mb_YesNo|mb_IconExclamation|mb_TopMost|mb_SetForeground "This ${thing} requires admin privileges, try again" /SD IDNO IDYES uac_tryagain IDNO 0
    ${EndIf}
    ;fall-through and die
  ${Case} 1223
    MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "This ${thing} requires admin privileges, aborting!"
    Quit
  ${Case} 1062
    MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Logon service not running, aborting!"
    Quit
  ${Default}
    MessageBox mb_IconStop|mb_TopMost|mb_SetForeground "Unable to elevate, error $0"
    Quit
  ${EndSwitch}
  
  ; The UAC plugin changes the error level even in the inner process, reset it.
  ; note fix install exit code 1223 to 0 with slient /S
  SetErrorLevel 0
  SetShellVarContext all
!macroend
 
;--------------------------------
; Install Pages

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE.md"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!define MUI_FINISHPAGE_LINK "Donate $$5"
!define MUI_FINISHPAGE_LINK_LOCATION "https://xmake.io/#/sponsor"
!insertmacro MUI_PAGE_FINISH

;--------------------------------
; Uninstall Pages

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

;--------------------------------
; Languages
 
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Version Information


VIProductVersion                         ${VERSION}.0
VIFileVersion                            ${VERSION}.0
VIAddVersionKey /LANG=0 ProductName      XMake
VIAddVersionKey /LANG=0 Comments         "A cross-platform build utility based on Lua$\nwebsite: https://xmake.io"
VIAddVersionKey /LANG=0 CompanyName      "The TBOOX Open Source Group"
VIAddVersionKey /LANG=0 LegalCopyright   "Copyright (C) 2015-2020 Ruki Wang, tboox.org, xmake.io$\nCopyright (C) 2005-2015 Mike Pall, luajit.org"
VIAddVersionKey /LANG=0 FileDescription  "XMake Installer - v${VERSION}"
VIAddVersionKey /LANG=0 OriginalFilename "xmake-${ARCH}.exe"
VIAddVersionKey /LANG=0 FileVersion      ${VERSION_FULL}
VIAddVersionKey /LANG=0 ProductVersion   ${VERSION_FULL}


;--------------------------------
; Reg paths

!define RegUninstall "Software\Microsoft\Windows\CurrentVersion\Uninstall\XMake"

;--------------------------------

Var NOADMIN

Function TrimQuote
	Exch $R1 ; Original string
	Push $R2
 
Loop:
	StrCpy $R2 "$R1" 1
	StrCmp "$R2" "'"   TrimLeft
	StrCmp "$R2" "$\"" TrimLeft
	StrCmp "$R2" "$\r" TrimLeft
	StrCmp "$R2" "$\n" TrimLeft
	StrCmp "$R2" "$\t" TrimLeft
	StrCmp "$R2" " "   TrimLeft
	GoTo Loop2
TrimLeft:	
	StrCpy $R1 "$R1" "" 1
	Goto Loop
 
Loop2:
	StrCpy $R2 "$R1" 1 -1
	StrCmp "$R2" "'"   TrimRight
	StrCmp "$R2" "$\"" TrimRight
	StrCmp "$R2" "$\r" TrimRight
	StrCmp "$R2" "$\n" TrimRight
	StrCmp "$R2" "$\t" TrimRight
	StrCmp "$R2" " "   TrimRight
	GoTo Done
TrimRight:	
	StrCpy $R1 "$R1" -1
	Goto Loop2
 
Done:
	Pop $R2
	Exch $R1
FunctionEnd

; Installer
Function .onInit
  ${GetOptions} $CMDLINE "/NOADMIN" $NOADMIN
  ${If} ${Errors}
    !insertmacro Init "installer"
    StrCpy $NOADMIN "false"
  ${Else}
    StrCpy $NOADMIN "true"
  ${EndIf}

  ; load from reg
  ${If} $InstDir == ""
    ${If} $NOADMIN == "false"
      ReadRegStr $R0 ${HKLM} ${RegUninstall} "InstallLocation"
    ${Else}
      ReadRegStr $R0 ${HKCU} ${RegUninstall} "InstallLocation"
    ${EndIf}
    ${If} $R0 != ""
      Push $R0
      Call TrimQuote
      Pop  $R0
      StrCpy $InstDir $R0
    ${EndIf}
  ${EndIf}
  ; use default
  ${If} $InstDir == ""
    StrCpy $InstDir ${PROGRAMFILES}\xmake
  ${EndIf}

FunctionEnd

Section "XMake (required)" InstallExeutable

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $InstDir

  ; Remove previous directories used
  RMDir /r "$InstDir"
  
  ; Put file there
  File /r /x ".DS_Store" /x "*.swp" "..\xmake\*.*"
  File "..\*.md"
  File "..\core\build\xmake.exe"
  File /r /x ".DS_Store" "..\winenv"

  WriteUninstaller "uninstall.exe"

  !macro AddReg RootKey

    ; Write uac info
    WriteRegStr   ${RootKey} ${RegUninstall} "NoAdmin"               "$NOADMIN"
    
    ; Write the uninstall keys for Windows
    WriteRegStr   ${RootKey} ${RegUninstall} "DisplayName"           "XMake build utility"
    WriteRegStr   ${RootKey} ${RegUninstall} "DisplayIcon"           '"$InstDir\xmake.exe"'
    WriteRegStr   ${RootKey} ${RegUninstall} "Comments"              "A cross-platform build utility based on Lua"
    WriteRegStr   ${RootKey} ${RegUninstall} "Publisher"             "The TBOOX Open Source Group"
    WriteRegStr   ${RootKey} ${RegUninstall} "UninstallString"       '"$InstDir\uninstall.exe"'
    WriteRegStr   ${RootKey} ${RegUninstall} "QuiteUninstallString"  '"$InstDir\uninstall.exe" /S'
    WriteRegStr   ${RootKey} ${RegUninstall} "InstallLocation"       $InstDir
    WriteRegStr   ${RootKey} ${RegUninstall} "HelpLink"              'https://xmake.io/'
    WriteRegStr   ${RootKey} ${RegUninstall} "URLInfoAbout"          'https://github.com/xmake-io/xmake'
    WriteRegStr   ${RootKey} ${RegUninstall} "URLUpdateInfo"         'https://github.com/xmake-io/xmake/releases'
    WriteRegDWORD ${RootKey} ${RegUninstall} "VersionMajor"          ${MAJOR}
    WriteRegDWORD ${RootKey} ${RegUninstall} "VersionMinor"          ${MINOR}
    WriteRegStr   ${RootKey} ${RegUninstall} "DisplayVersion"        ${VERSION_FULL}
    WriteRegDWORD ${RootKey} ${RegUninstall} "NoModify"              1
    WriteRegDWORD ${RootKey} ${RegUninstall} "NoRepair"              1

    ;write size to reg
    ${GetSize} "$InstDir" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD ${RootKey} ${RegUninstall} "EstimatedSize" "$0"
  !macroend

  ${If} $NOADMIN == "false"
    !insertmacro AddReg ${HKLM}
  ${Else}
    !insertmacro AddReg ${HKCU}
  ${EndIf}
  
SectionEnd

Section "Add to PATH" InstallPath

  ${If} $NOADMIN == "false"
    ; Remove the installation path from the $PATH environment variable first
    ReadRegStr $R0 ${HKLM} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
    ${WordReplace} $R0 ";$InstDir" "" "+" $R1

    ; Write the installation path into the $PATH environment variable
    WriteRegExpandStr ${HKLM} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R1;$InstDir"
  ${Else}
    ; Remove the installation path from the $PATH environment variable first
    ReadRegStr $R0 ${HKCU} "Environment" "Path"
    ${WordReplace} $R0 ";$InstDir" "" "+" $R1

    ; Write the installation path into the $PATH environment variable
    WriteRegExpandStr ${HKCU} "Environment" "Path" "$R1;$InstDir"
  ${EndIf}

SectionEnd

;--------------------------------
; Descriptions

; Language strings
LangString DESC_InstallExeutable ${LANG_ENGLISH} "A cross-platform build utility based on Lua"
LangString DESC_InstallPath ${LANG_ENGLISH} "Add xmake to PATH"

; Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${InstallExeutable} $(DESC_InstallExeutable)
!insertmacro MUI_DESCRIPTION_TEXT ${InstallPath} $(DESC_InstallPath)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------

; Uninstaller

Function un.onInit
  ; check if we need uac
  ReadRegStr $NOADMIN ${HKLM} ${RegUninstall} "NoAdmin"
  IfErrors 0 +2
  ReadRegStr $NOADMIN ${HKCU} ${RegUninstall} "NoAdmin"
  
  ${IfNot} $NOADMIN == "true"
    !insertmacro Init "uninstaller"
  ${EndIf}

FunctionEnd

Section "Uninstall"

  ; Remove directories used
  RMDir /r "$InstDir"

  ; Clean reg
  ${If} $NOADMIN == "false"
    DeleteRegKey ${HKLM} ${RegUninstall}
    ; Remove the installation path from the $PATH environment variable
    ReadRegStr $R0 ${HKLM} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
    ${WordReplace} $R0 ";$InstDir" "" "+" $R1
    WriteRegExpandStr ${HKLM} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R1"
  ${Else}
    DeleteRegKey ${HKCU} ${RegUninstall}
    ; Remove the installation path from the $PATH environment variable
    ReadRegStr $R0 ${HKCU} "Environment" "Path"
    ${WordReplace} $R0 ";$InstDir" "" "+" $R1
    WriteRegExpandStr ${HKCU} "Environment" "Path" "$R1"
  ${EndIf}

SectionEnd
