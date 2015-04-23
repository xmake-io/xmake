
build
-----

```bash
	// build for linux-x86 debug
    cd ./xmake/core
    [make f PLAT=linux ARCH=x86 DEBUG=y] => optional
    make r

	// build for linux-x64 release
    cd ./xmake/core
    [make f PLAT=linux ARCH=x64 DEBUG=n] => optional
    make r

	// build for linux and add cflags and ldflags
    cd ./xmake/core
    make f PLAT=linux CFLAG="-I." LDFLAG="-L. -lxxx"
    make r

	// build for mac
    cd ./xmake/core
    [make f PLAT=mac ARCH=x64] => optional
    make r

	// build for ios-armv7, using sdk7.1 framework
    cd ./xmake/core
    make f PLAT=ios ARCH=armv7 SDK=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.1.sdk
    make r
    
	// build for ios armv7 and arm64 universal version
    cd ./xmake/core
    make lipo ARCH1=armv7 ARCH2=arm64 SDK=/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS7.1.sdk

	// build for android-armv5te, need set the ndk and toolchains directory
    cd ./xmake/core
    make f PLAT=android ARCH=armv5te SDK=/home/xxxx/android-ndk-r9d BIN=/home/xxxx/android-ndk-r9d/toolchains/arm-linux-androideabi-4.8/prebuilt/darwin-x86_64/bin
    make r
    
	// build for android-armv6, if ndk and toolchains have been setted
    cd ./xmake/core
    make f PLAT=android ARCH=armv6
    make r

	// build for windows using msvc
    cd ./xmake/core
    run ./msys.bat
    [make f PLAT=msvc ARCH=x86] => optional
    make r

	// build for windows using mingw and need link libgcc.a from mingw
    run msys
    cd ./xmake/core
    [make f PLAT=mingw ARCH=x86] => optional
    make r

	// build for windows using cygwin 
    run cygwin
    cd ./xmake/core
    [make f PLAT=cygwin ARCH=x86] => optional
    make r

	// build for windows and custom complier path and prefix and need link libgcc.a from mingw
    run cygwin
    cd ./xmake/core
    make f PLAT=mingw ARCH=x86 BIN="/home/xxx/bin" PRE="i386-mingw32-"
    make r
```

