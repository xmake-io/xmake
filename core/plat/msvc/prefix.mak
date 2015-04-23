# architecture makefile configure

# prefix & suffix
BIN_PREFIX 			= 
BIN_SUFFIX 			= .exe

OBJ_PREFIX 			= 
OBJ_SUFFIX 			= .obj

LIB_PREFIX 			= 
LIB_SUFFIX 			= .lib

DLL_PREFIX 			= 
DLL_SUFFIX 			= .dll

ASM_SUFFIX 			= .S

# tool
CC 					= cl.exe
AR 					= link.exe
STRIP 				= 
RANLIB 				= 
LD 					= link.exe
AS					= 
RM 					= rm -f
RMDIR 				= rm -rf
CP 					= cp
CPDIR 				= cp -r
MKDIR 				= mkdir -p
MAKE 				= make -r
PWD 				= pwd

# cxflags: .c/.cc/.cpp files
CXFLAGS_RELEASE 	= -MT -Gy -Zi
CXFLAGS_DEBUG 		= -Od -GS -MTd -ZI -RTC1 -D__tb_debug__
CXFLAGS 			= \
					-SSE2 \
					-D_MBCS -D_CRT_SECURE_NO_WARNINGS -DNOCRYPT -DNOGDI -Gd -Gm -W3 -WX -nologo -c -TP -EHsc \
					-I'/usr/local/inc'
CXFLAGS-I 			= -I
CXFLAGS-o 			= -Fo

# opti
ifeq ($(SMALL),y)
CXFLAGS_RELEASE 	+= -Os
else
CXFLAGS_RELEASE 	+= -Ox
endif

# cflags: .c files
CFLAGS_RELEASE 		= 
CFLAGS_DEBUG 		= 
CFLAGS 				=

# ccflags: .cc/.cpp files
CCFLAGS_RELEASE 	=
CCFLAGS_DEBUG 		= 
CCFLAGS 			= 

# ldflags
LDFLAGS_RELEASE 	= 
LDFLAGS_DEBUG 		= -debug
LDFLAGS 			= \
					-nodefaultlib:"msvcrt.lib" \
					-manifest -manifestuac:"level='asInvoker' uiAccess='false'" \
					-nologo -machine:x86 -dynamicbase -nxcompat -libpath:'$(HOME)tool\msys\local\lib'
LDFLAGS-L 			= -libpath:
LDFLAGS-l 			= 
LDFLAGS-f 			= .lib
LDFLAGS-o 			= -out:

# asflags
ASFLAGS_RELEASE 	= 
ASFLAGS_DEBUG 		= 
ASFLAGS 			= 
ASFLAGS-I 			=
ASFLAGS-o 			= 

# arflags
ARFLAGS_RELEASE 	= 
ARFLAGS_DEBUG 		= -debug 
ARFLAGS 			= -lib -nologo -machine:x86 -libpath:'$(HOME)tool\msys\local\lib'
ARFLAGS-o 			= -out:

# shflags
SHFLAGS_RELEASE 	= 
SHFLAGS_DEBUG 		= -debug 
SHFLAGS 			= -dll -nologo -machine:x86 -libpath:'$(HOME)tool\msys\local\lib'

# prof
ifeq ($(PROF),y)
LDFLAGS_RELEASE 	+= -debug
ARFLAGS_RELEASE 	+= -debug
SHFLAGS_RELEASE 	+= -debug
endif

# include sub-config
include 		$(PLAT_DIR)/config.mak


