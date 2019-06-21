{ stdenv, substituteAll
, appstream, cmake, gcr, gettext, glib, granite, gtk3
, html-xml-utils, json-glib, libgee, libsoup, meson, ninja, pkgconfig, python3
, sqlite, vala, webkitgtk, glib-networking, wrapGAppsHook
}:

stdenv.mkDerivation {
  name = "odysseus";

  src = ./..;

  patches = [
    (substituteAll {
      src = ./patches/hxwls-path.patch;
      hxwls = "${html-xml-utils}/bin/hxwls";
    })
  ];

  nativeBuildInputs = [
    gettext
    meson
    ninja
    pkgconfig
    python3
    vala
    wrapGAppsHook
  ];

  buildInputs = [
    appstream
    gcr
    glib
    glib-networking
    granite
    gtk3
    json-glib
    libgee
    libsoup
    sqlite
    webkitgtk
  ];

  meta = with stdenv.lib; {
    description = "A simple and performant yet powerful elementary OS-style window onto the open decentralized web";
    homepage = "https://odysseus.adrian.geek.nz";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = [ maintainers.worldofpeace ];
  };
}
