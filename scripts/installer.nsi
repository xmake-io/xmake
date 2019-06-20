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
    !define MAJOR 2
!endif
!ifndef MINOR
    !define MINOR 2
!endif
!ifndef ALTER
    !define ALTER 7
!endif
!ifndef BUILD
    !define BUILD 201906200000
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

; The default installation directory
!ifdef x64
  InstallDir $PROGRAMFILES64\XMake
  !define HKLM HKLM64
  !define HKCU HKCU64
!else
  InstallDir $PROGRAMFILES\XMake
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
 
SetShellVarContext all
!macroend
 
;--------------------------------
; Pages

!insertmacro MUI_PAGE_LICENSE "..\LICENSE.md"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
 
;--------------------------------
; Finish Pages

!define MUI_FINISHPAGE_LINK "Donate $$5"
!define MUI_FINISHPAGE_LINK_LOCATION "https://xmake.io/pages/donation.html#donate"
!insertmacro MUI_PAGE_FINISH

;--------------------------------
; Languages
 
!insertmacro MUI_LANGUAGE "English"

;--------------------------------
; Version Information


VIProductVersion ${VERSION}.0
VIFileVersion ${VERSION}.0
VIAddVersionKey /LANG=0 ProductName XMake
VIAddVersionKey /LANG=0 Comments "A cross-platform build utility based on Lua$\nwebsite: https://xmake.io"
VIAddVersionKey /LANG=0 CompanyName "The TBOOX Open Source Group"
VIAddVersionKey /LANG=0 LegalCopyright "Copyright (C) 2015-2019 Ruki Wang, tboox.org, xmake.io$\nCopyright (C) 2005-2015 Mike Pall, luajit.org"
VIAddVersionKey /LANG=0 FileDescription "XMake Installer - v${VERSION}"
VIAddVersionKey /LANG=0 OriginalFilename "xmake-${ARCH}.exe"
VIAddVersionKey /LANG=0 FileVersion ${VERSION_FULL}
VIAddVersionKey /LANG=0 ProductVersion ${VERSION_FULL}


;--------------------------------
; Reg pathes

!define RegUninstall "Software\Microsoft\Windows\CurrentVersion\Uninstall\XMake"
!define RegProduct "Software\XMake"

;--------------------------------

Var NOADMIN

; Installer
Function .onInit
  ${GetOptions} $CMDLINE "/NOADMIN" $NOADMIN
  ${If} ${Errors}
    !insertmacro Init "installer"
    StrCpy $NOADMIN "false"
  ${Else}
    StrCpy $NOADMIN "true"
  ${EndIf}
FunctionEnd

Section "xmake (required)" Installer

  SectionIn RO
  
  ; Set output path to the installation directory.
  SetOutPath $INSTDIR

  ; Remove previous directories used
  RMDir /r "$INSTDIR"
  
  ; Put file there
  File /r /x ".DS_Store" /x "*.swp" "..\xmake\*.*"
  File "..\*.md"
  File "..\core\build\xmake.exe"
  File /r /x ".DS_Store" "..\winenv"

  WriteUninstaller "uninstall.exe"

  !macro AddReg RootKey    
    ; Write the installation path into the registry
    WriteRegStr ${RootKey} ${RegProduct} "Install_Dir" "$INSTDIR"
    ; Write uac info
    WriteRegStr ${RootKey} ${RegProduct} "NoAdmin" "$NOADMIN"
    
    ; Write the uninstall keys for Windows
    WriteRegStr ${RootKey} ${RegUninstall} "DisplayName" "XMake build utility"
    WriteRegStr ${RootKey} ${RegUninstall} "DisplayIcon" '"$INSTDIR\xmake.exe"'
    WriteRegStr ${RootKey} ${RegUninstall} "Publisher" "The TBOOX Open Source Group"
    WriteRegStr ${RootKey} ${RegUninstall} "UninstallString" '"$INSTDIR\uninstall.exe"'
    WriteRegStr ${RootKey} ${RegUninstall} "QuiteUninstallString" '"$INSTDIR\uninstall.exe" /S'
    WriteRegStr ${RootKey} ${RegUninstall} "InstallLocation" '"$INSTDIR"'
    WriteRegStr ${RootKey} ${RegUninstall} "HelpLink" 'https://xmake.io/'
    WriteRegStr ${RootKey} ${RegUninstall} "URLInfoAbout" 'https://github.com/xmake-io/xmake'
    WriteRegStr ${RootKey} ${RegUninstall} "URLUpdateInfo" 'https://github.com/xmake-io/xmake/releases'
    WriteRegDWORD ${RootKey} ${RegUninstall} "VersionMajor" ${MAJOR}
    WriteRegDWORD ${RootKey} ${RegUninstall} "VersionMinor" ${MINOR}
    WriteRegStr ${RootKey} ${RegUninstall} "DisplayVersion" ${VERSION_FULL}
    WriteRegDWORD ${RootKey} ${RegUninstall} "NoModify" 1
    WriteRegDWORD ${RootKey} ${RegUninstall} "NoRepair" 1

    ;write size to reg
    ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
    IntFmt $0 "0x%08X" $0
    WriteRegDWORD ${RootKey} ${RegUninstall} "EstimatedSize" "$0"

    ; Remove the installation path from the $PATH environment variable first
    ReadRegStr $R0 ${RootKey} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
    ${WordReplace} $R0 ";$INSTDIR" "" "+" $R1

    ; Write the installation path into the $PATH environment variable
    WriteRegExpandStr ${RootKey} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R1;$INSTDIR"
  !macroend

  ${If} $NOADMIN == "false"
    !insertmacro AddReg ${HKLM}
  ${Else}
    !insertmacro AddReg ${HKCU}
  ${EndIf}
  
SectionEnd

;--------------------------------
; Descriptions

; Language strings
LangString DESC_Installer ${LANG_ENGLISH} "A cross-platform build utility based on Lua"

; Assign language strings to sections
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
!insertmacro MUI_DESCRIPTION_TEXT ${Installer} $(DESC_Installer)
!insertmacro MUI_FUNCTION_DESCRIPTION_END

;--------------------------------

; Uninstaller

Function un.onInit
  ; check if we need uac
  ReadRegStr $NOADMIN ${HKLM} SOFTWARE\XMake "NoAdmin"
  IfErrors 0 +2
  ReadRegStr $NOADMIN ${HKCU} SOFTWARE\XMake "NoAdmin"
  
  ${IfNot} $NOADMIN == "true"
    !insertmacro Init "uninstaller"
  ${EndIf}

FunctionEnd

Section "Uninstall"

  !macro RemoveReg RootKey 
    ; Remove registry keys
    DeleteRegKey ${RootKey} ${RegUninstall}
    DeleteRegKey ${RootKey} ${RegProduct}

    ; Remove the installation path from the $PATH environment variable
    ReadRegStr $R0 ${RootKey} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path"
    ${WordReplace} $R0 ";$INSTDIR" "" "+" $R1
    ; MessageBox MB_OK|MB_USERICON '$R0 - $INSTDIR - $R1 '
    WriteRegExpandStr ${RootKey} "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "Path" "$R1"
  !macroend

  ; Remove directories used
  RMDir /r "$INSTDIR"
  ${If} $NOADMIN == "false"
    !insertmacro RemoveReg ${HKLM}
  ${Else}
    !insertmacro RemoveReg ${HKCU}
  ${EndIf}

SectionEnd
