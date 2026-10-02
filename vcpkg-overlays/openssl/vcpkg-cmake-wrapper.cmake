# Redirect find_package(OpenSSL) at the system shared OpenSSL 3.
#
# The distribution build exports OPENSSL_ROOT_DIR into the vcpkg install
# prefix and FindOpenSSL treats that hint as NO_DEFAULT_PATH. Leave a
# non-vcpkg root alone so a FIPS image can point at its own OpenSSL.

set(OPENSSL_USE_STATIC_LIBS FALSE)
unset(ENV{OPENSSL_USE_STATIC_LIBS})

set(_duckdb_aws_openssl_root "")
if(DEFINED ENV{OPENSSL_ROOT_DIR} AND NOT "$ENV{OPENSSL_ROOT_DIR}" MATCHES "vcpkg_installed")
    set(_duckdb_aws_openssl_root "$ENV{OPENSSL_ROOT_DIR}")
elseif(DEFINED OPENSSL_ROOT_DIR AND NOT "${OPENSSL_ROOT_DIR}" MATCHES "vcpkg_installed")
    set(_duckdb_aws_openssl_root "${OPENSSL_ROOT_DIR}")
endif()

unset(ENV{OPENSSL_ROOT_DIR})
unset(OPENSSL_ROOT_DIR)
unset(OPENSSL_ROOT_DIR CACHE)
if(_duckdb_aws_openssl_root)
    set(OPENSSL_ROOT_DIR "${_duckdb_aws_openssl_root}" CACHE PATH "System OpenSSL prefix" FORCE)
endif()

foreach(_duckdb_aws_openssl_var IN ITEMS OPENSSL_INCLUDE_DIR OPENSSL_CRYPTO_LIBRARY OPENSSL_SSL_LIBRARY OPENSSL_LIBRARIES)
    if(DEFINED ${_duckdb_aws_openssl_var} AND "${${_duckdb_aws_openssl_var}}" MATCHES "vcpkg_installed")
        unset(${_duckdb_aws_openssl_var} CACHE)
    endif()
endforeach()
unset(_duckdb_aws_openssl_var)

_find_package(${ARGS})

if(OPENSSL_FOUND)
    if(OPENSSL_VERSION VERSION_LESS "3.0.0")
        message(FATAL_ERROR
            "duckdb-aws FIPS build found OpenSSL ${OPENSSL_VERSION} at ${OPENSSL_CRYPTO_LIBRARY}. "
            "Link OpenSSL >= 3 from the image that ships the validated FIPS provider "
            "(install openssl-devel or libssl-dev on that image).")
    endif()
    if(OPENSSL_CRYPTO_LIBRARY MATCHES "\\.(a|lib)$" OR OPENSSL_SSL_LIBRARY MATCHES "\\.(a|lib)$")
        message(FATAL_ERROR
            "duckdb-aws FIPS build must link the shared OpenSSL, found crypto=${OPENSSL_CRYPTO_LIBRARY} ssl=${OPENSSL_SSL_LIBRARY}.")
    endif()
    message(STATUS "duckdb-aws FIPS: OpenSSL ${OPENSSL_VERSION}")
    message(STATUS "duckdb-aws FIPS: libcrypto ${OPENSSL_CRYPTO_LIBRARY}")
    message(STATUS "duckdb-aws FIPS: libssl ${OPENSSL_SSL_LIBRARY}")
endif()

unset(_duckdb_aws_openssl_root)
