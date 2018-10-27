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
/** This class abstracts away common UI structures used in the Odysseus
    headerbar. Specifically the headerbar is mostly made up of ToolButtons
    which show a menu at least on hold or right-click. 

To aid that sort of UI, this class both allows specifying toolbar icons, tooltips,
    actions, keyboard shortcuts and menus in one declaration; as well as
    MenuItem titles, actions, & shortcuts in one internal declaration. Both these
    operations may implicitly add the item, and will return it for additional
    customization.

Also this is a normal headerbar, so all everything that's normally possible is
    still possible and just as easy. This is vital to allow for controls like
    the AddressBar. */
public class Odysseus.Header.HeaderBarWithMenus : Gtk.HeaderBar {
    public Gtk.AccelGroup accel_group = new Gtk.AccelGroup();

    construct {
        show_close_button = true;
        set_has_subtitle(false);
    }

    public delegate void Action();
    public delegate void BuildMenu(MenuBuilder builder);
    public ButtonWithMenu build_tool_item(string icon, string tooltip,
            uint key, owned Action? action, owned BuildMenu build_menu,
            Gdk.ModifierType modifier = Gdk.ModifierType.CONTROL_MASK,
            bool dynamic_menu = false) {
        var item = new ButtonWithMenu.from_icon_name(icon + "-symbolic", Gtk.IconSize.LARGE_TOOLBAR);
        item.tooltip_text = tooltip;
        if (key != 0) item.tooltip_text += " (%s)".printf(
                Gtk.accelerator_get_label(key, modifier));

        Action normalized_action = () => item.popup_menu();
        if (action != null) normalized_action = action;
        item.button_release_event.connect(() => {
            normalized_action();
            return true;
        });

        if (dynamic_menu) {
            // Set fetcher to call build_menu
            item.fetcher = () => {
                var builder = new MenuBuilder();
                build_menu(builder);
                builder.menu.show_all();
                return builder.menu;
            };
        } else {
            // Call build_menu and set menu
            var builder = new MenuBuilder();
            builder.accel_group = accel_group;
            build_menu(builder);
            builder.menu.show_all();
            item.menu = builder.menu;
        }

        if (key != 0 && action != null)
            accel_group.connect(key, modifier,
                    Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                    (group, acceleratable, key, modifier) => {
                action();
                return true;
            });

        return item;
    }
    public ButtonWithMenu add_item_left(string icon, string tooltip,
            uint key, owned Action? action, owned BuildMenu build_menu,
            bool dynamic_menu = false) {
        var item = build_tool_item(icon, tooltip, key, action, build_menu,
                Gdk.ModifierType.CONTROL_MASK, dynamic_menu);
        pack_start(item);
        return item;
    }
    public ButtonWithMenu add_item_right(string icon, string tooltip,
            uint key, owned Action? action, owned BuildMenu build_menu,
            bool dynamic_menu = false) {
        var item = build_tool_item(icon, tooltip, key, action, build_menu,
                Gdk.ModifierType.CONTROL_MASK, dynamic_menu);
        pack_end(item);
        return item;
    }

    public class MenuBuilder : Object {
        public Gtk.Menu menu = new Gtk.Menu();
        public Gtk.AccelGroup? accel_group = null;

        public Gtk.ImageMenuItem add(string title, owned Action action, uint key = 0,
                Gdk.ModifierType modifier = Gdk.ModifierType.CONTROL_MASK) {
            var item = new Gtk.ImageMenuItem.with_mnemonic(title);
            item.activate.connect(() => {action();});
            menu.add(item);

            if (accel_group != null && key != 0) {
                accel_group.connect(key, modifier,
                        Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                        (group, acceleratable, key, modifier) => {
                    action();
                    return true;
                });
                item.tooltip_text = Gtk.accelerator_get_label(key, modifier);
            }

            return item;
        }

        public void separate() {
            menu.add(new Gtk.SeparatorMenuItem());
        }
    }

    public void shortcut(uint key, owned Action action,
            Gdk.ModifierType mod = Gdk.ModifierType.CONTROL_MASK) {
        accel_group.connect(key, mod, Gtk.AccelFlags.VISIBLE | Gtk.AccelFlags.LOCKED,
                (group, acceleratable, key, modifier) => {
            action();
            return true;
        });
    }
}
