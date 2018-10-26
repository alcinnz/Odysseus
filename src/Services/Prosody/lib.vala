/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017-2018).
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

/* Standard "tags" and "filters" to use in templates.
    Beware that these may differ subtly from Django's implementation. */
namespace Odysseus.Templating.Std {
    public Gee.Map<Slice, Variable> parse_params(WordIter args) throws SyntaxError {
        var parameters = new Gee.HashMap<Slice, Variable>();
        var count = 0;
        foreach (var arg in args) {
            var parts = smart_split(arg, "=");
            var key = parts.next();
            var val = parts.next_value();
            parts.assert_end();

            if (val == null) {
                val = key;
                key = new Slice.s("$%i".printf(count++));
            }

            parameters[key] = new Variable(val);
        }
        return parameters;
    }

    private class AutoescapeBuilder : TagBuilder, Object {
        public Gee.Map<Slice,Gee.Map<uint8,string>> modes =
                new Gee.HashMap<Slice, Gee.Map<uint8,string>>();

        public new void set(string key, Gee.Map<uint8, string> val) {
            modes[new Slice.s(key)] = val;
        }
        public new Gee.Map<uint8, string> get(Slice key) {return modes[key];}

        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var mode = args.next();
            args.assert_end();
            if (!modes.has_key(mode)) throw new SyntaxError.INVALID_ARGS(
                    @"Invalid {%% autoescape %%} mode: '$mode`");

            var prev = parser.escapes;
            parser.escapes = modes[mode];
            this["end"] = prev;

