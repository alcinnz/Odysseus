/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2021).
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
/** Allows dragging a sidebar pane providing an alternative, vertical view of the tabs. */
using Granite.Widgets;
public class Odysseus.VerticalTabs : Gtk.Paned {
    DynamicNotebook inner;
    SourceList tabs;
    Gee.Map<Tab, SourceList.Item> tab_map = new Gee.HashMap<Tab, SourceList.Item>();

    construct {
        wide_handle = true;
        orientation = Gtk.Orientation.HORIZONTAL;
        position = 0;
    }

    public VerticalTabs(Granite.Widgets.DynamicNotebook inner) {
        this.inner = inner; pack2(inner, true, false);
        var tabsGrid = new Gtk.Grid(); pack1(tabsGrid, true, true);

        tabsGrid.orientation = Gtk.Orientation.VERTICAL;
        this.tabs = new SourceList();
        var actionbar = new Gtk.ActionBar();
        actionbar.get_style_context ().add_class (Gtk.STYLE_CLASS_INLINE_TOOLBAR);

        var add_button = new Gtk.Button.from_icon_name("list-add-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        add_button.tooltip_text = inner.add_button_tooltip;
        add_button.clicked.connect(() => inner.new_tab_requested());
        actionbar.add(add_button);
        var rm_button = new Gtk.Button.from_icon_name("list-remove-symbolic", Gtk.IconSize.SMALL_TOOLBAR);
        rm_button.tooltip_text = _("Close tab");
        rm_button.clicked.connect(() => inner.remove_tab(inner.current));
        tabs.notify["selected"].connect((pspec) => rm_button.sensitive = tabs.selected != null);
        actionbar.add(rm_button);

        tabsGrid.add(tabs);
        tabsGrid.add(actionbar);

        connect_events();
    }

    private void connect_events() {
        inner.tab_added.connect(tab => {
            var row = new SourceList.Item();
            tab.bind_property("label", row, "name", BindingFlags.SYNC_CREATE);
            tab.bind_property("icon", row, "icon", BindingFlags.SYNC_CREATE);
            WebTab webtab = tab as WebTab;
            if (webtab != null) webtab.web.bind_property("uri", row, "tooltip", BindingFlags.SYNC_CREATE);

            tab_map[tab] = row;
            tabs.root.add(row);
        });
        inner.tab_removed.connect(tab => {
            SourceList.Item item;
            if (tab_map.unset(tab, out item)) item.parent.remove(item);
        });
        // Can't as trivially handle inner.tab_reordered()... Not as important.
        inner.tab_switched.connect(tab => {
            Idle.add(() => {
                tabs.selected = tab_map[inner.current];
                return Source.REMOVE;
            });
        });

        tabs.item_selected.connect(row => {
            foreach (var entry in tab_map.entries) {
                if (entry.@value == row) inner.current = entry.key;
            }
        });
        notify["position"].connect(pspec => {
            inner.tab_bar_behavior = position == 0 ?
                DynamicNotebook.TabBarBehavior.ALWAYS : DynamicNotebook.TabBarBehavior.NEVER;
        });
    }
}
