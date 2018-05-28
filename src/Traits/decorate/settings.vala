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
namespace Odysseus.Traits {
    public void configure_context(WebKit.WebContext web_ctx) {
        web_ctxt.get_cookie_manager().set_persistent_storage(build_config_path("cookies.sqlite"),
                WebKit.CookiePersistentStorage.SQLITE);
        web_ctxt.set_favicon_database_directory(build_config_path("favicons"));
        web_ctxt.set_process_model(WebKit.ProcessModel.MULTIPLE_SECONDARY_PROCESSES);
    }

    public void setup_settings(WebKit.WebView web) {
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
        Templating.HTTP.FetchTag.user_agent = settings.user_agent;
        settings.zoom_text_only = false;
        web.settings = settings;
    }
}
