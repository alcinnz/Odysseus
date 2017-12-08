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
            win.tabs.insert_tab(new WebTab(win.tabs, null, Qtabs.column_int64(0)), -1);
        }

        win.tabs.current = win.tabs.get_tab_by_index(stmt.column_int(5));
    }

    /* Notebook Persistance */
    public void register_notebook_events(BrowserWindow win) {
        var tabs = win.tabs;

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
        }
    }
}
