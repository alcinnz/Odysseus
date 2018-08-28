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
/** This tag helps Odysseus talk about filetypes in a slightly more natural way. */
namespace Odysseus.Templating.xMIMEInfo {
    public class MIMEInfoBuilder : TagBuilder, Object {
        public Template? build(Parser parser, WordIter args) throws SyntaxError {
            var variables = new Gee.ArrayList<Variable>();
            foreach (var arg in args) variables.add(new Variable(arg));

            return new MIMEInfoTag(variables.to_array());
        }
    }
    private class MIMEInfoTag : Template {
        private Variable[] vars;
        public MIMEInfoTag(Variable[] variables) {this.vars = variables;}

        public override async void exec(Data.Data ctx, Writer output) {
            var mime = new StringBuilder();
            foreach (var variable in vars) mime.append(variable.eval(ctx).to_string());

            // I wish I didn't have to, but assume that
            // if a filetype is in the database it has a decent description.
            if (ContentType.list_registered().index(mime.str) < 0) return;

            var desc = ContentType.get_description(mime.str);
            yield output.writes(@"($desc)");
        }
    }

    public class MIMEIconFilter : Filter {
        public override Data.Data filter0(Data.Data mime) {
            var ret = ContentType.get_generic_icon_name(@"$mime");
            return new Data.Literal(ret == null ? "unknown" : ret);
        }
    }
}
