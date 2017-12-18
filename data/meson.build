icon_sizes = ['16', '24', '32', '48', '64', '128', '256']

foreach i : icon_sizes
    install_data(
        join_paths('icons', i, 'odysseus-web.svg'),
        install_dir: join_paths(get_option('datadir'), 'icons', 'hicolor', i + 'x' + i, 'apps')
    )
endforeach

languages = []
foreach lang : languages
    install_data(
        join_paths('page-l10n', lang),
        install_dir: '/usr/share/Odysseus/l10n'
    )
endforeach


install_data(
    'io.github.alcinnz.odysseus.desktop',
    install_dir: join_paths(get_option('datadir'), 'applications')
)

install_data(
    'io.github.alcinnz.Odysseus.appdata.xml',
    install_dir: join_paths(get_option('datadir'), 'metainfo')
)
