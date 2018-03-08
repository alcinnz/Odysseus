/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016-2018).
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
/** Improved window for WebInspector, which doesn't duplicate the headerbar. */
public class Odysseus.Chromeless : Gtk.Window {
    public Chromeless(WebKit.WebInspector inspector) {
        var titlebar = new Gtk.HeaderBar();
        set_titlebar(titlebar);
        titlebar.no_show_all = true;

        title = "Web Inspector — " + inspector.inspected_uri;
        add(inspector.get_web_view());

        inspector.closed.connect(() => this.destroy());
        inspector.attach.connect(() => {
            remove(inspector.get_web_view());
            this.destroy();
            return false;
        });

        inspector.get_web_view().button_press_event.connect ((e) => {
            if (e.type == Gdk.EventType.@2BUTTON_PRESS && e.button == Gdk.BUTTON_PRIMARY) {
                begin_move_drag ((int) e.button, (int) e.x_root, (int) e.y_root, e.time);
                return true;
            }
            return false;
        });
    }
}
