This folder contains third party JavaScript (and/or CSS) libraries used in Oddysseus's internal pages. 

So far they include:

<dl>
<dt>highlight.js (with Django, HTML/XML, CSS, JavaScript, & SQL highlighting + Solarized Light Theme)</dt>
<dd>Adds syntax highlighting for view source and debugging pages.</dd>
<dd>As opposed to what Vala has for syntax highlighting (the Gtk.SourceView) this can work with HTML/WebKit as opposed to being it's own custom control.</dd>
</dl>

In using a library please make sure it doesn't come with functions we won't use, as we should be cogniscent of our download size. At the same time the user won't be waiting for Oddysseus to download each time they use it, so we can afford to use the uncompressed versions of our libraries. 
