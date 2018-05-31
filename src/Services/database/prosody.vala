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
            var limit_arg = args.next_value();
            var limit = -1;
            if (limit_arg != null) limit = int.parse(@"$limit_arg");
            args.assert_end();

            WordIter endtoken;
            var queryParams = new Gee.ArrayList<Variable>();
            var query = compile_block(parser.parse("except each-row empty endquery", out endtoken), queryParams);
            var endtag = endtoken.next();

            var exceptParams = new Gee.ArrayList<Variable>();
            var exceptQuery = "";
            if ("except" in endtag) {
                exceptQuery = compile_block(parser.parse("each-row empty endquery", out endtoken), exceptParams);
                endtag = endtoken.next();
            }

            Template loop_body = new Echo();
            if ("each-row" in endtag) {
                endtoken.assert_end();

                loop_body = parser.parse("endquery empty", out endtoken);
                endtag = endtoken.next();
            }

            Template emptyblock = new Echo();
            if ("empty" in endtag) {
                endtoken.assert_end();

                emptyblock = parser.parse("endquery", out endtoken);
            }

            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS("{%% query %%} must be balanced with an {%% endquery %%}");

            return new QueryTag(query, queryParams, exceptQuery, exceptParams, loop_body, emptyblock, limit);
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
                return @"$((ast as Echo).text)";
            } else if (ast is Std.WithTag) {
                var with = ast as Std.WithTag;

                var innerParams = new Gee.ArrayList<Variable>();
                var txt = compile_block(with.body, innerParams);

                foreach (var param in innerParams)
                    queryParams.add(param.inlineCtx(with.vars));

                return txt;
            } else
                throw new SyntaxError.OTHER("This tag is unsupported in combination with SQL!");
        }
    }

    private class MultiStatement {
        /* This is a linked-list of Sqlite Statements that works with their memory management. */
        public Sqlite.Statement query;
        public Gee.List<Variable> parameters;
        public MultiStatement? next;

        public MultiStatement(Sqlite.Database db, string sql, Gee.List<Variable> parameters) throws SyntaxError {
            string tail;
            var err = db.prepare_v2(sql, sql.length, out this.query, out tail);
            if (err != Sqlite.OK)
                throw new SyntaxError.OTHER("Invalid query (%s) %d: %s", sql, db.errcode(), db.errmsg());

            this.parameters = parameters[0:this.query.bind_parameter_count()];

            var tailParams = parameters[this.query.bind_parameter_count():parameters.size];
            this.next = tail.chug() == "" ? null : new MultiStatement(db, tail, tailParams);
        }

        public void bind(Data.Data ctx) {
            query.reset();

            int ix = 1;
            foreach (var param in parameters) {
                query.bind_text(ix, param.eval(ctx).to_string());
                ix++;
            }
        }
    }

    private class QueryTag : Template {
        private MultiStatement query;
        private MultiStatement except;
        private Template loopBody;
        private Template emptyblock;
        private int limit;

        public QueryTag(string query, Gee.List<Variable> qParams, string qExcept, Gee.List<Variable> exceptParams,
                    Template loopBody, Template emptyblock, int limit = -1) throws SyntaxError {
            unowned Sqlite.Database db = get_database();
            this.query = new MultiStatement(db, query, qParams);
            this.except = qExcept.chug() == "" ? null :
                    new MultiStatement(db, qExcept, exceptParams);
            this.loopBody = loopBody;
            this.emptyblock = emptyblock;
            this.limit = limit;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var count = 0;
            var err = Sqlite.OK;
            for (var iter = this.query; iter != null; iter = iter.next) {
                unowned Sqlite.Statement query = iter.query;
                iter.bind(ctx);

                while ((err = query.step()) == Sqlite.ROW) {
                    var loopParams = new Data.Stack(new DataSQLiteRow(query), ctx);

                    // Mostly just useful for odysseus:home's topsites.
                    var skip = false;
                    for (var except = this.except; except != null; except = except.next) {
                        except.bind(loopParams);
                        if (except.query.step() == Sqlite.ROW) continue;
                        skip = true;
                        break;
                    }
                    if (skip) continue;

                    yield loopBody.exec(loopParams, output);

                    count++;
                    if (count == this.limit) return;
                }

                if (err != Sqlite.OK && err != Sqlite.DONE) break;
            }

            if (err != Sqlite.OK && err != Sqlite.DONE) {
                // NOTE: If this yields messy markup, WebKit should be able to correct it.
                yield output.writes("<h1 style='color: red;'><img src=gtk-icon:64/dialog-error />");
                yield output.writes(get_database().errmsg());
                yield output.writes("</h1>");
            } else if (count == 0) yield emptyblock.exec(ctx, output);
        }
    }

    private class DataSQLiteRow : Data.Data {
        private unowned Sqlite.Statement query;
        public DataSQLiteRow(Sqlite.Statement q) {this.query = q;}
        public override void foreach_map(Data.Data.ForeachMap cb) {
            for (var i = 0; i < query.column_count(); i++) {
                var key = new Slice.s(query.column_name(i));
                var val = new DataSQLite(query.column_value(i));
                if (cb(key, val)) break;
            }
        }
    }

    private class DataSQLite : Data.Data {
        private unowned Sqlite.Value val;
        public DataSQLite(Sqlite.Value val) {this.val = val;}
        public override Data.Data get(Slice _) {return new Data.Empty();}
        public override string to_string() {return val.to_text();}
        public override void foreach_map(Data.Data.ForeachMap cb) {
            for (var i = 0; i < val.to_int(); i++)
                if (cb(new Slice(), new Data.Literal(i))) break;
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

    /** A tag for defining (non-recursive and indepent) abstractions.as new tags.
        Designed to work well with the {% ifchanged %} and {% query %} tags.

    Works by inlining the body text elsewhere in the template. */
    private class MacroMetaBuilder : TagBuilder, Object {
        // Inlining the source code naturally works with {% ifchanged %} because
        // that yields new instances of said tag
        // which track their own previous values.

        // It works well for {% query %} as it keeps the AST nice and simple
        // for it's compilation into a SQLite statement.
        // Though it *does* require it to handle {% with %}.
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var name = args.next();
            if (tag_lib.has_key(name) || parser.local_tag_lib.has_key(name))
                throw new SyntaxError.INVALID_ARGS(@"{%% $name %%} already exists!");
            // Don't assert end, so templates can indicate which args they expect.

            WordIter endtoken;
            Slice body;
            // parse() does a better job reporting errors than scan_until().
            parser.parse("endmacro", out endtoken, out body);
            if (endtoken == null) throw new SyntaxError.UNBALANCED_TAGS("Missing {%% endmacro %%}!");

            parser.local_tag_lib[name] = new MacroBuilder(body.strip(), parser.local_tag_lib);
            return null;
        }
    }
    private class MacroBuilder : TagBuilder, Object {
        private Slice source;
        private Gee.Map<Slice, TagBuilder> lib;
        public MacroBuilder(Slice source, Gee.Map<Slice, TagBuilder> lib) {
            this.source = source; this.lib = lib;
        }

        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var innerParser = new Parser(source);
            innerParser.local_tag_lib = lib;
            return new Std.WithTag(Std.parse_params(args), innerParser.parse());
        }
    }

    public void register_query_tags() {
        register_tag("query", new QueryBuilder());
        register_tag("macro", new MacroMetaBuilder());
    }
}
