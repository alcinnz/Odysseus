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
namespace Odysseus.Traits {
    public async string view_source(WebKit.WebView source) {
        var data = new Source();
        data.title = source.title;
        try {
            var code = yield source.get_main_resource().get_data(null);
            data.code = new Bytes(code);
        } catch (Error e) {
            return "odysseus:errors/no-source"; // Don't go through
        }

        var url = "source:" + source.get_main_resource().uri;
        if (sources == null) sources = new Gee.HashMap<string, Source>();
        sources[url] = data;
        return url;
    }

    private class Source {
        public string title;
        public Bytes code;
    }
    private Gee.Map<string, Source>? sources = null; // UGLY HACK

    public void handle_source_uri(WebKit.URISchemeRequest request) {
        if (sources != null && sources.has_key(request.get_uri())) {
            var resource = sources[request.get_uri()];
            sources.unset(request.get_uri());

            var data = Templating.ByteUtils.create_map<Templating.Data.Data>();
            data[Templating.ByteUtils.from_string("source")] =
                    new Templating.Data.Substr(resource.code);
            data[Templating.ByteUtils.from_string("title")] =
                    new Templating.Data.Literal(resource.title);
            var url = request.get_uri();
            url = url["source:".length:url.length];
            data[Templating.ByteUtils.from_string("url")] =
                    new Templating.Data.Literal(url);

            try {
                Templating.ErrorData? ignored = null;
                var template = Templating.get_for_resource(
                        "/io/github/alcinnz/Odysseus/odysseus:/special/viewsource",
                        ref ignored);
                // This is the reason for the hack: InputStreamWriter
                var stream = new Templating.InputStreamWriter();
                request.finish(stream, -1, "text/html");
                template.exec.begin(new Templating.Data.Mapping(data), stream,
                        (obj, res) => {
                    stream.close_write();
                });
            } catch (Error err) {
               // Don't bother reporting errors better
               request.finish_error(err); 
            }
        } else if (request.get_uri() == "source:favicon.ico") {
            try {
                var stream = resources_open_stream("/io/github/alcinnz/Odysseus/odysseus:/special/viewsource.ico", 0);
                request.finish(stream, -1, "image/x-icon");
            } catch (Error e) {
                request.finish_error(e);
            }
        } else {
            // If we're not viewing alternate HTML under this schema,
            //      close any tabs that have persisted. 
            var response = _("Please go through the \"View Source\" menu item.");
            var stream = new MemoryInputStream.from_bytes(
                    Templating.ByteUtils.from_string(response));
            request.finish(stream, response.length, "text/html");
        }
    }
}
