/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2018).
*
* Odysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Odysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Odysseus.  If not, see <http://www.gnu.org/licenses/>.
*/
/* Fix for the blurriness of Google Plus's fonts.

Not really something I want to build into Odysseus as I'd rather focus it should
    focus on making the whole web better, not just specific sites. Besides
    this only covers the symptoms, and not the real issue. */
namespace Odysseus.Traits {
    public void fix_google_plus(WebKit.WebView web) {
        var css = new WebKit.UserStyleSheet("* {-webkit-font-smoothing: subpixel-anialiased;}",
                WebKit.UserContentInjectedFrames.TOP_FRAME,
                WebKit.UserStyleLevel.USER,
                new string[] {"https://plus.google.com/*"}, new string[0]);
        web.user_content_manager.add_style_sheet(css);
    }
}
