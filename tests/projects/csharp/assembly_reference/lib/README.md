# MyLib.dll fixture

`MyLib.dll` in this directory is a **prebuilt fixture**, standing in for the kind of
external, non-NuGet, non-xmake-built assembly `csharp.references` exists to reference
(e.g. a vendor SDK's managed DLL). It is built from the source in `src/` and is not part
of the xmake build for this test project - `xmake.lua` references the committed `.dll`
directly by path, which is the exact scenario under test.

To rebuild it after changing `src/`:

```bash
cd src
dotnet build -c Release
cp bin/Release/netstandard2.0/MyLib.dll ../MyLib.dll
```
