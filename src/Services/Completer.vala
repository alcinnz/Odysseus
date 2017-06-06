/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2017).
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
/** Dispatches completion logic to registered handlers,
    exposing the results as a Gtk.ListStore (URL at 0, text at 1). 

This helps to combine results from multiple sources including
    the Web, simple transformations, and eventually a local database. */
namespace Oddysseus.Services {
    public abstract class CompleterDelegate : Object {
        public Completer completer { construct; get; }
        public string query = "";

        protected void suggest(string url, string label = "-") {
            completer.@yield(url, label == "-" ? url : label);
        }

        public abstract void autocomplete();
    }

    public class Completer : Object {
        public Gtk.ListStore model =
                new Gtk.ListStore(2, typeof(string), typeof(string));
        private static Gee.ArrayList<Type>? delegate_classes = null;
        private Gee.ArrayList<CompleterDelegate> delegates =
                new Gee.ArrayList<CompleterDelegate>();
        
        construct {
            foreach (var cls in delegate_classes) {
                var completer = Object.@new(cls, "completer", this)
                        as CompleterDelegate;
                if (completer != null) delegates.add(completer);
            }
        }

        public static void register(Type completer) {
            if (delegate_classes == null) delegate_classes = new Gee.ArrayList<Type>();
            delegate_classes.add(completer);
        }

        public void suggest(string query) {
            model.clear();

            foreach (var completer in delegates) {
                completer.query = query;
                completer.autocomplete();
            }
        }

        public void @yield(string url, string label) {
            Gtk.TreeIter item;
            model.append(out item);
            model.@set(item, 0, url, 1, label, -1);
        }
    }
}
