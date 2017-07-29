include (Translations)
    add_translations_directory(${GETTEXT_PACKAGE})
    add_translations_catalog(${GETTEXT_PACKAGE}
    ../src/
    DESKTOP_FILES
        ../data/io.github.alcinnz.odysseus.desktop
    APPDATA_FILES
        ../data/io.github.alcinnz.Odysseus.appdata.xml
    )

    # Compile our template translations into their own seperate format
    # TODO I'm not sure the custom command is working.
    add_custom_command(OUTPUT ${CMAKE_SOURCE_DIR}/data/page-l10n/Odysseus
            COMMAND ${CMAKE_SOURCE_DIR}/bin/template-strings.py
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR})
    file(GLOB page-l10n ${CMAKE_SOURCE_DIR}/data/page-l10n/*)
    install(FILES ${page-l10n} DESTINATION /usr/share/Odysseus/l10n)
