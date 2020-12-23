-- xmake.lua
-- global
add_rules('mode.debug', 'mode.release')

set_version('0.1.0')

set_kind('binary')
add_includedirs('..')
set_warnings('all')
--set_languages('cxx20')
target('test1')
    add_files('test1.cpp')
