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

/** Custom Natural Language Support routines.

This module sacrifices the availability of pretty tools to solicit contributions,
in order to gain better performance and fewer SEGFAULTs.

Essentially it parses the translation catalogs as a template with a custom tag
called "{% msg %}". This data can then be incorporated into other templates via
the "{% trans %}" tag.

When integrated with GitHub via templates this data can also be used to help
readers to improve the text they see. */
namespace Odysseus.Templating.I18n {
    private Bytes b(string s) {return ByteUtils.from_string(s);}

    private Expression.Expression plural_form;
    private Bytes catalogue_file;
    private Gee.Map<Bytes, int>? catalogue;
    // This second map is used both to cache lookups
    // and to capture which strings most need translations
    private Cache? cache;
    public void load_catalogue() {
        catalogue = ByteUtils.create_map<int>();
        cache = Cache();

        foreach (var language in Intl.get_language_names()) {
            try {
                uint8[] source;
                var SEP = Path.DIR_SEPARATOR_S;
                FileUtils.get_data(SEP + Path.build_path(SEP, "usr", "share",
                                "Odysseus", "l10n", language),
                        out source);
                catalogue_file = new Bytes(source);
                var parser = new Parser(catalogue_file);
                parser.local_tag_lib[b("plurals")] = new PluralsBuilder();
                parser.local_tag_lib[b("msg")] = new MsgBuilder();
                parser.parse(); // Called for MsgBuilder's side effects
                return;
            } catch (SyntaxError e) {
                warning("Failed to parse catalog template: %s", e.message);
            } catch (Error e) {
                // Try the next or fallback to no translations
            }
        }
    }

    private struct CacheEntry {
        Bytes key;
        Template[] val;
    }
    private struct Cache {
        /* Implements a cache in the form of a naive,
            fixed-size hashmap without collision handling. */
        CacheEntry[] items;
        const uint CACHE_SIZE = 64;
        public Cache() {
            this.items = new CacheEntry[CACHE_SIZE];
            for (var i = 0; i < CACHE_SIZE; i++) {
                items[i] = CacheEntry() {key = null, val = new Template[0]};
            }
        }

        public void set(Bytes key, Template[] val) {
            items[key.hash() & (CACHE_SIZE-1)] = CacheEntry() {
                key = key, val = val};
        }

        public Template[]? get(Bytes key) {
            var entry = items[key.hash() & (CACHE_SIZE-1)];
            if (entry.key != null && key.compare(entry.key) == 0) {
                return entry.val;
            } else {
                return null;
            }
        }

        public async Data.Data to_data() {
            var data = ByteUtils.create_map<Data.Data>();
            for (var i = 0; i < CACHE_SIZE; i++) {
                var entry = items[i];
                if (entry.key != null) {
                    var strings_data = ByteUtils.create_map<Data.Data>();
                    for (var j = 0; j < entry.val.length; j++) {
                        var msg = entry.val[j];
                        var capture = new CaptureWriter();
                        yield msg.exec(new Data.Mapping(), capture);
                        strings_data[b("%i".printf(i++))] =
                                new Data.Substr(capture.grab_data());
                    }
                    data[entry.key] = new Data.Mapping(strings_data);
                }
            }
            return new Data.Mapping(data);
        }
    }

