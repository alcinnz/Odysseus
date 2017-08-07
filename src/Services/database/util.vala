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
/** Wraps the SQLite library in functions that are my vala-y */
namespace Odysseus.Database {
    /* Adjusts interface to Sqlite.Database.prepare_v2 so that:
        1. It takes a string, not a string slice.
        2. Incorporates error reporting/crashing.
        3. Returns the statement, instead of writing it to an out param. */
    public Sqlite.Statement parse(string sql) {
        Sqlite.Statement stmt;
        var err = get_database().prepare_v2(sql, sql.length, out stmt);
        if (err != Sqlite.OK) error("Failed to parse: %s", sql);
        return stmt;
    }

    public struct QueryIterator {
        public unowned Sqlite.Statement stmt;
        public Gee.Map<string, unowned Sqlite.Value>? next() {
            if (stmt.step() != Sqlite.OK) {
                stmt.reset();
                return null;
            }

            var ret = new Gee.HashMap<string, unowned Sqlite.Value>();
            var n_columns = stmt.column_count();
            for (var i = 0; i < n_columns; i++) {
                ret[stmt.column_name(i)] = stmt.column_value(i);
            }
            return ret;
        }
    }
    public QueryIterator query(Sqlite.Statement stmt) {
        return QueryIterator() {stmt = stmt};
    }
}
