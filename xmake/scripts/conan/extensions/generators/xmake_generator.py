#!/usr/bin/env python
# -*- coding: utf-8 -*-

class XmakeGenerator:
    def __init__(self, conanfile):
        self._conanfile = conanfile

    def filename(self, pkgname = None):
        if pkgname:
            return "conanbuildinfo_%s.xmake.lua" %pkgname
        else:
            return "conanbuildinfo.xmake.lua"

    def generate(self):
        print("XmakeGenerator: generating build info ..")

        # extract all dependencies
        host_req = self._conanfile.dependencies.host
        test_req = self._conanfile.dependencies.test
        build_req = self._conanfile.dependencies.build

        full_req = list(host_req.items()) \
                   + list(test_req.items()) \
                   + list(build_req.items())

        dep_names = []
        pkginfo = None
        plat = self._conanfile.settings.os
        arch = self._conanfile.settings.arch
        mode = self._conanfile.settings.build_type
        for require, dep in full_req:
            # get aggregate dependency's cppinfo
            dep_aggregate = dep.cpp_info.aggregated_components()

            # format deps
            deps = XmakeDepsFormatter(dep_aggregate)

            # get package and deps
            dep_name = require.ref.name
            if not pkginfo:
                pkginfo = deps
            else:
                dep_names.append(dep_name)

            # make content
            template = ('  {plat}_{arch}_{mode} = \n'
                        '  {{\n'
                        '    includedirs    = {{{deps.include_paths}}},\n'
                        '    linkdirs       = {{{deps.lib_paths}}},\n'
                        '    links          = {{{deps.libs}}},\n'
                        '    frameworkdirs  = {{{deps.framework_paths}}},\n'
                        '    frameworks     = {{{deps.frameworks}}},\n'
                        '    syslinks       = {{{deps.system_libs}}},\n'
                        '    defines        = {{{deps.defines}}},\n'
                        '    cxxflags       = {{{deps.cppflags}}},\n'
                        '    cflags         = {{{deps.cflags}}},\n'
                        '    shflags        = {{{deps.sharedlinkflags}}},\n'
                        '    ldflags        = {{{deps.exelinkflags}}},\n'
                        '    __bindirs      = {{{deps.bin_paths}}},\n'
                        '    __resdirs      = {{{deps.res_paths}}},\n'
                        '    __srcdirs      = {{{deps.src_paths}}}\n'
                        '  }}')

            sections = []
            sections.append(template.format(plat = plat, arch = arch, mode = mode, deps = deps))
            content = "{\n" + ",\n".join(sections) + "\n}"
            print(dep_name, content)

            # save package content to file
            with open(self.filename(dep_name), 'w') as file:
                file.write(content)

        # save root content to file
        template = ('  {plat}_{arch}_{mode} = \n'
                    '  {{\n'
                    '    includedirs    = {{{pkginfo.include_paths}}},\n'
                    '    linkdirs       = {{{pkginfo.lib_paths}}},\n'
                    '    links          = {{{pkginfo.libs}}},\n'
                    '    frameworkdirs  = {{{pkginfo.framework_paths}}},\n'
                    '    frameworks     = {{{pkginfo.frameworks}}},\n'
                    '    syslinks       = {{{pkginfo.system_libs}}},\n'
                    '    defines        = {{{pkginfo.defines}}},\n'
                    '    cxxflags       = {{{pkginfo.cppflags}}},\n'
                    '    cflags         = {{{pkginfo.cflags}}},\n'
                    '    shflags        = {{{pkginfo.sharedlinkflags}}},\n'
                    '    ldflags        = {{{pkginfo.exelinkflags}}},\n'
                    '    __bindirs      = {{{pkginfo.bin_paths}}},\n'
                    '    __resdirs      = {{{pkginfo.res_paths}}},\n'
                    '    __srcdirs      = {{{pkginfo.src_paths}}},\n'
                    '    __dep_names    = {{{dep_names}}}\n'
                    '  }}')

        sections = []
        dep_names_str = ", ".join('"%s"' % p for p in dep_names)
        sections.append(template.format(plat = plat, arch = arch, mode = mode, pkginfo = pkginfo, dep_names = dep_names_str))
        content = "{\n" + ",\n".join(sections) + "\n}"
        print(content)

        # save package content to file
        with open(self.filename(), 'w') as file:
            file.write(content)

class XmakeDepsFormatter(object):
    def __prepare_process_escape_character(self, raw_string):
        if raw_string.find('\"') != -1:
            raw_string = raw_string.replace("\"","\\\"")
        return raw_string

    def __filter_char(self, raw_string):
        return self.__prepare_process_escape_character(raw_string)

    def __init__(self, deps_cpp_info):
        includedirs     = deps_cpp_info._includedirs if deps_cpp_info._includedirs else []
        libdirs         = deps_cpp_info._libdirs if deps_cpp_info._libdirs else []
        bindirs         = deps_cpp_info._bindirs if deps_cpp_info._bindirs else []
        resdirs         = deps_cpp_info._resdirs if deps_cpp_info._resdirs else []
        srcdirs         = deps_cpp_info._srcdirs if deps_cpp_info._srcdirs else []
        frameworkdirs   = deps_cpp_info._frameworkdirs if deps_cpp_info._frameworkdirs else []
        libs            = deps_cpp_info._libs if deps_cpp_info._libs else []
        frameworks      = deps_cpp_info._frameworks if deps_cpp_info._frameworks else []
        system_libs     = deps_cpp_info._system_libs if deps_cpp_info._system_libs else []
        defines         = deps_cpp_info._defines if deps_cpp_info._defines else []
        cxxflags        = deps_cpp_info._cxxflags if deps_cpp_info._cxxflags else []
        cflags          = deps_cpp_info._cflags if deps_cpp_info._cflags else []
        sharedlinkflags = deps_cpp_info._sharedlinkflags if deps_cpp_info._sharedlinkflags else []
        exelinkflags    = deps_cpp_info._exelinkflags if deps_cpp_info._exelinkflags else []

        self.include_paths   = ",\n".join('"%s"' % self.__filter_char(p.replace("\\", "/")) for p in includedirs)
        self.lib_paths       = ",\n".join('"%s"' % self.__filter_char(p.replace("\\", "/")) for p in libdirs)
        self.bin_paths       = ",\n".join('"%s"' % self.__filter_char(p.replace("\\", "/")) for p in bindirs)
        self.res_paths       = ",\n".join('"%s"' % self.__filter_char(p.replace("\\", "/")) for p in resdirs)
        self.src_paths       = ",\n".join('"%s"' % self.__filter_char(p.replace("\\", "/")) for p in srcdirs)
        self.framework_paths = ",\n".join('"%s"' % self.__filter_char(p.replace("\\", "/")) for p in frameworkdirs)
        self.libs            = ", ".join('"%s"' % p for p in libs)
        self.frameworks      = ", ".join('"%s"' % p for p in frameworks)
        self.system_libs     = ", ".join('"%s"' % p for p in system_libs)
        self.defines         = ", ".join('"%s"' % self.__filter_char(p) for p in defines)
        self.cppflags        = ", ".join('"%s"' % p for p in cxxflags)
        self.cflags          = ", ".join('"%s"' % p for p in cflags)
        self.sharedlinkflags = ", ".join('"%s"' % p for p in sharedlinkflags)
        self.exelinkflags    = ", ".join('"%s"' % p for p in exelinkflags)

