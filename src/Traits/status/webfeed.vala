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
    public void discover_webfeeds(Model.Link[] links,
            Gee.List<StatusIndicator> indicators) {
        // FIXME Determine that these actually ARE webfeeds,
        //      and determine the type of their attachments (for menu improvements).
        var alternatives = new Gee.ArrayList<string>();
        foreach (var link in links) if (link.rel == "alternate")
            alternatives.add(link.href);

        if (alternatives.size > 0) {
            var indicator = new StatusIndicator(
                    "webfeed-subscribe", Status.DISABLED,
                    _("Subscribe to webfeeds"),
                    (alts) => build_subscribe_popover(alts as Gee.List<string>));
            indicator.user_data = alternatives;
            indicators.add(indicator);
        }
    }

    private Gtk.Popover build_subscribe_popover(Gee.List<string> links) {
        // FIXME download these so I can determine if they actually are webfeeds,
        //      If there's a better label, and the best apps to suggest subscribing via.
        var grid = new Gtk.Grid();
        var session = FeedRow.build_session();
        foreach (var link in links) {
            var label = new FeedRow(session, link);
            grid.add(label);
        }

        var popover = new Gtk.Popover(null);
        popover.add(grid);
        return popover;
    }

    private class FeedRow : Gtk.Grid {
        Gtk.Label label = new Gtk.Label("");
        Gtk.Spinner spinner = new Gtk.Spinner();
        construct {
            orientation = Gtk.Orientation.HORIZONTAL;

            add(label);
            add(spinner);
        }

        public FeedRow(Soup.Session session, string link) {
            label.label = link;
            fetch_details.begin(session, link, null);
        }

        public static Soup.Session build_session() {
            var ret = new Soup.Session();
            ret.user_agent = Templating.xHTTP.FetchTag.user_agent;
            ret.add_feature(new Soup.ContentSniffer());
            return ret;
        }

        private async void fetch_details(Soup.Session session, string link) {
            try {
                spinner.start();
                var req = session.request_http("GET", link);
                req.get_message().request_headers.append(
                        "Accept", "application/rss+xml, application/atom+xml");
                var response = yield req.send_async(null);
                spinner.stop();

                if (req.get_message().status_code != 200) {destroy(); return;}
                var mime = req.get_content_type();
                if (!mime.has_prefix("application/rss+xml") &&
                        !mime.has_prefix("application/atom+xml")) {
                    destroy();
                    return;
                }

                // TODO parse out /title/text(), enclosure@type, content@type
            } catch (Error err) {
                destroy();
            }
        }
    }
}
