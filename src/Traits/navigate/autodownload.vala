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

namespace Odysseus.Traits {
    public void setup_autodownload(WebTab tab) {
        var web = tab.web;

        web.decide_policy.connect((decision, type) => {
            if (type == WebKit.PolicyDecisionType.RESPONSE) {
                var response_decision = (WebKit.ResponsePolicyDecision) decision;
                var mime_type = Download.normalize_mimetype(response_decision.response);

                if (!response_decision.is_mime_type_supported() ||
                        /* Show videos in Audience */
                        mime_type.has_prefix("video/") || mime_type == "application/ogg") {
                    // TODO This commented would be a nice experience, if only it
                    //      worked well in combination with cookies.
                    //      (I tried, and ended up with libSoup being unwilling to synchronize)
                    /*var appinfo = AppInfo.get_default_for_type(mime_type, false);
                    if (appinfo.supports_uris()) {
                        // Probably means it supports HTTP URIs.
                        var uris = new List<string>();
                        uris.append(response_decision.response.uri);
                        try {
                            appinfo.launch_uris(uris, null);
                            decision.ignore();
                            return true;
                        } catch (Error e) {
                            // Fallback to download
                        }
                    }*/

                    // Didn't work, download it first.
                    decision.download();
                    decision.ignore();
                    return true;
                }
            }
            return false;
        });

        web.load_failed.connect((load_evt, uri, err) => {
            if (!err.matches(WebKit.PolicyError.quark(), 101)) return false;

            var schema = uri.split(":", 2)[0];
            var app = AppInfo.get_default_for_uri_scheme(schema);
            if (app == null) {
                report_error("schema", uri, tab);
            } else if (app.get_id() == Odysseus.Application.instance.application_id) {
                // NOTE: If this case isn't handled, there'd be an infinite loop
                //      between this and Odysseus.Application.open.
                report_error("url", uri, tab);
            } else {
                var uris = new List<string>();
                uris.append(uri);
                try {
                    app.launch_uris(uris, null);
                } catch (Error err) {
                    warning(err.message);
                }
            }
            return true;
        });
    }
}
