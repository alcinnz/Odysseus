public class Odysseus.BrowserWindow : Gtk.Window {
    private weak Odysseus.Application app;

    private WebKit.WebView web;
    private WebKit.WebContext web_context;
    private Granite.Widgets.DynamicNotebook tabs;

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
        this.title = "(Loading)";
        this.icon_name = "internet-web-browser";

        init_layout();
        register_events();
        create_accelerators();
    }

    private void init_layout() {
        back = new ButtonWithMenu.from_icon_name ("go-previous-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        forward = new ButtonWithMenu.from_icon_name ("go-next-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        reload = new Gtk.Button.from_icon_name ("view-refresh-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        stop = new Gtk.Button.from_icon_name ("process-stop-symbolic",
                                                Gtk.IconSize.LARGE_TOOLBAR);
        reload_stop = new Gtk.Stack();
        reload_stop.add_named (reload, "reload");
        reload_stop.add_named (stop, "stop");
        addressbar = new Odysseus.AddressBar();
        
        var appmenu_menu = new Gtk.Menu();
        // TODO translate
        var find_in_page = new Gtk.MenuItem.with_label("Find in page...");
        find_in_page.activate.connect(find_in_page_cb);
        appmenu_menu.add(find_in_page);
        var appmenu = new Granite.Widgets.AppMenu(appmenu_menu);

        Gtk.HeaderBar header = new Gtk.HeaderBar();
        header.show_close_button = true;
        header.pack_start(back);
        header.pack_start(forward);
        header.pack_start(reload_stop);
        header.set_custom_title(addressbar);
        header.pack_end(appmenu);
        header.set_has_subtitle(false);
        set_titlebar(header);

        tabs = new Granite.Widgets.DynamicNotebook();
        this.add(tabs);
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
        addressbar.activate.connect(() => {
            web.load_uri(addressbar.text);
        });

        tabs.tab_switched.connect((old_tab, new_tab) => {
            if (web != null) disconnect_webview();
            web = ((WebTab) new_tab).web;
            connect_webview();
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
    
    private void create_accelerators() {
        var accel = new Gtk.AccelGroup();
        accel.connect(Gdk.Key.F, Gdk.ModifierType.CONTROL_MASK,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
            find_in_page_cb();
            return true;
        });
        add_accel_group(accel);
    }

    private void connect_webview() {
        var hs = web_event_handlers;

        hs.add(web.load_changed.connect ((load_event) => {
            if (load_event == WebKit.LoadEvent.FINISHED) {
                back.sensitive = web.can_go_back();
                forward.sensitive = web.can_go_forward();
                reload_stop.set_visible_child(reload);
                addressbar.progress_fraction = 0.0;
            } else {
                reload_stop.set_visible_child(stop);
            }
        }));

        bindings.add(web.bind_property("uri", addressbar, "text"));
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
            error("Failed to load favicon for '%s':", item.get_uri());
        }
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
}
