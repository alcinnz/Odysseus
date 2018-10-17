/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2018).
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
/** Finds webfeeds in order to make it easy to subscribe to them via 3rd party apps.

    This will build upon an (as yet unwritten) service capable of parsing out
    <link> tags. */
namespace Odysseus.Traits {
    // Initialize with:
    // Services.register_mime_indicator("application/xml+atom application/xml+rss",
    //      _("Subscribe to page updates."),
    //      "webfeed-subscribe", webfeed_indicator);
    public Gtk.Popover? webfeed_indicator(Gee.List<string> links, StatusIndicator ind) {
        return null;
    }

    // FIXME register_mime_indicator needs to be implemented.
    // FIXME webfeed-subscribe needs to be installed.
}
