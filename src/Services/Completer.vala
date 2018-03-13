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
/** Dispatches completion logic to registered handlers,
    exposing the results as a Gtk.ListStore (URL at 0, text at 1). 

This helps to combine results from multiple sources including
    the Web, simple transformations, and eventually a local database. */
namespace Odysseus.Services {
    public abstract class CompleterDelegate : Object {
        public Completer completer { construct; get; }
        public string query = "";

        protected void suggest(string url, string label = "-") {
            completer.@yield(url, label == "-" ? url : label);
        }

        public abstract void autocomplete();
    }

    private class Completion : Object {
        public string url {get; set;}
        public string label {get; set;}

        public Completion(string url, string label) {
            this.url = url;
            this.label = label;
        }
    }

    public class Completer : Object {
        public ListStore model = new ListStore(typeof(Completion));
        private static Gee.ArrayList<Type>? delegate_classes = null;
        private Gee.ArrayList<CompleterDelegate> delegates =
                new Gee.ArrayList<CompleterDelegate>();

        private Gee.Set<string> seen_urls = new Gee.HashSet<string>();
        
        construct {
            foreach (var cls in delegate_classes) {
                var completer = Object.@new(cls, "completer", this) as CompleterDelegate;
                if (completer != null) delegates.add(completer);
            }
        }

        public static void register(Type completer) {
            if (delegate_classes == null) delegate_classes = new Gee.ArrayList<Type>();
            delegate_classes.add(completer);
        }

        public delegate void YieldCallback(string url, string label);
        private YieldCallback yieldCallback;
        public void suggest(string query, owned YieldCallback cb) {
            this.yieldCallback = cb;
            seen_urls.clear();

            foreach (var completer in delegates) {
                completer.query = query;
                completer.autocomplete();
            }
        }

        public void @yield(string url, string label) {
            if (url in seen_urls) return;
            seen_urls.add(url);

            yieldCallback(url, label);
        }
    }
}
