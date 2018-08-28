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
/** Renders additional MIMEtypes to HTML.
  Of particular interest are the MIMEtypes Odysseus has some specific knowledge
  of otherwise. */
namespace Odysseus.Traits {
    using Templating;

    public void setup_other_mimetypes(WebTab tab) {
        tab.web.decide_policy.connect((decision, type) => {
            if (type != WebKit.PolicyDecisionType.RESPONSE) return false;
            var response = decision as WebKit.ResponsePolicyDecision;

            var mime = response.response.mime_type;
            var supports_mime = false;
            try {
                var path = @"/io/github/alcinnz/Odysseus/odysseus:/viewers/$mime";
                supports_mime = resources_get_info(path, 0, null, null);
            } catch (Error err) {supports_mime = false;}

            var query = Data.Let.builds("url", new Data.Literal(tab.web.uri),
                    new Data.Literal("url=" + Soup.URI.encode(tab.web.uri, null)));
            var data = Data.Let.builds("url", Data.Let.builds("query", query),
                    new Data.Literal("odysseus:view"));

            if (supports_mime) Services.render_alternate_html(tab, "view",
                    null, true, data);

            return supports_mime;
        });
    }
}
