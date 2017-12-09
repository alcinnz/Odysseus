namespace Odysseus {
    private static string build_config_path(string subdir) {
        return Path.build_path(Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir(), "odysseus", subdir);
    }

    private static WebKit.WebContext web_ctxt = null;

    public WebKit.WebContext get_web_context() {
        if (web_ctxt != null) return web_ctxt;

        var data_manager = Object.@new(typeof(WebKit.WebsiteDataManager),
                "base_cache_directory", build_config_path("site-cache"),
                "base_data_directory", build_config_path("site-data"),
                "disk_cache_directory", build_config_path("http-cache"),
                "indexeddb_directory", build_config_path("indexeddb"),
                "local_storage_directory", build_config_path("localstorage"),
                "offline_application_cache_directory", build_config_path("offline-cache"),
                "websql_directory", build_config_path("websql")
                ) as WebKit.WebsiteDataManager;
        web_ctxt = new WebKit.WebContext.with_website_data_manager(data_manager);
        web_ctxt.get_cookie_manager().set_persistent_storage(build_config_path("cookies.sqlite"),
                WebKit.CookiePersistentStorage.SQLITE);
        web_ctxt.set_favicon_database_directory(build_config_path("favicons"));
        web_ctxt.set_process_model(WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES);

        Traits.setup_context(web_ctxt);

        return web_ctxt;
    }
}
namespace Odysseus.Traits {
    private void setup_settings(WebKit.WebView web) {
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
        settings.media_playback_requires_user_gesture = false;
        settings.print_backgrounds = true;
        settings.set_user_agent_with_application_details("Odysseus",
                Odysseus.Application.instance.build_version);
        settings.zoom_text_only = false;
        web.settings = settings;
    }
}
