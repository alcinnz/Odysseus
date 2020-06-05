/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2018,2020).
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
/** Makes it trivial to write autocompletors as database queries. */
namespace Odysseus.Services {
    public abstract class CompleterQuery : Tokenized.CompleterDelegate {
        private Sqlite.Statement compiled;
        public abstract string sql();

        construct {
            if (Database.get_database().prepare_v2(sql(), -1, out compiled) != Sqlite.OK) {
                warning("Failed to initialize an autocompleter!\nThe addressbar will not be fully functional.");
                compiled = null;
            }
        }

        public override void autocomplete(string query, Tokenized.Completer c) {
            // These completers will generally be unhelpful in this case
            if (query == "") return;

            compiled.reset();
            compiled.bind_text(1, query);

            while (compiled.step() == Sqlite.ROW) {
                c.suggestion(compiled.column_text(1), compiled.column_text(0));
            }
        }
    }
}
