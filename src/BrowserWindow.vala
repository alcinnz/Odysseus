/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016-2018).
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
    private WebKit.WebView web {get {return tabs.web;}}
    public WebNotebook tabs;
    private DownloadsBar downloads;
    public Odysseus.Header.AddressBar addressbar; // So it can be autofocused.

    public bool closing = false;

    public BrowserWindow(int64 window_id) {
        this.window_id = window_id;
        set_application(Odysseus.Application.instance);
        this.title = "";

        init_layout();
        Persist.register_notebook_events(this);
        Persist.restore_window_state(this);
    }

    public BrowserWindow.from_new_entry() {
        string errmsg;
        unowned Sqlite.Database db = Database.get_database();

        // Create DB record
        var err = db.exec("""INSERT INTO window
                    (x, y, width, height, state, focused_index)
                VALUES (-1, -1, 1200, 800, 'N', 0);""", null, out errmsg);
        if (err != Sqlite.OK || db.last_insert_rowid() == 0)
            error("Failed to INSERT new window into database: %s", errmsg);

        // Create Vala object
        this(db.last_insert_rowid());
    }

    const string app_id = "com.github.alcinnz.odysseus.desktop";
    private void init_layout() {
        tabs = new WebNotebook();
        var header = new Header.HeaderBarWithMenus();
        build_toolbar(header);
        set_titlebar(header);
        add_accel_group(header.accel_group);
        tabs.bind_property("title", this, "title");

        var container = new Overlay.InfoContainer();
        add(container);

        if (AppInfo.get_default_for_uri_scheme("http").get_id() != app_id)
            prompt_make_default.begin(container);

        // Don't show tabbar when fullscreen
        window_state_event.connect((evt) => {
            if (Gdk.WindowState.FULLSCREEN in evt.new_window_state) {
                tabs.tab_bar_behavior = DynamicNotebook.TabBarBehavior.NEVER;
                downloads.expand = false;
            } else tabs.tab_bar_behavior = DynamicNotebook.TabBarBehavior.ALWAYS;
            return false;
        });
        container.add(tabs);

        downloads = new DownloadsBar();
        downloads.expand = false;
        downloads.transition_type = Gtk.RevealerTransitionType.SLIDE_UP;
        container.add(downloads);
    }

    private async void prompt_make_default(Overlay.InfoContainer prompt) throws Error {
        var options = new Overlay.InfoContainer.MessageOptions();
        options.ok_text = _("Make Default");
        options.type = Gtk.MessageType.INFO;
        if (!yield prompt.message(_("Odysseus is not your default browser."), options)) return;

        // These are the same things Switchboard would register Odysseus for.
        var app_info = new DesktopAppInfo(app_id);
        app_info.set_as_default_for_type("x-scheme-handler/http");
        app_info.set_as_default_for_type("x-scheme-handler/https");
        app_info.set_as_default_for_type("text/html");
        app_info.set_as_default_for_extension("htm");
        app_info.set_as_default_for_extension("html");
        app_info.set_as_default_for_extension("shtml");
        app_info.set_as_default_for_type("application/xhtml+xml");
        app_info.set_as_default_for_extension("xht");
    }

    private void build_toolbar(Header.HeaderBarWithMenus tools) {
        var back = tools.add_item_left("go-previous-symbolic", _("Go to previously viewed page"),
                Gdk.Key.comma, () => web.go_back(), (menu) => {
            web.get_back_forward_list().get_back_list().@foreach((item) => {
                var opt = menu.add(item.get_title(), () => web.go_to_back_forward_list_item(item));
                favicon_for_menuitem.begin(opt, item);
            });
        }, true);
        tabs.bind_property("can-go-back", back, "sensitive", BindingFlags.SYNC_CREATE);
        var forward = tools.add_item_left("go-next-symbolic", _("Go to next viewed page"),
                Gdk.Key.period, () => web.go_forward(), (menu) => {
            web.get_back_forward_list().get_forward_list().@foreach((item) => {
                var opt = menu.add(item.get_title(), () => web.go_to_back_forward_list_item(item));
                favicon_for_menuitem.begin(opt, item);
            });
        }, true);
        tabs.bind_property("can-go-forward", forward, "sensitive", BindingFlags.SYNC_CREATE);

        var reload = tools.build_tool_item("view-refresh-symbolic", _("Load this page from the website again"),
                Gdk.Key.r, () => web.reload(), (menu) => {
            menu.add(_("Ignore cache"), () => web.reload_bypass_cache(), Gdk.Key.r,
                    Gdk.ModifierType.CONTROL_MASK | Gdk.ModifierType.SHIFT_MASK);
        });
        var stop = tools.build_tool_item("process-stop-symbolic", _("Stop loading this page"),
                Gdk.Key.q, () => web.stop_loading(), (menu) => {
            menu.add(_("Stop And Reload"), () => {web.stop_loading(); web.reload();});
        });
        var reload_stop = new Gtk.Stack();
        reload_stop.add_named (reload, "reload");
        reload_stop.add_named (stop, "stop");
        tabs.notify["is-loading"].connect((pspec) => {
            if (tabs.is_loading) reload_stop.set_visible_child(stop);
            else reload_stop.set_visible_child(reload);
        });
        tools.pack_start(reload_stop);

        addressbar = new Odysseus.Header.AddressBar();
        tools.size_allocate.connect((box) => addressbar.max_width = box.width);
        addressbar.tooltip_text = _("Current web address") + " (Ctrl+L)";
        addressbar.navigate_to.connect((url) => web.load_uri(url));
        tabs.bind_property("uri", addressbar.entry, "text", BindingFlags.SYNC_CREATE);
        tabs.bind_property("favicon", addressbar.entry, "primary-icon-gicon", BindingFlags.SYNC_CREATE);
        tabs.bind_property("progress", addressbar.entry, "progress-fraction", BindingFlags.SYNC_CREATE);
        tabs.indicators_loaded.connect(addressbar.show_indicators);
        tools.set_custom_title(addressbar);
        tools.shortcut(Gdk.Key.L, () => addressbar.entry.grab_focus());

        tools.add_item_right("open-menu", _("Menu"), 0, null, (menu) => {
            menu.add(_("_New Window"), () => {
                    var win = new BrowserWindow.from_new_entry();
                    win.new_tab();
                    win.show_all();
                }, Gdk.Key.N);
            menu.add(_("_Open"), () => {
                    foreach (var uri in prompt_file(Gtk.FileChooserAction.OPEN, _("_Open"))) new_tab(uri);
                }, Gdk.Key.O);
            menu.add(_("_Save"), () => {
                    foreach (var uri in prompt_file(Gtk.FileChooserAction.SAVE, _("_Save As")))
                        web.save_to_file.begin(File.new_for_uri(uri), WebKit.SaveMode.MHTML, null);
                }, Gdk.Key.S);
            menu.add(_("_View Source"), () => viewsource_activated.begin(), Gdk.Key.U);
            menu.separate();
            menu.add(_("Zoom In"), () => web.zoom_level += 0.1, Gdk.Key.plus);
            tools.shortcut(Gdk.Key.equal, () => web.zoom_level += 0.1);
            menu.add(_("Zoom Out"), () => web.zoom_level -= 0.1, Gdk.Key.minus);
            tools.shortcut(Gdk.Key.@0, () => web.zoom_level = 1.0);
            menu.separate();
            menu.add(_("_History"), () => new_tab("odysseus:history"), Gdk.Key.H);
            menu.separate();
            menu.add(_("_Find In Page"), () => (tabs.current as WebTab).find_in_page(), Gdk.Key.F);
            tools.shortcut(Gdk.Key.Escape, () => {
                (tabs.current as WebTab).close_find();
                unfullscreen();
            }, 0);
            menu.add(_("_Print"), () => new WebKit.PrintOperation(web).run_dialog(this), Gdk.Key.P);
            menu.separate();
            menu.add(_("Show Downloads"), () => downloads.set_reveal_child(true), Gdk.Key.D);
            var about_link = "appstream://com.github.alcinnz.odysseus";
            menu.add(_("About Odysseus"), () => Granite.Services.System.open_uri(about_link));
        });
        tools.shortcut(Gdk.Key.T, () => new_tab());
    }

    /* Implemented down here so it can be async */
    private async void viewsource_activated() {
        new_tab(yield Traits.view_source(web));
    }

    public SList<string> prompt_file(Gtk.FileChooserAction type, string ok_text,
            string selected_path = "") {
        var chooser = new Gtk.FileChooserNative(ok_text.replace("_", ""),
                this, type, ok_text, null);
        if (selected_path != "") chooser.set_filename(selected_path);

        var ret = new SList<string>();
        if (chooser.run() == Gtk.ResponseType.OK) {
            ret = chooser.get_uris();
        }
        chooser.destroy();
        return ret;
    }

    private async void favicon_for_menuitem(Gtk.ImageMenuItem menuitem,
                WebKit.BackForwardListItem item) {
        menuitem.always_show_image = true;
        try {
            var favicon_db = web.web_context.get_favicon_database();
            var favicon = yield favicon_db.get_favicon(item.get_uri(), null);
            var icon = ImageUtil.surface_to_pixbuf(favicon);
            menuitem.image = new Gtk.Image.from_gicon(icon, Gtk.IconSize.MENU);
        } catch (Error e) {
            warning("Failed to load favicon for '%s':", item.get_uri());
        }
    }
    
    public void new_tab(string url = "odysseus:home") {
        var tab = new WebTab.with_new_entry(tabs, url);
        tabs.insert_tab(tab, -1);
        tabs.current = tab;
    }


    public override void grab_focus() {
        web.grab_focus();
    }

    // Persistance code
    public int64 window_id = 0;
    protected override bool delete_event(Gdk.EventAny evt) {
        Persist.on_window_closed(this);
        return false;
    }
}
