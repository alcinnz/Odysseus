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
/** Persists browser history, to be viewed via odysseus:history & eventually odysseus:home.

    Odysseus more info than other browsers, as it intends to use it to tell a
fully story of your browser history. */
namespace Odysseus.Traits {
    public void setup_history_tracker(WebTab tab) {
        var web = tab.web;
        var prev_uri = web.uri;
        var first = true; // Don't log session restoration!
        web.load_changed.connect((evt) => {
            if (evt == WebKit.LoadEvent.FINISHED && first) {
                prev_uri = web.uri; first = false; return;
            }
            if (evt != WebKit.LoadEvent.FINISHED ||
                    web.uri.has_prefix("odysseus:") || web.uri.has_prefix("source:") ||
                    prev_uri == web.uri ||
                    web.title == "") return;

            var stmt = Database.parse("""INSERT INTO page_visit
                    (tab, uri, title, favicon, visited_at, referrer)
                VALUES (
                    ?, ?, ?, ?, datetime('now', 'localtime'),
                    (SELECT rowid FROM page_visit WHERE tab = ? AND uri = ?)
            );""");
            stmt.bind_int(1, tab.historical_id);
            stmt.bind_text(2, web.uri);
            stmt.bind_text(3, web.title);
            stmt.bind_text(4, ""); // TODO
            stmt.bind_int(5, tab.historical_id);
            stmt.bind_text(6, prev_uri);

            stmt.step();
            prev_uri = web.uri;
        });
        /* NOTE: It'd be nice to save any URI changes to history,
            but on sites like OSM this can crowd out the other history entries
            unless we can distinguish between navigate and replace. */
    }
}
