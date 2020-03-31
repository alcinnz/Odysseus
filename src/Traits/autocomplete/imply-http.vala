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
/** Prepends 'https://' in the likely case the user dropped it.

Takes care to leave valid URIs as is so users can take advantage of the fact
URIs entered into the addressbar may be opened by other applications. */
namespace Odysseus.Traits {
    public class ImplyHTTP : Tokenized.CompleterDelegate {
        public override void autocomplete(string query, Tokenized.Completer c) {
            if (" " in query || !("." in query || ":" in query))
                return; // Doesn't even resemble a URI!

            // TODO handle IPv6 addresses.
            bool has_schema;
            if ("://" in query) has_schema = true;
            else if (!(":" in query)) has_schema = false;
            else {
                var host = query.split("/", 2)[0];
                if (host == null) host = query;

                var user = host[0:host.index_of("@")];
                if (user != null) has_schema = !(":" in user);
                else {
                    var port = host[host.index_of(":")+1:host.length];
                    has_schema = false;
                    foreach (var digit in port.data) {
                        if ('0' < digit || digit > '9') {
                            has_schema = true;
                            break;
                        }
                    }
                }
            }

            if (has_schema) c.suggestion(query);
            else c.suggestion("https://" + query);
        }
    }
}
