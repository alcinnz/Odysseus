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
/* Communicates that the connection to a page is secure, and
    (TODO) the certification for such. */
namespace Odysseus.Traits {
    public void report_https(Gee.List<StatusIndicator> indicators, WebKit.WebView web) {
        TlsCertificate cert;
        TlsCertificateFlags errors;

        if (web.get_tls_info(out cert, out errors)) return;
        if (errors == 0)
            indicators.add(new StatusIndicator("security-high", StatusIndicator.Classification.SECURE));
        else indicators.add(new StatusIndicator("security-low", StatusIndicator.Classification.ERROR));
    }
}
