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
        application_id = "io.github.alcinnz.Odysseus";
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.textdomain ("odysseus");

        app_launcher = "io.github.alcinnz.odysseus.desktop";
        program_name = "Odysseus";
        build_version = "0.3";
        exec_name = application_id = "io.github.alcinnz.odysseus";
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
        stdout.printf("STARTING...\n");
        // Setup application-unique resources.
        Odysseus.Database.setup_database();
        Odysseus.Traits.setup_autosuggest();

        // Restore application state.
        var stmt = Database.parse("SELECT MAX(delete_batch) FROM window;");
        var resp = stmt.step();
        assert(resp == Sqlite.ROW);
        Persist.delete_batch = stmt.column_int(0);

        string errmsg;
        var err = Database.get_database().exec(
                "SELECT ROWID FROM window WHERE delete_batch = %i;".printf(
                    Persist.delete_batch),
                build_window, out errmsg);
        if (err != Sqlite.OK) {
            // Remove faulty persistance, then crash.
            Database.get_database().exec("DELETE FROM window;", null);
            error("Failed to restore previous ");
        }

        // Create main application window, upon restore failure.
        if (get_last_window() == null) {
            var window = new BrowserWindow.from_new_entry();
            window.new_tab("https://alcinnz.github.io/Odysseus-recommendations/");
            window.show_all();

            ignore_NewWindow = has_NewWindow_arg;
        }
    }

    public static bool has_NewWindow_arg = false;
    public static bool ignore_NewWindow = false;
    public override void open(File[] files, string hint) {
        var window = get_last_window();
        foreach (var file in files) {
            if (file.get_uri() == NewWindow_url) {
                if (!ignore_NewWindow) {
                    window = new BrowserWindow.from_new_entry();
                    window.new_tab();
                    window.show_all();
                }
                ignore_NewWindow = false;
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

    private int build_window(int n_columns, string[] values, string[] column_names) {
        (new BrowserWindow(int64.parse(values[0]))).show_all();
        return 0;
    }

    public BrowserWindow? get_last_window() {
        unowned List<weak Gtk.Window> windows = get_windows();
        return windows.length() > 0 ?
                windows.last().data as BrowserWindow : null;
    }
}

const string NewWindow_url = "odysseus:///NewWindow";
public static int main(string[] args) {
    // It's a bit of a hack to use a URI to open new windows,
    // which means we need to be able to cancel these URIs. 
    Odysseus.Application.has_NewWindow_arg = NewWindow_url in args;

    return Odysseus.Application.instance.run(args);
}
