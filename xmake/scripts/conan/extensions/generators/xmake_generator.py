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
        print("XmakeGenerator generate")


