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
/** Grays out the content on which it is overlaid.
    Used to indicate that window.alert(), etc JavaScript calls are synchronous.

This modality ofcourse isn't ideal, but it's there whether we like it or not.*/
public class Odysseus.Shades : Gtk.Widget {
    construct {
        expand = true;
        events = Gdk.EventMask.ALL_EVENTS_MASK;
        no_show_all = true;
        visible = false;
    }

    public override bool draw(Cairo.Context ctx) {
        ctx.set_source_rgba(0, 0, 0, 0.5);
        ctx.fill();
        return true;
    }
}
