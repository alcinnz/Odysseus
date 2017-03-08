include (Translations)
    add_translations_directory(${GETTEXT_PACKAGE})
    add_translations_catalog(${GETTEXT_PACKAGE}
    ../src/
    DESKTOP_FILES
        ../data/oddysseus.desktop
    APPDATA_FILES
        ../data/io.github.alcinnz.Oddysseus.appdata.xml
)
