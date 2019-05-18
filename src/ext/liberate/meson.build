lib_sources = files(
    'Liberate.vala',
    'Reader.vala',
)

lib_gi_name = meson.project_name()
lib_gi_version = '1.0'

lib_gi = lib_gi_name + '-' + lib_gi_version
lib_gir = lib_gi + '.gir'
lib_typelib = lib_gi + '.typelib'

include_dir = join_paths(
    get_option('prefix'),
    get_option('includedir'),
    meson.project_name()
)

asresources = gnome.compile_resources(
  'as-resources', 'data/gresource.xml',
  source_dir: 'data',
  c_name: 'as'
)

lib = library(
    meson.project_name(),
    lib_sources,
    asresources,
    dependencies: [
        lib_deps,
        meson.get_compiler('c').find_library('m'),
    ],

    vala_header: meson.project_name() + '.h',
    vala_vapi: meson.project_name() + '.vapi',
    vala_gir: lib_gir,

    version: meson.project_version(),
    install: true,
    install_dir: [true, include_dir, true, true],
)

install_data(
    meson.project_name() + '.deps',
    install_dir: join_paths(get_option('datadir'), 'vala', 'vapi')
)

# typelib generation isn't automated yet
g_ir_compiler = find_program('g-ir-compiler')
custom_target(
    lib_typelib,
    command: [
        g_ir_compiler,
        '--shared-library',
        lib.full_path(),
        '--output',
        '@OUTPUT@',
        join_paths(meson.current_build_dir(), lib_gir),
    ],
    output: lib_typelib,
    depends: lib,
    install: true,
    install_dir: join_paths(get_option('libdir'), 'girepository-1.0'),
)

lib_dep = declare_dependency(
    link_with: lib,
    dependencies: lib_deps,
    include_directories: [include_directories('.')],
)

lib_pc = pkgconfig.generate(
    lib,
    name: meson.project_name(),
    requires: lib_deps,
    subdirs: [meson.project_name()],
    description: 'Reader mode for libwebkit2gtk',
    version: meson.project_version(),
    url: 'https://github.com/bleakgrey/liberate',
)
