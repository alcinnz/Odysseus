Odysseus Web Browser
====================

**Designed for elementary OS**

The goals (beyond following the elementary OS HIG) for Odysseus are:
1. Make the chrome look like nothing more than standard elementary OS window dressing
2. Provide tools to help users find where they want to go on the web
3. Support restricting how webpages can invade user privacy, catering to all skill levels
4. Reduce inconsistancies between WebKit and elementary OS

The design of the browsing tools described in goal 2 would be informed by the following principles:
* Avoid requiring any maintainance from the user
* Provide different tools for different circumstances
* Utilize a Web UX (over a native GTK UX) for it's links and to simplify the chrome
* Tags are easier to manage and assign then a folder hierarchy
* Screenshots are quicker to recognize then labels
* Let users semi-manually customize their search experience
* Utilize web standards whereever possible
* Keep data local where possible, and be explicit when data is shared

Technical Design
----------------

Odysseus mainly serves to integrate three Vala modules:
* GTK/Granite - for browser chrome
* (raw) SQLite - for user data
* WebKit - to render the Web

It may further use LibSoup and various parsers to implement browsing aids. 

To offer per-page permissions as well as enriching discovery tools while not slowing down page load unnecessarily, Odysseus offers data structures to combine checks together as much as possible. Specifically it will offer:
* Something between a trie & a deterministic finite automaton to optimize URL matching
* An XPath trie to optimize matching webpage content
* And a hashtable to optimize matching MIMEtypes

Most of these extensions will either adjust the behaviour of the WebView or extend the address bar. Specifically extensions should be able to:
* Insert "tokens" to the left - to aid searching bookmarks & history
* Add extra toggle buttons to the right - to allow users to add tag vocabularies, search engines, content blockers, etc
* Extend the autocompletions for any query
