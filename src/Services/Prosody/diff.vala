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

/* Detects what text has changed between two strings and renders to HTML.

    In contrast to the diff command, this works on a per-byte basis
        and does not combine the add & remove scripts.

WARNING! This computes solutions to all pairs of prefixes to the input strings
    (in computer science lingo it has O(mn) time & space requirements),
    so avoid using on large input files.
    Also it may be worth it to perform equality checks on the strings beforehand
    as that has a measly O(min(m, n)) time & 0 space requirements.

    The per-line basis of the command minimizes this problem there. */
namespace Odysseus.Templating.Diff {
    public class Duo {
        public int first;
        public int last;

        public Duo(int a, int b) {this.first = a; this.last = b;}
    }

    private List<Duo> longest_common_subsequence(uint8[] a, uint8[] b) {
        // 0. Initialize a table for Dynamic Programming
        var table = new int[a.length + 1, b.length + 1];
        for (var i = 0; i <= a.length; i++) table[i,0] = 0;
        for (var i = 0; i <= b.length; i++) table[0,i] = 0;

        // 1. Build up the LCS via Dynamic Programming
        for (var x0 = 0; x0 < a.length; x0++) {
            var x1 = x0 + 1;
            for (var y0 = 0; y0 < b.length; y0++) {
                var y1 = y0 + 1;

                if (a[x0] == b[y0]) {
                    // Denotes we can extend the subsequence by 1
                    table[x1,y1] = table[x0,y0] + 1;
                } else {
                    // Denotes we can continue with an existing subsequence,
                    // Choosing the optimal one to use.
                    table[x1,y1] = int.max(table[x1,y0], table[x0,y1]);
                }
            }
        }

        // 2. Extract the Longest Common Subsequence (LCS)
        var lcs = new List<Duo>();
        // 2a. Start at the end
        var x = a.length;
        var y = b.length;
        // 2b. We're done when we reach the start
        while (x > 0 && y > 0) {
            if (a[x-1] == b[y-1]) {
                // 2c. Capture equivalence and traverse diagonally up.
                lcs.prepend(new Duo(x-1, y-1));
                x--; y--; // Matches both chars
            } else {
                // 2d. In absence of equivalence find the chosen max.
                if (table[x,y] == table[x,y-1]) y--;
                else if (table[x,y] == table[x-1,y]) x--;
                else error("LCS table built incorrectly");
            }
        }

        return lcs;
    }

    public struct Ranges {
        Gee.List<Duo> a_ranges;
        Gee.List<Duo> b_ranges;

        public Ranges() {
            a_ranges = new Gee.ArrayList<Duo>();
            b_ranges = new Gee.ArrayList<Duo>();
        }
    }
    private Ranges get_ranges(List<Duo> equivs) {
        var ret = Ranges();

        var prev = new Duo(0, 0);
        foreach (var equiv in equivs) {
            if (equiv.first > prev.first)
                ret.a_ranges.add(new Duo(prev.first, equiv.first));

            if (equiv.last > prev.last)
                ret.b_ranges.add(new Duo(prev.last, equiv.last));

            // When saving prev, make sure to skip over this common character
            prev = new Duo(equiv.first+1, equiv.last+1);
        }

        return ret;
    }

    public Ranges diff(Bytes a, Bytes b) {
         var ranges = longest_common_subsequence(a.get_data(), b.get_data());
         // Ensure get_ranges captures trailing text that was added.
         ranges.append(new Duo(a.length, b.length));
        return get_ranges(ranges);
    }

    public async void render_ranges(Bytes source, Gee.List<Duo> ranges,
            string tagname, Writer output) {
        var last_end = 0;
        foreach (var range in ranges) {
            if (last_end != range.first)
                yield ByteUtils.write_escaped_html(source[last_end:range.first], output);
            last_end = range.last;

            yield output.writes(@"<$tagname>");
            yield ByteUtils.write_escaped_html(source[range.first:range.last], output);
            yield output.writes(@"</$tagname>");
        }
        yield ByteUtils.write_escaped_html(source[last_end:source.length], output);
    }
}
