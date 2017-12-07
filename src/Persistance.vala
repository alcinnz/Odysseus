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
}
