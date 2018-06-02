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

/** Exposes our GLib.Resource templates to WebKit. */
namespace Odysseus.Services {
    using Templating;

    private Data.Data parse_url_to_prosody(string url_text) {
        var url = new Data.Mapping(null, url_text);
        var parser = new Soup.URI(url_text);

        url["fragment"] = new Data.Literal(parser.fragment);
        url["host"] = new Data.Literal(parser.host);
        url["password"] = new Data.Literal(parser.password);
        url["path"] = new Data.Literal(parser.path);
        url["port"] = new Data.Literal(parser.port);
        url["scheme"] = new Data.Literal(parser.scheme);
        url["user"] = new Data.Literal(parser.user);

        var q = new Gee.HashMap<Slice, Gee.List<Data.Data>>();
        foreach (var keyvalue in parser.query.split("&")) {
            var segments = keyvalue.split("=", 2);
            if (segments.length == 0) {
                warning("Malformed query string '%s'", parser.query);
                continue;
            }

            var key = new Slice.s(segments[0]);
            Data.Data val = new Data.Literal("");
            if (segments.length > 1)
                val = new Data.Literal(Soup.URI.decode(segments[1]));

            if (!q.has_key(key)) q[key] = new Gee.ArrayList<Data.Data>();
            var vals = q[key];
            vals.add(val);
        }

        var query = new Gee.HashMap<Slice, Data.Data>();
        url["query"] = new Data.Mapping(query, parser.query);
        foreach (var p in q.entries) query[p.key] = new Data.List(p.value);

        // Predominantly used by the bad-certificate error page.
        if (url_text.has_prefix("https://")) {
            var http_url = "http" + url_text["https".length:url_text.length];
            url["http"] = new Data.Literal(http_url);
        }

		// And add content-negotiation header
        var langs = Intl.get_language_names();
        var langs_data = new Data.Data[langs.length];
        for (var i = 0; i < langs.length; i++) {
            langs_data[i] = new Data.Literal(langs[i]);
        }

        return Data.Let.builds("url", url,
                Data.Let.builds("LOCALE", new Data.List.from_array(langs_data)));
    }

    private void render_error(WebKit.URISchemeRequest request, string error,
            Data.Data base_data = new Data.Empty(),
            TagBuilder? error_tag = null) {
        try {
            var path = "/" + Path.build_path("/",
                    "io", "github", "alcinnz", "Odysseus", "odysseus:", error);

            var data = Data.Let.builds("url", new Data.Literal(request.get_uri()),
                    Data.Let.builds("path", new Data.Literal(request.get_path()),
                    base_data));

            ErrorData? error_data = null;
            Template template;
            if (error_tag == null)
                template = get_for_resource(path, ref error_data);
            else {
                // Parse specially with the custom {% error-line %} tag.
                var bytes = resources_lookup_data(path, 0);
                var parser = new Parser.b(bytes);
                parser.local_tag_lib[new Slice.s("error-line")] = error_tag;
                template = parser.parse();
            }

            var stream = new InputStreamWriter();
            request.finish(stream, -1, "text/html");
            template.exec.begin(data, stream, (obj, res) => stream.close_write());
        } catch (Error err) {
            warning("Error reporting errors.");
            request.finish_error(err);
        }
    }

    public async void render_alternate_html(WebTab tab,
            string subpath, string? alt_uri = null, bool render_errors = true,
            Data.Data? data = null,
            TagBuilder? error_tag = null) {
        var webview = tab.web;

        var alternative_uri = webview.uri;
        if (alt_uri != null) alternative_uri = alt_uri;

        var path = "/" + Path.build_path("/",
                "io", "github", "alcinnz", "Odysseus", "odysseus:", subpath);
        Template template;
        ErrorData? error_data = null;
        try {
            if (error_tag == null)
                template = get_for_resource(path, ref error_data);
            else {
                // Parse specially with custom {% error-line %} tag.
                var bytes = resources_lookup_data(path, 0);
                var parser = new Parser.b(bytes);
                parser.local_tag_lib[new Slice.s("error-line")] = error_tag;
                template = parser.parse();
            }
        } catch (SyntaxError e) {
            if (render_errors)
                yield render_alternate_html(tab, "SERVER-ERROR",
                        alt_uri, false, error_data, error_data.tag);
            else webview.load_alternate_html(@"<h1>$(e.domain) @ $(subpath)</h1><p>$(e.message)</p>",
                    alternative_uri, null);
            return;
        } catch (Error e) {
            if (render_errors) yield render_alternate_html(tab, "NOT-FOUND", alt_uri, false);
            else webview.load_alternate_html(@"<h1>$(e.domain) @ $(subpath)</h1><p>$(e.message)</p>",
                    alternative_uri, null);
            return;
        }

        Data.Data full_data;
        if (data != null)
            full_data = new Data.Stack(data, parse_url_to_prosody(alternative_uri));
        else full_data = parse_url_to_prosody(alternative_uri);

        var stream = new CaptureWriter();
        yield template.exec(full_data, stream);
        var content = stream.grab_string();
        webview.load_alternate_html(content, alternative_uri, alternative_uri);
    }

    public void handle_odysseus_uri(WebKit.URISchemeRequest request) {
        var path = "/" + Path.build_path("/",
                "io", "github", "alcinnz", "Odysseus", "odysseus:", request.get_path());
        string? mime_type;
        try {
            mime_type = (string) resources_lookup_data(path + ".mime", 0).get_data();
        } catch (Error e) {
            mime_type = "+text/html; charset=UTF-8";
        }

        if (mime_type[0] == '+') {
            mime_type = mime_type[1:mime_type.length];

            Template template;
            ErrorData? error_data = null;
            try {
                template = get_for_resource(path, ref error_data);
            } catch (SyntaxError e) {
                render_error(request, "SERVER-ERROR", error_data, error_data.tag);
                return;
            } catch (Error e) {
                render_error(request, "NOT-FOUND");
                return;
            }
            Data.Data data = parse_url_to_prosody(request.get_uri());

            var stream = new InputStreamWriter();
            request.finish(stream, -1, mime_type);
            template.exec.begin(data, stream, (obj, res) => stream.close_write());
        } else {
            try {
                var stream = resources_open_stream(path, 0);
                request.finish(stream, -1, mime_type);
            } catch (Error e) {
                render_error(request, "NOT-FOUND");
                return;
            }
        }
    }
}
