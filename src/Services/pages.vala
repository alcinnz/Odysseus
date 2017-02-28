/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017).
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

/** Exposes our GLib.Resource templates to WebKit. */
namespace Oddysseus.Services {
    private Templating.Data.Data parse_url_to_prosody(string url) {
        // TODO Implement properly
        return new Templating.Data.Empty();
    }

    private void render_error(WebKit.URISchemeRequest request, string error) {
        // TODO support rendering debugging information.
        try {
            var path = "/" + Path.build_path("/",
                    "io", "github", "alcinnz", "Oddysseus", "oddysseus:", error);
            var stream = resources_open_stream(path, 0);
            request.finish(stream, -1, "text/html");
        } catch (Error err) {
            request.finish_error(err);
        }
    }

    public async void render_alternate_html(WebKit.WebView webview,
            string subpath, string? alt_uri = null, bool render_errors = true,
            Templating.Data.Data? data = null) {
        var alternative_uri = webview.uri;
        if (alt_uri != null) alternative_uri = alt_uri;

        var path = "/" + Path.build_path("/",
                "io", "github", "alcinnz", "Oddysseus", "odysseus:", subpath);
        Templating.Template template;
        try {
            template = Templating.get_for_resource(path);
        } catch (Templating.SyntaxError e) {
            if (render_errors)
                yield render_alternate_html(webview, "SERVER-ERROR",
                        alt_uri, false); // TODO Add debugging information
            else webview.load_alternate_html(
                    @"<h1>$(e.domain)</h1><p>$(e.message)</p>",
                    alternative_uri, null);
            return;
        } catch (Error e) {
            if (render_errors) yield render_alternate_html(webview, "NOT-FOUND",
                    alt_uri, false); // TODO Add debugging information
            else webview.load_alternate_html(
                    @"<h1>$(e.domain)</h1><p>$(e.message)</p>",
                    alternative_uri, null);
            return;
        }

        Templating.Data.Data full_data;
        if (data != null)
            full_data = new Templating.Data.Stack(data,
                    parse_url_to_prosody(alternative_uri));
        else full_data = parse_url_to_prosody(alternative_uri);

        var stream = new Templating.CaptureWriter();
        yield template.exec(data, stream);
        webview.load_alternate_html(
                Templating.ByteUtils.to_string(stream.grab_data()),
                alternative_uri, "oddysseus:" + subpath);
    }

    public void handle_oddysseus_uri(WebKit.URISchemeRequest request) {
        var path = "/" + Path.build_path("/",
                "io", "github", "alcinnz", "Oddysseus", "oddysseus:",
                request.get_path());
        string? mime_type;
        try {
            mime_type = (string) resources_lookup_data(path + ".mime", 0)
                    .get_data();
        } catch (Error e) {
            mime_type = "+text/html";
        }

        if (mime_type[0] == '+') {
            mime_type = mime_type[1:mime_type.length];

            Templating.Template template;
            try {
                template = Templating.get_for_resource(path);
            } catch (Templating.SyntaxError e) {
                render_error(request, "SERVER-ERROR");
                return;
            } catch (Error e) {
                render_error(request, "NOT-FOUND");
                return;
            }
            Templating.Data.Data data;
            try {
                data = parse_url_to_prosody(request.get_uri());
            } catch (Error e) {
                render_error(request, "BAD-REQUEST");
                return;
            }

            var stream = new Templating.InputStreamWriter();
            request.finish(stream, -1, mime_type);
            template.exec.begin(data, stream, (obj, res) => {
                stream.close_write();
            });
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
