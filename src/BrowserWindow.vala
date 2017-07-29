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
using Granite.Widgets;
public class Odysseus.BrowserWindow : Gtk.ApplicationWindow {
    private weak Odysseus.Application app;

    private WebKit.WebView web;
    private Granite.Widgets.DynamicNotebook tabs;
    private DownloadsBar downloads;

    private ButtonWithMenu back;
    private ButtonWithMenu forward;
    private Gtk.Button reload;
    private Gtk.Button stop;
    private Gtk.Stack reload_stop;
    private AddressBar addressbar;

    private Gee.List<ulong> web_event_handlers;
    private Gee.List<Binding> bindings;

    public BrowserWindow(Odysseus.Application ody_app) {
        this.app = ody_app;
        set_application(this.app);
        this.title = "";

        init_layout();
        register_events();
        set_default_size(1200, 800);
    }
    
    public BrowserWindow.with_urls(Odysseus.Application ody_app, string[] urls) {
        this(ody_app);
        foreach (var url in urls) new_tab(url);
    }

    private void init_layout() {
        back = new ButtonWithMenu.from_icon_name ("go-previous-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        back.tooltip_text = _("Go to previously viewed page");
        forward = new ButtonWithMenu.from_icon_name ("go-next-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        forward.tooltip_text = _("Go to next viewed page");
        reload = new Gtk.Button.from_icon_name ("view-refresh-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        reload.tooltip_text = _("Load the page from the website again");
        stop = new Gtk.Button.from_icon_name ("process-stop-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        stop.tooltip_text = _("Stop loading page");
        reload_stop = new Gtk.Stack();
        reload_stop.add_named (reload, "reload");
        reload_stop.add_named (stop, "stop");
        addressbar = new Odysseus.AddressBar();
        addressbar.tooltip_text = _("Current web address");

        var appmenu = new Granite.Widgets.AppMenu(create_appmenu());

        Gtk.HeaderBar header = new Gtk.HeaderBar();
        header.show_close_button = true;
        header.pack_start(back);
        header.pack_start(forward);
        header.pack_start(reload_stop);
        header.set_custom_title(addressbar);
        header.pack_end(appmenu);
        header.set_has_subtitle(false);
        set_titlebar(header);

        var container = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        add(container);

        tabs = new Granite.Widgets.DynamicNotebook();
        // Don't show tabbar when fullscreen
        window_state_event.connect((evt) => {
            if (Gdk.WindowState.FULLSCREEN in evt.new_window_state)
                tabs.tab_bar_behavior = DynamicNotebook.TabBarBehavior.NEVER;
            else tabs.tab_bar_behavior = DynamicNotebook.TabBarBehavior.ALWAYS;
            return false;
        });
        tabs.allow_drag = true;
        //tabs.allow_duplication = true; // TODO implement
        tabs.allow_new_window = true;
        tabs.allow_pinning = true;
        //tabs.allow_restoring = true; // TODO implement
        tabs.group_name = "odysseus-web-browser";
        container.pack_start(tabs);
        
        downloads = new DownloadsBar();
        downloads.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        container.pack_end(downloads, false);
    }
    
    private Gtk.Menu create_appmenu() {
        var accel = new Gtk.AccelGroup();
        var menu = new Gtk.Menu();

        accel.connect(Gdk.Key.T, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            new_tab();
            return true;
        });

        // TRANSLATORS _ precedes the keyboard shortcut
        var new_window = new Gtk.MenuItem.with_mnemonic(_("_New Window"));
        new_window.activate.connect(() => {
            var window = new BrowserWindow(Odysseus.Application.instance);
            window.show_all();
        });
        menu.add(new_window);
        accel.connect(Gdk.Key.N, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            new_window.activate();
            return true;
        });

        // TRANSLATORS _ precedes the keyboard shortcut
        var open = new Gtk.MenuItem.with_mnemonic(_("_Open..."));
        open.activate.connect(() => {
            var chooser = new Gtk.FileChooserDialog(
                                _("Open Local Webpage"),
                                this,
                                Gtk.FileChooserAction.OPEN,
                                _("_Cancel"), Gtk.ResponseType.CANCEL,
                                _("_Open"), Gtk.ResponseType.OK);
            chooser.filter.add_mime_type("text/html");
            chooser.filter.add_mime_type("application/xhtml+xml");
            chooser.filter.add_pattern("*.html");
            chooser.filter.add_pattern("*.htm");
            chooser.filter.add_pattern("*.xhtml");

            if (chooser.run() == Gtk.ResponseType.OK) {
                foreach (string uri in chooser.get_uris()) {
                    new_tab(uri);
                }
            }
            chooser.destroy();
        });
        menu.add(open);
        accel.connect(Gdk.Key.O, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            open.activate();
            return true;
        });

        // TRANSLATORS _ precedes the keyboard shortcut
        var save = new Gtk.MenuItem.with_mnemonic(_("_Save..."));
        save.activate.connect(() => {
            var chooser = new Gtk.FileChooserDialog(
                                _("Save Page as"),
                                this,
                                Gtk.FileChooserAction.SAVE,
                                _("_Cancel"), Gtk.ResponseType.CANCEL,
                                _("_Save As"), Gtk.ResponseType.OK);

            if (chooser.run() == Gtk.ResponseType.OK) {
                web.save_to_file.begin(File.new_for_uri(chooser.get_uri()),
                                                    WebKit.SaveMode.MHTML, null);
            }
            chooser.destroy();
        });
        menu.add(save);
        accel.connect(Gdk.Key.S, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            save.activate();
            return true;
        });

        // TRANSLATORS _ precedes the keyboard shortcut
        var view_source = new Gtk.MenuItem.with_mnemonic(_("_View Source"));
        view_source.activate.connect(() => {
            var tab = new WebTab(tabs, web, "about:blank");
            tabs.insert_tab(tab, -1);
            Traits.view_source.begin(web, tab.web);
        });
        menu.add(view_source);
        accel.connect(Gdk.Key.U, Gdk.ModifierType.CONTROL_MASK,
                Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                (group, acceleratable, key, modifier) => {
            view_source.activate();
            return true;
        });

        menu.add(new Gtk.SeparatorMenuItem());

        var zoomin = new Gtk.MenuItem.with_mnemonic(_("Zoom in"));
        zoomin.activate.connect(() => {
            web.zoom_level += 0.1;
        });
        menu.add(zoomin);
        accel.connect(Gdk.Key.plus, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            zoomin.activate();
            return true;
        });
        accel.connect(Gdk.Key.equal, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            // So users can press ctrl-= instead of ctrl-shift-=
            zoomin.activate();
            return true;
        });

        var zoomout = new Gtk.MenuItem.with_mnemonic(_("Zoom out"));
        zoomout.activate.connect(() => {
            web.zoom_level -= 0.1;
        });
        menu.add(zoomout);
        accel.connect(Gdk.Key.minus, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            zoomout.activate();
            return true;
        });

        accel.connect(Gdk.Key.@0, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            web.zoom_level = 1.0;
            return true;
        });

        menu.add(new Gtk.SeparatorMenuItem());

        // TRANSLATORS _ precedes the keyboard shortcut
        var find_in_page = new Gtk.MenuItem.with_mnemonic(_("_Find In Page..."));
        find_in_page.activate.connect(find_in_page_cb);
        menu.add(find_in_page);
        accel.connect(Gdk.Key.F, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            find_in_page.activate();
            return true;
        });

        // TRANSLATORS _ precedes the keyboard shortcut
        var print = new Gtk.MenuItem.with_mnemonic(_("_Print..."));
        print.activate.connect(() => {
            var printer = new WebKit.PrintOperation(web);
            printer.run_dialog(this);
        });
        menu.add(print);
        accel.connect(Gdk.Key.P, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            print.activate();
            return true;
        });
        
        add_accel_group(accel);
        menu.show_all();
        return menu;
    }

    private void register_events() {
        web_event_handlers = new Gee.ArrayList<ulong>();
        bindings = new Gee.ArrayList<Binding>();

        back.button_release_event.connect((e) => {
            web.go_back();
            return false;
        });
        forward.button_release_event.connect((e) => {
            web.go_forward();
            return false;
        });
        back.fetcher = () => {
            var history = web.get_back_forward_list();
            return build_history_menu(history.get_back_list());
        };
        forward.fetcher = () => {
            var history = web.get_back_forward_list();
            return build_history_menu(history.get_forward_list());
        };
        reload.clicked.connect(() => {web.reload();});
        stop.clicked.connect(() => {web.stop_loading();});
        addressbar.navigate_to.connect((url) => {
            web.load_uri(url);
        });

        tabs.tab_switched.connect((old_tab, new_tab) => {
            if (web != null) disconnect_webview();
            web = ((WebTab) new_tab).web;
            connect_webview((WebTab) new_tab);
        });
        tabs.new_tab_requested.connect(() => {
            var tab = new WebTab(tabs);
            tabs.insert_tab(tab, -1);
            tabs.current = tab;
        });
        // Ensure a tab is always open
        tabs.tab_removed.connect((tab) => {
            if (tabs.n_tabs == 0) tabs.new_tab_requested();
        });
        tabs.show.connect(() => {
            if (tabs.n_tabs == 0) tabs.new_tab_requested();
        });
    }

    private void connect_webview(WebTab tab) {
        var hs = web_event_handlers;

        hs.add(web.load_changed.connect ((load_event) => {
            if (load_event == WebKit.LoadEvent.COMMITTED) {
                back.sensitive = web.can_go_back();
                forward.sensitive = web.can_go_forward();
            } else if (load_event == WebKit.LoadEvent.FINISHED) {
                reload_stop.set_visible_child(reload);
                addressbar.progress_fraction = 0.0;
                app.persist.begin();
            } else {
                reload_stop.set_visible_child(stop);
            }
        }));

        bindings.add(web.bind_property("uri", addressbar, "text"));
        hs.add(web.notify["uri"].connect((pspec) => {
            Idle.add(() => {
                // This works better with history.push/pop_state().
                back.sensitive = web.can_go_back();
                forward.sensitive = web.can_go_forward();
                return Source.REMOVE;
            });
        }));
        bindings.add(web.bind_property("title", this, "title"));
        bindings.add(web.bind_property("estimated-load-progress", addressbar,
                            "progress-fraction"));
        hs.add(web.notify["favicon"].connect((sender, property) => {
            if (web.get_favicon() != null) {
                var fav = surface_to_pixbuf(web.get_favicon());
                addressbar.primary_icon_pixbuf = fav;
            }
        }));

        // Replicate tab state to headerbar
        back.sensitive = web.can_go_back();
        forward.sensitive = web.can_go_forward();
        reload_stop.set_visible_child(web.is_loading ? stop : reload);
        addressbar.progress_fraction = web.estimated_load_progress == 1.0 ?
                0.0 : web.estimated_load_progress;
        addressbar.text = web.uri;
        this.title = web.title;
        if (web.get_favicon() != null) {
            var fav = surface_to_pixbuf(web.get_favicon());
            addressbar.primary_icon_pixbuf = fav;
        } else {
            addressbar.primary_icon_name = "internet-web-browser";
        }
    }

    private void disconnect_webview() {
        foreach (var binding in bindings) {
            binding.unbind();
        }
        bindings.clear();

        foreach (var handler in web_event_handlers) {
            web.disconnect(handler);
        }
        web_event_handlers.clear();
    }
    
    private void find_in_page_cb() {
        var current_tab = (WebTab) tabs.current;
        current_tab.find_in_page();
    }

    private Gtk.Menu build_history_menu(
                List<weak WebKit.BackForwardListItem> items) {
        var menu = new Gtk.Menu();

        items.@foreach((item) => {
            var menuItem = new Gtk.ImageMenuItem.with_label(item.get_title());
            menuItem.activate.connect(() => {
                web.go_to_back_forward_list_item(item);
            });
            favicon_for_menuitem.begin(menuItem, item);
            menuItem.always_show_image = true;

            menu.add(menuItem);
        });
        
        menu.show_all();
        return menu;
    }

    private async void favicon_for_menuitem(Gtk.ImageMenuItem menuitem,
                WebKit.BackForwardListItem item) {
        try {
            var favicon_db = web.web_context.get_favicon_database();
            var favicon = yield favicon_db.get_favicon(item.get_uri(), null);
            var icon = surface_to_pixbuf(favicon);
            menuitem.image = new Gtk.Image.from_gicon(icon, Gtk.IconSize.MENU);
        } catch (Error e) {
            warning("Failed to load favicon for '%s':", item.get_uri());
        }
    }
    
    public void new_tab(string url = "https://ddg.gg/") {
        var tab = new WebTab(tabs, null, url);
        tabs.insert_tab(tab, -1);
        tabs.current = tab;
    }

    // GDK does provide a utility for this,
    // but it requires me to specify size information I do not have.
    public static Gdk.Pixbuf? surface_to_pixbuf(Cairo.Surface surface) {
        try {
            var loader = new Gdk.PixbufLoader.with_mime_type("image/png");
            surface.write_to_png_stream((data) => {
                try {
                    loader.write((uint8[]) data);
                } catch (Error e) {
                    return Cairo.Status.DEVICE_ERROR;
                }
                return Cairo.Status.SUCCESS;
            });
            var pixbuf = loader.get_pixbuf();
            loader.close();
            return pixbuf;
        } catch (Error e) {
            return null;
        }
    }
    
    // Called by application to persist open tabs
    public async void persist(OutputStream persistFile) {
        var first = true;
        foreach (var tab in tabs.tabs) {
            try {
                if (!first) yield persistFile.write_async("\t".data);
                first = false;

                size_t bytes_written;
                var url = ((WebTab) tab).url;
                yield persistFile.write_all_async(url.data,
                                                Priority.DEFAULT,
                                                null, out bytes_written);
            } catch (Error e) {
                // The file should still work reasonably well. 
                // The separator must be successful written before the url is,
                // and if that isn't fully written things should still work.
                var url = ((WebTab) tab).url;
                warning("Failed to write tab for %s: %s", url, e.message);
            }
        }
    }

    public override void grab_focus() {
        web.grab_focus();
    }
}
