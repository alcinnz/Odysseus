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

using Odysseus.Services;
using Odysseus.Templating.Data;
namespace Odysseus.Traits {
    using Templating;
    public async string view_source(WebKit.WebView source) {
        var data = new Source();
        data.title = source.title;
        try {
            var code = yield source.get_main_resource().get_data(null);
            data.code = new Slice.a(code);
        } catch (Error e) {
            return "odysseus:errors/no-source"; // Don't go through
        }

        var url = "source:///" + source.get_main_resource().uri;
        if (sources == null) sources = new Gee.HashMap<string, Source>();
        sources[url] = data;
        return url;
    }

    private class Source {
        public string title;
        public Slice code;
    }
    private Gee.Map<string, Source>? sources = null; // UGLY HACK

    public void handle_source_uri(WebKit.URISchemeRequest request) {
        if (sources != null && sources.has_key(request.get_uri())) {
            var resource = sources[request.get_uri()];
            sources.unset(request.get_uri());

            var url = request.get_uri();
            var data = Let.builds("source", new Substr(resource.code),
                    Let.builds("title", new Literal(resource.title),
                    Let.builds("url", new Literal(url["source:///".length:url.length]))));

            try {
                ErrorData? ignored = null;
                var template = get_for_resource(
                        "/io/github/alcinnz/Odysseus/odysseus:/special/viewsource",
                        ref ignored);
                // This is the reason for the hack: InputStreamWriter
                var stream = new InputStreamWriter();
                request.finish(stream, -1, "text/html");
                template.exec.begin(data, stream, (obj, res) => stream.close_write());
            } catch (Error err) {
               // Don't bother reporting errors better
               request.finish_error(err); 
            }
        } else {
            // If we're not viewing alternate HTML under this schema,
            //      close any tabs that have persisted. 
            var response = _("Please go through the \"View Source\" menu item.");
            var stream = new MemoryInputStream.from_bytes(new Slice.s(response)._);
            request.finish(stream, response.length, "text/html");
        }
    }
}
