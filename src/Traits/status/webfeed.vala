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

        private static async string read_stream(InputStream stream) throws IOError {
            var ret = new StringBuilder();
            var buffer = new uint8[256];
            ssize_t size = 0;
            while ((size = yield stream.read_async(buffer)) > 0) {
                ret.append_len((string) buffer, size);
            }
            return ret.str;
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

                var response_text = yield read_stream(response);
                var info = new WebFeedParser();
                info.parse(response_text);
                // TODO do something with info

                populate_subscribe_buttons();
            } catch (Error err) {
                destroy();
            }
        }

        private void populate_subscribe_buttons() {
            var feedreaders = AppInfo.get_all_for_type("application/atom+xml");
            var is_empty = true;

            feedreaders.@foreach((feedreader) => {
                // Verify it's a supported app.
                if (!feedreader.supports_uris()) return;
                if (!("application/rss+xml" in feedreader.get_supported_types()))
                    return;
                is_empty = false;

                // Add toggle button for feedreader.
                var button = new Gtk.ToggleButton();
                button.image = new Gtk.Image.from_gicon(feedreader.get_icon(),
                        Gtk.IconSize.MENU);
                button.always_show_image = true;
                button.relief = Gtk.ReliefStyle.NONE;
                button.tooltip_text = _("Subscribe via %s").printf(feedreader.get_name());
                add(button);
            });

            if (is_empty) {
                var button = new Gtk.Button();
                button.image = new Gtk.Image.from_icon_name("system-software-install",
                        Gtk.IconSize.MENU);
                button.always_show_image = true;
                button.relief = Gtk.ReliefStyle.NONE;
                button.tooltip_text = _("Install a feedreader to subscribe");
                add(button);
            }
        }
    }

    private string strip_ns(string name) {
        return ":" in name ? name.split(":")[1] : name;
    }

    private class WebFeedParser {
        int depth = 0;
        public Gee.Set<string> types = new Gee.HashSet<string>();
        public string title = "";
        bool in_title = true;

        private void visit_start(MarkupParseContext context, string name,
                string[] attr_names, string[] attr_values) throws MarkupError {
            depth++;
            if (strip_ns(name) == "enclosure" || strip_ns(name) == "content") {
                for (var i = 0; i < attr_names.length; i++) {
                    if (strip_ns(attr_names[i]) == "type")
                        types.add(attr_values[i]);
                }
            } else if (depth == 1 && strip_ns(name) == "title") {
                in_title = true;
                title = "";
            }
        }

        private void visit_end(MarkupParseContext context, string name) throws MarkupError {
            depth--;
            in_title = false;
        }

        private void visit_text(MarkupParseContext context,
                string text, size_t text_len) throws MarkupError {
            title = title + text;
        }

        private void visit_passthrough(MarkupParseContext context,
                string text, size_t text_len) throws MarkupError {/* Do nothing */}

        public bool parse(string markup) throws MarkupError {
            var parser = MarkupParser() {
                start_element = visit_start,
                end_element = visit_end,
                text = visit_text,
                passthrough = visit_passthrough
            };
            var context = new MarkupParseContext(parser, 0, this, null);
            return context.parse(markup, -1);
        }
    }
}
