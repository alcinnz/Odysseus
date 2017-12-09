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

}
