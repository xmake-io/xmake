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

;--------------------------------

; The name of the installer
Name "xmake"

; The file to write
OutFile "xmake.exe"

; The default installation directory
InstallDir $PROGRAMFILES\xmake

; Request application privileges for Windows Vista
RequestExecutionLevel admin

;--------------------------------
; Interface Settings

!define MUI_ABORTWARNING

;--------------------------------
; Pages

!insertmacro MUI_PAGE_LICENSE "LICENSE.md"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
 
;--------------------------------
; Languages
 
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Version Information

VIProductVersion "2.1.1.0304"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "XMake"
VIAddVersionKey /LANG=${LANG_ENGLISH} "Comments" "website: http://www.xmake.io"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "The TBOOX Open Source Group"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright 2015-2017 tboox.org"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "The Make-like Build Utility based on Lua"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "2.1.1"

;--------------------------------

; Installer
Section "xmake (required)" Installer

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR
  
  ; Put file there
  File /r /x ".DS_Store" "xmake\*.*"
  File "*.md"
  File "core\build\demo.exe"
  
  ; Rename file
  Rename "$INSTDIR\demo.exe" "$INSTDIR\xmake.exe"

  ; Write the installation path into the registry
  WriteRegStr HKLM SOFTWARE\NSIS_xmake "Install_Dir" "$INSTDIR"
  
  ; Write the uninstall keys for Windows
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\xmake" "DisplayName" "NSIS xmake"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\xmake" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\xmake" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\xmake" "NoRepair" 1
  WriteUninstaller "uninstall.exe"

  ; Remove the installation path from the $PATH environment variable first
  ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
  ${WordReplace} $R0 ";$INSTDIR" "" "+" $R1

  ; Write the installation path into the $PATH environment variable
  WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R1;$INSTDIR"
  SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment"
  
SectionEnd

;--------------------------------
; Descriptions

; Language strings
LangString DESC_Installer ${LANG_ENGLISH} "The Make-like Build Utility based on Lua"

; Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${Installer} $(DESC_Installer)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------

; Uninstaller

Section "Uninstall"
  
  ; Remove registry keys
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\xmake"
  DeleteRegKey HKLM SOFTWARE\NSIS_xmake

  ; Remove directories used
  RMDir /r "$INSTDIR"

  ; Remove the installation path from the $PATH environment variable
  ReadRegStr $R0 HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
  ${WordReplace} $R0 ";$INSTDIR" "" "+" $R1
  ; MessageBox MB_OK|MB_USERICON '$R0 - $INSTDIR - $R1 '
  WriteRegExpandStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R1"

SectionEnd
