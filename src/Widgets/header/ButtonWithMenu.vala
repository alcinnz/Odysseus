/***
This code comes from Pantheon Files (with minor changes made by Adrian Cochrane 
in 2016) under the following license:
    Copyright (c) 2011-2013 Mathijs Henquet

    This program or library is free software; you can redistribute it
    and/or modify it under the terms of the GNU Lesser General Public
    License as published by the Free Software Foundation; either
    version 3 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
    Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General
    Public License along with this library; if not, write to the
    Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301 USA.

    Authors: Mathijs Henquet <mathijs.henquet@gmail.com>,
             ammonkey <am.monkeyd@gmail.com>
***/

/*
 * ButtonWithMenu
 * - support long click / right click with depressed button states
 * - activate a GtkAction if any or popup a menu.
 * (used in history navigation buttons next/prev, appmenu)
 *
 */

namespace Odysseus.Header {

    /**
     * ButtonWithMenu
     * - support long click / right click with depressed button states
     * - activate a GtkAction if any or popup a menu
     * (used in history navigation buttons and the AppMenu)
     */
    public class ButtonWithMenu : Gtk.ToggleButton {

        public signal void right_click (Gdk.EventButton ev);

        /**
         * VMenuPosition:
         */
        public enum VMenuPosition {
            /**
             * TOP: Align the menu at top of button position.
             */
            TOP,
            /**
             * TOP: Align the menu at top of button position.
             */
            BOTTOM
        }

        /**
         * HMenuPosition:
         */
        public enum HMenuPosition {
            /**
             * LEFT: Left-align the menu relative to the button's position.
             */
            LEFT,
            /**
             * CENTER: Center-align the menu relative to the button's position.
             */
            CENTER,
            /**
             * RIGHT: Right-align the menu relative to the button's position.
             */
            RIGHT,
            /**
             * INSIDE_WINDOW: Keep the menu inside the GtkWindow. Center-align when possible.
             */
            INSIDE_WINDOW // center by default but move it the menu goes out of the window
        }

        public HMenuPosition horizontal_menu_position { get; set; default = HMenuPosition.CENTER; }
        public VMenuPosition vertical_menu_position { get; set; default = VMenuPosition.BOTTOM; }

        public ulong toggled_sig_id;

        /**
         * Delegate function used to populate menu
         */
        public delegate Gtk.Menu MenuFetcher ();

        public signal void slow_press ();

        public MenuFetcher fetcher {
            set {
                _fetcher = value;
                has_fetcher = true;
            }
            get {
                return _fetcher;
            }
        }

        public Gtk.Menu menu {
            get {
                return _menu;
            }
            set {
                if (has_fetcher) {
                    warning ("Don't set the menu property on a ToolMenuButton when there is already a menu fetcher");
                }
                else {
                    _menu = value;
                    update_menu_properties ();
                }
            }
        }

        private int LONG_PRESS_TIME = Gtk.Settings.get_default ().gtk_double_click_time * 2;
        private uint timeout = 0;
        private uint last_click_time = 0;
        private bool has_fetcher = false;

        private unowned MenuFetcher _fetcher;
        private Gtk.Menu _menu;

        public ButtonWithMenu.from_icon_name (string icon_name, Gtk.IconSize size) {
            this ();
            image = new Gtk.Image.from_icon_name (icon_name, size);
        }

        private void update_menu_properties () {
            menu.attach_to_widget (this, null);
            menu.deactivate.connect ( () => {
                deactivate_menu ();
            });
            menu.deactivate.connect (popdown_menu);
        }

        public ButtonWithMenu () {
            use_underline = true;
            can_focus = true;

            this.menu = new Gtk.Menu ();

            mnemonic_activate.connect (on_mnemonic_activate);

            events |= Gdk.EventMask.BUTTON_PRESS_MASK
                   |  Gdk.EventMask.BUTTON_RELEASE_MASK;

            button_press_event.connect (on_button_press_event);
            button_release_event.connect (on_button_release_event);
        }

        public override void show_all () {
            menu.show_all ();
            base.show_all ();
        }

        private void deactivate_menu () {
            active = false;
        }

        private bool on_button_release_event (Gdk.EventButton ev) {
            if (ev.time - last_click_time < LONG_PRESS_TIME) {
                slow_press ();
                active = false;
            }

            if (timeout > 0) {
                Source.remove (timeout);
                timeout = 0;
            }

            return false;
        }

        private bool on_button_press_event (Gdk.EventButton ev) {
            /* If the button is kept pressed, don't make the user wait when there's no action */
            int max_press_time = LONG_PRESS_TIME;
            if (ev.button == 1 || ev.button == 3)
                active = true;

            if (timeout == 0 && ev.button == 1) {
                last_click_time = ev.time;
                timeout = Timeout.add (max_press_time, () => {
                    /* long click */
                    timeout = 0;
                    popup_menu (ev);
                    return false;
                });
            }

            if (ev.button == 3) {
                /* right_click */
                right_click (ev);
                popup_menu (ev);
            }
            return true;

        }

        private bool on_mnemonic_activate (bool group_cycling) {
            /* ToggleButton always grabs focus away from the editor,
             * so reimplement Widget's version, which only grabs the
             * focus if we are group cycling.
             */
            if (!group_cycling) {
                activate ();
            } else if (can_focus) {
                grab_focus ();
            }

            return true;
        }

        /*protected*/ public new void popup_menu (Gdk.EventButton? ev = null) {
            if (has_fetcher)
                fetch_menu ();

            menu.popup_at_widget(this, Gdk.Gravity.SOUTH, Gdk.Gravity.NORTH, ev);
            menu.select_first (false);
        }

        protected void popdown_menu () {
            menu.popdown ();
        }

        private void fetch_menu () {
            _menu = fetcher ();
            update_menu_properties ();
        }
    }
}
