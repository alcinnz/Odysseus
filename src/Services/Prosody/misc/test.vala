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
/** Template to use to test all the other tags work as expected.
    This builds on the diff & JSON extensions.

These are used on odysseus:debugging/test, and as a nice aside exercies the
    entire parser quite naturally. Leaving just the tags & filters to be tested. */
namespace Odysseus.Templating.xTestRunner {
    public class TestBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var caption = args.next().parse();
            var flag = args.next_value();
            args.assert_end();

            bool reset = false;
            bool ignore = false;
            if (flag == null) {/* ignore */}
            else if ("reset" in flag) reset = true;
            else if ("ignore" in flag) ignore = true;
            else throw new SyntaxError.INVALID_ARGS(
                    "If specified, the flag argument must be either " +
                    @"'reset' or 'ignore', got '$flag'");

            WordIter? endtoken;
            Slice test_source;
            Template testcase;
            try {
                testcase = parser.parse("input output", out endtoken, out test_source);
            } catch (SyntaxError e) {
                var lexer = parser.lex;
                var failed_token = lexer.text[lexer.last_start:lexer.last_end];
                var try_again = true;
                while (try_again) {
                    try {
                        parser.parse("endtest", out endtoken);
                        try_again = false;
                    } catch (SyntaxError e) {/* ignore */}
                }
                if (endtoken == null)
                    throw new SyntaxError.UNBALANCED_TAGS(
                        "{%% test %%} must be closed with a {%% endtest %%} tag.");

                return new TestSyntaxError(caption, failed_token, ignore, e);
            }
            Slice endtag = endtoken.next();
            endtoken.assert_end();

            Data.Data input = new Data.Empty();
            Slice input_text = new Slice();
            if ("input" in endtag) {
                input_text = parser.scan_until("output", out endtoken);
                endtag = endtoken.next();
                endtoken.assert_end();

                var json_parser = new Json.Parser();
                try {
                    json_parser.load_from_data((string) input_text.to_array(),
                            input_text.length);
                } catch (Error e) {
                    throw new SyntaxError.UNEXPECTED_CHAR(
                            "{%% test %%}: Content of the {%% input %%} block " +
                            "must be valid JSON: %s", e.message);
                }
                input = xJSON.build(json_parser.get_root());
            }

            if (endtag == null)
                throw new SyntaxError.UNBALANCED_TAGS(
                        "{%% test %%} expects an {%% output %%} branch");
            Slice output = parser.scan_until("endtest", out endtoken);

