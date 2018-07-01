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

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.USER.REPO) or [download a stable release](https://github.com/alcinnz/Odysseus/releases)

Technical Architecture
----------------------
In a nutshell Odysseus pulls together WebKitGTK and SQLite using GTK/Granite, splitting off minor enhancements to it's core UI into builtin "traits".

At the same time Odysseus pulls together the same SQLite database, web-APIs, and more into a templating language. Which is then used to develop helpful error pages and handy navigation aids accessible via a custom `odysseus:` URI scheme.

Building
----------

First ensure Git, Meson, Ninja, and the Vala compiler are installed, along with the GTK+ 3, [Granite](https://github.com/elementary/granite), WebKit2 GTK, LibJSON GLib, LibSoup 2.4, SQLite 3, [LibUnity](https://launchpad.net/libunity), and LibAppStream developer packages.

Then within the repository's root run the fullowing commands (or some OS-specific variation):

    mkdir build
    cd build
    meson ..
    ninja
    sudo ninja install


Contributing
------------

Help is always appreciated, so feel free to open a pull request! If you want to help but don't know what to do, take a look through Odysseus's issues. I'll be labelling several of them as "help-wanted" so I can focus on achieving the big picture described in this README.

For developers, the coding convention for Vala is GNOME's naming conventions with 4 space indents, another 4 space line continuations, and no spaces between method calls & their argument lists. Other style guides are strawn across the repository.

If you want to help teach Oddysseus a new language, please visit https://github.com/alcinnz/Odysseus/wiki/Localizing-Odysseus. 
