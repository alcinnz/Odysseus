/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2016).
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
public class Oddysseus.FindToolbar : Gtk.Toolbar {
    private WebKit.FindController controller;
    private bool smartcase;
    private WebKit.FindOptions options;

    private Gtk.Entry search;
    private Gdk.RGBA normal_color;
    private Gtk.ToolButton menu_button;

    public FindToolbar(WebKit.FindController controller) {
        set_style (Gtk.ToolbarStyle.ICONS);
        icon_size = Gtk.IconSize.SMALL_TOOLBAR;
        this.controller = controller;
        this.options = WebKit.FindOptions.NONE;

        search = new Gtk.Entry();
        search.primary_icon_name = "edit-find";
        search.placeholder_text = "Find in page..."; // TODO translate
        find_normal_color();
        search.changed.connect(() => {
            find_in_page();
            search.secondary_icon_name = search.text_length > 0 ?
                    "edit-clear" : null;
        });
        search.icon_press.connect((which, pos) => {
            if (which == Gtk.EntryIconPosition.SECONDARY) {
                search.text = "";
                search.secondary_icon_name = null;
                controller.search_finish();
            }
        });
        search.key_press_event.connect((evt) => {
            if (search.text == "") {
                return false;
            }

            string key = Gdk.keyval_name(evt.keyval);
            if (evt.state == Gdk.ModifierType.SHIFT_MASK) {
                key = "<Shift>" + key;
            }

            switch (key) {
            case "<Shift>Return":
            case "Up":
                controller.search_previous();
                return true;
            case "Return":
            case "Down":
                controller.search_next();
                return true;
            }

            return false;
        });
        add_widget(search);

        var prev = new Gtk.ToolButton(null, "");
        prev.icon_name = "go-up-symbolic";
        prev.tooltip_text = "Find previous match"; // TODO translate
        prev.clicked.connect(controller.search_previous);
        add_widget(prev);
        var next = new Gtk.ToolButton(null, "");
        next.icon_name = "go-down-symbolic";
        next.tooltip_text = "Find next match";
        next.clicked.connect(controller.search_next);
        add_widget(next);

        // TODO handle case where this nonstandard icon doesn't exist
        var options = new Gtk.ToolButton(null, "");
        options.icon_name = "open-menu-symbolic";
        options.tooltip_text = "View search options"; // TODO translate
        var options_menu = build_options_menu();
        options.clicked.connect(() => {
            options_menu.popup(null, null, position_menu_below, 0,
                                Gtk.get_current_event_time());
        });
        menu_button = options;
        add_widget(options);
        smartcase = true;

        controller.found_text.connect(found_text_cb);
        controller.failed_to_find_text.connect(failed_to_find_text_cb);
        controller.counted_matches.connect(counted_matches_cb);
    }

    ~FindToolbar() {
        controller.found_text.disconnect(found_text_cb);
        controller.failed_to_find_text.disconnect(failed_to_find_text_cb);
        controller.counted_matches.disconnect(counted_matches_cb);
    }

    private void add_widget(Gtk.Widget widget) {
        var toolitem = new Gtk.ToolItem();
        toolitem.add(widget);
        add(toolitem);
    }

    private Gtk.Menu build_options_menu() {
        // TODO translate menu options
        var options_menu = new Gtk.Menu();
        var match_case = new Gtk.RadioMenuItem.with_label(null,
                                "Match Uppercase");
        match_case.activate.connect(() => {
            smartcase = false;
            options &= ~WebKit.FindOptions.CASE_INSENSITIVE;
            find_in_page();
        });
        options_menu.add(match_case);
        var ignore_case = new Gtk.RadioMenuItem.with_label(
                                match_case.get_group(), "Ignore Uppercase");
        ignore_case.activate.connect(() => {
            smartcase = false;
            options |= WebKit.FindOptions.CASE_INSENSITIVE;
            find_in_page();
        });
        options_menu.add(ignore_case);
        var auto_case = new Gtk.RadioMenuItem.with_label(
                                ignore_case.get_group(), "Auto");
        auto_case.active = true;
        auto_case.activate.connect(() => {
            smartcase = true;
            options &= ~WebKit.FindOptions.CASE_INSENSITIVE;
            find_in_page();
        });
        options_menu.add(auto_case);
        options_menu.add(new Gtk.SeparatorMenuItem());

        var cyclic = new Gtk.CheckMenuItem.with_label("Cyclic Search");
        cyclic.active = true;
        options |= WebKit.FindOptions.WRAP_AROUND;
        cyclic.toggled.connect(() => {
            toggle_option(WebKit.FindOptions.WRAP_AROUND, cyclic.active);
        });
        options_menu.add(cyclic);
        var wordstart = new Gtk.CheckMenuItem.with_label("Match Word Start");
        wordstart.active = false;
        wordstart.toggled.connect(() => {
            toggle_option(WebKit.FindOptions.AT_WORD_STARTS, wordstart.active);
        });
        options_menu.add(wordstart);
        // If the user doesn't know what CamelCase means,
        // they probably don't want this option. (note the hint in it's name)
        var camelCase = new Gtk.CheckMenuItem.with_label("Match CamelCase");
        camelCase.active = false;
        camelCase.toggled.connect(() => {
            toggle_option(WebKit.FindOptions.TREAT_MEDIAL_CAPITAL_AS_WORD_START,
                            camelCase.active);
        });
        options_menu.add(camelCase);

        options_menu.show_all();
        return options_menu;
    }

    private void position_menu_below(Gtk.Menu menu,
                                    out int x, out int y, out bool push_in) {
        Gtk.Allocation menu_allocation;
        menu.get_allocation (out menu_allocation);

        menu_button.get_window ().get_origin (out x, out y);

        Gtk.Allocation allocation;
        menu.get_allocation (out allocation);

        /* position center */
        x += allocation.x;
        x += menu_allocation.width / 2;
        x += allocation.width / 2;

        int width, height;
        menu.get_size_request (out width, out height);

        y += allocation.y;
        y += 16;

        push_in = true;
    }

    private void find_in_page() {
        var flags = options;
        var max_count = 500; // something suitably large
        if (smartcase) {
            // AKA match case if it's mixed.
            if (search.text.down() == search.text
                    || search.text.up() == search.text) {
                flags |= WebKit.FindOptions.CASE_INSENSITIVE;
            }
        }

        controller.search(search.text, flags, max_count);
        controller.count_matches(search.text, flags, max_count);
    }

    private void toggle_option(WebKit.FindOptions opt, bool active) {
        if (active) {
            options |= opt;
        } else {
            options &= ~opt;
        }

        find_in_page();
    }

    private void find_normal_color() {
        var entry_context = new Gtk.StyleContext();
        var entry_path = new Gtk.WidgetPath();
        entry_path.append_type(typeof (Gtk.Widget));
        entry_context.set_path(entry_path);
        entry_context.add_class("entry");
        this.normal_color = entry_context.get_color(Gtk.StateFlags.FOCUSED);
    }

    private void found_text_cb(uint match_count) {
        search.override_color(Gtk.StateFlags.NORMAL, normal_color);
    }

    private void failed_to_find_text_cb() {
        search.override_color(Gtk.StateFlags.NORMAL, {1.0, 0.0, 0.0, 1.0});
    }

    /* Without this event handler, pressing next & prev gives counts of 1 */
    private void counted_matches_cb(uint match_count) {
        // TODO output somewhere
    }

    public override void grab_focus() {
        search.grab_focus();
    }
}
