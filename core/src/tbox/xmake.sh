#!/bin/sh

includes "tbox/src"
target_end

# enable hash
set_config "hash" true
set_configvar "TB_CONFIG_MODULE_HAVE_HASH" 1

# enable charset
set_config "charset" true
set_configvar "TB_CONFIG_MODULE_HAVE_CHARSET" 1

# enable utf8
set_config "force_utf8" true
set_configvar "TB_CONFIG_FORCE_UTF8" 1

# enable float
set_config "float" true
set_configvar "TB_CONFIG_TYPE_HAVE_FLOAT" 1

# disable demo
set_config "demo" false

