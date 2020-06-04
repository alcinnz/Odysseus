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
/** Popover used for bookmarking & unbookmarking webpages. */
public class Odysseus.Bookmarker : Gtk.Popover {
    public string href;
    public int64 rowid;
    private Gtk.Grid layout;

    private Gtk.Entry label;
    private Gtk.TextView desc;
    private TokenizedEntry tags;

    construct {
        this.position = Gtk.PositionType.BOTTOM;

        layout = new Gtk.Grid();
        layout.column_spacing = layout.row_spacing = layout.margin = 5;
        add(layout);

        var icon = new Gtk.Image.from_icon_name("starred", Gtk.IconSize.DIALOG);
        layout.attach(icon, 0, 0, 1, 2);
        label = new Gtk.Entry();
        layout.attach(label, 1, 0);
        desc = new Gtk.TextView();
        var desc_scrolled = new Gtk.ScrolledWindow(null, null);
        desc_scrolled.add(desc);
        layout.attach(desc_scrolled, 1, 1);

        var unbookmark = new Gtk.Button.with_label(_("Remove"));
        var Qremove_fav = Database.parse("DELETE FROM favs WHERE url = ?;");
        var Qremove_tags = Database.parse("DELETE FROM fav_tags WHERE fav = ?;");
        unbookmark.clicked.connect(() => {
            popdown();

            Qremove_fav.reset();
            Qremove_fav.bind_text(1, href);
            Qremove_fav.step();

            if (rowid != 0) {
                Qremove_tags.reset();
                Qremove_tags.bind_int64(1, rowid);
                Qremove_tags.step();
            }
        });
        layout.attach(unbookmark, 0, 3);

        tags = new TokenizedEntry();
        tags.autocompleter = new TagsCompleter();
        layout.attach(tags, 1, 3);
    }
    public void populate(string uri, string title) {
        this.label.text = title;
        this.href = uri;
        tags.clear_tokens();
    }

    public override void get_preferred_width(out int min, out int natural) {
        layout.get_preferred_width(out min, out natural);
        if (natural > 300) natural = int.max(min, 300);
    }

    private static Sqlite.Statement Qinsert_favs = Database.parse("INSERT OR REPLACE INTO favs VALUES (?, ?, ?);");
    private static Sqlite.Statement Qdelete_toks = Database.parse("DELETE FROM fav_tags WHERE fav = ?;");
    private static Sqlite.Statement Qinsert_tok = Database.parse("INSERT OR IGNORE INTO fav_tags VALUES (?, ?);");
    private static Sqlite.Statement Qinsert_tag = Database.parse("INSERT INTO tags VALUES (?, ?, (SELECT rowid FROM vocab WHERE url = 'odysseus:myvocab.ttl#'));");
    private static Sqlite.Statement Qinsert_label = Database.parse("INSERT INTO tag_labels VALUES (?, ?)");
    public override void closed() {
        unowned Sqlite.Database db = Database.get_database();
        // INSERT OR REPLACE INTO favs(url, title, desc) VALUES (?, ?, ?);
        Qinsert_favs.reset();
        Qinsert_favs.bind_text(1, href);
        Qinsert_favs.bind_text(2, label.text);
        Qinsert_favs.bind_text(3, desc.buffer.text);
        Qinsert_favs.step();

        rowid = Database.get_database().last_insert_rowid();

        Qdelete_toks.reset();
        Qdelete_toks.bind_int64(1, rowid);
        Qdelete_toks.step();
        foreach (var tok in tags.tokens) {
            int64 tagid = 0;
            var val = tok.val[1:tok.val.length];
            if (tok.val[0] == '+') {
                Qinsert_tag.reset();
                Qinsert_tag.bind_text(1, "odysseus:myvocab.ttl#" + Soup.URI.encode(val, null));
                Qinsert_tag.bind_text(2, val);
                if (Qinsert_tag.step() != Sqlite.DONE) continue;

                Qinsert_label.reset();
                Qinsert_label.bind_int64(1, Database.get_database().last_insert_rowid());
                Qinsert_label.bind_text(2, val);
                if (Qinsert_label.step() != Sqlite.DONE) continue;

                tagid = Database.get_database().last_insert_rowid();
            } else if (tok.val[0] == '#') {
                tagid = int64.parse(val);
            } else continue;

            Qinsert_tok.reset();
            Qinsert_tok.bind_int64(1, rowid);
            Qinsert_tok.bind_int64(2, tagid);
            Qinsert_tok.step();
        }
    }
}
class Odysseus.TagsCompleter : Tokenized.Completer {
    private static Sqlite.Statement qAutocompleteTags = Database.parse(
        "SELECT l.tag, t.label FROM tag_labels AS l, tags AS t WHERE l.altlabel LIKE ? AND l.tag == t.rowid;");
    public override void suggest(string query, owned Tokenized.Completer.YieldCallback cb) {
        if ("%" in query || "_" in query) return; // TODO Better handling?

        qAutocompleteTags.reset();
        qAutocompleteTags.bind_text(1, query + "%");
        while (qAutocompleteTags.step() == Sqlite.ROW)
            cb(new Tokenized.Completion.token("#" + qAutocompleteTags.column_int64(0).to_string(), qAutocompleteTags.column_text(1)));

        cb(new Tokenized.Completion.token("+" + query, query));
    }
}
