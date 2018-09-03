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
namespace Odysseus.Templating.xHTTP {
    using Std;
    public class FetchBuilder : TagBuilder, Object {
        private Gee.Map<uint8, string> escapeURL = new Gee.HashMap<uint8, string>();
        construct {escapeURL[0] = "escapeURI";}

        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var cache_flag = args.next_value();
            if (cache_flag != null && cache_flag != new Slice.s("permacached"))
                throw new SyntaxError.INVALID_ARGS(
                        "First arg to {%% fetch %%}, if any, must be 'permacached'!");
            args.assert_end();

            WordIter endtoken;
            var prevMode = parser.escapes; parser.escapes = escapeURL;
            var request = parser.parse("each", out endtoken);
            parser.escapes = prevMode;

            if (endtoken == null ||
                    !("each" in endtoken.next() && "as" in endtoken.next()))
                throw new SyntaxError.INVALID_ARGS(
                        "{%% fetch %%} must be contain a {%% each as _ %%} block!");

            var target = endtoken.next();
            var mimetarget = endtoken.next_value();
            endtoken.assert_end();

            var loop = parser.parse("endfetch", out endtoken);
            if (endtoken == null)
                throw new SyntaxError.INVALID_ARGS(
                        "{%% fetch %%} must be closed with an {%% endfetch %%}");
            endtoken.next(); endtoken.assert_end();

            return new FetchTag(request, cache_flag == null, target, mimetarget, loop);
        }
    }

    errordomain HTTPError {STATUS_CODE, UNSUPPORTED_FORMAT}

    private class FetchTag : Template {
        private Template body;
        private Template loop;
        private Slice target;
        private Slice? mimetarget;
        private bool nocache;

        private Mutex outputlock = new Mutex();

        public FetchTag(Template body, bool nocache, Slice target, Slice? mimetarget, Template loop) {
            this.body = body; this.nocache = nocache; this.target = target;
            this.mimetarget = mimetarget; this.loop = loop;
        }

        public override async void exec(Data.Data ctx, Writer output) {
            var capture = new CaptureWriter();
            yield body.exec(ctx, capture);
            var urls = capture.grab_string().split_set(" \t\r\n");

            var session = build_session();
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

        public static string user_agent = "Prosody-template";
        private Soup.Session build_session() {
            var session = new Soup.Session();
            session.user_agent = user_agent;
            // Required in order to read the ContentType header.
            session.add_feature(new Soup.ContentSniffer());

            if (!nocache) {
                var cache = new Soup.Cache(Odysseus.build_config_path("addons"), Soup.CacheType.SINGLE_USER);
                // If the UI's caching something from the Web, keep it around!
                // FIXME clear expired items.
                cache.set_max_size(uint.MAX);
                session.add_feature(cache);
            }
            return session;
        }

        private async void render_request(Soup.Session session, string url,
                Data.Data ctx, Writer output) throws Error {
            var req = session.request_http("GET", url);
            req.get_message().request_headers.append("Accept", ACCEPTS);
            var response = yield req.send_async(null);
            var status = req.get_message().status_code;
            if (status != 200) throw new HTTPError.STATUS_CODE("HTTP %u", status);

            var resp = yield build_response_data(req.get_content_type(), response);

            yield outputlock.enter();
            var coremime = req.get_content_type().split(";", 2)[0];
            var loopctx = Data.Let.build(target, resp,
                    Data.Let.build(mimetarget, new Data.Literal(coremime), ctx));
            yield loop.exec(loopctx, output);
            outputlock.exit();
        }

        private static async string read_stream(InputStream stream) throws IOError {
            var ret = new StringBuilder();
            var buffer = new uint8[256];
            ssize_t size = 0;
            while ((size = yield stream.read_async(buffer)) > 0) {
                ret.append_len((string) buffer, size);
            }
            return ret.str;
        }

        private const string ACCEPTS = "text/xml, application/json, text/tsv, text/tab-separated-values";
        private async Data.Data build_response_data(string mime, InputStream stream) throws Error {
            if ("json" in mime) {
                var json = new Json.Parser();
                yield json.load_from_stream_async(stream);
                return xJSON.build(json.get_root());
            } else if ("xml" in mime) {
                // Unfortunately libxml cannot read from an InputStream,
                // So read the entire response into a string.
                var text = yield read_stream(stream);
                return new xXML.XML.with_doc(Xml.Parser.parse_memory(text, text.length));
            } else if (mime == "text/tsv" || mime == "text/tab-separated-values") {
                return yield x.readTSV(new DataInputStream(stream));
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
