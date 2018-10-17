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
/** Scans a webpage for alternative links, and maybe renders favicons for them.

    This is used by, for example, the webfeed subscription status indicator. */
namespace Odysseus.Services {
    private class MIMEIndicatorFactory {
        public OnActivate on_activate;
        public string icon;
        public string text;

        public StatusIndicator build(Gee.List<string> links) {
            var indicator = new StatusIndicator(icon, Status.DISABLED, text);
            indicator.on_pressed = () => on_activate(links, indicator);
            return indicator;
        }
    }
    private Gee.Map<string, MIMEIndicator> alternative_mimes;

    public delegate Gtk.Popover? OnActivate(Gee.List<string> links, StatusIndicator ind);
    public void register_mime_indicator(string mimes, string text, string icon,
            OnActivate on_activate) {
        var factory = new MIMEIndicatorFactory();
        factory.text = text;
        factory.icon = icon;
        factory.on_activate = on_activate;

        foreach (var mime in mimes.split(" ") if (mime != "") {
            alternative_mimes[mime] = factory;
        }
    }

    private void parse_link_start(MarkupParseContext context, string name,
            string[] attr_names, string[] attr_values) throws MarkupError {
        if (name != "link") return;
        if (!("type" in attr_names && "href" in attr_names)) return;
        var links = (Gee.Map<string, Gee.List<string>>) context.get_user_data();

        var href = "";
        var type = 
        for (var i = 0; i < attr_names.length; i++) {
            if (attr_names[i] == "type") {
                type = attr_values[i];
                if (type in links) return;
            }
            if (attr_names[i] == "href") href = attr_values[i];
        }

        links[type].add(href);
    }

    // This function needs to be triggered once the page has been loaded.
    public async void report_mime_indicators(Gee.List<indicators> indicators, WebKit.WebView web) {
        var code = "";
        try {
            code = yield source.get_main_resource().get_data(null);
        } catch (Error err) {
            return;
        }

        var links = new Gee.HashMap<string, Gee.List<string>>();
        foreach (var type in alternative_mimes.keys)
            links[key] = new Gee.ArrayList<string>();

        MarkupParser parser = {parse_link_start, null, null, null, null};
        var parserContext = new MarkupParseContext(parser, 0, links, null);
        try {
            parserContext.parse(code, -1);
        } catch (MarkupError err) {
            return;
        }

        links.map_iterator().@foreach((type, links) => {
            if (links.size == 0) return true;
            if (!(type in alternative_mimes) return true;

            indicators.add(alternative_mimes[type].build(links));
        });
    }
}
