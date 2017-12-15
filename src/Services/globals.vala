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
/** Contains code to construct miscellaneous globals, particularly the WebContext
    and any configuration folders. */
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

        Traits.setup_context(web_ctxt);
        return web_ctxt;
    }
}
