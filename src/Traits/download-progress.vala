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

/** Integrates downloads into the Pantheon desktop.

Specifially it renders download progress onto the app icon
    and it notifies users of download completion. */
namespace Odysseus.Traits {
    public void show_download_progress_on_icon(Download dl) {
        var appuri = "application://com.github.alcinnz.odysseus.desktop";
        var launcher = new LauncherEntry();

        try {
            var conn = Bus.get_sync(BusType.SESSION);
            conn.register_object(@"/com/canonical/unity/launcherentry/$(appuri.hash())", launcher);

            dl.received_data.connect(() => {
                Idle.add(() => {
                    var props = new HashTable<string, Variant>(str_hash, str_equal);

                    var downloads = DownloadSet.get_downloads().downloads;
                    if (downloads.size == 0) {
                        props.insert("progress-visible", false);
                        launcher.update(appuri, props);
                        return false;
                    }

                    var progress = 1.0;
                    foreach (var download in downloads)
                        progress *= download.download.estimated_progress;

                    props.insert("progress-visible", true);
                    props.insert("progress", progress);
                    launcher.update(appuri, props);

                    return false;
                }, Priority.LOW);
            });
            dl.finished.connect(() => {
                if (dl.cancelled) return;

                var notify = new Notification(_("Web Download Completed"));
                var response = dl.download.response;
                var url = new Soup.URI(response.uri);
                notify.set_body(url.path[url.path.last_index_of("/")+1:url.path.length] + "\n" + url.host);
                notify.set_icon(dl.icon);
                Odysseus.Application.instance.send_notification(null, notify);
            });
        } catch (IOError e) {
            /* Ignore, assuming the desktop doesn't support these indicators. */
        }
    }

    [DBus(name="com.canonical.Unity.LauncherEntry")]
    private class LauncherEntry : Object {
	    public signal void update(string uri, HashTable<string,Variant> properties);
    }
}
