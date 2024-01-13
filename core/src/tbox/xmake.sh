#!/bin/sh

set_config "hash" true
set_config "charset" true
set_config "force_utf8" true
set_config "float" true
set_config "demo" false

check_interfaces_enabled=false
includes "tbox/src"

hide_options() {
    local name=""
    local options="demo small micro float info exception deprecated force_utf8 xml zip hash regex object charset database coroutine"
    for name in $options; do
        option "${name}"
            set_showmenu false
        option_end
    done
}
hide_options

target "tbox"
    set_default false
    set_configvar "TB_CONFIG_MODULE_HAVE_HASH" 1
    set_configvar "TB_CONFIG_MODULE_HAVE_CHARSET" 1
    set_configvar "TB_CONFIG_FORCE_UTF8" 1
    set_configvar "TB_CONFIG_TYPE_HAVE_FLOAT" 1
    add_includedirs "inc/${plat}" "{public}"
    if is_mode "debug"; then
        add_defines "__tb_debug__"
    fi
