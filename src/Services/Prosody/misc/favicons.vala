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
/** Template filter for accessing the WebKit Favicon Database. */
namespace Odysseus.Templating.x {

    /** Translates a URI into one for it's favicon. */
    private class FaviconFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            var db = get_web_context().get_favicon_database();
            var uri = db.get_favicon_uri(@"$a");
            return new Data.Literal(uri == null ?
                "icon:16/web-browser-symbolic" : uri);
        }
    }
}
