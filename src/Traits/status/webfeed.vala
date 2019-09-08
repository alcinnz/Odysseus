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
                    "webfeed-subscribe", Status.ENABLED,
                    _("Subscribe to webfeeds"),
                    (alts) => build_subscribe_popover(alts as Gee.List<string>));
            indicator.user_data = alternatives;
            indicators.add(indicator);
        }
    }

    public void setup_youtube_feed_discovery(WebTab tab) {
        // To help people move from YouTube's hueristics to ones they control.
        tab.web.load_changed.connect((evt) => {
            if (evt != WebKit.LoadEvent.FINISHED) return;
            discover_youtube_feeds(tab.url, tab);
        });

        // YouTube's a SPA, so handle that.
        tab.web.notify["uri"].connect((pspec) => {
            discover_youtube_feeds(tab.url, tab);
        });
    }

    public void discover_youtube_feeds(string uri, WebTab tab) {
        if (!uri.has_prefix("https://www.youtube.com/")) return;

        var alternatives = new Gee.ArrayList<string>();
        var feed_uri = "https://www.youtube.com/feeds/videos.xml";

        var channel_base = "https://www.youtube.com/channel/";
        if (uri.has_prefix(channel_base)) {
            var channel = uri[channel_base.length:uri.length].split_set("/#?", 2)[0];
            alternatives.add(feed_uri + "?channel_id=" + channel);
        }
        var user_base = "https://youtube.com/user/";
        if (uri.has_prefix(user_base)) {
            var user = uri[user_base.length:uri.length].split_set("/#?", 2)[0];
            alternatives.add(feed_uri + "?user=" + user);
        }

        if ("?" in uri) {
            var query = uri.split("?", 2)[1].split("#")[0].split("&");
            foreach (var q in query) {
                if (!q.has_prefix("list=")) continue;
                var playlist = q["list=".length:q.length];
                alternatives.add(feed_uri + "?playlist_id=" + playlist);
            }
        }

        if (alternatives.size > 0) {
            var indicator = new StatusIndicator(
                "webfeed-subscribe", Status.ENABLED,
                _("Subscribe to webfeeds"),
                (alts) => build_subscribe_popover(alts as Gee.List<string>));
            indicator.user_data = alternatives;
            tab.indicators.add(indicator);
            tab.indicators_loaded(tab.indicators);
        }
    }

    private Gtk.Popover build_subscribe_popover(Gee.List<string> links) {
        var grid = new Gtk.Grid();
        grid.orientation = Gtk.Orientation.VERTICAL;
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
                req.get_message().request_headers.append("Accept",
                    "application/rss+xml, application/atom+xml, text/xml, application/xml");
                var response = yield req.send_async(null);
                spinner.stop();

                if (req.get_message().status_code != 200) {destroy(); return;}
                var mime = req.get_content_type();
                if (!mime.has_prefix("application/rss+xml") &&
                        !mime.has_prefix("application/atom+xml") &&
                        !mime.has_prefix("text/xml") &&
                        !mime.has_prefix("application/xml")) {
                    destroy();
                    return;
                }

                var response_text = yield read_stream(response);
                var info = new WebFeedParser();
                info.parse(response_text);

                if (!info.is_webfeed) {destroy(); return;}
                label.label = info.title;
                populate_subscribe_buttons(link, info.types);

            } catch (Error err) {
                destroy();
            }
        }

        private void populate_subscribe_buttons(string link, Gee.Set<string> containers) {
            var feedreaders = AppInfo.get_all_for_type("application/atom+xml");
            var is_empty = true;

            var links = new List<string>();
            links.append(link);

            feedreaders.@foreach((feedreader) => {
                // Firefox is NOT a feedreader, less so now then ever.
                // It's .desktop file says otherwise.
                if (feedreader.get_id() == "firefox.desktop") return;

                // Verify it's a supported app.
                if (!feedreader.supports_uris()) return;
                if (!("application/rss+xml" in feedreader.get_supported_types()))
                    return;

                // Ask the app if I should show it
                var appinfo = feedreader as DesktopAppInfo;
                if (appinfo != null && appinfo.has_key("X-WebFeed-Type")) {
                    var feedtypes = appinfo.get_string("X-WebFeed-Type");
                    if (feedtypes == "none") return;

                    var supported = false;
                    foreach (var type in feedtypes.split(";"))
                        if (type in containers) supported = true;
                    if (!supported) return;
                }
                is_empty = false;

                // Add toggle button for feedreader.
                var button = new Gtk.Button();
                button.image = new Gtk.Image.from_gicon(feedreader.get_icon(),
                        Gtk.IconSize.MENU);
                button.always_show_image = true;
                button.relief = Gtk.ReliefStyle.NONE;
                button.tooltip_text = _("Subscribe via %s").printf(feedreader.get_name());
                add(button);

                button.clicked.connect(() => feedreader.launch_uris(links, null));
            });

            if (is_empty) {
                var button = new Gtk.Button();
                button.image = new Gtk.Image.from_icon_name("system-software-install",
                        Gtk.IconSize.MENU);
                button.always_show_image = true;
                button.relief = Gtk.ReliefStyle.NONE;
                button.tooltip_text = _("Install a feedreader to subscribe");
                add(button);

                button.clicked.connect(() =>
                    (get_toplevel() as BrowserWindow).new_tab("odysseus:feedreaders")
                );
            }

            show_all();
        }
    }

    private string strip_ns(string name) {
        return ":" in name ? name.split(":")[1] : name;
    }

    private class WebFeedParser {
        int depth = 0;
        public Gee.Set<string> types = new Gee.HashSet<string>();
        public string title = "";
        bool in_title = false;
        public bool is_webfeed = false;

        private void visit_start(MarkupParseContext context, string name,
                string[] attr_names, string[] attr_values) throws MarkupError {
            if (strip_ns(name) != "channel") depth++;

            if (depth == 1 && (strip_ns(name) == "rss" || strip_ns(name) == "feed"))
                is_webfeed = true;
            else if (strip_ns(name) == "enclosure" || strip_ns(name) == "content") {
                for (var i = 0; i < attr_names.length; i++) {
                    if (strip_ns(attr_names[i]) == "type")
                        types.add(attr_values[i].split(";", 2)[0]);
                }
            } else if (depth == 2 && strip_ns(name) == "title") {
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
            if (in_title) title = title + text.strip();
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
