#----------------------------------------------------------------
# Generated CMake target import file for configuration "Debug".
#----------------------------------------------------------------

# Commands may need to know the format version.
set(CMAKE_IMPORT_FILE_VERSION 1)

# Import target "@PROJECTNAME@::@TARGETNAME@" for configuration "Debug"
set_property(TARGET @PROJECTNAME@::@TARGETNAME@ APPEND PROPERTY IMPORTED_CONFIGURATIONS DEBUG)
set_target_properties(@PROJECTNAME@::@TARGETNAME@ PROPERTIES
  IMPORTED_LINK_INTERFACE_LANGUAGES_DEBUG "ASM_NASM;C"
  IMPORTED_LOCATION_DEBUG "@TARGETFILE@"
  )

list(APPEND _IMPORT_CHECK_TARGETS @PROJECTNAME@::@TARGETNAME@ )
list(APPEND _IMPORT_CHECK_FILES_FOR_@PROJECTNAME@::@TARGETNAME@ "@TARGETFILE@" )

# Commands beyond this point should not need to know the version.
set(CMAKE_IMPORT_FILE_VERSION)
