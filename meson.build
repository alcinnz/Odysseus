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
l10n_pages = gnome.compile_resources(
    'page-l10n', 'data/page-l10n/l10n.gresource.xml',
    source_dir: 'data/page-l10n',
    c_name: 'pagel10n')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')

subdir('data')
subdir('po')
subdir('src')
if get_option('nofts5')
else
    subdir('ext')
endif
