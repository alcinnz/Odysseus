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
        var tags = new TokenizedEntry();
        layout.attach(tags, 1, 3);
    }
    public void populate(string uri, string title) {
        this.label.text = title;
        this.href = uri;
    }

    public override void get_preferred_width(out int min, out int natural) {
        layout.get_preferred_width(out min, out natural);
        if (natural > 300) natural = int.max(min, 300);
    }

    private static Sqlite.Statement Qinsert_favs = Database.parse("INSERT OR REPLACE INTO favs VALUES (?, ?, ?);");
    public override void closed() {
        unowned Sqlite.Database db = Database.get_database();
        // INSERT OR REPLACE INTO favs(url, title, desc) VALUES (?, ?, ?);
        Qinsert_favs.reset();
        Qinsert_favs.bind_text(1, href);
        Qinsert_favs.bind_text(2, label.text);
        Qinsert_favs.bind_text(3, desc.buffer.text);
        Qinsert_favs.step();

        rowid = Database.get_database().last_insert_rowid();
    }
}
