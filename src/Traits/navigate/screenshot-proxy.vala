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
/** This URI scheme proxies
        https://alcinnz.github.io/Odysseus-recommendations/screenshot/*,
    whilst caching responses in the screenshot_v2 table.
It is triggered by odysseus:home upon finding a `null` screenshot. */
/** PRIVACY CONSIDERATIONS:
    This technique *does* increase the amount of data that gets leaked to the
        Odysseus developers and their webhosting service (namely GitHub).
    However the ammount of data leakage drastically reduces over time as more
        of these screenshots gets permantly cached, and after the first several
        newly opened tabs the data leakage should be about 0.
    Giving a fast and good first impression is worth the minuscule decrease in
        the surfers' privacy. As that'll help entice people. */
namespace Odysseus.Traits {
    public void handle_odysseusproxy_uri(WebKit.URISchemeRequest request) {
        async_handle_odysseusproxy_uri.begin(request.get_uri(), (response) => {
            request.finish(stream, -1, "image/png");
        }, (obj, res) => {
            try {
                async_handle_odysseusproxy_uri.end(res);
            } catch (Error err) {
                request.finish_error(err);
            }
        }
    }
    private delegate YieldResponse(InputStream response);
    errordomain HTTPError {STATUS};
    private async void async_handle_odysseusproxy_uri(string request,
            YieldResponse cb) throws Error {
        var uri = request["odysseusproxy:///".length:request.length];
        var hash = Checksum.compute_for_string(ChecksumType.MD5, uri);
        var proxy = "https://alcinnz.github.io/Odysseus-recommendations/screenshot/";
        proxy += hash + ".png";

        var session = new Soup.Session();
        var https = session.request_http("GET", proxy);
        var response = yield https.send_async(null);
        if (https.get_message().status_code != 200)
            throw new HTTPError.STATUS("HTTP %i", https.get_message().status_code);
        cb(response);

        /* Now cache it for greater speed and privacy!
            Afterall that's why this URI scheme is needed...*/
        // Start by reading the entire response in.
        var memory = new MemoryOutputStream.resizable();
        yield memory.splice_async(response);
        // The other APIs don't give a proper Vala array
        var binary = memory.steal_as_bytes().get_data();

        var base64 = Base64.encode((uchar[]) binary);

        // And save to database
        var sql = "INSERT INTO screenshot_v2(uri, image) VALUES (?, ?);";
        Sqlite.Statement query;
        if (Database.get_database().prepare_v2(sql, -1, out query) != Sqlite.OK)
            return;
        query.bind_text(1, uri);
        query.bind_text(2, base64);
        query.step();
    }
}
