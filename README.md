Odysseus Web Browser
====================

**Designed for elementary OS**

At the moment Odysseus is quite rudimentary and does not yet support browser history or bookmarks. It however does include several subtle features to make basic web surfing very nice, and support for browser history is being implemented. 

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

At the moment Odysseus is simply some GTK/Granite chrome around WebKitGTK. For internal and error pages Odysseus incorporates a simple internal templating language based on Django's. 

Autocompletion of URIs are implemented by dispatching the entry's change event through a number of different sources, for their results to be added as widgets to a Gtk.ListBox presented within a scrolled popover. 

INSTALLING
----------

I'd like elementary's AppHub to make this less technical, but to install: 

1. download off http://github.com/alcinnz/Oddysseus
2. In the untarred directory run:

:

    mkdir build
    cd build
    meson ..
    ninja
    sudo ninja install
    
(you will need to install Meson). 

Contributing
------------

Feel free to create a pull request or open an issue. The coding convention is GNOME's naming conventions with 4 space indents, another 4 space line continuations, and no spaces between method calls & their argument lists. 

If you want to help teach Oddysseus a new language, please visit https://www.transifex.com/none-483/odysseus/dashboard/. 