            if (endtoken == null)
                throw new SyntaxError.UNBALANCED_TAGS(
                        "{%% test %%} requires a closing {%% endtest %%} tag");
            endtoken.next(); endtoken.assert_end();
            return new TestTag(reset, ignore, caption, testcase, test_source,
                    input, input_text, output);
        }
    }
    private class TestTag : Template {
        private bool reset;
        private bool ignore;
        private Slice caption;
        private Template testcase;
        private Slice test_source;
        private Data.Data input;
        private Slice input_text;
        private Slice output;
        public TestTag(bool reset, bool ignore, string caption,
                Template testcase, Slice test_source, Data.Data input,
                Slice input_text, Slice output) {
            this.reset = reset;
            this.ignore = ignore;
            this.caption = new Slice.s(caption);
            this.testcase = testcase;
            this.test_source = test_source;
            this.input = input;
            this.input_text = input_text;
            this.output = output;
        }

        public static int passed;
        public static int count;

        public override async void exec(Data.Data ctx, Writer stream) {
            if (reset) {
                passed = 0;
                count = 0;
            }

            var capture = new CaptureWriter();
            yield testcase.exec(input, capture);
            Slice computed = capture.grab_data();

            xDiff.Ranges diff;
            bool passed;
            if (output.equal_to(computed)) {
                // Fast & thankfully common case
                passed = true;
                diff = xDiff.Ranges();
            } else {
                diff = xDiff.diff(output, computed);
                passed = diff.a_ranges.size == 0 && diff.b_ranges.size == 0;
                assert(!passed); // Do the fast & slow checks agree?
            }

            if (!ignore) {
                if (passed) TestTag.passed++;
                TestTag.count++;
            }
            yield format_results(passed, stream, computed, diff);
        }

        private async void format_results(bool passed, Writer stream,
            Slice computed, xDiff.Ranges diff)  {
            yield stream.writes("<details");
            if (ignore) yield stream.writes(" style='opacity: 75%;'");
            yield stream.writes(">\n\t<summary style='background: ");
            yield stream.writes((passed ? "green" : "red"));
            yield stream.writes(";' title='");
            if (ignore) yield stream.writes("Ignored ");
            yield stream.writes(passed ? "PASS" : "FAILURE");
            yield stream.writes("'>");
            yield stream.escaped(caption);
            yield stream.writes("</summary>\n\t");

            yield stream.writes("<table>\n\t\t");
            yield stream.writes("<tr><th>Test Code</th>");
            yield stream.writes("<th>Test Input</th></tr>\n\t\t");
            yield stream.writes("<tr><td><pre>");
            yield stream.escaped(test_source);
            yield stream.writes("</pre></td><td><pre>");
            yield stream.escaped(input_text);
            yield stream.writes("</pre></td></tr>\n\t\t");

            yield stream.writes("<tr><th>Computed</th>");
            yield stream.writes("<th>Expected</th></tr>\n\t\t");
            yield stream.writes("<tr><td><pre>");
            yield xDiff.render_ranges(computed, diff.b_ranges, "ins", stream);
            yield stream.writes("</pre></td><td><pre>");
            yield xDiff.render_ranges(output, diff.a_ranges, "del", stream);
            yield stream.writes("</pre></td></tr>\n\t");
            yield stream.writes("</table>\n</details>");
        }
    }
    private class TestSyntaxError : Template {
        private SyntaxError error;
        private bool ignore;
        private Slice caption;
        private Slice failed_tag;
        public TestSyntaxError(string caption, Slice failed_tag,
            bool ignore, SyntaxError e) {
            this.error = e;
            this.ignore = ignore;
            this.caption = new Slice.s(caption);
            this.failed_tag = failed_tag;
        }

        public override async void exec(Data.Data ctx, Writer stream) {
            yield stream.writes("<details");
            if (ignore) yield stream.writes(" style='opacity: 75%'");
            yield stream.writes(">\n\t<summary style='background: yellow' title='");
            if (ignore) yield stream.writes("Ignored ");
            yield stream.writes("ERROR'>");
            yield stream.escaped(caption);
            yield stream.writes("</summary>\n\t<h3>");
            yield stream.writes(error.domain.to_string());
            yield stream.writes(" thrown :: While Parsing <code>");
            yield stream.write(failed_tag);
            yield stream.writes("</code></h3>\n\t<p>");
            yield stream.escaped(new Slice.s(error.message));
            yield stream.writes("</p>\n</details>");

            // Report as failure to the stats
            if (!ignore) TestTag.count++;
        }
    }

    public class TestReportBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            args.assert_end();
            return new TestReportTag();
        }
    }
    private class TestReportTag : Template {
        public override async void exec(Data.Data ctx, Writer output) {
            var passed = TestTag.passed == TestTag.count;
            yield output.writes("<aside style='background: ");
            yield output.writes(passed ? "green" : "red");
            yield output.writes("; position: fixed; top: 10px; right: 10px; ");
            yield output.writes("padding: 10px;'>");
            yield output.writes(@"$(TestTag.passed)/$(TestTag.count)");
            yield output.writes(" passed</aside>\n<script>document.title = '");
            yield output.writes(passed ? "[process-completed] Tests PASSED" :
                    "[process-stop] Tests FAILED");
            yield output.writes("';</script>");
        }
    }

    public class DiffFilter : Filter {
        public override Data.Data filter(Data.Data a, Data.Data b) {
            var A = a.to_bytes(); var B = b.to_bytes();

            var loop = new MainLoop();
            AsyncResult? result = null;
            diff_to_str.begin(A, B, xDiff.diff(A, B), (obj, res) => {
                result = res;
                loop.quit();
            });
            loop.run();
            return new Data.Substr(diff_to_str.end(result));
        }

        private async Slice diff_to_str(Slice a, Slice b, xDiff.Ranges diff) {
            var output = new CaptureWriter();
            yield xDiff.render_ranges(a, diff.a_ranges, "-", output);
            yield output.writes("\t");
            yield xDiff.render_ranges(b, diff.b_ranges, "+", output);
            return output.grab_data();
        }
    }
}
