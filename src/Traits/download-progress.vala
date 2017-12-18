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
namespace Odysseus.Services {
    private class IconProgressManager : Object {
        private weak IconProgressManager _instance;
        public IconProgressManager instance {
            get {
                if (_instance == null) {
                    var ret = new IconProgressManager();
                    _instance = ret;
                    return ret;
                }
                return _instance;
            }
        }

        public void update_progress() {
            var downloads = DownloadSet.get_downloads().downloads;
            var largest_download = downloads[0];
            foreach (var download : downloads) {
                if (download.size > largest_download.size)
                    largest_download = download;
            }

            launcher.progress_visible = download.completed;
            launcher.progress = download.download.estimated_progress;
        }
    }

    public show_download_progress_on_icon(Download dl) {
        dl.received_data.connect(Icon.ProgressManager.instance.update_progress);
        dl.finished.connect(() => {
            var notify = new Notification(_("Web Download Completed"));
            notify.set_body(dl.response.uri);
            notify.set_icon(ContentType.get_icon(dl.response.mime_type));
            Odysseus.Application.send_notification(null, notify);
        });
    }
}
