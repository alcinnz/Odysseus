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
            WordIter each_tag;
            var queryParams = new Gee.ArrayList<Variable>();
            var query = compile_block(parser.parse("each-row", out each_tag), queryParams);

            if (each_tag == null)
                throw new SyntaxError.UNBALANCED_TAGS("Missing {%% each-row %%} within {%% query %%}");
            each_tag.next();each_tag.assert_end();

            WordIter endtoken;
            var loop_body = parser.parse("endquery", out endtoken);
            if (endtoken == null || !ByteUtils.equals_str(endtoken.next(), "endquery"))
                throw new SyntaxError.UNBALANCED_TAGS("{%% query %%} must be balanced with an {%% endquery %%}");
            endtoken.assert_end();

            return new QueryTag(query, queryParams, loop_body);
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

        public QueryTag(string query, Gee.List<Variable> qParams, Template loopBody) throws SyntaxError {
            unowned Sqlite.Database db = get_database();
            if (db.prepare_v2(query, query.length, out this.query) != Sqlite.OK)
                throw new SyntaxError.OTHER("Invalid query %d: %s", db.errcode(), db.errmsg());

            this.qParams = qParams;
            this.loopBody = loopBody;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            query.reset();

            int ix = 1;
            foreach (var param in qParams) {
                query.bind_text(ix, param.eval(ctx).to_string());
                ix++;
            }

            while (query.step() == Sqlite.ROW) {
                var row = new Gee.HashMap<Bytes, Data.Data>();
                var n_columns = query.column_count();
                for (var i = 0; i < n_columns; i++) {
                    row[b(query.column_name(i))] = new DataSQLite(query.column_value(i));
                }

                loopBody.exec(new Data.Stack.with_map(ctx, row), output);    
            }
        }
    }

    private class DataSQLite : Data.Data {
        private unowned Sqlite.Value val;
        public DataSQLite(Sqlite.Value val) {this.val = val;}
        public override Data.Data get(Bytes _) {return new Data.Empty();}
        public override string to_string() {return val.to_text();}
        public override void foreach_map(Data.Data.ForeachMap cb) {}
        public override int to_int(out bool is_length = null) {
            is_length = false; return val.to_int();
        }
        public override double to_double() {return val.to_double();}
    }

    public void register_query_tags() {
        register_tag("query", new QueryBuilder());
    }
}
