#.rst:
# FindBrahma
# -----------
#
# Find brahma headers and libraries.
#
# ::
#
#   brahma_FOUND          - True if brahma found.
#   brahma_INCLUDE_DIRS   - Where to find brahma.h.
#   brahma_LIBRARIES      - List of libraries when using brahma.

#cmake_minimum_required(VERSION 3.10.2) # based on the requirement of brahma

foreach (_brahma_hint "$ENV{brahma_DIR}" "$ENV{BRAHMA_DIR}" "$ENV{Brahma}")
  if (_brahma_hint)
    foreach (_suffix
             "lib/cmake/brahma"   "lib/cmake/BRAHMA" "lib/cmake/Brahma"
             "lib64/cmake/brahma" "lib64/cmake/BRAHMA" "lib64/cmake/Brahma"
             "lib"                "lib64"
    )
        list(APPEND CMAKE_PREFIX_PATH "${_brahma_hint}/${_suffix}")
    endforeach ()
    # Also add the hint root itself
    list(APPEND CMAKE_PREFIX_PATH "${_brahma_hint}")
  endif ()
endforeach ()


find_package(brahma 
             NAMES brahma BRAHMA Brahma
             QUIET
)

if (NOT brahma_FOUND AND CMAKE_VERSION VERSION_GREATER_EQUAL "3.14")
  message(STATUS "brahma not found, fetching ...") 
  include(FetchContent)
  FetchContent_Declare(
    brahma
    GIT_REPOSITORY https://github.com/hariharan-devarajan/brahma.git
    GIT_TAG        v1.0.2
    PATCH_COMMAND  ${CMAKE_COMMAND} -E echo "Applying brahma patch..."
              COMMAND patch -p1 --forward --input=${CMAKE_SOURCE_DIR}/cmake/modules/brahma-fix.patch
    # brahma CMakeLists.txt has a bug that exports target twice and 
    # misuses CMAKE_BINARY_DIR where it should be CMAKE_CURRENT_BINARY_DIR.
    # misuses CMAKE_SOURCE_DIR where it should be CMAKE_CURRENT_SOURCE_DIR.
  )

  set(BRAHMA_ENABLE_TESTING OFF CACHE BOOL "" FORCE)
  set(CMAKE_WARN_DEPRECATED OFF CACHE BOOL "" FORCE)
  FetchContent_MakeAvailable(brahma)
  set(CMAKE_WARN_DEPRECATED ON CACHE BOOL "" FORCE)

  target_compile_options(brahma PRIVATE -std=gnu11 -w)
endif ()

if (TARGET brahma::brahma)
  get_target_property(brahma_INCLUDE_DIRS brahma::brahma INTERFACE_INCLUDE_DIRECTORIES)
  if (NOT brahma_INCLUDE_DIRS)
    set(brahma_INCLUDE_DIRS ${BRAHMA_INCLUDE_DIRS})
  endif ()
  set(brahma_LIBRARIES brahma::brahma)
  set(brahma_FOUND TRUE)
elseif (TARGET brahma)
  get_target_property(brahma_INCLUDE_DIRS brahma INTERFACE_INCLUDE_DIRECTORIES)
  if (NOT brahma_INCLUDE_DIRS)
    set(brahma_INCLUDE_DIRS ${BRAHMA_INCLUDE_DIRS})
  endif ()
  set(brahma_LIBRARIES brahma)
  set(brahma_FOUND TRUE)
elseif (brahma_LIBRARIES)
  add_library(brahma::brahma UNKNOWN IMPORTED)
  set_target_properties(brahma::brahma PROPERTIES
    IMPORTED_LOCATION             "${brahma_LIBRARIES}"
    INTERFACE_INCLUDE_DIRECTORIES "${brahma_INCLUDE_DIRS}"
  )
  set(brahma_LIBRARIES brahma::brahma)
  set(brahma_FOUND TRUE)
else ()
  message(FATAL_ERROR "brahma: could not find or create target brahma::brahma")
endif ()

message(STATUS "brahma_LIBRARIES: ${brahma_LIBRARIES}")
message(STATUS "brahma_INCLUDE_DIRS: ${brahma_INCLUDE_DIRS}")
set(BRAHMA_INCLUDE_DIRS ${brahma_INCLUDE_DIRS})
set(BRAHMA_LIBRARIES ${brahma_LIBRARIES})
mark_as_advanced(brahma_INCLUDE_DIRS BRAHMA_INCLUDE_DIR brahma_LIBRARIES BRAHMA_LIBRARIES)
