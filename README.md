Odysseus Web Browser
====================

**Designed for elementary OS**

At the moment Odysseus is quite rudimentary and does not yet support browser history or bookmarks. That said it's still quite comfortable for normal browsing. 

Design Principles
-----------------

<dl>
<dt>Oddysseus is a bridge between the elementary and Web user experiences.</dt>

<dd>elementary's UX is clearly defined with toolbars, tabbars, and sidebars visually part of the window decoration. As far as possible Oddysseus tries to be just an elementary window onto The Web. </dd>

<dd>The web's UX is less clear cut, but HTML's default styles and behaviours provide a distinct aesthetic. That said when designing pages don't be constrained to these defaults, if there's good usability or typography reason they can be overriden.</dd>

<dt>Guide users where they want to go.</dt>

<dd>As users try to go places, Odysseus should provide a gentle helping hand. It should avoid being burdensome and where it make sense pick up on subtle cues. </dd>

<dd>Odysseus's behaviour towards this end should be trivial to understand, as a set of independant "tools"/"traits". </dd>

<dt>Give users control over their privacy, no matter their skills.</dt>

<dd>Odysseus is a "User Agent", it serves it's users not webmasters. Give them the control over what's uploaded to the SEC (Someone Elses' Computers).</dd>

<dd>For it's own uses Odysseus should feel free to capture data, but only share it online with informed consent. Odysseus shouldn't even upload any information to a service operated by the project, as that would be asking for blind faith. </dd>
</dl>

Where in doubt, consult elementary's HIG. 

Technical Architecture
----------------------

At the moment Odysseus is simply some GTK/Granite chrome around WebKitGTK. For internal and error pages Odysseus incorporates a simple internal templating language based on Django's. 

Autocompletion of URIs are implemented by dispatching the entry's change event through a number of different sources, for their results to be loaded into a Gtk.ListStore and displayed in a Gtk.EntryCompletion. Work is ongoing to change the look and behaviour of the completion popup to be more appropriate to this usecase. 

INSTALLING
----------

I'd like elementary's AppHub to make this less technical, but to install: 

1. download off http://github.com/alcinnz/Oddysseus
2. In the untarred directory run:

:

    cmake .
    sudo make install

Contributing
------------

Feel free to create a pull request or open an issue. The coding convention is GNOME's naming conventions with 4 space indents, another 4 space line continuations, and no spaces between method calls & their argument lists. 

If you want to help teach Oddysseus a new language, please visit https://www.transifex.com/none-483/odysseus/dashboard/. 
