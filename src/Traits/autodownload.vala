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

namespace Oddysseus.Traits {
    public void setup_autodownload(WebKit.WebView web) {
        web.decide_policy.connect((decision, type) => {
            if (type == WebKit.PolicyDecisionType.RESPONSE) {
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
                    decision.download();
                    decision.ignore();
                    return true;
                }
            }
            return false;
        });
    }
}
