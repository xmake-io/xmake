add_rules('mode.debug', 'mode.release')
    set_languages('c++23')
    set_policy('build.c++.modules.std', false)

target('module_dep')
    set_kind('moduleonly')
    add_files('src/*.cppm')

target('module_target')
    set_kind('moduleonly')
    add_files('src/*.cppm')

add_deps('module_dep')
    add_tests('test', { kind = 'binary', files = 'src/main.cpp', build_should_pass = true })
    add_tests('test2', { kind = 'binary', files = 'src/main.cpp', build_should_pass = true })
