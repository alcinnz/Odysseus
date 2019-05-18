using WebKit;

namespace Liberate {

	protected const string RESOURCES_PATH = "/com/github/bleakgrey/liberate/";
	protected const string DEP_READABLE = "Readability-readerable.js";
	protected const string DEP_IS_READABLE = "is_readable.js";

	public const string HANDLER = "liberate";
	public const string MSG_PATCHED = "liberate:done";
	public const string MSG_READABLE = "liberate:readable";

 	protected const string[] READER_MODE_DEPS = {
 		DEP_READABLE,
 		"Readability.js",
 		"patcher.js",
 		"theme-light.css",
 		"theme-solarized.css",
 		"theme-moonlight.css"
 	};

	public static string[] get_themes () {
		return {"light", "solarized", "moonlight"};
	}

	static string read_resource (string name) {
		var res = GLib.resources_lookup_data (RESOURCES_PATH + name, ResourceLookupFlags.NONE);
		return (string)res.get_data ();
	}

	static inline string to_vala_string (global::JS.String js) {
		size_t len = js.get_maximum_utf8_cstring_size ();
		uint8[] str = new uint8[len];
		js.get_utf8_cstring (str);
		return (string) str;
	}

	static string decode_message (JavascriptResult result) {
		unowned JS.GlobalContext ctx = result.get_global_context ();
		unowned JS.Value js_str_value = result.get_value ();
		JS.Value? err = null;
		JS.String js_str = js_str_value.to_string_copy (ctx, out err);

		if (err == null)
			return to_vala_string (js_str);
		else {
			warning ("Caught JS error on receiving bridge message");
			return "";
		}
	}

	public delegate void IsReadableCallback ();
	public static void on_readable (WebView view, IsReadableCallback cb) {
		var content = view.user_content_manager;
		content.register_script_message_handler (HANDLER);
		content.script_message_received.connect (result => {
			if (decode_message (result) == MSG_READABLE)
				cb ();
		});

		view.load_changed.connect ((ev) => {
			if (ev != LoadEvent.FINISHED)
				return;

			var source = read_resource (DEP_READABLE) + read_resource (DEP_IS_READABLE);
			view.run_javascript.begin (source, null);
		});
	}

	static void inject (WebView view, string[] resources) {
		var content = view.user_content_manager;
		foreach (string name in resources) {
			var source = read_resource (name);
			if (".css" in name) {
				var stylesheet = new UserStyleSheet (source,
					UserContentInjectedFrames.TOP_FRAME,
					UserStyleLevel.USER, null, null);

				content.add_style_sheet (stylesheet);
			}
			else {
				view.run_javascript.begin (source, null);
			}
		}
	}

	public static void apply_theme (WebView view, string name) {
		view.run_javascript.begin ("var reader_theme=\""+name+"\"; theme(\""+name+"\");", null);
	}

	public static void read (WebView view, string theme = "light") {
		if (view.is_loading)
			view.stop_loading ();

		ulong id = 0;
		id = view.load_changed.connect ((ev) => {
			if (ev != LoadEvent.STARTED)
				return;

			debug ("Unloading injected content");
			view.user_content_manager.remove_all_style_sheets ();
			view.disconnect (id);
		});

		inject (view, READER_MODE_DEPS);
		apply_theme (view, theme);
	}

}
