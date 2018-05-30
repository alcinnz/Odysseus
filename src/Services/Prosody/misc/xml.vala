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
/** Various dataformats Odysseus will want to render nicely and otherwise handle
    (RSS/Atom, OpenSearch) are encoded as XML. And as such this code allows
    Prosody to easily handle this data.

For simple cases, this naively coerces to the Prosody data model (a coercion that
    is actually helpful for handling RSS/Atom), but for more complex cases
    it exposes XPath support. */
namespace Odysseus.Templating.xXML {
    using Data;

    public class XML : Data {
        private Xml.Node *node;
        public XML(Xml.Node *node) {this.node = node;}

        public override Data get(Slice property) {
            var prop = @"$property";
            // First lookup amongst the properties
            for (Xml.Attr *iter = node->properties; iter != null; iter = iter->next) {
                if (iter->name == prop) return new XML(iter->children);
            }
            // Second lookup amongst child nodes
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
                if (iter->name == prop) return new XML(iter);
            }

            return new Empty();
        }
        public override string to_string() {
            return node->get_content();
        }
        public override bool exists {get {return true;}}
        public override void foreach_map(Data.ForeachMap cb) {
            for (Xml.Node* iter = node->children; iter != null; iter = iter->next) {
                if (cb(b(iter->name), new XML(iter))) return;
            }
        }
        public override double to_double() {return 0.0;}
        // How you access the full XML datamodel: XPath
        public override Data lookup(string query) {
            var ctx = new Xml.XPath.Context(node);
            return new XPathResult(ctx.eval(query));
        }
    }

    private class XPathResult : Data {
        private Xml.XPath.Object *inner;
        public XPathResult(Xml.XPath.Object *obj) {return this.inner = obj;}

        public override Data get(Slice property) {
            var property = @"$property_bytes";
            uint64 index = 0;
            if (property[0] == '$' &&
                    uint64.try_parse(property[1:0], out index) &&
                    index < inner->nodesetval->length()) {
                return new XML(inner->nodesetval->item((int) index));
            }
            return new Empty();
        }
        public override void foreach_map(Data.ForeachMap cb) {
            range(cb, inner->nodesetval.length());
        }
        public override string to_string() {return inner->stringval;}
        public override bool exists {get {return inner->boolval;}}
        public override int to_double() {return inner->floatval;}
    }
}
