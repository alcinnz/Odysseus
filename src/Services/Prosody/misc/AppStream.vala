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
/** Odysseus follows elementary's principal of "build small apps that work
        together", but that can often lead to a usability hurdle for adoption
        of technologies the user doesn't have apps for. This is a concern
        expressed by: https://blogg.forteller.net/2013/first-steps/ .

Unfortunately I have to duplicate some AppCenter UI due to the way the AppStream
        standards are designed, but that'll give Odysseus a chance to explain
        why it's bringing up this UI.

And given I can link to app descriptions where they can be installed via simple
        URLs, it looks quite trivial to write that UI in Prosody. The
        challenging bit is getting at the data, which is what's done here. */
namespace Odysseus.Templating.xAppStream {
#if HAVE_APPSTREAM
    using AppStream;

    public class AppStreamBuilder : TagBuilder, Object {
        private weak AppStream.Pool pool;
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var variables = new Gee.ArrayList<Variable>();
            foreach (var arg in args) variables.add(new Variable(arg));

            // Ideally this would be called rarely if ever,
            // leading to setup and teardown happening each time.
            // But this parsing infrastracture helps us take advantage
            // of the off-chance where this can be better optimized than that.
            var appstream = pool;
            if (appstream == null) {
                appstream = new AppStream.Pool();
                this.pool = appstream;
                try {
                    appstream.load();
                } catch (Error err) {
                    // The system might not support AppStream so disable those features.
                    warning(err.message);
                    return null;
                }
            }
            try {
                return new AppStreamTag(variables.to_array(), appstream);
            } catch (SyntaxError err) {
                throw err;
            } catch (Error err) {
                var msg = new Slice.s(@"<p style='color: red;'>$(err.message)</p>");
                return new Echo(msg);
            }
        }
    }

    private class AppStreamTag : Template {
        private AppStream.Pool pool;
        private Variable[] vars;

        private Template renderer;
        public AppStreamTag(Variable[] vars, AppStream.Pool appstream) throws Error {
            this.vars = vars; this.pool = appstream;

            var path = "/io/github/alcinnz/Odysseus/odysseus:/special/applist";
            ErrorData? error_data = null; // ignored
            this.renderer = get_for_resource(path, ref error_data);
        }
        public override async void exec(Data.Data ctx, Writer output) {
            // 1. Assemble the MIMEtype query
            var mimes = new StringBuilder();
            foreach (var variable in vars) mimes.append(variable.eval(ctx).to_string());
            var extra_mimes = mimes.str.split(";");
            var mime = extra_mimes[0];
            extra_mimes = extra_mimes[1:extra_mimes.length];

            // 2. Query AppStream
            var apps = pool.get_components_by_provided_item(ProvidedKind.MIMETYPE, mime);

            // 3. Construct a datamodel for rendering
            var app_list = new Data.Data[apps.length]; int j = 0;
            for (var i = 0; i < apps.length; i++) {
                // First check if it also matches extra_mimes!
                var app_mimes = apps[i].get_provided_for_kind(AppStream.ProvidedKind.MIMETYPE);
                var matches = true;
                foreach (var extra_mime in extra_mimes) {
                    if (app_mimes.has_item(extra_mime)) continue;
                    matches = false;
                    break;
                }
                if (!matches) continue;

                // Find an icon for the app.
                var icon = "icon:128/application-x-executable";
                var icons = apps[i].get_icons();
                if (icons.length > 0) icon = icons[0].get_url();

                // WebKit refuses to renderer file: images inline, so translate to data:
                if (icon.has_prefix("file:")) {
                    uint8[] img; string etag;
                    try {
                        var file = File.new_for_uri(icon);
                        yield file.load_contents_async(null, out img, out etag);
                        var img64 = Base64.encode(img);
                        var info = yield file.query_info_async("standard::*", 0);
                        var img_mime = info.get_content_type();
                        icon = @"data:$img_mime;base64,$img64";
                    } catch (Error err) {
                        icon = "icon:128/application-x-executable";
                    }
                }

                // For non-AppStream-compatible package manager GUIs.
                var packages = string.joinv(" ", apps[i].get_pkgnames());

                app_list[j++] = Data.Let.builds("icon", new Data.Literal(icon),
                        Data.Let.builds("name", new Data.Literal(apps[i].get_name()),
                        Data.Let.builds("packages", new Data.Literal(packages),
                        new Data.Literal(apps[i].id)
                )));
            }
            app_list = app_list[0:j];

            // 4. What was the package manager again?
            var pacman = AppInfo.get_default_for_uri_scheme("appstream");

            // 5. Render via a common template
            var data = Data.Let.builds("pacman",
                        new Data.Literal(pacman != null ? pacman.get_display_name() : ""),
                    Data.Let.builds("apps", new Data.List.from_array(app_list)));
            yield renderer.exec(data, output);
        }
    }
#else
    public class AppStreamBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            return null;
        }
    }
#endif
}
