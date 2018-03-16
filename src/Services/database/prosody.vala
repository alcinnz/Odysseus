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
/** Syntax for querying the internal database within Prosody templates. 

This will be used to make all of the more interesting webpages. */
namespace Odysseus.Database.Prosody {
    using Templating;

    private class QueryBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            WordIter endtoken;
            var queryParams = new Gee.ArrayList<Variable>();
            var query = compile_block(parser.parse("each-row empty endquery", out endtoken), queryParams);

            Template loop_body = new Echo(b(""));
            if (ByteUtils.equals_str(endtoken.next(), "each-row")) {
                endtoken.assert_end();

                loop_body = parser.parse("endquery empty", out endtoken);
            }

            Template emptyblock = new Echo(b(""));
            if (ByteUtils.equals_str(endtoken.next(), "empty")) {
                endtoken.assert_end();

                emptyblock = parser.parse("endquery", out endtoken);
            }

            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS("{%% query %%} must be balanced with an {%% endquery %%}");

            return new QueryTag(query, queryParams, loop_body, emptyblock);
        }

        private string compile_block(Template ast, Gee.ArrayList<Variable> queryParams) throws SyntaxError {
            if (ast is Block) {
                var query = new StringBuilder();
                foreach (var child in (ast as Block).children)
                    query.append(compile_block(child, queryParams));
                return query.str;
            } else if (ast is Variable) {
                queryParams.add(ast as Variable);
                return "?";
            } else if (ast is Echo) {
                return ByteUtils.to_string((ast as Echo).text);
            } else
                throw new SyntaxError.OTHER("This tag is unsupported in combination with SQL!");
        }
    }

    private class QueryTag : Template {
        private Sqlite.Statement query;
        private Gee.List<Variable> qParams;
        private Template loopBody;
        private Template emptyblock;

        public QueryTag(string query, Gee.List<Variable> qParams, Template loopBody, Template emptyblock) throws SyntaxError {
            unowned Sqlite.Database db = get_database();
            if (db.prepare_v2(query, query.length, out this.query) != Sqlite.OK)
                throw new SyntaxError.OTHER("Invalid query %d: %s", db.errcode(), db.errmsg());

            this.qParams = qParams;
            this.loopBody = loopBody;
            this.emptyblock = emptyblock;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            query.reset();

            int ix = 1;
            foreach (var param in qParams) {
                query.bind_text(ix, param.eval(ctx).to_string());
                ix++;
            }

            var empty = true;
            int err = 0;
            while ((err = query.step()) == Sqlite.ROW) {
                var loopParams = new Data.Stack(new DataSQLiteRow(query), ctx);
                yield loopBody.exec(loopParams, output);
                empty = false;
            }

            if (err != Sqlite.OK && err != Sqlite.DONE) {
                // NOTE: If this yields messy markup, WebKit should be able to correct it.
                output.writes("<h1 style='color: red;'><img src=gtk-icon:64/dialog-error />");
                output.writes(get_database().errmsg());
                output.writes("</h1>");
            } else if (empty) yield emptyblock.exec(ctx, output);
        }
    }

    private class DataSQLiteRow : Data.Data {
        private unowned Sqlite.Statement query;
        public DataSQLiteRow(Sqlite.Statement q) {this.query = q;}
        public override void foreach_map(Data.Data.ForeachMap cb) {
            for (var i = 0; i < query.column_count(); i++) {
                var key = b(query.column_name(i));
                var val = new DataSQLite(query.column_value(i));
                if (cb(key, val))
                    break;
            }
        }
    }

    private class DataSQLite : Data.Data {
        private unowned Sqlite.Value val;
        public DataSQLite(Sqlite.Value val) {this.val = val;}
        public override Data.Data get(Bytes _) {return new Data.Empty();}
        public override string to_string() {return val.to_text();}
        public override void foreach_map(Data.Data.ForeachMap cb) {
            for (var i = 0; i < val.to_int(); i++)
                if (cb(b(""), new Data.Literal(i))) break;
        }
        public override int to_int(out bool is_length = null) {
            is_length = false;
            // Implicitly add correct datetime parsing
            var date = TimeVal();
            if (date.from_iso8601(to_string().replace(" ", "T")))
                return (int) date.tv_sec;
            return val.to_int();
        }
        public override double to_double() {return val.to_double();}
    }

    public void register_query_tags() {
        register_tag("query", new QueryBuilder());
    }
}
