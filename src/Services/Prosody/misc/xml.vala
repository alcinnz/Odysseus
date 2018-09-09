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
    public class XML : Data.Data {
        protected Xml.Node *node;
        string[] locale;
        public XML(Xml.Node *node, string[] locale = I18n.get_locales()) {
            this.node = node;
            this.locale = locale;
        }
        public XML.with_doc(Xml.Doc *node, string[] locale = I18n.get_locales()) {
            this(node->get_root_element(), locale);
        }

        public override bool exists {get {return true;}}

        public override Data.Data get(Slice property) {
            var self = get_localized(); // Only traverse localized nodes.
            if (self == null) return new Data.Empty();

            // First lookup amongst the properties
            for (Xml.Attr *iter = self->properties; iter != null; iter = iter->next) {
                if (iter->name in property) return new XML(iter->children, locale);
            }
            // Second lookup amongst child nodes
            for (Xml.Node *iter = self->children; iter != null; iter = iter->next) {
                if (iter->name in property) return new XML(iter, locale);
            }

            return new Data.Empty();
        }

        private Xml.Node *get_localized() {
            var ret = node; Xml.Node* unlocalized = null;
            for (; ret != null; ret = ret->next) {
                if (ret->name != node->name) continue;
                var lang = ret->get_prop("lang");
                if (unlocalized == null && lang == null)
                    unlocalized = ret;
                if (lang != null && lang in locale) break;
            }

            return ret != null ? ret : unlocalized;
        }
        private bool is_sanitary(Xml.Node *node) {
            var ctx = new Xml.XPath.Context(node->doc);
            return ctx.eval("script|style")->nodesetval->is_empty();
        }

        public override string to_string() {
            var self = get_localized();
            return self == null ? "" : self->get_content();
        }
        public override bool show(string defaultType, out Slice text) {
            var self = get_localized();
            if (self == null) {text = new Slice(); return true;}
            var type = self->get_prop("type");
            if (type == null) type = defaultType;

            text = new Slice.s(self->get_content());
            switch (type) {
            case "xhtml":
                var output = new Xml.Buffer();
                for (var iter = self->children; iter != null; iter = iter->next) {
                    if (output.node_dump(iter->doc, iter, 0, 1) == 0) return false;
                }
                text = new Slice.s(output.content());
                return is_sanitary(self);
            case "html":
                var html = Html.Doc.read_doc(@"$text", "about:blank");
                if (html == null) return false;

                return is_sanitary(html->get_root_element());
            case "text":
                return false;
            case "":
                return false;
            default:
                info("Encountered unsupported type= attribute.");
                return false;
            }
        }

        public override void foreach_map(Data.Data.ForeachMap cb) {
            var _ = new Slice();
            for (Xml.Node* iter = node; iter != null; iter = iter->next) {
                if (iter->name == node->name &&
                        // localize!
                        (iter->has_prop("lang") == null ||
                        iter->get_prop("lang") in locale)) {
                    if (cb(_, new XML(iter, locale))) return;
                }
            }
        }

        public override double to_double() {return double.parse(node->get_content());}

        private void lookup_internal(Xml.Node *self, string query, Data.Data.LookupCallback cb) {
            for (Xml.Node *iter = self->children; iter != null; iter = iter->next) {
                if (iter->name == query) cb(new XML(iter, locale));
                lookup_internal(iter, query, cb);
            }
        }
        public override void lookup(string query, Data.Data.LookupCallback cb) {
            lookup_internal(node, query, cb);
        }

        public override Gee.SortedSet<string> items() {
            var ret = new Gee.TreeSet<string>();

            var name = new Slice.s("name");
            foreach_map((_, item_) => {
                var namenode = item_[name];
                if (namenode is Data.Empty) namenode = item_;
                ret.add(@"$namenode");
                return false;
            });

            return ret;
        }
    }
}
