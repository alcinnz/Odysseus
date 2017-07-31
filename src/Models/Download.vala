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
/** Wraps a WebKit.Download with additional data and behaviour.

    It is important to unify this data/behaviour or else the multiple
    DownloadButtons presenting this info may conflict. */
public class Odysseus.Download : Object {
    public WebKit.Download download;
    public bool completed = false;
    public bool auto_open = true;
    private string _destination = "";
    public string destination {
        get {
            return _destination;
        }
        set {
            if (completed) move(_destination, value);
            _destination = value;
        }
    }
    
    public signal void received_data();
    
    public Download(WebKit.Download download) {
        this.download = download;
        this.destination = download.destination;
        
        download.received_data.connect((len) => received_data());
        download.finished.connect(() => {
            // Can't set destination after a download's started,
            //      so do it afterwords
            if (destination != download.destination)
                move(download.destination, destination);

            received_data();
            completed = true;
            if (auto_open) open();
        });
    }
    
    public bool open() {
        if (completed) Granite.Services.System.open_uri(destination);
        return completed;
    }

    private void move(string old_path, string new_path) {
        try {
            File.new_for_uri(old_path).move(File.new_for_uri(new_path),
                    FileCopyFlags.OVERWRITE | FileCopyFlags.BACKUP);
        } catch (Error e) {
            var dlg = new Gtk.MessageDialog(null,
                    Gtk.DialogFlags.DESTROY_WITH_PARENT,
                    Gtk.MessageType.ERROR,
                    Gtk.ButtonsType.CLOSE,
                    // TRANSLATORS "%s is replaced with the filepath
                    // the user specified they wanted their download to be at
                    _("Error moving download to %s.\nIt has been left in your Downloads folder") + "\n\n%s",
                    new_path, e.message);
            dlg.run();
            dlg.destroy();
        }
    }
    
    // Downloads collection
    public static ListStore? downloads;
    public static int active_downloads = 0;
    public static void setup_ctx(WebKit.WebContext ctx) {
        if (downloads == null) downloads = new ListStore(typeof(Download));
        ctx.download_started.connect((download) => {
            downloads.append(new Download(download));
        });
    }
    
    public void cancel() {
        download.cancel();

        // Remove from list
        uint i = 0;
        while (downloads.get_item(i) != null) {
            if (downloads.get_item(i) == this) {
                downloads.remove(i);
                return;
            }
            i++;
        }
    }
}
