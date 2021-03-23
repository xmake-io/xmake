#----------------------------------------------------------------
# Generated CMake target import file for configuration "Release".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "@TARGETNAME@::@TARGETBASENAME@" for configuration "Release"
set_property(TARGET @TARGETNAME@::@TARGETBASENAME@ APPEND PROPERTY IMPORTED_CONFIGURATIONS RELEASE)
set_target_properties(@TARGETNAME@::@TARGETBASENAME@ PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_RELEASE "ASM_NASM;C"
  IMPORTED_LOCATION_RELEASE "@TARGETFILE@"
  )

list(APPEND _IMPORT_CHECK_TARGETS @TARGETNAME@::@TARGETBASENAME@ )
list(APPEND _IMPORT_CHECK_FILES_FOR_@TARGETNAME@::@TARGETBASENAME@ "@TARGETFILE@" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