    private class PluralsBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            plural_form = new Expression.Parser(args).expression();
            return null;
        }
    }

    private class MsgBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var index = parser.lex.last_start;
            catalogue[Message(parser, args).key] = index;
            return null;
        }
    }
    private struct Message {
        public Bytes[] args;
        public Template[] msgs;
        public Bytes comment;
        public Bytes key;
        public Bytes plural;
        public Message(Parser parser, WordIter args) throws SyntaxError {
            this.args = args.collect();

            var msgs = new Gee.ArrayList<Template>();
            Bytes endtag = b("");
            do {
                WordIter? endtoken;
                Bytes source;
                var msg = parser.parse("msg en", out endtoken, out source);
                if (ByteUtils.strip(source).length > 0) msgs.add(msg);
                if (endtoken == null) throw new SyntaxError.UNBALANCED_TAGS("");
                endtag = endtoken.next();
            } while (ByteUtils.equals_str(endtag, "msg"));
            this.msgs = msgs.to_array();

            comment = b("");
            key = b("");
            plural = b("");
            if (ByteUtils.equals_str(endtag, "en")) {
	            // Parse comment
	            var token = parser.lex.peek();
	            if (ByteUtils.strip(token).length == 0) {
	                parser.lex.next();
	                token = parser.lex.peek();
                }
                if (token.length > 4 && token[0] == '{' && token[1] == '#') {
                    // This is a translator comment
                    // that shouldn't appear in the string
                    comment = token[2:token.length-2];
                    parser.lex.next();
                }

                WordIter? endtoken;
                key = ByteUtils.strip(parser.scan_until("plural endmsg", out endtoken));
                if (endtoken == null) throw new SyntaxError.UNBALANCED_TAGS("Expected {%% endmsg %%}");
                if (ByteUtils.equals_str(endtoken.next(), "plural")) {
                    plural = ByteUtils.strip(parser.scan_until("endmsg", out endtoken));
                    if (endtoken == null) throw new SyntaxError.UNBALANCED_TAGS("Expected {%% endmsg %%} after {%% plural %%}");
                }
            } else {
                throw new SyntaxError.UNEXPECTED_CHAR("Expected {%% en %%}");
            }
        }

        public static Message? parse_offset(int index) {
            var parser = new Parser(catalogue_file[index:catalogue_file.length]);
            try {
                WordIter open_msg;
                parser.scan_until("msg", out open_msg);
                open_msg.next();
                return Message(parser, open_msg);
            } catch (SyntaxError e) {
                warning("Syntax error in message: %s", e.message);
                return null;
            }
        }

        public async Data.Data to_data() {
            var data = ByteUtils.create_map<Data.Data>();

            var args_data = ByteUtils.create_map<Data.Data>();
            var i = 0;
            foreach (var item in args) {
                args_data[b("$%i".printf(i++))] = new Data.Substr(item);
            }
            data[b("args")] = new Data.Mapping(args_data);

            var msgs_data = ByteUtils.create_map<Data.Data>();
            i = 0;
            foreach (var msg in msgs) {
                var capture = new CaptureWriter();
                yield msg.exec(new Data.Mapping(), capture);
                msgs_data[b("$%i".printf(i++))] = new Data.Substr(capture.grab_data());
            }
            data[b("messages")] = new Data.Mapping(msgs_data);

            data[b("comment")] = new Data.Substr(comment);
            data[b("key")] = new Data.Substr(key);
            data[b("plural")] = new Data.Substr(plural);

            return new Data.Mapping(data);
        }
    }

    public class TransTagBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var parameters = Std.parse_params(args);

	        // Parse comment
	        var token = parser.lex.peek();
	        if (ByteUtils.strip(token).length == 0) {
	            parser.lex.next();
	            token = parser.lex.peek();
            }
            if (token.length > 4 && token[0] == '{' && token[1] == '#') {
                // This is a translator comment
                // that shouldn't appear in the string
                parser.lex.next();
            }

            // Parse strings
            WordIter? endtoken;
            Bytes key;
            Template plural = new Echo(new Bytes("".data));
            var fallback = parser.parse("endtrans plural", out endtoken, out key);
            key = ByteUtils.strip(key);
            if (endtoken == null) throw new SyntaxError.UNBALANCED_TAGS("Expected {%% endtrans %%}");
            if (ByteUtils.equals_str(endtoken.next(), "plural")) {
                plural = parser.parse("endtrans", out endtoken);
                if (endtoken == null) throw new SyntaxError.UNBALANCED_TAGS("Expected {%% endtrans %%} after {%% plural %%}");
            }

            return new TransTag(parameters, key, new Template[] {fallback, plural});
        }
    }
    public class TransTag : Template {
        private Gee.Map<Bytes, Variable> parameters;
        private Bytes key;
        private Template[] fallback;
        static Expression.Expression? fallback_plural_form;

        public TransTag(Gee.Map<Bytes, Variable> parameters, Bytes key, Template[] fallback) throws SyntaxError {
            this.parameters = parameters;
            this.key = key;
            this.fallback = fallback;

            if (fallback_plural_form == null) {
                var exp = smart_split(new Bytes("x != 1".data), " \t\r\n");
                fallback_plural_form = new Expression.Parser(exp).expression();
            }
        }

        public async override void exec(Data.Data ctx, Writer output) {
            if (catalogue == null) load_catalogue();

            var inner_ctx = new Data.Lazy(parameters, ctx);
            var trans = cache[key];
            var my_plural_form = plural_form;
            if (trans == null) {
                trans = Message.parse_offset(catalogue[key]).msgs;
                if (trans == null) {
                    trans = fallback;
                    my_plural_form = fallback_plural_form;
                } else {
                    cache[key] = trans;
                }
            }

            var variant = 0;
            if (parameters.has_key(b("count"))) {
                var exp_ctx = new Gee.HashMap<Bytes, Data.Data>();
                exp_ctx[b("x")] = inner_ctx[b("count")];
                my_plural_form.context = new Data.Mapping(exp_ctx);
                variant = (int) my_plural_form.eval();
            }
            yield trans[variant].exec(inner_ctx, output);
        }
    }

    // Extracts data for use in translation tools
    public async Data.Data build_translation_context() {
        var data = ByteUtils.create_map<Data.Data>();

        var catalogue_data = ByteUtils.create_map<Data.Data>();
        foreach (var entry in catalogue.entries) {
            var message = Message.parse_offset(entry.value);
            if (message != null)
                catalogue_data[entry.key] = yield message.to_data();
            else
                catalogue_data[entry.key] = new Data.Empty();
        }
        data[b("translations")] = new Data.Mapping(catalogue_data);

        data[b("progress")] = new ProgressData();
        data[b("common_strings")] = yield cache.to_data();
        return new Data.Mapping(data);
    }

    // Routines to gather progress data for the "Verbatim" homepage
    private class ProgressData : Data.Data {
        public override Data.Data get(Bytes language) {
            uint8[] source;
            var SEP = Path.DIR_SEPARATOR_S;
            try {
                FileUtils.get_data(SEP + Path.build_path(SEP, "usr", "share",
                                "Odysseus", "l10n", language),
                        out source);
                catalogue_file = new Bytes(source);
                var parser = new Parser(catalogue_file);
                parser.local_tag_lib[b("plurals")] = new IgnoreTagBuilder();
                var counter = new MsgCounter();
                parser.local_tag_lib[b("msg")] = counter;
                parser.parse(); // Called for MsgBuilder's side effects
                return counter.to_data();
            } catch (Error e) { 
                warning("Failed to parse catalogue file: %s", e.message);
                return new Data.Empty();
            }
        }

        public override void @foreach(Data.Data.Foreach cb) {
            try {
                var SEP = Path.DIR_SEPARATOR_S;
                var catalogue = File.new_for_path(SEP + Path.build_path(SEP,
                        "usr", "share", "Odysseus", "l10n"));
                var enumerator = catalogue.enumerate_children("standard::*",
                        FileQueryInfoFlags.NONE);
                FileInfo info;
                while ((info = enumerator.next_file()) != null) {
                    if (info.get_name() == "README" ||
                            info.get_name().has_suffix(".unused")) continue;
                    cb(b(info.get_name()));
                }
            } catch (Error e) {
                warning("Failed to list catalogue files: %s", e.message);
            }
        }
    }

    private class IgnoreTagBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            /* Don't do anything */
            return null;
        }
    }

    private class MsgCounter : TagBuilder, Object {
        private int quantity;
        private int translated;
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            quantity++;
            var msg = Message(parser, args);
            if (msg.msgs.length > 0) translated++;
            return null;
        }

        public Data.Data to_data() {
            var data = ByteUtils.create_map<Data.Data>();
            data[b("total")] = new Data.Literal(quantity);
            data[b("translated")] = new Data.Literal(translated);
            return new Data.Mapping(data);
        }
    }
}
