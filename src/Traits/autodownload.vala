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

                if (!web.can_show_mime_type(mime_type) ||
                        /* Show videos in Audience */
                        mime_type.has_prefix("video/")) {
                    decision.download();
                    return true;
                }
            }
            return false;
        });
    }
}
