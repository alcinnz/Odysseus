/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2019).
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
namespace Odysseus.Model {
    public class Link {
        public string rel;
        public string href;
        public Link(string rel, string href) {
            this.rel = rel; this.href = href;
        }
    }
    public async Link[] parse_links(uint8[] src) {
        // Runs a W3C utility to extract additional information WebKit won't
        //      readily give me.
        try {
            int stdin;
            int stdout;
            Process.spawn_async_with_pipes("/",
                    {"hxwls", "-l"},
                    null,
                    SpawnFlags.SEARCH_PATH,
                    null,
                    null,
                    out stdin,
                    out stdout,
                    null);
            var hxwls_in = new UnixOutputStream(stdin, true);
            var hxwls_out = new DataInputStream(new UnixInputStream(stdout, true));

            // Fix for webpages with, say, megabytes of HTML, so they don't freeze.
            // Scanning just the first KB should be very generous.
            if (src.length > 2048) {
                yield hxwls_in.write_all_async(src[0:2048], Priority.DEFAULT, null, null);
            } else {
                yield hxwls_in.write_all_async(src, Priority.DEFAULT, null, null);
            }
            yield hxwls_in.close_async(Priority.DEFAULT, null);

            var links = new Gee.ArrayList<Link>();
            string line;
            while ((line = yield hxwls_out.read_line_async()) != null) {
                var record = line.split("\t");
                links.add(new Link(record[1], record[2]));
            }
            return links.to_array();
        } catch (Error err) {
            warning("Failed to parse links from page source: %s", err.message);
        }
        return new Link[0];
    }
}
