Oddysseus Web Browser
====================

**Designed for elementary OS**

The goals (beyond following the elementary OS HIG) for Oddysseus are:

1. Make the chrome look like nothing more than standard elementary OS window dressing
2. Provide tools to help users find where they want to go on the web
3. Support restricting how webpages can invade user privacy, catering to all skill levels
4. Reduce inconsistancies between WebKit and elementary OS (some of these fixes will need to be made to WebKitGTK)

Oddysseus's users may or may not be power-users, but what they have in common is that they want to focus on the Web's content and less on the application they browse it with. 

The design of the browsing tools described in goal 2 will be informed by the following principles:
* Avoid requiring any maintainance from the user
* Provide different tools for different circumstances
* Be skimmable
* Utilize a Web UX (over a native GTK UX)
* Utilize web standards whereever possible
* Keep data local where possible, and be explicit when data is shared

The reasons why I opt for a WebUX for the link management tools are because a) links and typography are a stronger part of the WebUX (in fact they're the strongest parts of the WebUX) than they are of the GTK UX and b) it adds the least complexity to my surrounding chrome. 

At the moment Oddysseus is quite rudimentary and does not yet support those link management tools. It doesn't even support global history or bookmarks! That said it does implement just enough for browsing the Web to be comfortable. 

Technical Architecture
----------------------

At the moment Oddysseus is simply some GTK/Granite chrome around WebKitGTK. For internal and error pages Oddysseus incorporates a simple internal templating language based on Django's. 

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

If you want to help teach Oddysseus a new language, please visit https://poeditor.com/join/project/CXYmd0gvmt. 
