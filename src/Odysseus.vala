/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016).
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
public class Odysseus.Application : Granite.Application {

    public BrowserWindow mainWindow;

    construct {
        application_id = "com.github.alcinnz.odysseus";
        flags = ApplicationFlags.FLAGS_NONE;
        /*Intl.setlocale (LocaleCategory.ALL, "");
        Intl.textdomain (Build.GETTEXT_PACKAGE);*/

        program_name = "Odysseus";
        app_years = "2016";

        /* TODO specify more metadata */
        app_icon = "internet-web-browser";
        app_launcher = "odysseus.desktop";
        main_url = "https://github.com/alcinnz/Odysseus";
        bug_url = "https://github.com/alcinnz/Odysseus/issues";
        about_authors = { "Adrian Cochrane <alcinnz@eml.cc>", null };
        about_license_type = Gtk.License.GPL_3_0;
    }
    
    private static Odysseus.Application _instance = null;
    public static Odysseus.Application instance {
        get {
            if (_instance == null)
                _instance = new Odysseus.Application();
            return _instance;
        }
    }

    public override void activate () {
        if (mainWindow == null) {
            mainWindow = new BrowserWindow(this);
        }
        mainWindow.show_all();
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
            stdout.printf("Odysseus Web Browser version 0.1\n");
            stdout.printf("Copyright 2016 Adrian Cochrane\n");
            return Posix.EXIT_SUCCESS;
        }
        
        // Create (or show) the first window
        activate();
        
        // Create a next window if requested and it's not the app launch
        bool is_app_launch = (get_last_window() == null);
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
            // TODO Open given URLs
            File[] files = new File[unclaimed_args];
            files.length = 0;
            
            foreach (string arg in args[1:unclaimed_args + 1]) {
                try {
                    files += File.new_for_uri(arg);
                } catch (Error e) {
                    warning(e.message);
                }
            }
            open(files, "");
        }
        
        return Posix.EXIT_SUCCESS;
    }

    protected override void open(File[] files, string hint) {
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
}

public static int main(string[] args) {
    return Odysseus.Application.instance.run(args);
}
