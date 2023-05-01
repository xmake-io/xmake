#!/usr/bin/env python
# -*- coding: utf-8 -*-

from conan import ConanFile
from conan.tools.files import save, load
from conan.tools.microsoft import unix_path, VCVars, is_msvc
from conan.errors import ConanInvalidConfiguration
from conan.errors import ConanException
from conans.model.build_info import CppInfo

class XmakeGenerator:
    def __init__(self, conanfile):
        self._conanfile = conanfile
    def generate(self):
        print("XmakeGenerator: generating build info ..")

        # Extract all dependencies
        host_req = self._conanfile.dependencies.host
        test_req = self._conanfile.dependencies.test
        build_req = self._conanfile.dependencies.build

        # Merge into one list
        full_req = list(host_req.items()) \
                   + list(test_req.items()) \
                   + list(build_req.items())

        # Process dependencies and accumulate globally required data
        pkg_files = []
        dep_names = []
        for require, dep in full_req:
            dep_name = require.ref.name
            dep_names.append(dep_name)
            print("dep_name", dep_name)

            # Convert and aggregate dependency's
            dep_cppinfo = dep.cpp_info.copy()
            dep_cppinfo.set_relative_base_folder(dep.package_folder)
            dep_aggregate = dep_cppinfo.aggregated_components()
            print("dep_aggregate", dep_aggregate)


