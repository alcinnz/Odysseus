/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2017).
*
* Oddysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Oddysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Oddysseus.  If not, see <http://www.gnu.org/licenses/>.
*/
/** Suggests the user "quacks" what they entered into the addressbar. */
namespace Oddysseus.Traits.Search {
    public class DuckDuckGo : Services.CompleterDelegate {

        public DuckDuckGo(Services.Completer completer, string query = "") {
            this.completer = completer; this.query = query;
        }

        public override void autocomplete() {
            suggest("http://duckduckgo.com/?q=" + Soup.URI.encode(query, null),
                    "🔍\t" + query);
        }
    }
}
