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
/** This trait allows internal pages to mutate the database.

Sure they can mutate the database using a {% query %} tag, but that would ruin
    the idempotency of requests (thereby messing tab history) and
    this allows for more clear and succinct code. */
namespace Odysseus.Database {
    public void setup_pseudorest(WebTab tab) {
        var web = tab.web;
        web.submit_form.connect((form) => {
            if (!web.uri.has_prefix("odysseus:")) return; // It's not meant for us.

            /* FIXME This is deprecated, but the alternative isn't accessible
                on the currently released version of WebKit. */
            GenericArray<string> keys;
            GenericArray<string> values;
            if (!form.list_text_fields(out keys, out values)) return;

            var builder = new StringBuilder();

            builder.append("(");

            // Build up attr list (assume pages are trusted).
            var table_index = -1;
            var first = true;
            for (var i = 0; i < keys.length; i++) {
                if (keys[i] == "$") {table_index = i;first = true;}
                else {
                    if (!first) builder.append(", ");
                    else first = false;

                    builder.append(keys[i]);
                }
            }
            if (table_index == -1) return; // It's not meant for us.

            builder.append(") VALUES (");

            // Now value list (this isn't trusted)
            var table_name = "";
            first = true;
            for (var i = 0; i < values.length; i++) {
                if (i == table_index) {
                    table_name = values[i];
                    first = true; // Don't double up on seperators
                } else {
                    if (!first) builder.append(", ");
                    else first = false;

                    builder.append("'");
                    builder.append(values[i].replace("'", "''"));
                    builder.append("'");
                }
            }

            builder.append(");");

            // Start the statement.
            builder.prepend(table_name);
            builder.prepend("INSERT OR REPLACE INTO ");

            // Now execute what we've built up.
            string msg;
            var err = get_database().exec(builder.str, null, out msg);

            if (err != Sqlite.OK) {
                var data = new Templating.Data.Mapping();
                data["error"] = new Templating.Data.Literal(msg);
                data["sql"] = new Templating.Data.Literal(builder.str);
                Services.render_alternate_html.begin(tab, "INVALID-FORM", null, true, data);
            } else {
                web.reload(); // So we can see the changes.
            }
        });
    }
}
