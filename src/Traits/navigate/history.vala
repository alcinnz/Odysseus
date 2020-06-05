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

        var qSaveHistory = Database.parse("""INSERT INTO page_visit
                (tab, uri, title, favicon, visited_at, referrer)
            VALUES (
                ?, ?, ?, ?, datetime('now', 'localtime'),
                (SELECT rowid FROM page_visit WHERE tab = ? AND uri = ?)
        );""");
        var qSaveScreenshot = Database.parse("INSERT OR REPLACE INTO screenshot(uri, image) VALUES (?, ?);");

        web.load_changed.connect((evt) => {
            if (evt == WebKit.LoadEvent.FINISHED && tab.is_restoring) {
                prev_uri = web.uri; return;
            }
            if (evt != WebKit.LoadEvent.FINISHED ||
                    web.uri.has_prefix("odysseus:") || web.uri.has_prefix("source:") ||
                    prev_uri == web.uri ||
                    web.title == "") return;

            qSaveHistory.reset();
            qSaveHistory.bind_int(1, tab.historical_id);
            qSaveHistory.bind_text(2, web.uri);
            qSaveHistory.bind_text(3, web.title);
            qSaveHistory.bind_text(4, ""); // TODO
            qSaveHistory.bind_int(5, tab.historical_id);
            qSaveHistory.bind_text(6, prev_uri);

            qSaveHistory.step();
            prev_uri = web.uri;
            var uri = web.uri;

            web.get_snapshot.begin(WebKit.SnapshotRegion.FULL_DOCUMENT,
                    WebKit.SnapshotOptions.NONE, null, (obj, res) => {
                Cairo.Surface surface = null;
                try {
                    surface = web.get_snapshot.end(res);
                } catch (Error err) {return;}

                const int DESIRED_SIZE = 256;
                var width = (double) web.get_allocated_width();
                var pixbuf = new Gdk.Pixbuf(Gdk.Colorspace.RGB, false, 8,
                        DESIRED_SIZE, DESIRED_SIZE);
                ImageUtil.surface_to_pixbuf(surface).scale(pixbuf,
                        0, 0, DESIRED_SIZE, DESIRED_SIZE,
                        0, 0, /* scale */ DESIRED_SIZE/width, DESIRED_SIZE/width,
                        Gdk.InterpType.NEAREST /* Quality's not important, responsiveness is */);

                uint8[] png;
                try {
                    pixbuf.save_to_buffer(out png, "png");
                } catch (Error err) {
                    warning("Failed to save screenshot for %s.", uri);
                    return;
                }
                var encoded = Base64.encode(png);

                qSaveScreenshot.reset();
                qSaveScreenshot.bind_text(1, uri);
                qSaveScreenshot.bind_text(2, encoded);
                qSaveScreenshot.step();
            });
        });
        /* NOTE: It'd be nice to save any URI changes to history,
            but on sites like OSM this can crowd out the other history entries
            unless we can distinguish between navigate and replace. */
    }
}
