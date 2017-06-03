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
public class Oddysseus.Application : Granite.Application {
    construct {
        this.flags |= ApplicationFlags.HANDLES_OPEN;
        this.flags |= ApplicationFlags.HANDLES_COMMAND_LINE;
        application_id = "io.github.alcinnz.Oddysseus";
        Intl.setlocale (LocaleCategory.ALL, "");
        Intl.textdomain ("oddysseus");

        program_name = "Oddysseus";
        app_years = "2016-2017";
        app_icon = "oddysseus-web";
        app_launcher = "oddysseus.desktop";
        main_url = "https://github.com/alcinnz/Oddysseus";
        bug_url = "https://github.com/alcinnz/Oddysseus/issues";
        translate_url = "https://poeditor.com/join/project/6VytorOTQY";
        about_authors = { "Adrian Cochrane <alcinnz@eml.cc>", null };
        about_license_type = Gtk.License.GPL_3_0;
    }
    
    private static Oddysseus.Application _instance = null;
    public static Oddysseus.Application instance {
        get {
            if (_instance == null)
                _instance = new Oddysseus.Application();
            return _instance;
        }
    }
    
    public override int command_line(ApplicationCommandLine cmdline) {
        var context = new OptionContext("File");
        context.add_main_entries(entries, null);
        context.add_group(Gtk.get_option_group(true));
        
        string[] args = cmdline.get_arguments();
        int unclaimed_args;
        
        try {
            unowned string[] tmp = args;
            context.parse(ref tmp);
            unclaimed_args = tmp.length - 1;
        } catch(Error e) {
            print(e.message + "\n");
            
            return Posix.EXIT_FAILURE;
        }
        
        if (print_version) {
            stdout.printf("Oddysseus Web Browser version 0.1\n");
            stdout.printf("Copyright 2016 Adrian Cochrane\n");
            return Posix.EXIT_SUCCESS;
        }

        bool is_app_launch = (get_last_window() == null);
        if (is_app_launch) {
            /* Restore tabs */
            try {
                var file = File.new_for_commandline_arg_and_cwd(".oddysseus",
                                    Environment.get_home_dir());
                if (!file.query_exists()) {
                    new BrowserWindow(this).show_all();
                }

                var restoreFile = new DataInputStream(file.read());

                string? windowState;
                while ((windowState = restoreFile.read_line()) != null) {
                    new BrowserWindow.with_urls(this, windowState.split("\t"))
                        .show_all();
                }
            } catch (Error e) {
                warning("Failed to restore tabs: %s", e.message);
            }
        }
        
        // Create a next window if requested and it's not the app launch
        if (create_new_window && !is_app_launch) {
            create_new_window = false;
            var window = new BrowserWindow(this);
            window.show_all();
        }
        
        // Create new tab if requested
        // TODO Check if we're on a new tab
        if (create_new_tab) {
            create_new_tab = false;
            var window = get_last_window();
            window.new_tab();
        }
        
        // Open all URLs given as arguments
        if (unclaimed_args > 0) {
            var window = get_last_window();
            foreach (string arg in args[1:unclaimed_args + 1]) {
                window.new_tab(File.new_for_commandline_arg(arg).get_uri());
            }
        }

        return Posix.EXIT_SUCCESS;
    }

    public override void open(File[] files, string hint) {
        var window = get_last_window();
        if (window == null) return;

        foreach (var file in files) {
            window.new_tab(file.get_uri());
        }
    }

    public BrowserWindow? get_last_window() {
        unowned List<weak Gtk.Window> windows = get_windows();
        return windows.length() > 0 ?
                windows.last().data as BrowserWindow : null;
    }

    private static bool create_new_tab = false;
    private static bool create_new_window = false;
    private static bool print_version = false;
    const OptionEntry[] entries = {
        { "new-tab", 't', 0, OptionArg.NONE, out create_new_tab,
                "New Tab", null},
        { "new-window", 'n', 0, OptionArg.NONE, out create_new_window,
                "New Window", null},
        { "version", 'v', 0, OptionArg.NONE, out print_version,
                "Print version info and exit", null},
        { null }
    };
    
    // Called by windows when a tab navigates to a new page
    public async void persist() {
        try {
            var file = File.new_for_commandline_arg_and_cwd(".oddysseus",
                                Environment.get_home_dir());
            var persistFile = yield file.replace_async(null, false,
                FileCreateFlags.PRIVATE | FileCreateFlags.REPLACE_DESTINATION);
            foreach (var win in get_windows()) {
                var browser = win as BrowserWindow;
                if (browser != null) {
                    yield browser.persist(persistFile);
                    yield persistFile.write_async("\n".data);
                }
            }
        } catch (Error e) {
            warning("Failed to persist state: %s", e.message);
        }
    }
}

public static int main(string[] args) {
    Oddysseus.Traits.setup_autosuggest();
    return Oddysseus.Application.instance.run(args);
}
