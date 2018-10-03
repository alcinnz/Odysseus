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
        SECURITY, ERROR, ENABLED, DISABLED, ACTIVE
    }
    public Classification status {get; set;}

    public StatusIndicator(string icon, Classification status) {
        this.icon = icon; this.status = status;
    }
    public Gtk.Widget build_ui() {
        Icon icon = new ThemedIcon(icon);
        switch (status) {
        case Classification.SECURITY:
            icon = emblem(icon, "process-completed");
            break;
        case Classification.ERROR:
            if (this.icon != "error" && this.icon != "error-symbolic")
                icon = emblem(icon, "error");
            break;
        case Classification.ENABLED:
            icon = emblem(icon, "list-remove");
            break;
        case Classification.DISABLED:
            icon = emblem(icon, "list-add");
            break;
        case Classification.ACTIVE:
            icon = emblem(icon, "open-menu");
            break;
        }

        return new Gtk.Image.from_gicon(icon, Gtk.IconSize.SMALL_TOOLBAR);
    }
    private static Icon emblem(Icon icon, string name) {
        return new EmblemedIcon(icon, new Emblem(new ThemedIcon(name + "-symbolic")));
    }
}
