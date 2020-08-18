/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2020).
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
/** Allows searching bookmarks by tag. */
namespace Odysseus.Traits {
    public class Bookmarks : Tokenized.CompleterDelegate {
        public override void autocomplete(string query, Tokenized.Completer c) {
            // Gather tag IDs
            var tags = new int64?[c.tags.size];
            foreach (var i = 0; i < c.tags.size; i++) {
                tags[i] = int64.parse(c.tags[i].val);
            }
            // Determine related, matching tags.
            foreach (var tag in Services.Database.Tagging.related_tags(c.tags)) {
                // query to see if the name matches query, if provided.
                // query to find label.
                c.token(tag, query);
            }
        }
    }
}
