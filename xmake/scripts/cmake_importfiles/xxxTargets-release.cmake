#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "@PROJECTNAME@::@TARGETNAME@" for configuration "Release"
set_property(TARGET @PROJECTNAME@::@TARGETNAME@ APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(@PROJECTNAME@::@TARGETNAME@ PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "ASM_NASM;C"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/lib/@TARGETFILENAME@"
  )

list(APPEND _IMPORT_CHECK_TARGETS @PROJECTNAME@::@TARGETNAME@ )
list(APPEND _IMPORT_CHECK_FILES_FOR_@PROJECTNAME@::@TARGETNAME@ "${_IMPORT_PREFIX}/lib/@TARGETFILENAME@" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
