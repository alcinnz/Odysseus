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

using Oddysseus.Services;
namespace Oddysseus.Traits {
    private void report_error(string error_, string uri, WebTab tab) {
        var web = tab.web;
        string error = error_;

        web.go_back();// Hack for replacing page,
                // though has unfortunate side-effects

        var test_path = "/" + Path.build_path("/",
                "io", "github", "alcinnz", "Oddysseus", "oddysseus:", "errors",
                error);
        try {
            size_t ignored; uint32 ignored2;
            resources_get_info(test_path, 0, out ignored, out ignored2);
        } catch (Error e) {
            try {
                var res = resources_lookup_data(test_path + ".link", 0);
                error = Templating.ByteUtils.to_string(res).chomp();
            } catch (Error err) {
                error = "xxx";
            }
        }

        render_alternate_html(web, "errors/" + error, uri);
        try {
            var path = "/" + Path.build_path("/",
                    "io", "github", "alcinnz", "Oddysseus", "oddysseus:",
                    "errors", error + ".icon");
            var res = resources_lookup_data(path, 0);
            var icon = Templating.ByteUtils.to_string(res).chomp();
            tab.icon = new ThemedIcon.with_default_fallbacks(icon + "-symbolic");
        } catch (Error e) { /* pass */ }
    }

    // Utility to handle a form submit on an error page. 
    private delegate void FormCallback(WebKit.FormSubmissionRequest request);
    private void connect_form(WebKit.WebView web, FormCallback cb) {
        var handler_id = web.submit_form.connect((req) => cb(req));
        web.load_changed.connect((evt) => {
            web.disconnect(handler_id);
        });
    }

    private async void report_status_errors(WebKit.WebView web, WebTab tab) {
        var resource = web.get_main_resource();
        var content = yield resource.get_data(null);
        if (content.length == 0) {
            var error = resource.response.status_code.to_string();
            report_error(error, web.uri, tab);
        }
    }

    private string parse_hostname(string uri) {
        int start = uri.index_of_char('/') + 2;
        int end = uri.index_of_char('/', start);
        return uri[start:end];
    }

    public void setup_report_errors(WebTab tab) {
        var web = tab.web;

        web.web_process_crashed.connect(() => {
            report_error("crashed", web.uri, tab);
            return true;
        });
        web.load_failed_with_tls_errors.connect((uri, certificate, error) => {
            // TODO test
            report_error("bad-certificate", uri, tab);
            // This is to debug potential hostname parsing problems.
            stderr.printf("'%s'\n", parse_hostname(uri));
            connect_form(web, (req) => {
                var host = parse_hostname(uri);
                WebTab.global_context.allow_tls_certificate_for_host(
                        certificate, host);
            });
            // TODO show certificate
           return true;
        });
        web.load_failed.connect((load_evt, uri, err) => {
            // Diagnose the problem
            if (err.code == 302) // Network.CANCELLED
                return false;
            var netman = NetworkMonitor.get_default();
            string error = "protocol";
            if (!netman.network_available) error = "network";
            else {
                try {
                    var dest = NetworkAddress.parse_uri(uri, 80);
                    if (netman.can_reach(dest)) error = "dns";
                } catch (Error e) {
                    error = "dns";
                }
            }

            report_error(error, uri, tab);
            return true;
        });
        web.load_changed.connect((load_evt) => {
            if (load_evt == WebKit.LoadEvent.FINISHED)
                report_status_errors.begin(web, tab);
        });
        web.authenticate.connect((request) => {
            report_error("401", web.uri, tab);
            connect_form(web, (req) => {
                var data = (HashTable<string, string>) req.get_text_fields();
                var creds = new WebKit.Credential(data["username"],
                        data["password"],
                        WebKit.CredentialPersistence.FOR_SESSION);
                request.authenticate(creds);
            });
           return true;
       });
    }
}
