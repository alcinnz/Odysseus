/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016).
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
public class Odysseus.DownloadsBar : Gtk.Revealer {
    private Gtk.FlowBox mainbox;

    public DownloadsBar() {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        this.add(box);

        mainbox = new Gtk.FlowBox();
        mainbox.margin = 5;
        mainbox.column_spacing = 10;
        mainbox.row_spacing = 10;
        box.pack_start(mainbox);

        var close_button = new Gtk.Button.from_icon_name("window-close");
        close_button.clicked.connect(() => {
            set_reveal_child(false);
        });
        close_button.relief = Gtk.ReliefStyle.NONE;
        close_button.tooltip_text = _("Close downloads bar");
        box.pack_end(close_button, false, false);

        set_reveal_child(false);

        populate_downloads();
    }

    public void add_entry(Gtk.Widget widget) {
        set_reveal_child(true);
        mainbox.add(widget);
    }

    public void populate_downloads() {
        foreach (var download in Download.get_downloads().downloads) {
            add_entry(new DownloadButton(download));
        }
        Download.get_downloads().add.connect((download) => {
            add_entry(new DownloadButton(download));
        });
    }

    public static void setup_context(WebKit.WebContext ctx) {
        Download.setup_ctx(ctx);
    }
}
