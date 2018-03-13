Odysseus Web Browser
====================

**Designed for elementary OS**

Odysseus aims to be a simple yet powerful web browser that makes surfing the web a breeze.

It's not there yet, but work is actively ongoing to ease your surfing with vital navigation aids. 

Design Principles
-----------------

<dl>
<dt>Oddysseus is a bridge between the elementary and Web user experiences.</dt>

<dd>elementary's UX is clearly defined with toolbars, tabbars, and sidebars visually part of the window decoration. As far as possible Oddysseus tries to be just an elementary window onto The Web. </dd>

<dd>The web's UX is less clear cut, but HTML's default styles and behaviours provide a distinct aesthetic. That said when designing pages don't be constrained to these defaults, if there's good usability or typography reason they can be overriden.</dd>

<dt>Guide users where they want to go.</dt>

<dd>As users try to go places, Odysseus should provide a gentle helping hand. It should avoid being burdensome and where it make sense pick up on subtle cues. </dd>

<dd>Odysseus's behaviour towards this end should be trivial to understand, as a set of independant "tools"/"traits". </dd>

<dt>Make the web as a whole better, not particular sites.</dt>

<dd>Odysseus has no idea which sites you'll want to use with it, and it's developers wish to avoid giving an extra leg up to the already dominant sites. So Odysseus should avoid specially integrating any websites, and when it does the sites it integrates should similar aim to make the whole Web better.</dd>

<dt>Give users control over their privacy, no matter their skills.</dt>

<dd>Odysseus is a "User Agent", it serves it's users not webmasters. Give them the control over what's uploaded to the SEC (Someone Elses' Computers).</dd>

<dd>For it's own uses Odysseus should feel free to capture data, but only share it online with informed consent. Odysseus shouldn't even upload any information to a service operated by the project, as that would be asking for blind faith. </dd>
</dl>

Where in doubt, consult elementary's HIG. 

Technical Architecture
----------------------

At the base Odysseus is a simple GTK/Granite wrapper around WebKitGTK. From there additional conveniences (like middle-click scrolling and the tracking of browser history) are implemented as independant chunks of code enhancing the WebKit WebView.

The state of your open tabs and windows are saved into an SQLite database. This database is further used to save data about pages you may want to revisit, and can be rendered into local webpages using the custom `odysseus:` URI scheme (amongst a few others). These custom URI schemes use a templating language to move data from the database into the webpages they generate. That is currently being used to implement browser history, and soon topsites, bookmarks, extensions, and more.

Autocompletion of URIs are implemented by dispatching the entry's change event through a number of different sources, for their results to be added as widgets to a Gtk.ListBox presented within a scrolled popover. 

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

Feel free to create a pull request or open an issue. The coding convention is GNOME's naming conventions with 4 space indents, another 4 space line continuations, and no spaces between method calls & their argument lists. 

If you want to help teach Oddysseus a new language, please visit https://www.transifex.com/none-483/odysseus/dashboard/. 
