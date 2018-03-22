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
public class Odysseus.Application : Granite.Application {
    construct {
        this.flags |= ApplicationFlags.HANDLES_OPEN;
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.textdomain ("odysseus");

        app_launcher = "com.github.alcinnz.odysseus.desktop";
        program_name = "Odysseus";
        build_version = "1";
        exec_name = application_id = "com.github.alcinnz.odysseus";
    }

    private static Odysseus.Application _instance = null;
    public static Odysseus.Application instance {
        get {
            if (_instance == null)
                _instance = new Odysseus.Application();
            return _instance;
        }
    }

    public void initialize() {
        // Ensure configuration folder exists
        try {
            var config = File.new_for_path(Environment.get_user_config_dir());
            config = config.get_child("com.github.alcinnz.odysseus");
            if (!config.query_exists()) config.make_directory_with_parents();
        } catch (Error err) {
            error("Failed to setup configuration directory!\n" +
                "Is ~/.config readonly?");
        }

        // Setup application-unique resources.
        var is_first_start = Odysseus.Database.setup_database();
        Odysseus.Traits.setup_autosuggest();

        // Create main application window, upon restore failure.
        if (is_first_start) {
            var window = new BrowserWindow.from_new_entry();
            /* TRANSLATORS: This is the link Odysseus opens on first launch.
                Feel free to set it to whatever works best for your locale. */
            window.new_tab(_("https://alcinnz.github.io/Odysseus-recommendations/"));
            window.show_all();
        } else Persist.restore_application();
    }

    public override void open(File[] files, string hint) {
        activate(); // To gaurantee the application is initialized.

        var window = get_last_window();
        foreach (var file in files) {
            if (file.get_uri() == "odysseus:///NewWindow" ||
                    file.get_uri() == "odysseus:NewWindow") {
                window = new BrowserWindow.from_new_entry();
                window.new_tab();
                window.show_all();
            } else window.new_tab(file.get_uri());
        }
    }

    private bool initialized = false;
    public override void activate() {
        if (!initialized) {
            initialize();
            initialized = true;
        }
    }

    public BrowserWindow? get_last_window() {
        unowned List<weak Gtk.Window> windows = get_windows();
        return windows.length() > 0 ?
                windows.last().data as BrowserWindow : null;
    }
}

public static int main(string[] args) {
    return Odysseus.Application.instance.run(args);
}
