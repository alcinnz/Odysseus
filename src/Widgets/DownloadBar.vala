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
    private Gtk.Grid box;

    public DownloadsBar() {
        box = new Gtk.Grid();
        box.orientation = Gtk.Orientation.HORIZONTAL;
        box.column_spacing = 5;
        this.add(box);

        mainbox = new Gtk.FlowBox();
        mainbox.margin = 5;
        mainbox.column_spacing = 10;
        mainbox.row_spacing = 10;
        mainbox.expand = true;
        box.add(mainbox);

        add_action("folder", _("View all downloads"),
                (button) => {
                    try {
                        AppInfo.launch_default_for_uri(Download.folder.get_uri(), null);
                    } catch (Error e) {
                        button.image = new Gtk.Image.from_icon_name("error", Gtk.IconSize.MENU);
                        warning("Failed to open file manager: %s", e.message);
                    }
        });
        add_action("window-close", _("Close downloads bar"), (_) => set_reveal_child(false));

        reveal_child = false;
        notify["child-revealed"].connect((pspec) => {
            if (child_revealed) populate_downloads();
            else {
                mainbox.@foreach((widget) => widget.destroy());
                DownloadSet.get_downloads().disconnect(on_add);
            }
        });
        DownloadSet.get_downloads().add.connect((dl) => reveal_child = true);
    }

    private delegate void Action(Gtk.Button button);
    private void add_action(string icon, string help, owned Action action) {
        var button = new Gtk.Button.from_icon_name(icon);
        button.clicked.connect(() => action(button));
        button.relief = Gtk.ReliefStyle.NONE;
        button.tooltip_text = help;
        box.add(button);
    }

    public void add_download(Odysseus.Download dl) {
        mainbox.add(new DownloadButton(dl));
    }

    private ulong on_add = 0;
    public void populate_downloads() {
        foreach (var download in DownloadSet.get_downloads().downloads) {
            add_download(download);
        }
        on_add = DownloadSet.get_downloads().add.connect((download) => {
            add_download(download);
        });
    }
}
