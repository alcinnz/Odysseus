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
public class Odysseus.StatusIndicator : Object {
    public string icon;
    public enum Classification {
        SECURE, ERROR, ENABLED, DISABLED, ACTIVE
    }
    public Classification status {get; set;}

    public StatusIndicator(string icon, Classification status) {
        this.icon = icon; this.status = status;
    }
    public Gtk.Widget build_ui() {
        Icon icon = new ThemedIcon(icon);
        Gdk.RGBA colour = Gdk.RGBA();
        switch (status) {
        case Classification.SECURE:
            icon = emblem(icon, "process-completed");
            colour.parse("#68b723");
            break;
        case Classification.ERROR:
            if (this.icon != "error" && this.icon != "error-symbolic")
                icon = emblem(icon, "error");
            colour.parse("#c6262e");
            break;
        case Classification.ENABLED:
            icon = emblem(icon, "list-remove");
            colour.parse("#3689e6");
            break;
        case Classification.DISABLED:
            icon = emblem(icon, "list-add");
            colour.parse("#333333");
            break;
        case Classification.ACTIVE:
            colour.parse("#f37329");
            break;
        }

        var iconinfo = Gtk.IconTheme.get_default().lookup_by_gicon(icon, 16,
                Gtk.IconLookupFlags.FORCE_SYMBOLIC);
        try {
            var coloured_icon = iconinfo.load_symbolic(colour);

            return new Gtk.Image.from_pixbuf(coloured_icon);
        } catch (Error err) {
            return new Gtk.Image.from_gicon(icon, Gtk.IconSize.SMALL_TOOLBAR);
        }
    }
    private static Icon emblem(Icon icon, string name) {
        return new EmblemedIcon(icon, new Emblem(new ThemedIcon(name + "-symbolic")));
    }
}
