/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2016-2017).
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
public class Oddysseus.AddressBar : Gtk.Entry {
    construct {
        this.margin_start = 20;
        this.margin_end = 20;

        // GTK BUG: This code should expand this to fill, but it doesn't.
        this.hexpand = true;
        this.halign = Gtk.Align.FILL;

        build_autocomplete();
    }

    /* This approximates the expand to fill effect. */
    public override void get_preferred_width(out int min_width, out int nat_width) {
        min_width = 20; // Meh
        nat_width = 848; // Something large, so it fills this space if possible
    }

    private void build_autocomplete() {
        this.completion = new Gtk.EntryCompletion();
        var completer = new Services.Completer();

        completion.model = completer.model;
        completion.text_column = 0;
        // Don't second guess the completer.
        completion.set_match_func((completion, key, iter) => {return true;});

        // Serves to get started, but ideally:
        //  a) I'd render a favicon and the URL as subtext.
        //  b) Require an entry to be selected.
        //  and c) Not have to subvert the completion's logic.
        completion.clear();
        var labelRenderer = new Gtk.CellRendererText();
        completion.pack_start(labelRenderer, true);
        completion.add_attribute(labelRenderer, "text", 1);

        changed.connect(() => {completer.suggest(this.text);});
    }
}
