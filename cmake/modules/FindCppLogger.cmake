#.rst:
# FindCppLogger
# -----------
#
# Find cpp-logger headers and libraries.
#
# ::
#
#   cpp-logger_FOUND          - True if cpp-logger found.
#   cpp-logger_INCLUDE_DIRS   - Where to find cpp-logger.h.
#   cpp-logger_LIBRARIES      - List of libraries when using cpp-logger.

#cmake_minimum_required(VERSION 3.10.2) # based on the requirement of cpp-logger

foreach (_cpp-logger_hint "$ENV{cpp_logger_DIR}" "$ENV{CPP_LOGGER_DIR}" "$ENV{Cpp_logger}")
  if (_cpp-logger_hint)
    foreach (_suffix
             "lib/cmake/cpp-logger"   "lib/cmake/CPP-LOGGER" "lib/cmake/Cpp_logger"
             "lib64/cmake/cpp-logger" "lib64/cmake/CPP-LOGGER" "lib64/cmake/Cpp_logger"
             "lib"                    "lib64"
    )
        list(APPEND CMAKE_PREFIX_PATH "${_cpp-logger_hint}/${_suffix}")
    endforeach ()
    # Also add the hint root itself
    list(APPEND CMAKE_PREFIX_PATH "${_cpp-logger_hint}")
  endif ()
endforeach ()


find_package(cpp-logger 
             NAMES cpp-logger CPP-LOGGER Cpp_logger
             QUIET
)

if (NOT cpp-logger_FOUND AND CMAKE_VERSION VERSION_GREATER_EQUAL "3.14")
  message(STATUS "cpp-logger not found, fetching ...") 
  include(FetchContent)
  FetchContent_Declare(
    cpp-logger
    GIT_REPOSITORY https://github.com/hariharan-devarajan/cpp-logger.git
    GIT_TAG        v0.0.6
    PATCH_COMMAND  ${CMAKE_COMMAND} -E echo "Applying cpp-logger patch..."
              COMMAND patch -p1 --forward --input=${CMAKE_SOURCE_DIR}/cmake/modules/cpp-logger-fix-export.patch
    # cpp-logger CMakeLists.txt has a bug that exports target twice and 
    # misuses CMAKE_BINARY_DIR where it should be CMAKE_CURRENT_BINARY_DIR.
  )

  set(CPP_LOGGER_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
  set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(cpp-logger)
  set(CMAKE_WARN_DEPRECATED ON CACHE BOOL "" FORCE)

  target_compile_options(cpp-logger PRIVATE -std=gnu11 -w)
endif ()

if (TARGET cpp-logger::cpp-logger)
  get_target_property(cpp-logger_INCLUDE_DIRS cpp-logger::cpp-logger INTERFACE_INCLUDE_DIRECTORIES)
  if (NOT cpp-logger_INCLUDE_DIRS)
    set(cpp-logger_INCLUDE_DIRS ${CPP_LOGGER_INCLUDE_DIRS})
  endif ()
  set(cpp-logger_LIBRARIES cpp-logger::cpp-logger)
  set(cpp-logger_FOUND TRUE)
elseif (TARGET cpp-logger)
  get_target_property(cpp-logger_INCLUDE_DIRS cpp-logger INTERFACE_INCLUDE_DIRECTORIES)
  if (NOT cpp-logger_INCLUDE_DIRS)
    set(cpp-logger_INCLUDE_DIRS ${CPP_LOGGER_INCLUDE_DIRS})
  endif ()
  set(cpp-logger_LIBRARIES cpp-logger)
  set(cpp-logger_FOUND TRUE)
elseif (cpp-logger_LIBRARIES)
  add_library(cpp-logger::cpp-logger UNKNOWN IMPORTED)
  set_target_properties(cpp-logger::cpp-logger PROPERTIES
    IMPORTED_LOCATION             "${cpp-logger_LIBRARIES}"
    INTERFACE_INCLUDE_DIRECTORIES "${cpp-logger_INCLUDE_DIRS}"
  )
  set(cpp-logger_LIBRARIES cpp-logger::cpp-logger)
  set(cpp-logger_FOUND TRUE)
else ()
  message(FATAL_ERROR "cpp-logger: could not find or create target cpp-logger::cpp-logger")
endif ()

message(STATUS "cpp-logger_LIBRARIES: ${cpp-logger_LIBRARIES}")
message(STATUS "cpp-logger_INCLUDE_DIRS: ${cpp-logger_INCLUDE_DIRS}")
set(CPP_LOGGER_INCLUDE_DIRS ${cpp-logger_INCLUDE_DIRS})
set(CPP_LOGGER_LIBRARIES ${cpp-logger_LIBRARIES})
mark_as_advanced(cpp-logger_INCLUDE_DIRS CPP_LOGGER_INCLUDE_DIR cpp-logger_LIBRARIES CPP_LOGGER_LIBRARIES)
