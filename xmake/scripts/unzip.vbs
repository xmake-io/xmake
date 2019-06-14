'The location of the zip file.
ZipFile = WScript.Arguments(0)
'The folder the contents should be extracted to.
ExtractTo = WScript.Arguments(1)

'If the extraction location does not exist create it.
Set fso = CreateObject("Scripting.FileSystemObject")
If NOT fso.FolderExists(ExtractTo) Then
   fso.CreateFolder(ExtractTo)
End If
WScript.Echo ZipFile
WScript.Echo ExtractTo
'Extract the contants of the zip file.
set objShell = CreateObject("Shell.Application")
set FilesInZip=objShell.NameSpace(ZipFile).items
objShell.NameSpace(ExtractTo).CopyHere(FilesInZip)
Set fso = Nothing
Set objShell = Nothing
