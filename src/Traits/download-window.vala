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
/** Without this trait, it is too easy for a surfer to accidentally
    cancel all downloads by closing Odysseus. This trait adds a new
    toplevel and minimized window to address this problem whilst 
    ensuring the download progress stays in the dock for a quick glance. */
/* NOTE: This builds on the UI layer to expose it's own. */
namespace Odysseus.Traits {
    private class DownloadsWindow : Gtk.ApplicationWindow {
        public static DownloadsWindow? instance = null;

        construct {
            title = _("Downloads Are In Progress…");
            icon_name = "browser-download";
            deletable = false;

            var header = new Gtk.HeaderBar();
            header.title = title;
            header.has_subtitle = true;
            header.subtitle = _("Click a download to cancel or alter it");
            // The whole point of this window is to be open while downloads are
            // in progress, so replace normal close buttons with minimize. 
            header.show_close_button = false;
            var min = new Gtk.Button.from_icon_name("window-minimize-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            min.clicked.connect(() => iconify());
            header.pack_start(min);
            var restore = new Gtk.Button.from_icon_name("document-open-recent-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
            restore.clicked.connect(() => Persist.restore_application());
            header.pack_end(restore);
            set_titlebar(header);

            // For window content, a Downloads bar is appropriate. 
            // However the X instead of closing it should simply clear away
            // completed downloads
            var body = new DownloadsBar();
            body.notify["child-revealed"].connect((pspec) => body.reveal_child = true);
            body.reveal_child = true;
            add(body);
        }
    }

    private void consider_show_download_window() {
        Idle.add(() => {
            if (DownloadSet.get_downloads().downloads.size > 0) {
                if (DownloadsWindow.instance != null) return false;

                DownloadsWindow.instance = new DownloadsWindow();
                DownloadsWindow.instance.show_all();
                DownloadsWindow.instance.iconify();
            } else {
                DownloadsWindow.instance.destroy();
                DownloadsWindow.instance = null;
            }
            return false;
        }, Priority.LOW);
    }

    public void download_window_handle_download(Download dl) {
        dl.finished.connect(consider_show_download_window);
        consider_show_download_window();
    }
}
