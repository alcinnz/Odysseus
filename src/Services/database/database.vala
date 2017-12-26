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
/** Maintains access to a global database for use by the chrome and internal pages. */
namespace Odysseus.Database {
    private Sqlite.Database? main_db;
    public unowned Sqlite.Database get_database() {
        return main_db;
    }

    private class ProsodyPipeSQLite : Templating.Writer, Object {
        // NOTE: This Writer doesn't like SQL statements
        //      being split up by templating.
        public async void write(Bytes text) {
            yield writes(Templating.ByteUtils.to_string(text));
        }
        public async void writes(string text) {
            string err_msg;
            var err = get_database().exec(text, null, out err_msg);
            if (err != Sqlite.OK)
                error("Failed to execute SQL: %s: %s", err_msg, text);
        }
    }

    public bool setup_database() {
        if (main_db != null) return false; // Doesn't need initialization.

        var db_path = Path.build_path(Path.DIR_SEPARATOR_S,
                Environment.get_user_config_dir(), "com.github.alcinnz.odysseus", "ui.sqlite");
        var err = Sqlite.Database.open(db_path, out main_db);
        if (err != Sqlite.OK)
            error("Failed to load UI state! " + main_db.errmsg());

        // Upgrade the database from whatever version it was
        var errmsg = "";
        int version = 0;
        err = main_db.exec("PRAGMA user_version;", (n, values, columns) => {
            version = int.parse(values[0]);
            stdout.printf("%i\n", version);
            var raw_data = Templating.ByteUtils.create_map<Templating.Data.Data>();
            raw_data[Templating.ByteUtils.from_string("v")] =
                    new Templating.Data.Literal(version);
            var data = new Templating.Data.Mapping(raw_data);

            var upgrade_path = "/io/github/alcinnz/Odysseus/database/init.sql";
            Templating.ErrorData? error_data = null;
            var template = Templating.get_for_resource(upgrade_path, ref error_data);
            if (error_data != null)
                error("Failed to parse init script's templating!");

            var writer = new ProsodyPipeSQLite();
            var loop = new MainLoop();
            template.exec.begin(data, writer, (obj, res) => loop.quit());
            loop.run();

            return 0;
        }, out errmsg);
        if (err != Sqlite.OK)
            error("Failed to read UI database version! " + errmsg);
        return version == 0;
    }
}
