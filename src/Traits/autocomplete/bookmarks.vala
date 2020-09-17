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
		private Sqlite.Statement qGetName = Database.parse("SELECT label FROM tags WHERE rowid = ?;");
		private Sqlite.Statement qQueryName = Database.parse("SELECT * FROM tag_labels WHERE tag = ? AND altlabel LIKE ?;");
        public override void autocomplete(string query, Tokenized.Completer c) {
			if (query == null || query == "") return; // Prefer URL autocompletion...

            // Gather tag IDs
            var tags = new Gee.ArrayList<int64?>();
            var params_builder = new StringBuilder();
            for (var i = 0; i < c.tags.size; i++) {
                tags[i] = int64.parse(c.tags[i].val);
                params_builder.append("t=");
                params_builder.append(c.tags[i].val);
                params_builder.append("&");
            }
            var param = params_builder.str;

            // Determine related, matching tags.
            foreach (var tag in Database.Tagging.related_tags(tags)) {
                // query to find label.
                qGetName.reset();
                qGetName.bind_int64(1, tag);
                if (qGetName.step() != Sqlite.ROW) continue;
                var name = qGetName.column_text(0);
                if (name == null) continue;

                // query to see if the name matches query, if provided.
                // SELECT * FROM tag_labels WHERE tag = ? AND altlabel = ?;
                if (!name.contains(query)) {
                    qQueryName.reset();
                    qQueryName.bind_int64(1, tag);
                    qQueryName.bind_text(2, "%" + query + "%");
                    if (qGetName.step() != Sqlite.ROW) continue;
                }
                c.suggestion(@"odysseus:bookmarks?$(param)t=$tag", name);
            }
        }
    }
}
