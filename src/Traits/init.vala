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
    public void setup_context(WebKit.WebContext ctx) {
        var sec = ctx.get_security_manager();

        ctx.register_uri_scheme("oddysseus", Services.handle_oddysseus_uri);
        // Explicitly do not enable CORs, as the information here is quite sensitive. 
        sec.register_uri_scheme_as_secure("oddysseus"); // so resources load in error pages on an HTTPS connection
        sec.register_uri_scheme_as_no_access("oddysseus"); // Forces us to not rely on the Internet
        ctx.register_uri_scheme("source", handle_source_uri);
        DownloadsBar.setup_context(ctx);
    }

    public void setup_webview(WebTab tab) {
        // FIXME overrides site-provided pages too often:
        //setup_report_errors(tab);
        setup_autodownload(tab.web);
    }
}
