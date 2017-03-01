/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017).
*
* Oddysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Oddysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Oddysseus.  If not, see <http://www.gnu.org/licenses/>.
*/

/** Cached loading for templates. */
namespace Oddysseus.Templating {
    private Gee.Map<string, Template>? template_cache = null;
    public Template get_for_resource(string resource, ref ErrorData? error_data)
            throws SyntaxError, Error {
        if (template_cache == null)
            template_cache = new Gee.HashMap<string, Template>();

        if (!template_cache.has_key(resource)) {
            if (!lib_initialized()) Std.register_standard_library();
            var bytes = resources_lookup_data(resource, 0);
            var parser = new Parser(bytes);
            try {
                template_cache[resource] = parser.parse();
            } catch (SyntaxError err) {
                // FIXME segfaults
                /*int line_number; int line_offset; int err_start; int err_end;
                parser.get_current_token(out line_number, out line_offset, 
                        out err_start, out err_end);
                error_data = new ErrorData(err, line_number, line_offset,
                        err_start, err_end, bytes);*/
                throw err;
            }
        }
        return template_cache[resource];
    }
    // NOTE in the future we may want to cap the number
    //      of templates in the cache.

    public class ErrorData : Data.Mapping {
        public TagBuilder tag;
        public ErrorData(SyntaxError err, int line_number, int line_offset,
                int error_start, int error_end, Bytes source) {
            data[ByteUtils.from_string("err-code")] = new Data.Literal(err.code);

            data[ByteUtils.from_string("err-text")] =
                    new Data.Literal(err.message);

            var err_token = source.slice(error_start, error_end);
            if (Token.get_type(err_token) == TokenType.TAG) {
                var err_tag = new Data.Literal(Token.get_args(err_token).next());
                data[ByteUtils.from_string("err-tag")] = err_tag;
            }

            data[ByteUtils.from_string("line-number")] =
                    new Data.Literal(line_number);

            var tag = new ErrorTag(line_offset, error_start, error_end, source);
            this.tag = new ErrorTagBuilder(tag);
        }
    }

    private class ErrorTagBuilder : Object, TagBuilder {
        private ErrorTag tag;
        public ErrorTagBuilder(ErrorTag tag) {this.tag = tag;}
        public Template? build(Parser parser, WordIter args) {
            args.assert_end();
            return tag;
        }
    }

    private class ErrorTag : Template {
        private int line_start;
        private int line_end;
        private int err_start;
        private int err_end;
        private Bytes source;

        public ErrorTag(int line_offset, int error_start, int error_end,
                Bytes source) {
            this.line_start = line_offset;
            this.line_end = line_offset;
            ByteUtils.find_next(source, {'\n'}, ref this.line_end);
            this.err_start = error_start - line_offset;
            this.err_end = error_end - line_offset;
            this.source = source;
        }

        public override async void exec(Data.Data ctx, Writer stream) {
            // Utilize diff rendering for this. 
            var err_ranges = new Gee.ArrayList<Diff.Duo>();
            err_ranges.add(new Diff.Duo(err_start, err_end));
            Diff.render_ranges(source.slice(line_start, line_end), err_ranges,
                    "strong", stream);
        }
    }
}
