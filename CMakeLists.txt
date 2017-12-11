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
set (PKGDATADIR "${DATADIR}/odysseus")

set (EXEC_NAME "io.github.alcinnz.odysseus")
set (RELEASE_NAME "A web browser for elementary OS")
set (VERSION "0.1")
set (VERSION_INFO "development")

# Translation files
set (GETTEXT_PACKAGE "${CMAKE_PROJECT_NAME}")
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)

# we're about to use pkgconfig to make sure dependencies are installed so let's find pkgconfig first
find_package(PkgConfig)

# now let's actually check for the required dependencies
pkg_check_modules(DEPS REQUIRED gtk+-3.0 granite webkit2gtk-4.0 json-glib-1.0
        gee-0.8 libsoup-2.4 sqlite3)

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
    src/Odysseus.vala
    src/BrowserWindow.vala
    src/Persistance.vala
    src/Widgets/header/AddressBar.vala
    src/Widgets/WebTab.vala
    src/Widgets/header/ButtonWithMenu.vala
    src/Widgets/overlays/FindToolbar.vala
    src/Widgets/DownloadButton.vala
    src/Widgets/DownloadBar.vala
    src/Widgets/ProgressBin.vala
    src/Widgets/overlays/InfoContainer.vala
    src/Widgets/header/AutomaticScrollBox.vala
    src/Widgets/WebNotebook.vala
    src/Widgets/header/HeaderBarWithMenus.vala

    src/Services/pages.vala
    src/Services/Prosody/byteutils.vala
    src/Services/Prosody/data.vala
    src/Services/Prosody/diff.vala
    src/Services/Prosody/expression.vala
    src/Services/Prosody/lib.vala
    src/Services/Prosody/parser.vala
    src/Services/Prosody/writers.vala
    src/Services/Prosody/loader.vala
    src/Services/Prosody/i18n.vala
    src/Services/Completer.vala
    src/Services/globals.vala
    src/Services/database/database.vala
    src/Services/database/util.vala

    src/Traits/navigate/viewsource.vala
    src/Traits/navigate/errors.vala
    src/Traits/init.vala
    src/Traits/navigate/autodownload.vala
    src/Traits/decorate/alert.vala
    src/Traits/decorate/permit.vala
    src/Traits/autocomplete/imply-http.vala
    src/Traits/autocomplete/duckduckgo.vala
    src/Traits/autocomplete/ddg-autocomplete.vala
    src/Traits/navigate/persist-tab-history.vala
    src/Traits/decorate/settings.vala
    src/Traits/decorate/internal-favicons.vala

    src/Models/Download.vala
    src/Models/DownloadSet.vala


# tell what libraries to use when compiling
PACKAGES
    gtk+-3.0
    granite
    webkit2gtk-4.0
    json-glib-1.0
    gee-0.8
    posix
    libsoup-2.4
    sqlite3
)

# Bundle in about: page templates
include(GResource)
glib_compile_resources(GLIB_RESOURCES_PAGES SOURCE data/pages/about-pages.gresource.xml)
glib_compile_resources(GLIB_RESOURCES_DB SOURCE data/db/database.gresource.xml)

# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${VALA_C} ${GLIB_RESOURCES_PAGES} ${GLIB_RESOURCES_DB})
target_link_libraries(${EXEC_NAME} ${DEPS_LIBRARIES})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
configure_file_translation(${CMAKE_SOURCE_DIR}/data/io.github.alcinnz.odysseus.desktop ${CMAKE_BINARY_DIR}/data/io.github.alcinnz.odysseus.desktop ${CMAKE_SOURCE_DIR}/po/extra/)
install (FILES ${CMAKE_BINARY_DIR}/data/io.github.alcinnz.odysseus.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/256/odysseus-web.svg DESTINATION share/icons/hicolor/256x256/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/128/odysseus-web.svg DESTINATION share/icons/hicolor/128x128/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/64/odysseus-web.svg DESTINATION share/icons/hicolor/64x64/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/48/odysseus-web.svg DESTINATION share/icons/hicolor/48x48/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/32/odysseus-web.svg DESTINATION share/icons/hicolor/32x32/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/24/odysseus-web.svg DESTINATION share/icons/hicolor/24x24/apps)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/16/odysseus-web.svg DESTINATION share/icons/hicolor/16x16/apps)
