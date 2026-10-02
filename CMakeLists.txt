cmake_minimum_required(VERSION 3.5...3.29)

# Set extension name here
set(TARGET_NAME aws)

set(EXTENSION_NAME ${TARGET_NAME}_extension)
project(${TARGET_NAME})
include_directories(src/include)

set(EXTENSION_SOURCES src/aws_extension.cpp src/aws_secret.cpp)
add_library(${EXTENSION_NAME} STATIC ${EXTENSION_SOURCES})

set(PARAMETERS "-warnings")
build_loadable_extension(${TARGET_NAME} ${PARAMETERS} ${EXTENSION_SOURCES})

# Weirdly we need to manually to this, otherwise linking against
# ${AWSSDK_LINK_LIBRARIES} fails for some reason
find_package(ZLIB REQUIRED)
find_package(AWSSDK REQUIRED COMPONENTS core sso sts identity-management rds)

# s2n, curl, and aws-c-cal are built against the system OpenSSL (see
# vcpkg-overlays/openssl). Link that shared library into the extension and
# do not bake a build-tree RPATH, so the loader opens the image's
# libcrypto.so.3, the one that can load its validated FIPS provider.
set(OPENSSL_USE_STATIC_LIBS OFF CACHE BOOL "Link the system shared OpenSSL" FORCE)
if(DEFINED ENV{OPENSSL_ROOT_DIR} AND "$ENV{OPENSSL_ROOT_DIR}" MATCHES "vcpkg_installed")
  unset(ENV{OPENSSL_ROOT_DIR})
endif()
find_package(OpenSSL REQUIRED)
if(OPENSSL_VERSION VERSION_LESS "3.0.0")
  message(FATAL_ERROR "OpenSSL >= 3 is required, found ${OPENSSL_VERSION}")
endif()

# Build static lib
target_include_directories(${EXTENSION_NAME}
                           PUBLIC $<BUILD_INTERFACE:${AWSSDK_INCLUDE_DIRS}>)
target_link_libraries(${EXTENSION_NAME} ${AWSSDK_LINK_LIBRARIES} OpenSSL::SSL OpenSSL::Crypto)

# Build loadable binary
target_include_directories(aws_loadable_extension
                           PRIVATE $<BUILD_INTERFACE:${AWSSDK_INCLUDE_DIRS}>)
target_link_libraries(aws_loadable_extension ${AWSSDK_LINK_LIBRARIES} OpenSSL::SSL OpenSSL::Crypto)
if(UNIX AND NOT APPLE)
  set_target_properties(aws_loadable_extension PROPERTIES
    SKIP_BUILD_RPATH TRUE
    BUILD_RPATH ""
    INSTALL_RPATH "")
endif()

install(
  TARGETS ${EXTENSION_NAME}
  EXPORT "${DUCKDB_EXPORT_SET}"
  LIBRARY DESTINATION "${INSTALL_LIB_DIR}"
  ARCHIVE DESTINATION "${INSTALL_LIB_DIR}")
