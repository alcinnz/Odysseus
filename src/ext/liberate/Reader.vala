using Gtk;
using GLib;
using WebKit;

public class Liberate.Reader: Grid {

	protected WebKit.WebView view;
	protected WebKit.Settings settings;
	protected WebKit.UserContentManager content;
	
	public signal void progress (double fraction, bool ready);
	public string theme {get; set;}
	public string url {get; set;}

	construct {
		halign = Align.FILL;
		valign = Align.FILL;
		
		settings = new WebKit.Settings ();
		settings.enable_smooth_scrolling = true;
		settings.enable_javascript = false;
		settings.javascript_can_access_clipboard = false;
		settings.javascript_can_open_windows_automatically = false;
		settings.enable_java = false;
		settings.enable_media_stream = false;
		settings.enable_mediasource = false;
		settings.enable_plugins = false;
		settings.enable_html5_database = false;
		settings.enable_html5_local_storage = false;
		settings.enable_webaudio = false;
		settings.enable_webgl = false;

		content = new UserContentManager ();
		content.register_script_message_handler (HANDLER);

		view = new WebView.with_user_content_manager (content);
		view.expand = true;
		view.settings = settings;
		attach (view, 0, 0);
		view.visible = false;

		view.notify["estimated-load-progress"].connect (on_progress);
		notify["theme"].connect (() => {
			apply_theme (view, theme);
		});
		
		content.script_message_received.connect (result => {
			var msg = decode_message (result);
			if (msg != "")
				on_message (msg);
			else
				warning ("Caught JS error on receiving bridge message");
		});
		view.load_changed.connect (on_patch_request);
		
		notify["url"].connect (() => {
			debug ("Navigating to %s", url);
			view.load_uri (url);
		});
	}

	public Reader (string theme = "light") {
		this.theme = theme;
	}
	
	public Reader.with_url (string url, string theme = "light") {
		this.theme = theme;
		this.url = url;
	}

	protected bool on_message (string text) {
		debug ("Bridge message: %s", text);
		
		if (text == MSG_PATCHED) {
			progress (1, false);
			view.load_changed.disconnect (on_patch_request);
		}
		return true;
	}

	protected void on_progress () {
		progress (view.estimated_load_progress, view.is_loading);
	}

	protected void on_patch_request (LoadEvent ev) {
		if (ev != LoadEvent.FINISHED)
			return;

		debug ("Page load complete");
		settings.set_enable_javascript (true);
		Liberate.read (view, theme);
		view.visible = true;
	}

}
