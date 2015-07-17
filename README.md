The Automatic Cross-platform Build Tool
========================

Xmake is an automatic cross-platform build tool.


features
--------

1. create c/c++ projects 
2. automatically probe the host environment and configure project 
3. build and rebuild project 
4. clean generated target files
5. package the project targets automatically
   - *.ipa for ios
   - *.apk for android
   - *.pkg for library
   - *.app for macosx
   - *.exe for windows
   - others
   

6. install target to pc or the mobile device
7. run a given target
8. describe the project file using lua script, more flexible and simple
	```lua
	
	-- xmake.lua
    add_target("console")

        -- set kind
        set_kind("binary")

        -- add files
        add_files("src/*.c") 
    ```
9. custom platforms and toolchains
10. custom rules for package/compiler/linker

contact
-------

- email:   	    
	- waruqi@gmail.com
	- waruqi@126.com
- source:  	    
	- [github](https://github.com/waruqi/xmake)
	- [coding](https://coding.net/u/waruqi/p/xmake/git)
	- [oschina](http://git.oschina.net/tboox/xmake)
- website: 	    
	- http://www.tboox.org
	- http://www.tboox.net
- download:
 	- [github](https://github.com/waruqi/xmake/archive/master.zip)
 	- [coding](https://coding.net/u/waruqi/p/xmake/git/archive/master)
 	- [oschina](http://git.oschina.net/tboox/xmake/repository/archive?ref=master)
- document:
	- [github](https://github.com/waruqi/xmake/wiki/)
	- [oschina](http://git.oschina.net/tboox/xmake/wikis/home)
- qq(group):    
	- 343118190

donate
------

####alipay
<img src="http://www.tboox.net/ruki/alipay.png" alt="alipay" width="128" height="128">

####paypal
<a href="http://tboox.net/%E6%8D%90%E5%8A%A9/">
<img src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_SM.gif" alt="paypal">
</a>

install
-------

####windows
1. download xmake source codes
2. enter the xmake directory
3. run install.bat 
4. select the install directory 

####linux/macosx
1. git clone git@github.com:waruqi/xmake.git
2. cd ./xmake
3. ./install

usage
-----

Please see [wiki](https://github.com/waruqi/xmake/wiki) if you want to known more usage or run xmake --help command.


```bash
	// create a c++ console project 
	xmake create -l c++ -t 1 console
 or xmake create --language=c++ --template=1 console
	
	// enter the project directory
    cd ./console
	
	// build for the host platform
    xmake
    
	// only build for the given target
	xmake target
    
	// config and build for the host platform for debug
    xmake f -m debug 
 or xmake config --mode=debug
    xmake

	// config and build for the iphoneos platform
	xmake f -p iphoneos 
 or xmake config --plat=iphoneos 
    xmake
    
	// config and build for the iphoneos platform with arm64 
    xmake f -p iphoneos -a arm64
 or xmake config --plat=iphoneos --arch=arm64
    xmake
    
	// config and build for the android platform
    xmake f -p android --ndk=xxxxx
    xmake
    
	// build and package project
	xmake package 
	xmake package -a "i386, x86_64"
	xmake package --arch="armv7, arm64"
	xmake package --output=/tmp
	
    // rebuild project
    xmake -r
 or xmake --rebuild
 
    // clean all project targets
    xmake c
 or xmake clean
    
    // clean the given project target
    xmake c target
 or xmake clean target
    
    // run the given project target
    xmake r target
 or xmake run target
    
    // install all targets
    xmake i
 or xmake install
    

```

example
-------

```lua
-- the debug mode
if modes("debug") then
    
    -- enable the debug symbols
    set_symbols("debug")

    -- disable optimization
    set_optimize("none")
end

-- the release mode
if modes("release") then

    -- set the symbols visibility: hidden
    set_symbols("hidden")

    -- enable fastest optimization
    set_optimize("fastest")

    -- strip all symbols
    set_strip("all")
end

-- add target
add_target("test")

    -- set kind
    set_kind("static")

    -- add files
    add_files("src/*.c") 

```
