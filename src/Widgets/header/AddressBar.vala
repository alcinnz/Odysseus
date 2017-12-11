/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016-2017).
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
public class Odysseus.Header.AddressBar : Gtk.Entry {
    private Services.Completer completer = new Services.Completer();
    private Gtk.Popover popover;
    private Gtk.ListBox list;
    private int selected = 0;

    public int max_width {get; set;
            default = 840;} // Something large, so it fills all available space

    public signal void navigate_to(string url);

    construct {
        this.margin_start = 20;
        this.margin_end = 20;

        // GTK BUG: This code should expand this to fill, but it doesn't.
        this.hexpand = true;
        this.halign = Gtk.Align.FILL;

        build_dropdown();
        connect_events();
        notify["max-width"].connect(queue_resize);
    }

    /* This approximates the expand to fill effect. */
    public override void get_preferred_width(out int min_width, out int nat_width) {
        min_width = 20; // Meh
        nat_width = max_width;
    }
    
    private void connect_events() {
        changed.connect(autocomplete);

        this.focus_in_event.connect((evt) => {
            popover.show_all();
            autocomplete();

            Idle.add(() => {
                this.select_region(0, -1);
                return false;
            }, Priority.HIGH); // To aid retyping URLs, copy+paste
            return false;
        });
        this.focus_out_event.connect((evt) => {
            popover.hide();
            return false;
        });
        this.key_press_event.connect((evt) => {
            switch (evt.keyval) {
            case Gdk.Key.Up:
            case Gdk.Key.KP_Up:
                selected--;
                break;
            case Gdk.Key.Down:
            case Gdk.Key.KP_Down:
                selected++;
                break;
            default:
                return false;
            }

            if (list.get_row_at_index(selected) == null)
                return true; // Don't go beyond the boundaries.

            list.select_row(list.get_row_at_index(selected));
            return true;
        });
        this.activate.connect(() => {
            var row = list.get_selected_row();
            if (row == null) return;
            string url;
            row.@get("url", out url);
            navigate_to(url);

            // Remove focus from text entry
            get_toplevel().grab_focus();
        });
        
        list.row_activated.connect((row) => {
            string url;
            row.@get("url", out url);
            navigate_to(url);
        });
    }
    
    private void autocomplete() {
        list.@foreach((widget) => {list.remove(widget);});

        completer.suggest(this.text, (url, label) => {
            list.add(this.build_dropdown_row(url, label));

            /* Ensure a row is selected. */
            if (list.get_children().length() == 1) {
                list.select_row(list.get_row_at_index(0));
                this.selected = 0;
            }
        });
    }
    
    public void build_dropdown() {
        list = new Gtk.ListBox();
        list.activate_on_single_click = true;
        list.selection_mode = Gtk.SelectionMode.BROWSE;
        
        var scrolled = new AutomaticScrollBox();
        scrolled.add(list);
        scrolled.shadow_type = Gtk.ShadowType.IN;

        popover = new Gtk.Popover(this);
        popover.add(scrolled);
        popover.modal = false;
        popover.position = Gtk.PositionType.BOTTOM;

        this.size_allocate.connect((box) => scrolled.width_request = box.width);
    }
    
    public Gtk.Widget build_dropdown_row(string url, string label) {
        var row = new Gtk.Grid();
        row.row_spacing = 3;
        row.margin = 5;
        row.attach(build_label("font_size='large' font_weight='bold'", label), 0, 0);
        row.attach(build_label("font_size='small' color='blue' underline='single'", url),
                0, 1);
        return new CompletionRow(row, url);
    }
    
    private Gtk.Label build_label(string style, string text) {
        var label = new Gtk.Label(text);
        var markup = Markup.printf_escaped("<span "+style+">%s</span>", text);
        label.set_markup(markup);
        label.xalign = 0.0f;
        return label;
    }
}

/** This class serves to associate a URL with each ListBoxRow. */
private class CompletionRow : Gtk.ListBoxRow {
    public string url {get; set;}
    public CompletionRow(Gtk.Widget child, string url) {
        this.url = url;
        this.selectable = true;
        this.activatable = true;
        this.add(child);
        this.show_all();
    }
}
