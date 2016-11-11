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
    }

    public override void activate () {
        if (mainWindow == null) {
            mainWindow = new BrowserWindow(this);
        }
        mainWindow.show_all();
    }

    /* TODO Handle HTTP(S) URLs */
}

public static int main(string[] args) {
    var application = new Odysseus.Application();
    return application.run(args);
}
