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
/** Helps out when surfers attempt to revisit a webpage. */
namespace Odysseus.Traits {
    public class HistoryAutocompleter : Services.CompleterQuery {
        public override string sql() {
            return """SELECT title, uri FROM page_visit WHERE INSTR(uri, ?)
                    ORDER BY length(uri) ASC, visited_at DESC LIMIT 1;""";
        }
    }
}
