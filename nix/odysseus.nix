{ stdenv
, appstream, cmake, gcr, gettext, glib, granite, gtk3
, html-xml-utils, json-glib, libgee, libsoup, meson, ninja, pkgconfig, python3
, sqlite, vala, webkitgtk
}:

stdenv.mkDerivation {
  name = "odysseus";
  nativeBuildInputs = [ gettext meson ninja pkgconfig python3 vala ];
  buildInputs = [ appstream gcr glib granite gtk3 html-xml-utils json-glib
                  libgee libsoup sqlite webkitgtk ];
  src = ./..;
}
