# project name
project (odysseus)

# the oldest stable cmake version we support
cmake_minimum_required (VERSION 2.6)

# tell cmake where its modules can be found in our project directory
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake/src)

# where we install data directory (if we have any)
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")

# what to call that directory where we install data too
set (PKGDATADIR "${DATADIR}/oddysseus")

set (EXEC_NAME "oddysseus")
set (RELEASE_NAME "A web browser for elementary OS")
set (VERSION "0.1")
set (VERSION_INFO "development")

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite webkit2gtk-4.0 json-glib-1.0
        gee-0.8)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

# make sure we have vala
find_package(Vala REQUIRED)
# make sure we use vala
include(ValaVersion)
# make sure it's the desired version of vala
ensure_vala_version("0.16" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(VALA_C ${EXEC_NAME}
    src/Oddysseus.vala
    src/BrowserWindow.vala
    src/Widgets/AddressBar.vala
    src/Widgets/WebTab.vala
    src/Widgets/ButtonWithMenu.vala
    src/Widgets/FindToolbar.vala
    src/Widgets/DownloadButton.vala
    src/Widgets/DownloadBar.vala
    src/Widgets/ProgressBin.vala

    src/Services/pages.vala
    src/Services/icons.vala
    src/Services/Prosody/byteutils.vala
    src/Services/Prosody/data.vala
    src/Services/Prosody/diff.vala
    src/Services/Prosody/expression.vala
    src/Services/Prosody/lib.vala
    src/Services/Prosody/parser.vala
    src/Services/Prosody/writers.vala
    src/Services/Prosody/loader.vala

    src/Traits/viewsource.vala
    src/Traits/errors.vala
    src/Traits/init.vala

# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    granite
    webkit2gtk-4.0
    json-glib-1.0
    gee-0.8
    posix
)

# Bundle in about: page templates
include(GResource)
glib_compile_resources(GLIB_RESOURCES_PAGES SOURCE data/pages/about-pages.gresource.xml)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C} ${GLIB_RESOURCES_PAGES})
target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/oddysseus.desktop DESTINATION ${DATADIR}/applications/)
