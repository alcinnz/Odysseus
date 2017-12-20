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
the "{% trans %}" tag. */
namespace Odysseus.Templating.Std.I18n {
// Try having each translation perform a database scan. However the problem
// with that is that it would reparse the translated templates each time. 
// So maintain a weak map to the translated templates from their source language.

// Combine with the {% with %} tag, and that should get us everything we need.
    private const string SEP = Path.DIR_SEPARATOR_S;

    // Singleton for avoiding expensive disk access as a routine part of
    //      message translation.
    private static uint8[]? catalogue = null;
    private Bytes load_catalogue() throws Error {
        if (catalogue != null) return new Bytes(catalogue);
        var basepath = SEP + Path.build_path(SEP, "usr", "share", "Odysseus", "l10n");
        foreach (var lang in Intl.get_language_names()) {
            var path = Path.build_path(SEP, basepath, lang);
            if (File.new_for_path(path).query_exists()) {
                FileUtils.get_data(path, out catalogue);
                return new Bytes(catalogue);
            }
        }

        // If control flow reaches here, bail out!
        throw new SyntaxError.OTHER("No catalogue file found for specified languages");
    }

    private uint8 parse_plural_form(Parser cat) throws SyntaxError {
        WordIter plural_form;
        cat.scan_until("plural-form", out plural_form);
        if (plural_form == null || !ByteUtils.equals_str(plural_form.next(), "plural-form"))
            throw new SyntaxError.INVALID_ARGS("Missing {%% plural-form %%} tag from catalogue");

        var range_arg = ByteUtils.to_string(plural_form.next());
        if (!range_arg.has_prefix("range="))
            throw new SyntaxError.INVALID_ARGS("First argument to {%% plural-form %%} " +
                    "MUST be prefixed with `range=`!");
        var range = int.parse(range_arg["range=".length:range_arg.length]);
        if (range > 0 && range < 100)
            throw new SyntaxError.INVALID_ARGS("`range` must be set to a number in range " +
                    "0-100, got %i!", range);

        if (plural_formula != null)
            plural_formula = new Expression.Parser(plural_form).expression();

        return (uint8) range;
    }
    private Bytes locate_message(Parser cat, Bytes key) throws SyntaxError {
        WordIter msg;
        cat.scan_until("msg", out msg);
        while (msg != null) {
            msg.next(); msg.assert_end();

            WordIter trans;
            var message = cat.scan_until("trans", out trans);
            if (trans == null)
                throw new SyntaxError.UNBALANCED_TAGS("Missing {%% trans %%} in {%% msg %%} body");
            trans.next(); trans.assert_end();

            if (ByteUtils.strip(message).compare(key) == 0)
                // Output so the cache doesn't need to hold external templates in memory.
                return ByteUtils.strip(message);

            cat.scan_until("endmsg", out trans);
            if (trans == null)
                throw new SyntaxError.UNBALANCED_TAGS("Missing {%% endtrans %%}!");
            trans.next(); trans.assert_end();

            cat.scan_until("msg", out msg);
        }

        throw new SyntaxError.UNCLOSED_ARG("Failed to find translation for string '%s'!",
                ByteUtils.to_string(key));
    }

    private Template[] parse_translations(Parser cat, uint8 range) throws SyntaxError {
        var translations = new Template[range];
        for (var i = 0; i < range; i++) {
            WordIter trans;
            translations[i] = cat.parse("trans endmsg", out trans);
            if (trans == null)
                throw new SyntaxError.UNBALANCED_TAGS("Missing {%% endtrans %%}!");
            if (ByteUtils.equals_str(trans.next(), i + 1 == range ? "endmsg" : "trans"))
                throw new SyntaxError.UNBALANCED_TAGS("Incorrect number of translations!");
        }

        return translations;
    }

    // cache used to avoid keeping multiple copies of a translation in memory.
    private class CacheEntry {
        public Bytes key;
        public weak Template[] translation;

        public static List<CacheEntry> translation_cache = new List<CacheEntry>();
    }

    private void lookup_translation(Bytes key, 
                ref Template[] bodies, ref Expression.Expression formula) {
        foreach (var entry in CacheEntry.translation_cache) {
            if (entry.translation == null) {
                // Do a bit of cleanup
                CacheEntry.translation_cache.remove(entry);
            }

            if (entry.key.compare(key) != 0) continue;

            bodies = entry.translation;
            // This is non-null, as a previous parse would have had to populate it
            // before we had a chance to insert this cache.
            formula = plural_formula;
        }

        var is_singular = bodies.length == 1;
        try {
            var cat = new Parser(load_catalogue());
            var range = parse_plural_form(cat);
            var key2 = locate_message(cat, key);
            bodies = parse_translations(cat, is_singular ? 1 : range);
            formula = plural_formula;

            var entry = new CacheEntry();
            // Matching key from catalogue,
            //      So the calling template needn't be kept in memory.
            entry.key = key2;
            entry.translation = bodies;
            CacheEntry.translation_cache.prepend(entry);
        } catch (Error e) {
            warning("Failed to parse translation catalogue: %s", e.message);
        }
    }

    private Expression.Expression? plural_formula = null;
    private Expression.Expression? english_formula = null;

    public class TransBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var parameters = parse_params(args);

            WordIter? endtoken;
            Bytes key;
            var bodies = parse_fallback(parser, out endtoken, out key);
            var formula = english_formula;
            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS("Missing {%% endtrans %%} tag.");
            endtoken.assert_end();

            lookup_translation(ByteUtils.strip(key), ref bodies, ref formula);

            if (bodies.length > 1) {
                if (!(b("count") in parameters))
                    throw new SyntaxError.INVALID_ARGS("Plural {%% trans %%} tag" +
                            "MUST specify a `count` parameter.");

                return new PluralTransTag(bodies, parameters, formula);
            }
            return new WithTag(parameters, bodies[0]);
        }

        private Template[] parse_fallback(Parser parser, out WordIter endtoken,
                    out Bytes key) throws SyntaxError {
            var body = parser.parse("plural endtrans", out endtoken, out key);
            if (endtoken != null && ByteUtils.equals_str(endtoken.next(), "plural")) {
                var plural = parser.parse("endtrans", out endtoken);
                if (english_formula == null) {
                    var english = smart_split(b("count != 1"), " ");
                    english_formula = new Expression.Parser(english).expression();
                }
                return new Template[2] {body, plural};
            }
            return new Template[1] {body};
        }
    }
    private class PluralTransTag : Template {
        private Template[] bodies;
        private Gee.Map<Bytes,Variable> vars;
        private Expression.Expression formula;

        public PluralTransTag(Template[] bodies, Gee.Map<Bytes,Variable> vars,
                    Expression.Expression formula) {
            this.bodies = bodies;
            this.vars = vars;
            this.formula = formula;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var i = (uint) formula.eval_type(Expression.TypePreference.NUMBER, ctx);
            yield bodies[i].exec(new Data.Lazy(vars, ctx), output);
        }
    }
}
