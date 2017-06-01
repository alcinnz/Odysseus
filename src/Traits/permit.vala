/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2017).
*
* Oddysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Oddysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Oddysseus.  If not, see <http://www.gnu.org/licenses/>.
*/
/** Exposes a UI for when WebKit asks for various permissions
    on behalf of webpages. 

This is not the final UI as it neither persists configurations
    nor allows the user to edit the persisted permissions.
Also It's an easy UI for a webpage to spoof,
    so an alternative would be more secure.
As such this UI will be reimplemented later. */
namespace Oddysseus.Traits {
    private async bool confirm_permit(WebTab tab, WebKit.PermissionRequest req) {
        var msg = "";
        var opts = new InfoContainer.MessageOptions();
        opts.type = Gtk.MessageType.WARNING;
        if (req is WebKit.GeolocationPermissionRequest) {
            msg = "This page wants to know where you currently are.";
        } else if (req is WebKit.NotificationPermissionRequest) {
            msg = "This page wants the ability to show you notifications.";
        } else if (req is WebKit.UserMediaPermissionRequest) {
            var media_req = req as WebKit.UserMediaPermissionRequest;
            var listens = media_req.is_for_audio_device;
            var watches = media_req.is_for_video_device;
            if (listens && watches) {
                msg = "This page wants to watch and listen to you.";
            } else if (listens) {
                msg = "This page wants to listen to you.";
            } else if (watches) {
                msg = "This page wants to watch you.";
            } else return false;
        } else if (req is WebKit.InstallMissingMediaPluginsPermissionRequest) {
            var install_req = req as
                    WebKit.InstallMissingMediaPluginsPermissionRequest;
            msg = "Additional software is required to play media on this page:\n";
            msg += install_req.get_description();
            opts.ok_text = "Install";
        }

        return yield tab.info.message(msg, opts);
    }

    public void setup_permits(WebTab tab) {
        tab.web.permission_request.connect((req) => {
            confirm_permit.begin(tab, req, (obj, res) => {
                if (confirm_permit.end(res)) req.allow();
                else req.deny();
            });
            return true;
        });
    }
}
