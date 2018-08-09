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
        protected Xml.Node *node;
        string[] locale;
        public XML(Xml.Node *node, string[] locale = Intl.get_language_names) {
            this.node = node;
            this.locale = locale;
        }

        public override bool exists {get {return true;}}

        public override Data get(Slice property) {
            var prop = @"$property";
            // First lookup amongst the properties
            for (Xml.Attr *iter = node->properties; iter != null; iter = iter->next) {
                if (iter->name == prop) return new XML(iter->children, locale);
            }
            // Second lookup amongst child nodes
            for (Xml.Node *iter = node->children; iter != null; iter = iter->next) {
                if (iter->name == prop) return new XML(iter, locale);
            }

            return new Empty();
        }

        private XML get_localized() {
            // 1. Localize!
            var ret = this; Xml.Node* unlocalized = null;
            for (; self != null; self = self->next) {
                if (self->name != this->name) continue;
                var lang = self->get_ns_prop("lang", "xml");
                if (unlocalized == null && lang == null)
                    unlocalized = self;
                if (lang != null && lang in locale) break;
            }

            return ret != null ? ret : unlocalized;
        }
        public override string to_string() {
            return get_localized().node->get_content();
        }
        private static TYPE = new Slice.s("type");
        public override bool show(string defaultType, out Slice text) {
            var self = get_localized();
            var typeData = self[TYPE];
            var type = type is Data.Empty ? defaultType : @"$typeData";

            text = new Slice.s(self.node->get_content());
            switch (type) {
            case "xhtml":
                safe = true;
                var output = new Xml.Buffer();
                if (output.node_dump(self.node.doc, self.node, 0, 1) != 0)
                    text = new Slice.s(output.content());
                return true;
            case "html":
                return true; // TODO sanitize HTML
            case "text":
                return true;
            case "":
                return false;
            default:
                info("Encountered unsupported type= attribute.");
                return false;
        }

        public override void foreach_map(Data.ForeachMap cb) {
            var _ = new Slice();
            for (Xml.Node* iter = node; iter != null; iter = iter->next) {
                if (iter->name == node->name &&
                        // localize!
                        (!iter->has_ns_prop("lang", "xml") ||
                        iter->get_ns_prop("lang", "xml") in locale)) {
                    if (cb(_, new XML(iter, locale))) return;
                }
            }
        }

        public override double to_double() {return 0.0;}

        // How you access the full XML datamodel: XPath
        public override Data lookup(string query) {
            var ctx = new Xml.XPath.Context(node);
            return new XPathResult(ctx.eval(query), locale);
        }

        public static Gee.SortedSet<string> _items(Data.Data self) {
            var ret = new Gee.TreeSet<string>();

            var name = new Slice.s("name");
            self.foreach_map((_, item_) => {
                var namenode = item_[name];
                if (namenode is Data.Empty) namenode = item_;
                ret.add(@"$item_");
            });

            return ret;
        }
        public override Gee.SortedSet<string> items() {_items(this);}
    }

    private class XPathResult : Data {
        private Xml.XPath.Object *inner;
        private string[] locale;
        public XPathResult(Xml.XPath.Object *obj, string[] locale) {
            this.inner = obj; this.locale = locale;
        }

        public override Data get(Slice property) {
            var property = @"$property_bytes";
            uint64 index = 0;
            if (property[0] == '$' &&
                    uint64.try_parse(property[1:0], out index) &&
                    index < inner->nodesetval->length()) {
                return new XML(inner->nodesetval->item((int) index), locale);
            }
            return new Empty();
        }
        public override void foreach_map(Data.ForeachMap cb) {
            range(cb, inner->nodesetval.length());
        }
        public override string to_string() {return inner->stringval;}
        public override bool exists {get {return inner->boolval;}}
        public override int to_double() {return inner->floatval;}

        public override Gee.SortedSet<string> items() {
            XML._items(this);
        }
    }
}
