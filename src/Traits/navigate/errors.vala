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
    private void report_error(string error_, string uri, WebTab tab) {
        string error = error_;

        var test_path = "/" + Path.build_path("/",
                "io", "github", "alcinnz", "Odysseus", "odysseus:", "errors",
                error);
        try {
            size_t ignored; uint32 ignored2;
            resources_get_info(test_path, 0, out ignored, out ignored2);
        } catch (Error e) {
            try {
                var res = new Slice.b(resources_lookup_data(test_path + ".link", 0));
                error = @"$res".chomp();
            } catch (Error err) {
                error = "xxx";
            }
        }

        render_alternate_html.begin(tab, "errors/" + error, uri);
    }

    // Utility to handle a form submit on an error page. 
    private delegate void FormCallback(WebKit.FormSubmissionRequest request);
    private void connect_form(WebKit.WebView web, owned FormCallback cb) {
        var handler_id = web.submit_form.connect((req) => {
            cb(req);
        });
        ulong remove_handler_id = 0;
        remove_handler_id = web.decide_policy.connect((decision, type) => {
            if (type != WebKit.PolicyDecisionType.NAVIGATION_ACTION) return false;
            Timeout.add(100, () => {
                web.disconnect(handler_id);
                web.disconnect(remove_handler_id);
                return false;
            }); // FIXME Code smell in that the timing might still not work out.
            return false;
        });
    }

    private string parse_hostname(string uri) {
        int start = uri.index_of_char('/') + 2;
        int end = uri.index_of_char('/', start);
        return uri[start:end];
    }

    public void setup_report_errors(WebTab tab) {
        var web = tab.web;

        web.load_failed_with_tls_errors.connect((uri, certificate, error) => {
            ulong handler = 0;
            handler = tab.populate_indicators.connect((indicators, web) => {
                report_https_certificate(indicators, new Soup.URI(web.uri).host,
                        certificate, error);
                tab.disconnect(handler);
            });

            report_error("bad-certificate", uri, tab);
            // This is to debug potential hostname parsing problems.
            connect_form(web, (req) => {
                var host = parse_hostname(uri);
                get_web_context().allow_tls_certificate_for_host(certificate, host);
            });
            // TODO show certificate
           return true;
        });
        web.load_failed.connect((load_evt, uri, err) => {
            // Policy and manual cancels shouldn't be handled as errors. 
            if (err.code == 302 || err.code == 204 || err.code == 102)
                return false;

            // Diagnose the problem
            // This is necessary as otherwise unknown domains
            //      are indistiguishable from network outages.
            var netman = NetworkMonitor.get_default();
            string error = "protocol";
            if (!netman.network_available) error = "network";
            else if (uri.has_prefix("https://")) {
                // Try falling back to HTTP. This is vital because we load HTTPS by default.
                web.load_uri("http" + uri["https".length:uri.length]);
                return true;
            } else {
                try {
                    var dest = NetworkAddress.parse_uri(uri, 80);
                    if (!netman.can_reach(dest)) error = "dns";
                } catch (Error e) {
                    error = "dns";
                }
            }

            report_error(error, uri, tab);
            return true;
        });
        // FIXME Overrides site-provided pages too often.
        //      I think this needs to be fixed in WebKitGTK (but not WebCore)
        /*web.decide_policy.connect((decision, type) => {
            if (type == WebKit.PolicyDecisionType.RESPONSE) {
                var response_decision = (WebKit.ResponsePolicyDecision) decision;
                var response = response_decision.response;
                if (response.content_length == 0 &&
                        response.uri == web.uri &&
                        response.status_code != 200) {
                    report_error(response.status_code.to_string(), response.uri,
                            tab);
                    return true;
                } else {
                    // So we don't get stuck with the error icon
                    tab.restore_favicon();
                }
            }
            return false;
        });*/
        web.authenticate.connect((request) => {
            report_error("401", web.uri, tab);
            connect_form(web, (req) => {
                GenericArray<string> keys;
                GenericArray<string> values;
                if (!req.list_text_fields(out keys, out values)) return;

                var username = ""; var password = "";
                for (var i = 0; i < keys.length; i++) {
                    if (keys[i] == "username") username = values[i];
                    else if (keys[i] == "password") password = values[i];
                }

                var creds = new WebKit.Credential(username, password,
                        WebKit.CredentialPersistence.FOR_SESSION);
                request.authenticate(creds);
            });
           return true;
       });
    }
}
