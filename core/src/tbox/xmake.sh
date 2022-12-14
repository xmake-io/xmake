#!/bin/sh

set_config "hash" true
set_config "charset" true
set_config "force_utf8" true
set_config "float" true
set_config "demo" false

includes "tbox/src"
target_end

set_configvar "TB_CONFIG_MODULE_HAVE_HASH" 1
set_configvar "TB_CONFIG_MODULE_HAVE_CHARSET" 1
set_configvar "TB_CONFIG_FORCE_UTF8" 1
set_configvar "TB_CONFIG_TYPE_HAVE_FLOAT" 1
