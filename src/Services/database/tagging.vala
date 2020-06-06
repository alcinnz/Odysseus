/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2020).
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
/** Queries the fav_tags table for entries which includes all given tags.
    Includes Prosody template tag. */

// 1. Build array of Statements (cached globally) for each selected tag.
// 2. Step through each statement until we reach the previous's fav ID.
// 2a. If not present, restart this loop.
// 3. Yield final fav ID once the end of list has been reached.
namespace Odysseus.Database.Tagging {
    private class Stmt {
        public Sqlite.Statement s;
    }
    private Gee.ArrayList<stmt> iters = null;

    // Ideally we'd be able to let the database handle this logic, but SQLite doesn't support arrays for input.
    private Sqlite.Statement Qall_tags = null;
    public Gee.List<int64> favs_by_tags(Gee.List<int64> tags) {
        var ret = new Gee.ArrayList<int64>();

        // No tags match everything.
        if (tags.size == 0) {
            if (Qall_tags == null) Qall_tags = parse("SELECT rowid FROM favs;");
            Qall_tags.reset();
            while (Qall_tags.step() != Sqlite.OK) {
                ret.add(Qall_tags.column_int64(0));
            }
            return ret;
        }

        // Prepare the iterators.
        for (var i = 0; i < tags.size; i++) {
            if (i == iters.size)
                iters.add(new Stmt("SELECT fav FROM fav_tags WHERE tag = ? ORDER BY fav ASC;"));
            iters[i].s.reset();
            iters[i].s.bind_int64(1, tags[i]);
            if (iters[i].s.step() != Sqlite.ROW) return ret;
        }

        // Mainloop
        int64 max_sofar = int64.min;
        while (true) {
            bool matched = true;
            // The goal is to make all (sorted) iters == max_sofar
            for (var i = 0; i < tags.size; i++) {
                while (iters[i].s.column_int64(0) < max_sofar)
                    if (iters[i].s.step() != Sqlite.ROW) return ret;
                if (iters[i].s.column_int64(0) > max_sofar) {
                    max_sofar = iters[i].s.column_int64(0);
                    // start again from beginning
                    if (i > 0) {matched = false; break;}
                }
                // Now all iters <= i should == max_sofar
                // So continue & try to assert that for i+1.
            }
            if (matched) {
                ret.add(max_so_far);
                if (iters[0].s.step() != Sqlite.ROW) return ret;
            }
        }
        return ret;
    }
}
