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

/** This code handles the concern of keeping browser state persisted to disk
    in case of crash. 

It is integrated directly into windows and tabs. */
namespace Odysseus.Persist {
    public bool restore_application() {
        var stmt = Database.parse("SELECT MAX(delete_batch) FROM window;");
        var resp = stmt.step();
        if (resp != Sqlite.ROW) return false;
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

        return true;
    }

    private int build_window(int n_columns, string[] values, string[] column_names) {
        (new BrowserWindow(int64.parse(values[0]))).show_all();
        return 0;
    }

    /* Window persistance */
    public static int delete_batch = 0;
    public static bool in_batch = true;

    public void on_window_closed(BrowserWindow win) {
        // Read window state...
        var state = win.get_window().get_state();
        string window_state;
        int width = 1200, height = 800;
        if (Gdk.WindowState.MAXIMIZED in state) window_state = "M";
        else {
            window_state = "N"; // 'N'ormal
            win.get_size(out width, out height);
        }

        int x, y;
        win.get_position(out x, out y);

        // then save it to disk
        var stmt = Database.parse("""UPDATE window
                SET x=?, y=?, width=?, height=?, state=?, delete_batch=?
                WHERE ROWID = ?;""");
        stmt.bind_int(1, x);
        stmt.bind_int(2, y);
        stmt.bind_int(3, width);
        stmt.bind_int(4, height);
        stmt.bind_text(5, window_state);
        stmt.bind_int(6, delete_batch);
        stmt.bind_int64(7, win.window_id);
        stmt.step();

        win.closing = true;
        in_batch = true;
    }

    public void on_browse() {
        if (in_batch) {
            in_batch = false;
            delete_batch++;
        }
    }

    public void restore_window_state(BrowserWindow win) {
        var stmt = Database.parse("""SELECT x, y, width, height, state, focused_index
                FROM window
                WHERE window.ROWID = ?;""");
        stmt.bind_int64(1, win.window_id);
        var resp = stmt.step();
        assert(resp == Sqlite.ROW);

        win.set_default_size(stmt.column_int(2), stmt.column_int(3));
        switch (stmt.column_text(4)) {
        case "M":
            win.maximize();
            break;
        default:
            if (stmt.column_int(0) == -1 || stmt.column_int(1) == -1) break;
            win.move(stmt.column_int(0), stmt.column_int(1));
            break;
        }

        var Qtabs = Database.parse(
                "SELECT ROWID FROM tab WHERE window_id = ? ORDER BY order_ ASC;");
        Qtabs.bind_int64(1, win.window_id);
        while (Qtabs.step() == Sqlite.ROW) {
            win.tabs.insert_tab(new WebTab(win.tabs, Qtabs.column_int64(0)), -1);
        }

        win.tabs.current = win.tabs.get_tab_by_index(stmt.column_int(5));
    }

    /* Notebook Persistance */
    public void register_notebook_events(BrowserWindow win) {
        Granite.Widgets.DynamicNotebook tabs = win.tabs;

        var Qupdate_window = Database.parse(
                "UPDATE tab SET window_id = ? WHERE ROWID = ?;");
        tabs.tab_added.connect((tab) => {
            var wtab = (WebTab) tab;
            Qupdate_window.reset();
            Qupdate_window.bind_int64(1, win.window_id);
            Qupdate_window.bind_int64(2, wtab.tab_id);
            Qupdate_window.step();

            persist_tab_order(tabs);
        });
        var Qdelete_tab = Database.parse("DELETE FROM tab WHERE ROWID = ?;");
        tabs.tab_removed.connect((tab) => {
            if (win.closing) return; // We want to persist them then. 

            var wtab = (WebTab) tab;
            Qdelete_tab.reset();
            Qdelete_tab.bind_int64(1, wtab.tab_id);
            Qdelete_tab.step();

            persist_tab_order(tabs);
        });
        tabs.tab_reordered.connect((tab, new_pos) => {
            persist_tab_order(tabs);
        });
        var Qupdate_focused_tab = Database.parse(
                "UPDATE window SET focused_index = ? WHERE ROWID = ?;");
        tabs.tab_switched.connect((old_tab, new_tab) => {
            Qupdate_focused_tab.reset();
            Qupdate_focused_tab.bind_int(1, tabs.get_tab_position(new_tab));
            Qupdate_focused_tab.bind_int64(2, win.window_id);
            Qupdate_focused_tab.step();
        });
    }

    private void persist_tab_order(Granite.Widgets.DynamicNotebook tabs) {
        var Qsave_index = Database.parse(
                "UPDATE tab SET order_ = ? WHERE ROWID = ?;");

        int i = 0;
        for (var tab = tabs.get_tab_by_index(i) as WebTab;
                tab != null;
                tab = tabs.get_tab_by_index(++i) as WebTab) {
            if (tab.order == i) continue;
            Qsave_index.reset();
            Qsave_index.bind_int(1, i);
            Qsave_index.bind_int64(2, tab.tab_id);
            Qsave_index.step();
            tab.order = i;
        }
    }

    /* Tab persistance */
    private void setup_tab(WebTab tab, Granite.Widgets.DynamicNotebook tabs) {
        ulong on_add_registration = 0;
        on_add_registration = tabs.tab_added.connect((added) => {
            if (added != tab) return;
            Idle.add(() => {
                restore_tab_state(tab); register_tab_events(tab);
                return false;
            });
            tabs.disconnect(on_add_registration);
        });
    }

    private static Sqlite.Statement? Qsave_pinned;
    private void register_tab_events(WebTab tab) {
        if (Qsave_pinned == null)
            Qsave_pinned = Database.parse(
                    "UPDATE tab SET pinned = ? WHERE ROWID = ?;");
        tab.notify["pinned"].connect((pspec) => {
            var window = tab.get_toplevel() as BrowserWindow;
            if (window == null || window.closing) return;
            Qsave_pinned.reset();
            Qsave_pinned.bind_int(1, tab.pinned ? 1 : 0);
            Qsave_pinned.bind_int64(2, tab.tab_id);
            Qsave_pinned.step();
        });
    }

    private static Sqlite.Statement? Qsave_restore_data;
    // Called by persist-tab-history trait.
    public void save_restore_data(WebTab tab) {
        if (Qsave_restore_data == null)
            Qsave_restore_data = Database.parse(
                    "UPDATE tab SET history = ? WHERE ROWID = ?;");

        Qsave_restore_data.reset();
        Qsave_restore_data.bind_text(1, tab.restore_data);
        Qsave_restore_data.bind_int64(2, tab.tab_id);
        Qsave_restore_data.step();
    }

    private static Sqlite.Statement? Qload_state;
    private void restore_tab_state(WebTab tab) {
        if (Qload_state == null)
            Qload_state = Database.parse(
                    "SELECT pinned, history, order_ FROM tab WHERE ROWID = ?");
        Qload_state.reset();
        Qload_state.bind_int64(1, tab.tab_id);
        var resp = Qload_state.step();
        assert(resp == Sqlite.ROW);

        tab.pinned = Qload_state.column_int(0) != 0;
        tab.restore_data = Qload_state.column_text(1);
        tab.order = Qload_state.column_int(2);

        var parser = new Json.Parser();
        try {
            parser.load_from_data(tab.restore_data);
            var root = parser.get_root();
            //tab.web.load_uri(root.get_object().get_string_member("current"));
            Services.render_alternate_html.begin(tab, "restore",
                    root.get_object().get_string_member("current"));
        } catch (Error err) {
            tab.web.load_uri("odysseus:errors/crashed");
        }
    }
}
