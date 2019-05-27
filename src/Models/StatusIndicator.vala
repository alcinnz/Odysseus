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
public enum Odysseus.Status {
    SECURE, ERROR, ENABLED, DISABLED, ACTIVE
}
public class Odysseus.StatusIndicator : Object {
    public string icon;
    public Status status {get; set;}
    public string text;

    public delegate Gtk.Popover? OnPressed(Object? dat);
    public Object user_data; // Closures haven't been working reliably.
    public OnPressed? on_pressed;

    public StatusIndicator(string icon, Status status, string text,
            OnPressed? on_pressed = null) {
        this.icon = icon; this.status = status; this.text = text;
        this.on_pressed = on_pressed;
    }
    public Gtk.Popover? tooltip_popover() {
        var label = new Gtk.Label(this.text);
        label.margin = 20;
        var popover = new Gtk.Popover(null);
        popover.add(label);
        return popover;
    }

    public void bullet_point(string msg) {
        text += "\n • " + msg;
    }

    public Gtk.Widget build_ui() {
        var ret = new Gtk.Button();
        ret.image = build_image();

        ret.clicked.connect(() => {
            var popover = on_pressed != null ? on_pressed(user_data) : tooltip_popover();
            ret.image = build_image();

            if (popover == null) return;
            popover.relative_to = ret;
            popover.show_all();
        });

        // Force elementary to render the borders, they're necessary for visual clarity.
        var style = ret.get_style_context();
        style.remove_class("image-button");
        style.changed.connect(() => style.remove_class("image-button"));
        style.add_class("entry");

        ret.halign = Gtk.Align.CENTER;
        ret.valign = Gtk.Align.BASELINE;
        ret.tooltip_text = text;
        return ret;
    }
    private Gtk.Image build_image() {
        Icon icon = new ThemedIcon.from_names(icon.split(" "));
        Gdk.RGBA colour = Gdk.RGBA();
        switch (status) {
        case Status.SECURE:
            icon = emblem(icon, "process-completed");
            colour.parse("#68b723");
            break;
        case Status.ERROR:
            if (this.icon != "error" && this.icon != "error-symbolic")
                icon = emblem(icon, "error");
            colour.parse("#c6262e");
            break;
        case Status.ENABLED:
            icon = emblem(icon, "list-remove");
            colour.parse("#3689e6");
            break;
        case Status.DISABLED:
            icon = emblem(icon, "list-add");
            colour.parse("#333333");
            break;
        case Status.ACTIVE:
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
