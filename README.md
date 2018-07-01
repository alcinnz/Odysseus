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

Technical Architecture
----------------------
In a nutshell Odysseus pulls together WebKitGTK and SQLite using GTK/Granite, splitting off minor enhancements to it's core UI into builtin "traits".

At the same time Odysseus pulls together the same SQLite database, web-APIs, and more into a templating language. Which is then used to develop helpful error pages and handy navigation aids accessible via a custom `odysseus:` URI scheme.

INSTALLING
----------

The simple way is to [use the elementary AppCenter](https://appcenter.elementary.io/com.github.alcinnz.odysseus.desktop).

But if you're not running elementary OS (and hasn't been packaged for your operating system by a third party), or you simply want to contribute to the project:

    git clone https://github.com/alcinnz/Odysseus.git
    mkdir build
    cd build
    meson ..
    ninja
    sudo ninja install
    
(you will need to install Meson and Git for this to work). 

Contributing
------------

Help is always appreciated, so feel free to open a pull request! If you want to help but don't know what to do, take a look through Odysseus's issues. I'll be labelling several of them as "help-wanted" so I can focus on achieving the big picture described in this README.

For developers, the coding convention for Vala is GNOME's naming conventions with 4 space indents, another 4 space line continuations, and no spaces between method calls & their argument lists. Other style guides are strawn across the repository.

If you want to help teach Oddysseus a new language, please visit https://github.com/alcinnz/Odysseus/wiki/Localizing-Odysseus. 
