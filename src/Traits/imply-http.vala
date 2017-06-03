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
/** Prepends 'http://' in the likely case the user dropped it.

Takes care to leave valid URIs as is so users can take advantage of the fact
URIs entered into the addressbar may be opened by other applications. */
namespace Oddysseus.Traits {
    public class ImplyHTTP : Services.CompleterDelegate {
        public override void autocomplete() {
            if (" " in query || !("." in query)) return; // Doesn't even resemble a URI!

            bool has_schema;
            if ("://" in query) has_schema = true;
            else if (!(":" in query)) has_schema = false;
            else {
                var host = query.str("/");
                if (host == null) host = query;

                var user = host.str("@");
                if (user != null) has_schema = ":" in user;
                else {
                    var port = host.rstr(":");
                    has_schema = false;
                    foreach (var digit in port.data) {
                        if ('0' <= digit && digit <= '9') {
                            has_schema = true;
                            break;
                        }
                    }
                }
            }

            if (has_schema) suggest(query);
            else suggest("http://" + query);
        }
    }
}
