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
/** The primary purpose of this widget is to allow binding to various 
    properties of the currently active webview.

This is tricky not just because we want to treat a mutating variable like a
    constant but also because the WebKit.WebView fails to properly notify us
    of changes to certain properties. */
using Granite.Widgets;
public class Odysseus.WebNotebook : DynamicNotebook {
    public bool can_go_back {get; set;}
    public bool can_go_forward {get; set;}
    public bool is_loading {get; set;}
    public double progress {get; set;}
    public string uri {get; set;}
    public Icon? favicon {get; set;}
    public string title {get; set;}

    public WebKit.WebView? web {
        get {
            if (current == null) return null;
            return (current as WebTab).web;
        }
    }

    construct {
        allow_drag = allow_duplication = allow_new_window = true;
        allow_pinning = allow_restoring = true;
        group_name = "io.github.alcinnz.Odysseus";

        // If all else fails, poll for history changes. 
        Timeout.add_seconds(1, () => {
            can_go_back = web.can_go_back();
            can_go_forward = web.can_go_forward();
            return true;
        }, Priority.DEFAULT_IDLE);

        // Register event handlers on self (doing so implicitly fails to compile).
        new_tab_requested.connect(on_new_tab_requested);
        tab_duplicated.connect(on_tab_duplicated);
        tab_restored.connect(on_tab_restored);
        tab_moved.connect(on_tab_moved);
        tab_removed.connect(on_tab_removed);
        tab_switched.connect(on_tab_switched);
    }

    public void on_new_tab_requested() {
        var tab = new WebTab.with_new_entry(this);
        insert_tab(tab, -1);
        current = tab;
    }

    public void on_tab_duplicated(Tab tab) {
        var t = new WebTab.rebuild_existing(this, tab.label, tab.icon, tab.restore_data);
        insert_tab(t, -1);
        current = t;
    }

    public void on_tab_restored(string label, string data, Icon? icon) {
        var t = new WebTab.rebuild_existing(this, label, icon, data);
        insert_tab(t, -1);
        current = t;
    }

    public void on_tab_moved(Tab tab, int x, int y) {
        var window = new BrowserWindow.from_new_entry();
        window.show_all();
        Idle.add(() => {
          remove_tab(tab);
          window.tabs.insert_tab(tab, -1);
          window.move(x, y);

          return false;
        });
    }

    public void on_tab_removed(Tab tab) {
        var window = get_toplevel() as BrowserWindow;
        if (n_tabs == 0 && window != null && !window.closing)
            new_tab_requested();
    }

    public void on_tab_switched(Tab? old_tab, Tab new_tab) {
        var old_wtab = old_tab as WebTab;
        if (old_wtab != null) disconnect_webview(old_wtab);
        var new_wtab = new_tab as WebTab;
        if (new_wtab != null) connect_webview(new_wtab);
    }

    private Gee.List<Binding> bindings = new Gee.ArrayList<Binding>();
    private Gee.List<ulong> handlers = new Gee.ArrayList<ulong>();

    private void connect_webview(WebTab tab) {
        var web = tab.web;
        handlers.add(web.load_changed.connect((load_evt) => {
            switch (load_evt) {
            case WebKit.LoadEvent.COMMITTED:
                can_go_back = web.can_go_back();
                can_go_forward = web.can_go_forward();
                break;
            case WebKit.LoadEvent.FINISHED:
                is_loading = false;
                progress = 0.0;
                break;
            default:
                is_loading = true;
                break;
            }
        }));

        bindings.add(
            web.bind_property("uri", this, "uri", BindingFlags.SYNC_CREATE));
        handlers.add(web.notify["uri"].connect((pspec) => {
            // This does a modest job of capturing dynamically added history entries.
            Idle.add(() => {
                can_go_back = web.can_go_back();
                can_go_forward = web.can_go_forward();

                return Source.REMOVE;
            });
        }));

        bindings.add(
            web.bind_property("title", this, "title", BindingFlags.SYNC_CREATE));
        bindings.add(
            web.bind_property("estimated-load-progress", this, "progress",
                BindingFlags.SYNC_CREATE));
        bindings.add(
            tab.bind_property("coloured_icon", this, "favicon", BindingFlags.SYNC_CREATE));
        bindings.add(
            web.bind_property("is-loading", this, "is-loading",
                BindingFlags.SYNC_CREATE));

        can_go_back = web.can_go_back();
        can_go_forward = web.can_go_forward();
        if (progress == 1.0) progress = 0.0;
    }

    private void disconnect_webview(WebTab tab) {
        var web = tab.web;

        foreach (var binding in bindings) {
            binding.unbind();
        }
        bindings.clear();

        foreach (var handler in handlers) {
            web.disconnect(handler);
        }
        handlers.clear();
    }
}
