# prefix
include $(PRO_DIR)/prefix.mak

# module name
NAMES 					= xmake

# module type
xmake_TYPE 				= LIB

# config
xmake_CONFIG 			= y

# core files
xmake_C_FILES 			+= \
						xmake \
						machine \
						os/argv \
						os/find \
						os/link \
						os/isdir \
						os/rmdir \
						os/mkdir \
						os/cpdir \
						os/chdir \
						os/mtime \
						os/sleep \
						os/mclock \
						os/curdir \
						os/tmpdir \
						os/isfile \
						os/islink \
						os/rmfile \
						os/cpfile \
						os/rename \
						os/exists \
						os/setenv \
						os/getenv \
						os/getenvs \
						os/readlink \
						os/emptydir \
						os/strerror \
						os/filesize \
						os/getwinsize \
						os/uid \
						os/gid \
						os/getown \
						io/file___len \
						io/file___tostring \
						io/file_close___gc \
						io/file_flush \
						io/file_isatty \
						io/file_path \
						io/file_read \
						io/file_seek \
						io/file_write \
						io/open \
						io/std \
						path/relative \
						path/absolute \
						path/translate \
						path/is_absolute \
						hash/uuid \
						hash/sha256 \
						string/convert \
						string/endswith \
						string/startswith \
						process/open \
						process/openv \
						process/wait \
						process/waitlist \
						process/close \
						sandbox/interactive \
						semver/parse \
						semver/compare \
						semver/satisfies \
						semver/select \
						semver/semver \
						readline/readline \
						readline/history_list \
						readline/add_history \
						readline/clear_history
						

# flags
xmake_CXFLAGS 			+= -D__tb_prefix__=\"xmake\"
xmake_CXFLAGS 			+= $(if $(findstring readline,$(base_LIBNAMES)),-DXM_CONFIG_API_HAVE_READLINE,)
xmake_CXFLAGS 	   	    += $(if $(findstring curses,$(base_LIBNAMES)),-DXM_CONFIG_API_HAVE_CURSES,)
	
# includes
xmake_INC_DIRS 		    += \
						../tbox/tbox/src \
						../tbox/inc/$(PLAT) \
						../luajit/luajit/src \
                        ../sv/sv/include

						
# suffix
include $(PRO_DIR)/suffix.mak

