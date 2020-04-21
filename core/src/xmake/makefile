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
						engine \
						os/argv \
						os/args \
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
						os/cpuinfo \
						os/readlink \
						os/emptydir \
						os/syserror \
						os/strerror \
						os/filesize \
						os/getwinsize \
						os/uid \
						os/gid \
						os/getown \
						io/stdfile \
						io/file_size \
						io/file_close \
						io/file_flush \
						io/file_isatty \
						io/file_open \
						io/file_read \
						io/file_seek \
						io/file_write \
						io/file_rawfd \
						io/filelock_open \
						io/filelock_lock \
						io/filelock_unlock \
						io/filelock_trylock \
						io/filelock_close \
						io/poller \
						io/poller_wait \
						io/poller_insert \
						io/poller_remove \
						io/poller_modify \
						io/poller_spank \
						io/poller_support \
						io/socket_open \
						io/socket_rawfd \
						io/socket_wait \
						io/socket_bind \
						io/socket_listen \
						io/socket_accept \
						io/socket_connect \
						io/socket_send \
						io/socket_sendto \
						io/socket_sendfile \
						io/socket_recv \
						io/socket_recvfrom \
						io/socket_close \
						io/pipe_open \
						io/pipe_openpair \
						io/pipe_close \
						io/pipe_read \
						io/pipe_write \
						io/pipe_wait \
						io/pipe_connect \
						path/relative \
						path/absolute \
						path/translate \
						path/is_absolute \
						hash/uuid4 \
						hash/sha256 \
						string/trim \
						string/split \
						string/lastof \
						string/convert \
						string/endswith \
						string/startswith \
						process/open \
						process/openv \
						process/wait \
						process/kill \
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

iswin =
ifeq ($(PLAT),windows)
	iswin = yes
endif
ifeq ($(PLAT),msys)
	iswin = yes
endif
ifeq ($(PLAT),cygwin)
	iswin = yes
endif

ifdef iswin
xmake_C_FILES 			+= \
						winos/ansi \
						winos/logical_drives \
						winos/registry_query
endif

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

