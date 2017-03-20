about:* Pages
=============

This directory contains the internal about: pages that report errors and helps the user find links. Right now its the early days so it's not that helpful yet.

The way this works is:

1. These pages are loaded into the executable file using GIO's Resources. 
2. In the about: URI handler for WebKit it loads the appropriate GResource to hand over.
3. It also loads the corrosponding *.mime resource to report the MIMEtype of the resource (defaults to "+text/html").
4. If the given MIMEtype starts with +, strip it and run the internal templating language over the resource.
5. WebKit displays the page
6. Forms and JavaScript on these pages are allowed to POST or UPDATE about:database/* pages, which'll mutate the SQLite database before reloading the referring page.

The templating language is syntactically very similar to [Django's](https://docs.djangoproject.com/en/1.10/ref/templates/language/) though it's tags differ somewhat, and the basics should be familiar to anyone who's used a web framework like [Django](https://www.djangoproject.com/), [Ruby on Rails](http://rubyonrails.org/), or even [node.js](https://nodejs.org/en/). You can call this language "Prosody" if you need a name.

Design Guidelines
-----------------

As stated in the README, the goals for these pages are:

* Avoid requiring any maintainance from the user
* Provide different tools for different circumstances
* Be skimmable
* Utilize a Web UX (over a native GTK UX)
* Utilize web standards whereever possible
* Keep data local where possible, and be explicit when data is shared

Visually the pages should, where it's aesthetically pleasing, rely on web defaults for their appearance. Where the aesthetics and/or afforances are lacking, the look should angle towards that of elementary OS. And (unlike several other browsers) our error and other pages should not be branded.

Behaviourally tags are used for organizing links over a folder hierarchy as they induce less structure that the user would need to manage. And when a user inevitably fails to maintain their bookmark hierarchy it tends to go to waste. Meanwhile to improve skimmability, screenshots can be useful as they are more instantly recognized than names or labels.

Finally nothing in these internal pages should duplicate behaviour provided by the chrome. 

Code Guidelines
---------------

* Use 2 spaces for indenting SQL, Prosody, HTML, CSS, & Javascript.
* Don't indent the &lt;head&gt; or &lt;body&gt; HTML tags
* Follow [Zepto.js's Style Guid for JavaScript](https://github.com/madrobby/zepto/blob/master/CONTRIBUTING.md#code-style-guidelines)
* Write version [ES6](http://es6-features.org/) JavaScript, and avoid typing "function".
* Try to write cross-browser code for readability <br /> BUT don't write vendor prefixes or fallbacks not required by the latest WebKit (as that's all we'll run it on).
* Use lowerCamelCase for JavaScript variables but underscore_seperators for Prosody and SQL.

--

* Use each language for what it's good at: <strong>SQL</strong> for <em>logic</em>, <strong>Prosody</strong> for <em>data mapping</em>, <strong>HTML</strong> for <em>structuring the text</em>, <strong>CSS</strong> for <em>custom appearance</em>, & <strong>JavaScript</strong> for <em>custom behaviours</em>.
* Don't use AJAX [to cover up latency](http://www.oreilly.com/catalog/headra/chapter/ch01.pdf) &mdash; we don't have any.
* Write [meaningful CSS](https://alistapart.com/article/meaningful-css-style-like-you-mean-it)
* Where you use third party libraries, host the uncompressed version in the application bundle so it works offli

Finally the more you use CSS or particularly JavaScript, the more we'll question whether you're adhearing to the design guidelines of relying on the browser's defaults. 

Most importantly document the design of each internal page in a preceding template comment for it's file. 
