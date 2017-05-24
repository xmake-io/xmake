add_executable(version version.c)
target_link_libraries(version ${PROJECT_NAME})
add_test(version version)

add_executable(comp comp.c)
target_link_libraries(comp ${PROJECT_NAME})
add_test(comp comp)

add_executable(range range.c)
target_link_libraries(range ${PROJECT_NAME})
add_test(range range)

add_executable(match match.c)
target_link_libraries(match ${PROJECT_NAME})
add_test(match match)

add_executable(utils utils.c)
target_link_libraries(utils ${PROJECT_NAME})
add_test(utils utils)

add_executable(usage usage.c)
target_link_libraries(usage ${PROJECT_NAME})
add_test(usage usage)

add_executable(semvers semvers.c)
target_link_libraries(semvers ${PROJECT_NAME})
add_test(semvers semvers)
