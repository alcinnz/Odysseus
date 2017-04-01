This folder contains the HTML/Templated error messages for various network errors.

The goals are to be thorough in regards to the errors that might occur, non-technical in the explanations, and helpful in getting out of these situations. Beyond that it helps to be personable (which some may find funny) as that not only helps relieve frustration but makes it easier to be nontechnical. Furthermore the page title should be in all-uppercase in order to differentiate error pages from pretty much all other web pages. 

Currently this folder contains files for all the standard HTTP error statuses (though some which are almost certainly not going to be encountered aren't HTML formatted), and all the errors WebKit might report to us. 

ASSIGNING ICONS
---------------

WebKit refuses to show icons from different domains, and will interpret any common icons we provide as being on a different domain. As such, we don't use favicon links to assign URIs. Instead we specify the icons as seperate resources, which tells our chrome (instead of WebKit) which system icon to use. Besides this techique is more succinct and can in total save a fair few bytes.

The logic here ensures that these pages uses the more simplistic symbolic icons where they exist, again to contrast against tendancies on the broader web. 

Templating
----------

When one of these pages show, we want to help the reader fix the problem as quickly as possible. To make it easier for us to help them the base URL for any of these pages is that of the erroring page (this means no templating or JavaScript is required to reload the page or navigate to another page on the site). Furthermore the "url" outputs the page's URL while allowing you to use subproperties to access it's different components. 
