project('com.github.alcinnz.odysseus', ['vala', 'c'],
    version: '1.0.0',
    license: 'GNU',
    meson_version: '>=0.40.1')

gnome = import('gnome')
i18n = import('i18n')

about_pages = gnome.compile_resources(
    'about-pages', 'data/pages/about-pages.gresource.xml',
    source_dir: 'data/pages',
    c_name: 'ap')
sql_scripts = gnome.compile_resources(
    'sql-scripts', 'data/db/database.gresource.xml',
    source_dir: 'data/db',
    c_name: 'sqlscripts')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

subdir('data')
subdir('po')
subdir('src')
subdir('ext')
