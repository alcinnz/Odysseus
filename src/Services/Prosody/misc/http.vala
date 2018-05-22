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
/** Sometimes internal pages will want to incorporate data available online,
    and the {% fetch %} tag implemented here allows for this.

This would mostly just serve to implement of builtin federated search,
    but it's also useful for loading in recommendations to fill in the gaps. */
namespace Odysseus.Templating.HTTP {
    using namespace Std;
    public class FetchBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            args.assert_end();
            WordIter endtoken;
            var body = parser.parse("endfatch", out endtoken);
            if (endtoken == null ||
                    (!ByteUtils.equals_str(endtoken.next(), "endfetch") &&
                    !ByteUtils.equals_str(endtoken.next(), "as")))
                throw new SyntaxError.INVALID_ARGS(
                    "{%% fetch %%} must be closed with an {%% endfetch as _ %%}");

            var target = endtoken.next();
            endtoken.assert_end();

            var tail = parser.parse();
            return new FetchTag(body, target, tail);
        }
    }

    public class FetchTag : Template {
        private Template body, tail;
        private Bytes target;
        public FetchTag(Template body, Bytes target, Template tail) {
            this.body = body;
            this.target = target;
            this.tail = tail;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var capture = new CaptureWriter();
            yield body.exec(ctx, capture);
            var urls = capture.grab_string().split_set(" \t\r\n");

            var data = new ListData(yield request(urls));
            var tail_ctx = ByteUtils.build_map<Data.Data>();
            tail_ctx[target] = data;
            yield tail.exec(new Data.Stack.with_map(ctx, tail_ctx), output);
        }

        private async Gee.List<Data.Data> request(string[] urls) {
            var session = new Soup.Session();
            var responses = new Gee.ArrayList<Data.Data>();
            var mutex = 0;
            foreach (var url in urls) {
                var req = session.request(url);
                mutex += 1;
                req.send_async.begin(null, (obj, res) => {
                    var response = req.send_async.end(res);
                    var mime = req.get_content_type();
                    responses.add(yield build_response_data(mime, response));

                    mutex -= 1;
                    if (mutex == 0) request.callback();
                });
            }
            yield;
            return responses;
        }

        private async Data.Data build_response_data(
                string mime, InputStream stream, string filename = "") {
            try {
            if ("json" in mime) {
                var json = new Json.Parser();
                yield json.load_from_stream_async(stream);
                return Data.JSON.build(json.get_root());
            } else if ("xml" in mime) {
                // Unfortunately libxml cannot read from an InputStream,
                // So read the entire response into a string.
                var b = new MemoryOutputStream.resizable();
                yield b.splice_async(stream, 0);
                var xml = Xml.Parser.parse_memory((char[]) b.data, b.get_data_size());
                return new Data.XML(xml);
            } else if (filename != "") {
                return new Data.Literal(filename);
            } else {
                var temp = File.new_tmp(null, null);
                var output = yield temp.append_to_async(0);
                yield output.splice_async(stream, 0);
                yield output.close_async();

                return new Data.Literal(temp.get_path());
            }
            } catch (Error err) {
                return Data.Empty();
            }
        }
    }
}
