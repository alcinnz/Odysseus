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
    private Gtk.Box box;

    public DownloadsBar() {
        box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        this.add(box);

        mainbox = new Gtk.FlowBox();
        mainbox.margin = 5;
        mainbox.column_spacing = 10;
        mainbox.row_spacing = 10;
        box.pack_start(mainbox);

        add_action("folder-download", _("View all downloads"),
                () => Granite.Services.System.open(Download.folder));
        add_action("window-close", _("Close downloads bar"), () => set_reveal_child(false));

        set_reveal_child(false);

        populate_downloads();
    }

    private delegate void Action();
    private void add_action(string icon, string help, owned Action action) {
        var button = new Gtk.Button.from_icon_name(icon);
        button.clicked.connect(() => action());
        button.relief = Gtk.ReliefStyle.NONE;
        button.tooltip_text = help;
        box.pack_end(button, false, false);
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
