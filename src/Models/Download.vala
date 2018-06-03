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
            return _destination == "" ? download.destination : _destination;
        }
        set {
            if (completed) move(_destination, value);
            _destination = value;
        }
    }
    public uint64 size {
        get {return download.response.content_length;}
    }
    
    public signal void received_data();
    public signal void finished();
    
    public Download(WebKit.Download download) {
        this.download = download;
        download.decide_destination.connect(decide_destination);
        
        download.received_data.connect((len) => received_data());
        download.finished.connect(() => {
            // Can't set destination after a download's started,
            //      so do it afterwords
            if (destination != download.destination)
                move(download.destination, destination);

            received_data();
            finished();
            completed = true;
            if (auto_open && !cancelled) open();
        });

        // Allow surfer to install an app for a download before it completes.
        // Do so upon receiving first chunk, as otherwise
        // the mimetype property caches an invalid value.
        ulong first_chunk_hook = 0;
        first_chunk_hook = received_data.connect(() => {
            find_apps();
            disconnect(first_chunk_hook);
        });
    }
    
    public bool open() {
        if (!completed) return false;

        var app = find_apps();
        if (app == null) return false;

        var files = new List<string>();
        files.append(destination);
        try {
            app.launch_uris(files, null);
        } catch (Error err) {
            warning(err.message);
            return false;
        }

        return true;
    }

    private AppInfo? find_apps() {
        var app = AppInfo.get_default_for_type(mimetype, false);
        if (app != null) return app;

        var suggest_uri = "odysseus:filetype?mime=" + Soup.URI.encode(mimetype, null);
        var win = Odysseus.Application.instance.get_active_window() as BrowserWindow;
        if (win != null) win.new_tab(suggest_uri);

        return null;
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
                    _("Error moving download to %s.\nIt has been left in your Downloads folder") + "\n\n%s",
                    new_path, e.message);
            dlg.run();
            dlg.destroy();
        }
    }

    public string estimate() {
        var progress = download.estimated_progress;
        int estimate = (int) ((download.get_elapsed_time()/progress) * (1-progress));

        if (estimate < 60) {
            /// TRANSLATORS: "%i" seconds
            return _("%is").printf((int) estimate);
        } else {
            int minutes = (int) estimate / 60;
            if (minutes < 60) {
                /// TRANSLATORS: "%i" minutes
                return _("%im").printf((int) minutes);
            } else {
                var hours = (int) minutes / 60;
                minutes = (int) minutes % 60;
                /// TRANSLATORS: "%i" hours and "%i" minutes,
                return _("%ih %im").printf(hours, minutes);
            }
        }
    }

    // Downloads collection
    public static File folder = File.new_for_path(
            Environment.get_user_special_dir(UserDirectory.DOWNLOAD));
    
    public bool cancelled = false;
    public virtual signal void cancel() {
        cancelled = true;
        download.cancel();
    }

    public bool decide_destination(string filename) {
        var Downloads = File.new_for_path(
                Environment.get_user_special_dir(UserDirectory.DOWNLOAD));
        // THIS IS NOT Y10K COMPLIANT! (http://longnow.org/clock/)
        // Well in the unlikely event this is relevant, it's unlikely to cause serious problems.
        folder = Downloads.get_child(new DateTime.now_local().format("%Y-%m-%d"));
        if (!folder.query_exists()) {
            try {folder.make_directory();}
            catch (Error e) {folder = Downloads;}
        }

        var path = folder.get_child(filename);
        var i = 0;
        while (path.query_exists())
            path = folder.get_child("%s%i".printf(filename, i++));

        // This method only works before the download is in operation.
        download.set_destination(path.get_uri());
        return true;
    }

    private string _mimetype = "";
    public string mimetype {
        get {
            if (_mimetype == "") _mimetype = normalize_mimetype(download.response);
            return _mimetype;
        }
    }
    private Icon? _icon = null;
    public Icon icon {
        get {
            if (_icon == null) _icon = ContentType.get_icon(mimetype);
            return _icon;
        }
    }
    private string _filetype = "";
    public string filetype {
        get {
            if (_filetype == "") _filetype = ContentType.get_description(mimetype);
            return _filetype;
        }
    }

    public static string normalize_mimetype(WebKit.URIResponse dl) {
        if (dl.mime_type == "application/octet-stream")
            return ContentType.guess(dl.uri, null, null);
        else
            return ContentType.from_mime_type(dl.mime_type);
    }
}
