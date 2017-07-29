/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017).
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
/** Suggests the user "quacks" what they entered into the addressbar. */
namespace Odysseus.Traits.Search {
    public class DuckDuckGo : Services.CompleterDelegate {

        public override void autocomplete() {
            suggest("http://duckduckgo.com/?q=" + Soup.URI.encode(query, null),
                    "🔍\t" + query);
        }
    }
}
