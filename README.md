Odysseus has been discontinued. After a neglecting Odysseus for too long I (Adrian Cochrane) have decided to discontinue its development in favor of contributing what I consider some of its most important features to [elementary's default browser](https://appcenter.elementary.io/org.gnome.Epiphany/), & developing [my own browser engines](https://rhapsode.adrian.geek.nz/). If you wish to continue its development, please offer to take over maintenance & port it to newer elementary releases.

Odysseus web browser
====================

[![Build Status](https://travis-ci.com/alcinnz/Odysseus.svg?branch=master)](https://travis-ci.com/alcinnz/Odysseus)

A simple and performant yet powerful [elementary OS](https://elementary.io/)-[style](https://elementary.io/docs/human-interface-guidelines) window onto the open decentralized web, exploring how best to help you (re)discover interesting/entertaining/useful/etc webpages!

Odysseus is already and will continue to be a convenient, privacy-respecting,
[ethically designed](https://2017.ind.ie/ethical-design/), and opensource
(under the GPLv3+ license) web browser that should run great on any free desktop.
However work is ongoing to make Odysseus more convenient with handy navigation
aids that gently and unobtrusively guide you wherever you want to go online.

In doing so Odysseus aims to help you focus on the webpages that matter to you,
and to support the open decentralized web over the centralized services of today.

[![Get it on AppCenter](https://appcenter.elementary.io/badge.svg)](https://appcenter.elementary.io/com.github.alcinnz.odysseus.desktop) or [download a stable release](https://github.com/alcinnz/Odysseus/releases)

Discovery features
------------------

Odysseus wants to help you (re)discover the best of the web without relying on any one webservice! To this end it features:

* Tracks your top-visited websites to be linked to on the default homepage.
* Lets you set multiple homepages, with a random one loading for each new tab.
* Hardcodes some initial recommendations to get you started.
* Echos back frequently encountered unvisited links as personalized recommendations.
* Helps you subscribe to "webfeeds" offered by most websites, including YouTube.
* (In progress) Redesigned bookmarking
* (TODO) Bookmark sharing
* (TODO) Combined websearch

Issues From Other Platforms
---------------------------
While Odysseus is primarily targetted towards elementary OS, I do welcome issues
to be reported about breakages in other platforms. And I welcome Odysseus's app
icon to be reworked for those themes as well, whether you want to contribute that
work to my repository or their's.

Because I've had an easy dealing with past issues in this regard, and I have people
interested in using Odysseus on those other platforms. I want them to have a great
experience too.

**NOTE:** This notice is in no way a condemnation of app devs who are asking not to
have to deal with these issues. It should only indicate that some app devs have an
easier time dealing with them than others through no fault of their own.

Technical Architecture
----------------------
In a nutshell Odysseus pulls together WebKitGTK and SQLite using GTK/Granite, splitting off minor enhancements to it's core UI into builtin "traits".

At the same time Odysseus pulls together the same SQLite database, web-APIs, and more into a templating language. Which is then used to develop helpful error pages and handy navigation aids accessible via a custom `odysseus:` URI scheme.

Building
----------

First ensure Git, W3C's HTML XML Utils (optional), Meson, Ninja, and the Vala compiler are installed, along with:

* GTK+ 3
* [Granite](https://github.com/elementary/granite)
* WebKit2 GTK
* JSON GLib
* LibSoup 2.4
* SQLite 3
* LibAppStream
* LibGCR 3
* Gettext

developer packages.

On elementary OS these dependencies can be installed with:

    sudo apt install meson valac libgtk-3-dev libsqlite3-dev libwebkit2gtk-4.0-dev libgranite-dev
    sudo apt install libjson-glib-dev libsoup2.4-dev libappstream-dev libgcr-3-dev gettext html-xml-utils

If your on other Debian-based distributions these commands should still work, except you may find the libgranite-dev package is unavailable. You may need to follow their [installation instructions](https://github.com/elementary/granite).

Then within the repository's root run the fullowing commands (or some OS-specific variation):

    mkdir build
    cd build
    meson ..
    ninja
    sudo ninja install


Contributing
------------
Please see [the guide](https://odysseus.adrian.geek.nz/guides/contributing.html), and join the
[Matrix room](https://riot.im/app/#/room/#odysseus-web:matrix.org) to discuss your ideas or get help.
