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
    using Std;
    public class FetchBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            args.assert_end();
            WordIter endtoken;
            var prevMode = parser.escapes;
            parser.escapes = Std.AutoescapeBuilder.modes[b("url")];
            var request = parser.parse("each", out endtoken);
            parser.escapes = prevMode;
            if (endtoken == null ||
                    !(ByteUtils.equals_str(endtoken.next(), "each") &&
                    ByteUtils.equals_str(endtoken.next(), "as")))
                throw new SyntaxError.INVALID_ARGS(
                        "{%% fetch %%} must be contain a {%% each as _ %%} block!");

            var target = endtoken.next();
            endtoken.assert_end();

            var loop = parser.parse("endfetch", out endtoken);
            if (endtoken == null)
                throw new SyntaxError.INVALID_ARGS(
                        "{%% fetch %%} must be closed with an {%% endfetch %%}");
            endtoken.next(); endtoken.assert_end();
            return new FetchTag(request, target, loop);
        }
    }

    errordomain HTTPError {STATUS_CODE, UNSUPPORTED_FORMAT}

    private class FetchTag : Template {
        private Template body;
        private Template loop;
        private Bytes target;

        private Mutex outputlock = new Mutex();

        public FetchTag(Template body, Bytes target, Template loop) {
            this.body = body; this.target = target; this.loop = loop;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var capture = new CaptureWriter();
            yield body.exec(ctx, capture);
            var urls = capture.grab_string().split_set(" \t\r\n");

            var session = new Soup.Session();
            session.add_feature(new Soup.ContentSniffer());
            var inprogress = new Semaphore(urls.length);
            foreach (var url in urls) {
                if (url == "") {inprogress.dec(); continue;}

                render_request.begin(session, url, ctx, output, (obj, res) => {
                    try {
                        render_request.end(res);
                    } catch (Error err) {
                        // Try to render to WebInspector
                        var js_err = "\"Error fetching %s: %s\"".printf(
                                url.escape(), err.message.escape());
                        // Don't bother locking and let these occur wherever.
                        output.writes.begin(@"<script>console.warn($js_err)</script>");
                    }

                    if (inprogress.dec()) exec.callback();
                });
            }
            if (inprogress.count == 0) {
                output.writes.begin("<script>console.warn('No requests to make!')</script>");
            } else yield;
        }

        private async void render_request(Soup.Session session, string url,
                Data.Data ctx, Writer output) throws Error {
            var req = session.request_http("GET", url);
            var response = yield req.send_async(null);
            var status = req.get_message().status_code;
            if (status != 200) throw new HTTPError.STATUS_CODE("HTTP %u", status);

            var mime = req.get_content_type();
            var loop_vars = ByteUtils.create_map<Data.Data>();
            loop_vars[target] = yield build_response_data(mime, response);

            yield outputlock.enter();
            yield loop.exec(new Data.Stack.with_map(ctx, loop_vars), output);
            outputlock.exit();
        }

        private async Data.Data build_response_data(string mime, InputStream stream) throws Error {
            if ("json" in mime) {
                var json = new Json.Parser();
                yield json.load_from_stream_async(stream);
                return Data.JSON.build(json.get_root());
            } /*else if ("xml" in mime) {
                // Unfortunately libxml cannot read from an InputStream,
                // So read the entire response into a string.
                var b = new MemoryOutputStream.resizable();
                yield b.splice_async(stream, 0);
                var xml = Xml.Parser.parse_memory((char[]) b.data, b.get_data_size());
                return new Data.XML(xml);
            }*/ else if (mime == "text/tsv" || mime == "text/tab-separated-values") {
                return yield readTSV(new DataInputStream(stream));
            }
            throw new HTTPError.UNSUPPORTED_FORMAT("Cannot read %s files!", mime);
        }
    }

    /* This must to make `count` mutable within callback functions. */
    private class Semaphore {
        public int count;
        public Semaphore(int count = 0) {this.count = count;}
        public bool dec() {
            this.count--;
            return this.count == 0;
        }
    }

    /* A very simplistic GLib mainloop mutex. */
    private class Mutex {
        private bool locked = false;
        public async void enter() {
            while (locked) {
                Idle.add(enter.callback, Priority.LOW);
                yield;
            }
            locked = true;
        }
        public void exit() {locked = false;}
    }
}
