#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "@PROJECTNAME@::@TARGET_NAME@" for configuration "Release"
set_property(TARGET @PROJECTNAME@::@TARGET_NAME@ APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(@PROJECTNAME@::@TARGET_NAME@ PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "ASM_NASM;C"
  # IMPORTED_IMPLIB_RELEASE "${_IMPORT_PREFIX}/@LIBDIR@/@TARGETFILENAME@"
  IMPORTED_LOCATION_RELEASE "${_IMPORT_PREFIX}/@LIBDIR@/@TARGETFILENAME@"
  )

list(APPEND _IMPORT_CHECK_TARGETS @PROJECTNAME@::@TARGET_NAME@ )
list(APPEND _IMPORT_CHECK_FILES_FOR_@PROJECTNAME@::@TARGET_NAME@ "${_IMPORT_PREFIX}/@LIBDIR@/@TARGETFILENAME@" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
