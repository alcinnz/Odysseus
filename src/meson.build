sources = ['Odysseus', 'BrowserWindow', 'Persistance']
widgets = ['WebTab','ProgressBin','WebNotebook','DownloadButton','DownloadBar']
header_widgets = ['AddressBar', 'ButtonWithMenu', 'AutomaticScrollBox',
        'HeaderBarWithMenus']
overlay_widgets = ['FindToolbar', 'InfoContainer']
traits = ['init', 'download-progress', 'download-window']
nav_traits = ['viewsource', 'errors', 'autodownload', 'persist-tab-history']
decor_traits = ['alert', 'permit', 'settings', 'internal-favicons']
complete_traits = ['imply-http', 'duckduckgo', 'ddg-autocomplete']
services = ['pages', 'Completer', 'globals']
db_services = ['database', 'util']
prosody = ['parser', 'lib', 'data', 'expression', 'writers', 'loader',
        'byteutils', 'jsondata', 'diff', 'i18n']
models = ['Download', 'DownloadSet']

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
foreach f : traits
    sources += ['Traits/' + f]
endforeach

foreach f : db_services
    services += ['database/' + f]
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
source_files = [about_pages, sql_scripts]
foreach f : sources
    source_files += [f + '.vala']
endforeach


c_args = ['-include', 'config.h']
posix_dep = meson.get_compiler('vala').find_library('posix')

executable('io.github.alcinnz.Odysseus',
    source_files,

    c_args: c_args,
    link_args: ['-lm'],
    dependencies: [
        dependency('gtk+-3.0'),
        dependency('granite'),
        dependency('webkit2gtk-4.0'),
        dependency('json-glib-1.0'),
        dependency('gee-0.8'),
        dependency('libsoup-2.4'),
        dependency('sqlite3'),
        dependency('unity'),
        posix_dep
    ],
    install: true
)
