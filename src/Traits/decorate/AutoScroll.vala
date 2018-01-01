/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2018).
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
/* Scroll by moving the dragging with a middle-click. 

This is a great help for reading long webpages (say, the upcoming odysseus:history),
    and is a common but not ubiquitous feature of other browsers. */
namespace Odysseus.Traits {
    public void setup_autoscroll(WebKit.WebView web) {
        double start_x = 0, start_y = 0, x = 0, y = 0;
        bool autoscroll_active = false;

        web.button_press_event.connect((evt) => {
            if (evt.button != 2 || autoscroll_active) return false;

            web.get_window().set_cursor(new Gdk.Cursor.from_name(Gdk.Display.get_default(), "move"));

            x = start_x = evt.x; y = start_y = evt.y;
            autoscroll_active = true;

            Timeout.add(100 /* 10 times per second*/, () => {
                // It's scroll using JavaScript than in Vala here...
                var js = "window.scrollBy(%f, %f)".printf(x - start_x, y - start_y);
                web.run_javascript.begin(js, null);
                return autoscroll_active;
            }); 
            return true;
        });

        web.motion_notify_event.connect((evt) => {
            if (!autoscroll_active) return false;

            x = evt.x; y = evt.y;
            return true;
        });

        web.button_release_event.connect((evt) => {
            if (!autoscroll_active) return false;

            web.get_window().set_cursor(null);
            autoscroll_active = false;
            return true;
        });
    }
}
