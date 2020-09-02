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
    using Templating;

    private class Stmt {
        public Sqlite.Statement s;
        public Stmt(string query) {
            this.s = parse(query);
        }
    }
    private Gee.ArrayList<Stmt> iters = null;

    // Ideally we'd be able to let the database handle this logic, but SQLite doesn't support arrays for input.
    private Sqlite.Statement Qall_tags = null;
    public Gee.List<int64?> favs_by_tags(Gee.List<int64?> tags) {
        var ret = new Gee.ArrayList<int64?>();

        // No tags match everything.
        if (tags.size == 0) {
            if (Qall_tags == null) Qall_tags = parse("SELECT rowid FROM favs;");
            Qall_tags.reset();
            while (Qall_tags.step() == Sqlite.ROW) {
                ret.add(Qall_tags.column_int64(0));
            }
            return ret;
        }

        // Prepare the iterators.
        if (iters == null) iters = new Gee.ArrayList<Stmt>();
        for (var i = 0; i < tags.size; i++) {
            if (i == iters.size)
                iters.add(new Stmt("SELECT fav FROM fav_tags WHERE tag = ? ORDER BY fav ASC;"));
            iters[i].s.reset();
            iters[i].s.bind_int64(1, tags[i]);
            if (iters[i].s.step() != Sqlite.ROW) return ret;
        }

        // Mainloop
        int64 max_sofar = int64.MIN;
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
                ret.add(max_sofar);
                if (iters[0].s.step() != Sqlite.ROW) return ret;
            }
        }
        return ret;
    }

    private Sqlite.Statement Qtags_by_fav = null;
    public Gee.Set<int64?> related_tags(Gee.List<int64?> tags) {
        if (tags == null || tags.size == 0) {
            // Return all tags if we've yet to filter them down...
            if (Qall_tags == null) Qall_tags = parse("SELECT rowid FROM tags;");

            var ret = new Gee.HashSet<int64?>();
            Qall_tags.reset();
            while (Qall_tags.step() == Sqlite.ROW) ret.add(Qall_tags.column_int64(0));
            return ret;
        }

        if (Qtags_by_fav == null) Qtags_by_fav = parse("SELECT tag FROM fav_tags WHERE fav = ?;");

        Gee.HashSet<int64?> ret = null;
        foreach (var fav in favs_by_tags(tags)) {
            var this_tags = new Gee.HashSet<int64?>();

            Qtags_by_fav.reset();
            Qtags_by_fav.bind_int64(1, fav);
            while (Qtags_by_fav.step() == Sqlite.ROW)
                this_tags.add(Qtags_by_fav.column_int64(0));

            if (ret == null) ret = this_tags;
            else ret.retain_all(this_tags);
        }

        if (ret == null) return new Gee.HashSet<int64?>();
        else {
            ret.remove_all(tags);
            return ret;
        }
    }

    public class TaggedBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var source = new Variable(args.next());
            var type = args.next();
            if ("as" in type) type = new Slice.s("fav");
            else if (!("as" in args.next()))
                throw new SyntaxError.INVALID_ARGS("Expecting 'as' before iteration variable.");
            var dest = args.next();
            args.assert_end();
            if (!("fav" in type || "tag" in type))
                throw new SyntaxError.INVALID_ARGS("Type must be 'tag' or 'fav', default 'fav'.");

            WordIter endtoken;
            var body = parser.parse("empty endtagged", out endtoken);

            var endtag = endtoken.next(); endtoken.assert_end();
            Template empty_block = new Echo();
            if ("empty" in endtag) {
                empty_block = parser.parse("endtagged", out endtoken);
                endtag = endtoken.next(); endtoken.assert_end();
            }
            if (!("endtagged" in endtag))
                throw new SyntaxError.UNBALANCED_TAGS("Expected {%% endtagged %} tag following {%% tagged %}, possibly with one {%% else %} tag inbetween.");

            return new TaggedTag("fav" in type, source, dest, body, empty_block);
        }
    }

    private class TaggedTag : Template {
        private bool type; // true for fav, false for tag.
        private Variable source;
        private Slice dest;
        private Template body;
        private Template empty;

        public TaggedTag(bool type, Variable source, Slice dest, Template body, Template empty) {
            this.type = type; this.source = source; this.dest = dest;
            this.body = body; this.empty = empty;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var input = new Gee.ArrayList<int64?>();
            source.eval(ctx).foreach_map((k, v) => input.add((int64) v.to_int()));

            Gee.Collection<int64?> ids;
            if (this.type) ids = favs_by_tags(input);
            else ids = related_tags(input);

            foreach (var id in ids) {
                yield body.exec(Data.Let.build(dest, new Data.Literal(id), ctx), output);
            }
            if (ids.size == 0) empty.exec(ctx, output);
        }
    }
}
