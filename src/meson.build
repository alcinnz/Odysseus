liberate_resources = gnome.compile_resources(
         'liberate-resources', 'ext/liberate/data/gresource.xml',
         source_dir: 'ext/liberate/data',
         c_name: 'liberate'
       )
liberate = ['Liberate', 'Reader']

sources = ['Odysseus', 'BrowserWindow', 'Persistance']
widgets = ['WebTab','ProgressBin','WebNotebook','DownloadButton','DownloadBar', 'Chromeless']
header_widgets = ['AddressBar', 'ButtonWithMenu', 'AutomaticScrollBox',
        'HeaderBarWithMenus']
overlay_widgets = ['FindToolbar', 'InfoContainer']
traits = ['init', 'download-progress', 'download-window']
nav_traits = ['autodownload', 'persist-tab-history', 'newtab', 'history',
        'errors', 'other-types', 'screenshot-proxy', 'viewsource']
decor_traits = ['alert', 'permit', 'settings', 'internal-favicons', 'AutoScroll',
        'fix-plus.google.com', 'fix-bg-videos', 'addressbar-autofocus',
        'notifications']
complete_traits = ['imply-http', 'duckduckgo', 'ddg-autocomplete', 'history']
indicators = ['https', 'local', 'webfeed', 'liberate']
services = ['pages', 'Completer', 'globals', 'icons']
db_services = ['database', 'util', 'prosody', 'completer', 'psuedorest']
prosody = ['parser', 'lib', 'data', 'expression', 'writers', 'loader',
        'slice']
prosody_misc = ['json', 'http', 'diff', 'i18n', 'tsv', 'favicons', 'test',
        'AppStream', 'mimeinfo']
prosody_misc = ['http', 'AppStream', 'mimeinfo', 'favicons',
        'json', 'tsv', 'xml',
        'diff', 'test', 'i18n']
models = ['Download', 'DownloadSet', 'ImageUtil', 'I18nUtil', 'StatusIndicator', 'Links']

foreach f : liberate
    sources += ['ext/liberate/' + f]
endforeach
foreach f : header_widgets
    widgets += ['header/' + f]
endforeach
foreach f : overlay_widgets
    widgets += ['overlays/' + f]
endforeach
foreach f : widgets
    sources += ['Widgets/' + f]
endforeach

foreach f : nav_traits
    traits += ['navigate/' + f]
endforeach
foreach f : decor_traits
    traits += ['decorate/' + f]
endforeach
foreach f : complete_traits
    traits += ['autocomplete/' + f]
endforeach
foreach f : indicators
    traits += ['status/' + f]
endforeach
foreach f : traits
    sources += ['Traits/' + f]
endforeach

foreach f : db_services
    services += ['database/' + f]
endforeach
foreach f : prosody_misc
    prosody += ['misc/' + f]
endforeach
foreach f : prosody
    services += ['Prosody/' + f]
endforeach
foreach f : services
    sources += ['Services/' + f]
endforeach

foreach f : models
    sources += ['Models/' + f]
endforeach
source_files = [about_pages, sql_scripts, l10n_pages, liberate_resources]
foreach f : sources
    source_files += [f + '.vala']
endforeach


c_args = ['-DGCR_API_SUBJECT_TO_CHANGE', '-include', 'config.h']
posix_dep = meson.get_compiler('vala').find_library('posix')

dependencies = [
    dependency('gtk+-3.0'),
    dependency('granite'),
    dependency('webkit2gtk-4.0'),
    dependency('json-glib-1.0'),
    dependency('gee-0.8'),
    dependency('libsoup-2.4'),
    dependency('sqlite3'),
    posix_dep,
    dependency('libxml-2.0'),
]
vala_args = []
if get_option('appstream')
    dependencies += [dependency('appstream')]
    vala_args += ['--define=HAVE_APPSTREAM']
endif
if get_option('gcr')
    dependencies += [dependency('gcr-3')]
    vala_args += ['--define=HAVE_GCR3']
endif

executable('com.github.alcinnz.odysseus',
    source_files,

    c_args: c_args,
    link_args: ['-lm'],
    vala_args: vala_args,
    dependencies: dependencies,
    install: true
)
