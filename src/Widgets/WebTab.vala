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
public class Odysseus.WebTab : Granite.Widgets.Tab {
    public WebKit.WebView web; // To allow it to be wrapped in layout views.
    private Gtk.Revealer find;
    public InfoContainer info; // for prompts.

    public int64 tab_id;
    public int order = -1;

    public string url {
        get {return web.uri;}
    }
    private Granite.Widgets.OverlayBar status_bar;
    public string status {
        get {return status_bar.status;}
        set {
            status_bar.status = value;
            status_bar.visible = value != "";
        }
    }

    public WebTab(Granite.Widgets.DynamicNotebook parent,
                  WebKit.WebView? related = null,
                  int64 tab_id) {
        this.tab_id = tab_id;

        var user_content = new WebKit.UserContentManager();
        this.web = (WebKit.WebView) Object.@new(typeof(WebKit.WebView),
                "web-context", get_web_context(),
                "user-content-manager", user_content);

        this.info = new InfoContainer();
        info.expand = true;
        this.page = info;

        var container = new Gtk.Overlay();
        container.expand = true;
        container.add(this.web);
        info.add(container);


        // Avoid taking too much screen realestate away from the page.
        // That's why we're using an overlay
        var find_toolbar = new FindToolbar(web.get_find_controller());
        find_toolbar.counted_matches.connect((search, count) => {
            if (find.child_revealed && search != "")
                /// Translators. "%u" will be replaced with the number of matches
                /// while %s will be replaced with the text being searched for.
                this.status = _("%u matches of \"%s\" found").printf(
                        count, search);
            else this.status = "";
        });
        find_toolbar.escape_pressed.connect(() => {
            find.reveal_child = false;
        });
        find = new Gtk.Revealer();
        find.notify["reveal-child"].connect((pspec) => {
            if (!find.reveal_child) {
                this.status = "";
                web.get_find_controller().search_finish();
            } else find_toolbar.grab_focus();
        });
        find.add(find_toolbar);
        find.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        find.halign = Gtk.Align.END;
        find.valign = Gtk.Align.START;
        container.add_overlay(find);
        find.show_all();

        status_bar = new Granite.Widgets.OverlayBar(container);
        status_bar.visible = false;
        status_bar.no_show_all = true;

        web.bind_property("title", this, "label");
        web.notify["favicon"].connect((sender, property) => {
            restore_favicon();
        });
        web.bind_property("is-loading", this, "working");

        web.create.connect((nav_action) => {
            var tab = new WebTab.with_new_entry(parent, web, nav_action.get_request().uri);
            parent.insert_tab(tab, -1);
            parent.current = tab;
            return tab.web;
        });
        web.button_press_event.connect((evt) => {
            find.set_reveal_child(false);
            return false;
        });
        web.grab_focus.connect(() => {
            find.set_reveal_child(false);
        });
        web.mouse_target_changed.connect((target, modifiers) => {
            if (target.context_is_link()) {
                status = target.link_uri;
            } else status = "";
        });

        web.load_failed.connect((load_evt, failing_uri, err) => {
            // 101 = CANNOT_SHOW_URI
            if (err.matches(WebKit.PolicyError.quark(), 101)) {
                Granite.Services.System.open_uri(failing_uri);
                return true;
            }
            return false;
        });
        web.load_changed.connect((load_evt) => {
            Persist.on_browse();
        });

        this.page.show_all();

        Traits.setup_webview(this);
        Persist.setup_tab(this, parent);
    }

    private static Sqlite.Statement? Qinsert_new;
    public WebTab.with_new_entry(Granite.Widgets.DynamicNotebook parent,
                  WebKit.WebView? related = null,
                  string uri = "odysseus:home") {
        var history_json = @"{\"current\": \"$(uri.escape())\"}";
        if (Qinsert_new == null)
            Qinsert_new = Database.parse("""INSERT
                    INTO tab(window_id, order_, pinned, history)
                    VALUES (?, -1, 0, ?);""");
        Qinsert_new.reset();
        var window = parent.get_toplevel() as BrowserWindow;
        Qinsert_new.bind_int64(1, window.window_id);
        Qinsert_new.bind_text(2, history_json);

        var resp = Qinsert_new.step();
        this(parent, related, Database.get_database().last_insert_rowid());
    }

    public WebTab.rebuild_existing(Granite.Widgets.DynamicNotebook parent,
                    string title, Icon? icon, string history_json,
                    WebKit.WebView? related = null) {
        if (Qinsert_new == null)
            Qinsert_new = Database.parse("""INSERT
                    INTO tab(window_id, order_, pinned, history)
                    VALUES (?, -1, 0, ?);""");
        Qinsert_new.reset();
        var window = parent.get_toplevel() as BrowserWindow;
        Qinsert_new.bind_int64(1, window.window_id);
        Qinsert_new.bind_text(2, history_json);

        var resp = Qinsert_new.step();
        this(parent, related, Database.get_database().last_insert_rowid());

        this.label = title;
        if (icon != null) this.icon = icon;
    }

    public void restore_favicon() {
        var fav = BrowserWindow.surface_to_pixbuf(web.get_favicon());
        icon = fav.scale_simple(16, 16, Gdk.InterpType.BILINEAR);
    }

    public void find_in_page() {
        if (!find.has_focus || !find.child_revealed) {
            find.set_reveal_child(true);
            find.get_child().grab_focus();
        } else {
            find.set_reveal_child(false);
            web.grab_focus();
        }
    }
}