            return null;
        }
    }

    private class DebugBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            args.assert_end();
            return new DebugTag();
        }
    }
    private class DebugTag : Template {
        public override async void exec(Data.Data ctx, Writer output) {
            yield output.writes("<dl>");
            foreach (var e in ctx.to_array()) {
                yield output.writes("<dt>");
                yield output.write(e.key);
                yield output.writes("</dt>");
                yield output.writes(@"<dd>$(e.val)</dd>\n");
            }
            yield output.writes("</dl>");
        }
    }

    private class FilterBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var filter_tail = args.next();
            args.assert_end();
            var variable = new Variable(new Slice.s(@"_|$filter_tail"));

            WordIter? endtoken;
            var body = parser.parse("endfilter", out endtoken);
            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS(
                        "{%% filter %%} must be closed with a {%% endfilter %%} tag");

            return new FilterTag(variable, body);
        }
    }
    private class FilterTag : Template {
        private Variable filter;
        private Template body;
        public FilterTag(Variable filter, Template body) {
            this.filter = filter;
            this.body = body;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var capture = new CaptureWriter();
            yield body.exec(ctx, capture);
            var text = capture.grab_data();

            yield filter.exec(Data.Let.builds("_", new Data.Substr(text)), output);
        }
    }

    private class ForBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var targetvar = args.next();
            var sep = args.next();
            var keyvar = new Slice();
            if (!("in" in sep)) {
                keyvar = targetvar;
                targetvar = sep;
                sep = args.next();
            }
            if (!("in" in sep))
                throw new SyntaxError.INVALID_ARGS("{%% for %%} expects the second to last " +
                        @"template argument to be 'in', got '$sep'");

            var collection = new Variable(args.next());
            args.assert_end();

            WordIter? endtoken;
            var body = parser.parse("endfor empty", out endtoken);
            var endtag = endtoken.next();

            Template empty_block = new Echo();
            if ("empty" in endtag) {
                endtoken.assert_end();

                empty_block = parser.parse("endfor", out endtoken);
                endtag = endtoken.next();
            }

            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS(
                        "{%% for %%} must be closed with a {%% endfor %%} tag");
            endtoken.assert_end();
            return new ForTag(keyvar, targetvar, collection, body, empty_block);
        }
    }
    private class ForTag : Template {
        private Slice keyvar;
        private Slice valuevar;
        private Variable collection;
        private Template body;
        private Template empty_block;
        public ForTag(Slice keyvar, Slice valuevar, Variable collection,
                Template body, Template empty_block) {
            this.keyvar = keyvar;
            this.valuevar = valuevar;
            this.collection = collection;
            this.body = body;
            this.empty_block = empty_block;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var isempty = true;

            foreach (var e in collection.eval(ctx).to_array()) {
                isempty = false;
                // NOTE: valuevar is defined in the outermost context for a minor performance gain.
                var local_ctx = Data.Let.build(keyvar, new Data.Substr(e.key), ctx);
                yield body.exec(Data.Let.build(valuevar, e.val, local_ctx), output);
            }

            if (isempty) yield empty_block.exec(ctx, output);
        }
    }

    private class IfBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var expression = new Expression.Parser(args).expression();
            args.assert_end();

            WordIter? endtoken;
            var true_branch = parser.parse("elif else endif", out endtoken);
            var end_tag = endtoken.next();

            Template false_branch = new Echo();
            if ("elif" in end_tag) {
                false_branch = build(parser, endtoken);
            } else if ("else" in end_tag) {
                endtoken.assert_end();

                false_branch = parser.parse("endif", out endtoken);
                end_tag = endtoken.next();
            }

            if (!("endif" in end_tag || "elif" in end_tag))
                throw new SyntaxError.UNBALANCED_TAGS(
                        "{%% if %%} must be closed with a {%% endif %%}");
            if ("endif" in end_tag) endtoken.assert_end();

            return new IfTag(expression, true_branch, false_branch);
        }
    }
    private class IfTag : Template {
        private Expression.Expression expression;
        private Template true_branch;
        private Template false_branch;
        public IfTag(Expression.Expression exp, Template yes, Template no) {
            this.expression = exp;
            this.true_branch = yes;
            this.false_branch = no;
        }

        public override async void exec(Data.Data ctx, Writer stream) {
            if (expression.eval(ctx)) yield this.true_branch.exec(ctx, stream);
            else yield this.false_branch.exec(ctx, stream);
        }
    }

    private class IfChangedBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var variables = new Gee.ArrayList<Variable>();
            foreach (var arg in args) variables.add(new Variable(arg));

            WordIter? endtoken;
            var true_branch = parser.parse("endif else", out endtoken);
            var endtag = endtoken.next();

            Template false_branch = new Echo();
            if ("else" in endtag) {
                endtoken.assert_end();
                false_branch = parser.parse("endif", out endtoken);
                endtag = endtoken.next();
            }

            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS(
                        "{%% ifchanged %%} must be closed with an {%% endif %%} tag.");
            endtoken.assert_end();

            return new IfChangedTag(variables.to_array(), true_branch, false_branch);
        }
    }
    private class IfChangedTag : Template {
        private Variable[] test_vars;
        private Template ifchanged;
        private Template ifunchanged;
        public IfChangedTag(Variable[] vars,
                Template true_branch, Template false_branch) {
            this.test_vars = vars;
            this.ifchanged = true_branch;
            this.ifunchanged = false_branch;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            Gee.List<string> last_values;
            var changed = setup_context(output, out last_values);

            for (var i = 0; i < test_vars.length; i++) {
                var val = test_vars[i].eval(ctx).to_string();
                if (val == last_values[i]) continue;

                changed = true;
                last_values[i] = val;
            }

            yield (changed ? ifchanged : ifunchanged).exec(ctx, output);
        }

        // This cleans up some rendering artifacts.

        // It ensures each template instance (identified by a Writer) has it's
        // own context, so they don't interfere with each other's rendering.
        // Django found this much easier to do in dynamically typed Python,

        // Though template rendering is fast enough this isn't really a problem.
        private IfChangedContext? contexts = null;
        public bool setup_context(Object id, out Gee.List<string> values) {
            var int_id = (int) id;
            IfChangedContext? prev = null;
            for (var entry = contexts; entry != null; prev = entry, entry = entry.next) {
                if (((int) entry.key) == int_id) {values = entry.values; return false;}
                if (entry.key == null) {
                    if (prev == null) contexts = entry.next;
                    else prev.next = entry.next;
                }
            }

            values = new Gee.ArrayList<string>.wrap(new string[test_vars.length]);
            this.contexts = new IfChangedContext() {
                key = id, values = values, next = contexts
            };
            return true;
        }
    }
    private class IfChangedContext {
        public weak Object key; public Gee.List<string> values;
        public IfChangedContext? next;
    }

    private class IncludeBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var variables = new Gee.ArrayList<Variable>();
            foreach (var arg in args) variables.add(new Variable(arg));

            return new IncludeTag(variables.to_array(), parser.path);
        }
    }
    private class IncludeTag : Template {
        private Variable[] vars;
        private string @base;
        public IncludeTag(Variable[] vars, string @base) {
            this.vars = vars; this.@base = @base;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            // 1. Resolve path
            var relative = new StringBuilder();
            foreach (var variable in vars) relative.append(variable.eval(ctx).to_string());
            var basepath = File.new_for_path(this.@base).get_parent();
            var absolute = basepath.resolve_relative_path(relative.str);

            // 2. Render that template. This benefits heavily from caching.
            ErrorData? error_data = null;
            try {
                yield get_for_resource(absolute.get_path(), ref error_data)
                        .exec(ctx, output);
            } catch (Error err) {
                yield output.writes(@"<p style='color: red;'>$(err.message)</p>");
            }
        }
    }

    /* This isn't tested, as it's intentionally non-determinate */
    private class RandomBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var alts = new Gee.ArrayList<Template>();
            WordIter endtoken = args;
            do {
                endtoken.assert_end();
                alts.add(parser.parse("alt endrandom", out endtoken));
            } while ("alt" in endtoken.next());
            endtoken.assert_end();

            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS("{%% random %%} must be closed with a {%% endrandom %%}");

            return new RandomTag(alts.to_array());
        }
    }
    private class RandomTag : Template {
        private Template[] alts;
        public RandomTag(Template[] alts) {this.alts = alts;}

        public override async void exec(Data.Data ctx, Writer output) {
            yield alts[Random.int_range(0, alts.length)].exec(ctx, output);
        }
    }

    private class TemplateTagBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var variant = args.next();
            args.assert_end();

            switch (@"$variant") {
            case "openblock": return new Echo(new Slice.s("{%"));
            case "closeblock": return new Echo(new Slice.s("%}"));
            case "openvariable": return new Echo(new Slice.s("{{"));
            case "closevariable": return new Echo(new Slice.s("}}"));
            case "openbrace": return new Echo(new Slice.s("{"));
            case "closebrace": return new Echo(new Slice.s("}"));
            case "opencomment": return new Echo(new Slice.s("{#"));
            case "closecomment": return new Echo(new Slice.s("#}"));
            default: throw new SyntaxError.INVALID_ARGS(
                    @"Expected '(open|close)(block|variable|brace|comment)' got '$variant'!");
            }
        }
    }

    private class WithBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var parameters = parse_params(args);

            WordIter? endtoken;
            var body = parser.parse("endwith", out endtoken);

            return new WithTag(parameters, body);
        }
    }
    private class WithTag : Template {
        // These fields are public to allow for external code to inline them.
        public Gee.Map<Slice,Variable> vars;
        public Template body;
        public WithTag(Gee.Map<Slice,Variable> variables, Template bodyblock) {
            this.vars = variables;
            this.body = bodyblock;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            yield body.exec(new Data.Lazy(vars, ctx), output);
        }
    }



    private class AddFilter : Filter {
        public override Data.Data filter(Data.Data a, Data.Data b) {
            return new Data.Literal(a.to_double() + b.to_double());
        }
    }

    /** This filter is mostly used with CSS hsl() to allocate colours for
        visualization-type interfaces.

    It takes a number to represent as a colour, which should be roughly
        evenly spaced out over the range for optimal clarity.
    But to be effective, the filtered numbers should be kept as small as
        possible, this just deterministically lays them out. */
    private class AllocateFilter : Filter {
        public override Data.Data filter(Data.Data a, Data.Data b) {
            var x = (uint) a.to_int();
            var max = (uint) b.to_int();

            /* This works by having each bit subdivide the available space
                so that 0 means it's on the lower half of the current region,
                and 1 means it's on the upper half.

            Classic divide-and-conquer. */
            var ret = 0u;
            while (x != 0) {
                max >>= 1;
                if ((x & 1) == 1) ret += max;
                x >>= 1;
            }
            return new Data.Literal((int) ret);
        }
    }

    private class BaseFilter : Filter {
        public override Data.Data filter(Data.Data relative, Data.Data _base) {
            var normalized = new Soup.URI.with_base(new Soup.URI(@"$_base"), @"$relative");
            return new Data.Literal(normalized.to_string(false));
        }
    }

    private class CapFirstFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            var text = a.to_string();
            int index = 0;
            unichar c;
            text.get_next_char(ref index, out c);
            return new Data.Literal(@"$(c.toupper())$(text.substring(index))");
        }
    }

    private class CutFilter : Filter {
        public override Data.Data filter(Data.Data a, Data.Data b) {
            var A = @"$a"; var B = @"$b";
            return new Data.Literal(A.replace(B, ""));
        }
    }

    private class DateFilter : Filter {
        public override Data.Data filter(Data.Data date, Data.Data format) {
            var datetime = new DateTime.from_unix_local(date.to_int());
            var format_str = @"$format";
            if (format_str == "")
                format_str = Granite.DateTime.get_default_date_format(false, true, true) +
                        " " + Granite.DateTime.get_default_time_format();
            var ret = datetime.format(format_str);
            return new Data.Literal(ret);
        }
    }

    private class DefaultFilter : Filter {
        public override Data.Data filter(Data.Data main, Data.Data @default) {
            if (main.exists) return main;
            else return @default;
        }
    }

    private class EscapeFilter : Filter {
        public override bool? should_escape() {return true;}
    }

    private class EscapeURIFilter : Filter {
        public override bool? should_escape() {return false;}
        public override Data.Data filter0(Data.Data a) {
            return new Data.Literal(Soup.URI.encode(a.to_string(), "#?&=/"));
        }
    }

    private class FileSizeFormatFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            return new Data.Literal(format_size(a.to_int()));
        }
    }

    private class FilterFilter : Filter {
        public override Data.Data filter(Data.Data items, Data.Data condition) {
            var lexed = smart_split(condition.to_bytes(), " \t");
            Expression.Expression cond;
            try {
                cond = new Expression.Parser(lexed).expression();
            } catch (SyntaxError err) {
                return items;
            }
            var ret = new Gee.ArrayList<Data.Data>();

            items.@foreach_map((_, item) => {
                if (cond.eval(item)) ret.add(item);
                return false;
            });
            return new Data.List(ret);
        }
    }

    private class FirstFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            Data.Data ret = new Data.Empty();
            a.foreach_map((key, val) => {ret = val; return true;});
            return ret;
        }
    }

    private class ForceEscape : Filter {
        public AutoescapeBuilder modes;
        public override bool? should_escape() {return false;}

        public override Data.Data filter(Data.Data a, Data.Data mode) {
            var loop = new MainLoop();
            AsyncResult? result = null;
            escape.begin(a.to_bytes(), modes[mode.to_bytes()], (obj, res) => {
                result = res;
                loop.quit();
            });
            loop.run();
            return new Data.Substr(escape.end(result));
        }

        private async Slice escape(Slice text, Gee.Map<uint8,string> escapes) {
            var capture = new CaptureWriter();
            yield capture.escaped(text, escapes);
            return capture.grab_data();
        }
    }

    private class JoinFilter : Filter {
        public override Data.Data filter(Data.Data list, Data.Data sep) {
            var sep_str = sep.to_string();
            var builder = new StringBuilder();
            var first = true;
            list.foreach_map((key, val) => {
                if (!first) builder.append(sep_str);
                else first = false;
                builder.append(val.to_string());
                return false; // AKA continue;
            });
            return new Data.Literal(builder.str);
        }
    }

    private class LastFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            // This is more inneficient than is often needed,
            //     but avoids complicating the datamodel further.
            Data.Data ret = new Data.Empty();
            a.foreach_map((key, val) => {ret = val; return false;});
            return ret;
        }
    }

    private class LengthFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            bool is_length;
            int ret = a.to_int(out is_length);

            if (!is_length) {
                ret = 0;
                a.foreach_map((key, val) => {ret++; return false;});
            }
            return new Data.Literal(ret);
        }
    }

    private class LengthIsFilter : Filter {
        private LengthFilter length_filter = new LengthFilter();

        public override Data.Data filter(Data.Data a, Data.Data b) {
            var length = length_filter.filter0(a);
            return new Data.Literal(length.to_int() == b.to_int());
        }
    }

    private class LookupFilter : Filter {
        public override Data.Data filter(Data.Data a, Data.Data items) {
            var ret = new Gee.ArrayList<Data.Data>();
            foreach (var item in @"$items".split(" "))
                a.lookup(item, (d) => ret.add(d));
            return new Data.List(ret);
        }
    }

    private class LowerFilter : Filter {
        public override Data.Data filter0(Data.Data text) {
            return new Data.Literal(@"$text".down());
        }
    }

    private class MD5Filter : Filter {
        public override Data.Data filter0(Data.Data text) {
            var ret = Checksum.compute_for_bytes(ChecksumType.MD5, text.to_bytes()._);
            return new Data.Literal(ret);
        }
    }

    private class SafeFilter : Filter {
        public override bool? should_escape() {return false;}
    }

    private class SplitFilter : Filter {
        public override Data.Data filter(Data.Data text, Data.Data sep) {
            var texts = @"$text".split(@"$sep");

            var ret = new Data.Data[texts.length];
            for (var i = 0; i < texts.length; i++)
                ret[i] = new Data.Literal(texts[i]);
            return new Data.List.from_array(ret);
        }
    }

    /* Explicit coercion potentially useful for working with SQL results or query params. */
    private class TextFilter : Filter {
        public override Data.Data filter(Data.Data text, Data.Data arg) {
            Slice ret;
            var safe = text.show(@"$arg", out ret);
            return new Data.Substr(ret, safe);
        }
    }

    private class TitleFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            var builder = new StringBuilder();
            var text = a.to_string();
            int index = 0;
            unichar c;
            bool capitalize = true;

            while (text.get_next_char(ref index, out c)) {
                if (capitalize) {
                    c = c.totitle();
                    capitalize = false;
                } else {
                    c = c.tolower();
                    capitalize = c.isspace();
                }
                builder.append_unichar(c);
            }

            return new Data.Literal(builder.str);
        }
    }

    private class UniqSortFilter : Filter {
        public override Data.Data filter0(Data.Data a) {
            var strings = a.items();
            var ret = new Data.Data[strings.size];

            var i = 0;
            foreach (var item in strings) ret[i++] = new Data.Literal(item);

            return new Data.List.from_array(ret);
        }
    }




    public void register_standard_library() {
        var escapes = new AutoescapeBuilder();
        register_tag("appstream", new xAppStream.AppStreamBuilder());
        register_tag("autoescape", escapes);
        register_tag("debug", new DebugBuilder());
		register_tag("fetch", new xHTTP.FetchBuilder());
        register_tag("filter", new FilterBuilder());
        register_tag("for", new ForBuilder());
        register_tag("if", new IfBuilder());
        register_tag("ifchanged", new IfChangedBuilder());
        register_tag("include", new IncludeBuilder());
        register_tag("mimeinfo", new xMIMEInfo.MIMEInfoBuilder());
        register_tag("random", new RandomBuilder());
        register_tag("templatetag", new TemplateTagBuilder());
        register_tag("test", new xTestRunner.TestBuilder());
        register_tag("test-report", new xTestRunner.TestReportBuilder());
        register_tag("trans", new xI18n.TransBuilder());
        register_tag("with", new WithBuilder());

        register_filter("add", new AddFilter());
        register_filter("alloc", new AllocateFilter());
        register_filter("base", new BaseFilter());
        register_filter("capfirst", new CapFirstFilter());
        register_filter("cut", new CutFilter());
        register_filter("date", new DateFilter());
        register_filter("default", new DefaultFilter());
        register_filter("diff", new xTestRunner.DiffFilter());
        register_filter("escape", new EscapeFilter());
        register_filter("escapeURI", new EscapeURIFilter());
        register_filter("favicon", new x.FaviconFilter());
        register_filter("filesize", new FileSizeFormatFilter());
        register_filter("filter", new FilterFilter());
        register_filter("first", new FirstFilter());
        register_filter("force-escape", new ForceEscape() {modes = escapes});
        register_filter("join", new JoinFilter());
        register_filter("last", new LastFilter());
        register_filter("length", new LengthFilter());
        register_filter("lengthis", new LengthIsFilter());
        register_filter("lookup", new LookupFilter());
        register_filter("lower", new LowerFilter());
        register_filter("md5", new MD5Filter());
        register_filter("mimeicon", new xMIMEInfo.MIMEIconFilter());
        register_filter("safe", new SafeFilter());
        register_filter("split", new SplitFilter());
        register_filter("text", new TextFilter());
        register_filter("title", new TitleFilter());
        register_filter("trans", new xI18n.TransFilter());
        register_filter("uniqsort", new UniqSortFilter());

        escapes["off"] = Gee.Map.empty<char,string>();
        escapes["html"] = Writer.html();
        escapes["html-lines"] = Writer.build_escapes("<>&'\"\n",
                "&lt;", "&gt;", "&amp;", "&apos;", "&quot;", "<br />");
        escapes["csv"] = Writer.build_escapes("'\"", "\\'", "\\\"");
        // These escape codes taken from Django
        // https://github.com/django/django/blob/9718fa2e8abe430c3526a9278dd976443d4ae3c6/django/utils/html.py#L51
        var escape_js_string = Writer.build_escapes("\\\"><&=-;\x2028\x2029'",
                "\\u005C", "\\u0022", "\\u003E", "\\u003C", "\\u0026",
                "\\u003D", "\\u002D", "\\u003B", "\\u2028", "\\u2029");
        // Escape every ASCII character with a value less than 32.
        escape_js_string['\''] = "\\u0027";
        for (char z = 0; z < 32; z++)
            escape_js_string[z] = "\\u%04X".printf(z);
        escapes["js-string"] = escape_js_string;
        var escape_uri = new Gee.HashMap<uint8, string>();
        escape_uri[0] = "escapeURI"; // Ugly hack to call better maintained logic.
        escapes["uri"] = escape_uri;
        escapes["url"] = escape_uri;
    }
}
