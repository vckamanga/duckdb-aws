# Do not build or ship OpenSSL. s2n, curl, and aws-c-cal find the system
# library through vcpkg-cmake-wrapper.cmake, and the extension records a
# dependency on its SONAME (libcrypto.so.3 / libssl.so.3).
set(VCPKG_POLICY_EMPTY_PACKAGE enabled)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/vcpkg-cmake-wrapper.cmake"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

file(WRITE "${CURRENT_BUILDTREES_DIR}/copyright"
     "This port does not distribute OpenSSL. The extension links the system OpenSSL.\n")
vcpkg_install_copyright(FILE_LIST "${CURRENT_BUILDTREES_DIR}/copyright")
