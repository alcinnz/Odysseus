Odysseus web browser
====================

A simple and performant yet powerful [elementary OS](https://elementary.io/)-[style](https://elementary.io/docs/human-interface-guidelines) window onto the open decentralized web.

Odysseus is already and will continue to be a convenient, privacy-respecting,
[ethically designed](https://2017.ind.ie/ethical-design/), and opensource
(under the GPLv3+ license) web browser that should run great on any free desktop.
However work is ongoing to make Odysseus more convenient with handy navigation
aids that gently and unobtrusively guide you wherever you want to go online.

In doing so Odysseus aims to help you focus on the webpages that matter to you,
and to support the open decentralized web over the centralized services of today.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.alcinnz.odysseus.desktop) or [download a stable release](https://github.com/alcinnz/Odysseus/releases)

Technical Architecture
----------------------
In a nutshell Odysseus pulls together WebKitGTK and SQLite using GTK/Granite, splitting off minor enhancements to it's core UI into builtin "traits".

At the same time Odysseus pulls together the same SQLite database, web-APIs, and more into a templating language. Which is then used to develop helpful error pages and handy navigation aids accessible via a custom `odysseus:` URI scheme.

Building
----------

First ensure Git, Meson, Ninja, and the Vala compiler are installed, along with the GTK+ 3, [Granite](https://github.com/elementary/granite), WebKit2 GTK, LibJSON GLib, LibSoup 2.4, SQLite 3, [LibUnity](https://launchpad.net/libunity), and LibAppStream developer packages.

On elementary OS these dependencies can be installed with:

    sudo apt install meson valac libgtk-3-dev libsqlite3-dev libwebkit2gtk-4.0-dev
    sudo apt install libgranite-dev libjson-glib-dev libsoup2.4-dev libunity-dev libappstream-dev

If your on other Debian-based distributions these commands should still work, except you may find the libgranite-dev package is unavailable. You may need to follow their [installation instructions](https://github.com/elementary/granite).

Then within the repository's root run the fullowing commands (or some OS-specific variation):

    mkdir build
    cd build
    meson ..
    ninja
    sudo ninja install


Contributing
------------

For anyone interested in contributing new features, fixes, etc to Odysseus, pull requests are always welcome and there is a discussion [Matrix room](https://riot.im/app/#/room/#odysseus-web:matrix.org) for you to discuss your ideas or get help. If you don't know where to start, try one of these [feature requests](https://github.com/alcinnz/Odysseus/issues?q=is%3Aopen+is%3Aissue+label%3AEasy+label%3A%22help+wanted%22).

If you want to help teach Oddysseus a new language, please visit https://github.com/alcinnz/Odysseus/wiki/Localizing-Odysseus. Work is ongoing to make this easier.
