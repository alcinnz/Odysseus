/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2017).
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
class WebApp : Gtk.ApplicationWindow {
    WebKit.WebView web;
    string domain;
    construct {
        web = new WebKit.WebView();
        web.show();
        add(web);

        var titlebar = new Gtk.HeaderBar();
        var titlebox = new Gtk.Grid();
        titlebox.orientation = Gtk.Orientation.HORIZONTAL;
        titlebar.custom_title = titlebox;

        var spinner = new Gtk.Spinner();
        web.bind_property("is-loading", spinner, "active");
        titlebox.add(spinner);
        var title = new Gtk.Label("");
        web.bind_property("title", title, "label");
        web.bind_property("title", this, "title");
        titlebox.add(title);
        
        show_all();
    }

    public WebApp(Gtk.Application app, string uri) {
        set_application(app);
        resize(1000, 600);

        connect_events();
        domain = get_domain(uri);
        web.load_uri(uri);
    }

    void connect_events() {
        web.permission_request.connect((req) => {req.allow(); return true;});
        web.decide_policy.connect((decision, type) => {
            if (type == WebKit.PolicyDecisionType.NAVIGATION_ACTION) {
                var nav_decision = (WebKit.NavigationPolicyDecision) decision;
                var uri = nav_decision.navigation_action.get_request().uri;
                if (get_domain(uri) != domain && nav_decision.frame_name == null) {
                    decision.ignore();
                    Granite.Services.System.open_uri(uri);
                }
            } else if (type == WebKit.PolicyDecisionType.RESPONSE) {
                var response_decision = (WebKit.ResponsePolicyDecision) decision;
                var mime_type = response_decision.response.mime_type;

                if (!response_decision.is_mime_type_supported() ||
                        /* Show videos in Audience */
                        mime_type.has_prefix("video/")) {
                    var appinfo = AppInfo.get_default_for_type(mime_type, false);
                    if (appinfo.supports_uris()) {
                        // Probably means it supports HTTP URIs.
                        var uris = new List<string>();
                        uris.append(response_decision.response.uri);
                        try {
                            appinfo.launch_uris(uris, null);
                            decision.ignore();
                            return true;
                        } catch (Error e) {/* Fallback to download */}
                    }

                    // Didn't work, download it first.
                    Granite.Services.System.open_uri(response_decision.response.uri);
                    decision.ignore();
                    return true;
                }
            }
            return false;
        });
        web.web_context.download_started.connect((download) => {
            Granite.Services.System.open_uri(download.response.uri);
            download.cancel();
        });
    }

    static string get_domain(string uri) {
        return new Soup.URI(uri).host;
    }
}

class ViewerApplication : Gtk.Application {
    construct {
        this.flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
        this.flags |= ApplicationFlags.NON_UNIQUE;
    }

    public override int command_line(ApplicationCommandLine cmdline) {
        Gtk.Settings.get_default().gtk_application_prefer_dark_theme = true;

        string[] args = cmdline.get_arguments();
        if (args.length != 2) {
            error("USAGE: oddysseus-viewer URI\n");
        }

        new WebApp(this, args[1]);

        return 0;
    }

    public static int main(string[] args) {
        return new ViewerApplication().run(args);
    }
}
