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
public class Oddysseus.WebTab : Granite.Widgets.Tab {
    public static WebKit.WebContext? global_context;

    private static string build_config_path(string subdir) {
        return Path.build_path(Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir(), "oddysseus", subdir);
    }

    public static void init_global_context() {
        var data_manager = Object.@new(typeof(WebKit.WebsiteDataManager),
                "base_cache_directory", build_config_path("site-cache"),
                "base_data_directory", build_config_path("site-data"),
                "disk_cache_directory", build_config_path("http-cache"),
                "indexeddb_directory", build_config_path("indexeddb"),
                "local_storage_directory", build_config_path("localstorage"),
                "offline_application_cache_directory",
                    build_config_path("offline-cache"),
                "websql_directory", build_config_path("websql")
                ) as WebKit.WebsiteDataManager;
        global_context = new WebKit.WebContext.with_website_data_manager(
                data_manager);
        global_context.get_cookie_manager().set_persistent_storage(
                build_config_path("cookies.sqlite"),
                WebKit.CookiePersistentStorage.SQLITE);
        global_context.set_favicon_database_directory(
                build_config_path("favicons"));

        global_context.register_uri_scheme("oddysseus",
                Oddysseus.Services.handle_oddysseus_uri);
        global_context.register_uri_scheme("source",
                Oddysseus.Traits.handle_source_uri);
        DownloadsBar.setup_context(global_context);
    }

    public WebKit.WebView web; // To allow it to be wrapped in layout views. 
    private Gtk.Revealer find;
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
                  string uri = "https://ddg.gg/") {
        if (global_context == null) init_global_context();

        if (related != null) {
            this.web = (WebKit.WebView) related.new_with_related_view();
        } else {
            var user_content = new WebKit.UserContentManager();
            this.web = (WebKit.WebView) Object.@new(typeof(WebKit.WebView),
                    "web-context", global_context,
                    "user-content-manager", user_content);
        }
        var container = new Gtk.Overlay();
        container.add(this.web);
        this.page = container;

        // Avoid taking too much screen realestate away from the page.
        // That's why we're using an overlay
        var find_toolbar = new FindToolbar(web.get_find_controller());
        find_toolbar.counted_matches.connect((search, count) => {
            if (find.child_revealed && search != "")
                this.status = "%u matches of \"%s\" found".printf(count, search);
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
            var fav = BrowserWindow.surface_to_pixbuf(web.get_favicon());
            icon = fav.scale_simple(16, 16, Gdk.InterpType.BILINEAR);
        });
        web.bind_property("is-loading", this, "working");

        web.create.connect((nav_action) => {
            var tab = new WebTab(parent, web, nav_action.get_request().uri);
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
                stderr.printf("%s\n", failing_uri);
                Granite.Services.System.open_uri(failing_uri);
                return true;
            }
            return false;
        });

        Traits.setup_webview(this);

        configure();
        web.load_uri(uri);
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

    private void configure() {
        var settings = new WebKit.Settings();
        settings.allow_file_access_from_file_urls = true;
        settings.allow_modal_dialogs = true;
        settings.allow_universal_access_from_file_urls = false;
        settings.auto_load_images = true;
        settings.default_font_family = Gtk.Settings.get_default().gtk_font_name;
        settings.enable_caret_browsing = false;
        settings.enable_developer_extras = true;
        settings.enable_dns_prefetching = true;
        settings.enable_frame_flattening = false;
        settings.enable_fullscreen = true;
        settings.enable_html5_database = true;
        settings.enable_html5_local_storage = true;
        settings.enable_java = false;
        settings.enable_javascript = true;
        settings.enable_offline_web_application_cache = true;
        settings.enable_page_cache = true;
        settings.enable_plugins = false;
        settings.enable_resizable_text_areas = true;
        settings.enable_site_specific_quirks = true;
        settings.enable_smooth_scrolling = true;
        settings.enable_spatial_navigation = false;
        settings.enable_tabs_to_links = true;
        settings.enable_xss_auditor = true;
        settings.javascript_can_access_clipboard = true;
        settings.javascript_can_open_windows_automatically = false;
        settings.load_icons_ignoring_image_load_setting = true;
        settings.media_playback_allows_inline = true;
        settings.media_playback_requires_user_gesture = true;
        settings.print_backgrounds = true;
        // Use Safari's user agent so as to avoid standing out to trackers
        //      and having sites warn that we're using a unpopular browser.
        // Use Safair's, as opposed to FireFox, as we're both using WebKit.
        settings.user_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9) AppleWebKit/537.71 (KHTML, like Gecko) Version/7.0 Safari/537.71";
        settings.zoom_text_only = false;
        web.settings = settings;
    }
}
