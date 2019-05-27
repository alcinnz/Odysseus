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
/** Tidies up webpage clutter via Bleakgray's Liberate and Mozilla's Readability. */
namespace Odysseus.Traits {
    public void detect_readability(WebTab tab) {
        var web = tab.web;
        web.load_changed.connect((event) => {
            if (event == WebKit.LoadEvent.FINISHED)
                Liberate.on_readable(web, () => offer_readability(tab));
        });
    }

    public class ReaderData : Object {
        public WebKit.WebView web;
        public StatusIndicator indicator;
        // Serves the dual purpose of caching, and tracking it's active status.
        public Gtk.Popover popover;
    }

    private void offer_readability(WebTab tab) {
        // Upstream fixme: this callback is triggered repeatedly.
        foreach (var indicator in tab.indicators)
            if (indicator.icon == "com.github.bleakgrey.liberate") return;

        var indicator = new StatusIndicator(
            "com.github.bleakgrey.liberate", Status.DISABLED,
            _("Improve this page's readability"),
            (data) => {
                var d = data as ReaderData;
                if (d == null) return null;
                var web = d.web;

                if (d.popover == null) {
                    Liberate.read(web);
                    d.indicator.status = Status.ACTIVE;

                    d.popover = new Gtk.Popover(null);
                    var menu = new Gtk.Grid();
                    menu.orientation = Gtk.Orientation.VERTICAL;
                    menu.row_spacing = 5;
                    menu.margin = 5;
                    d.popover.add(menu);

                    /// Translators: name of a Reader Mode theme.
                    var group = add_theme(web, menu, _("Light"), "light");
                    /// Translators: name of a Reader Mode theme.
                    add_theme(web, menu, _("Moonlight"), "moonlight", group);
                    /// Translators: name of a Reader Mode theme.
                    add_theme(web, menu, _("Solarized"), "Solarized", group);

                    var reload = new Gtk.Button.with_label(_("Exit Reader Mode"));
                    reload.image = new Gtk.Image.from_icon_name("view-refresh", Gtk.IconSize.BUTTON);
                    reload.always_show_image = true;
                    reload.tooltip_text = _("Reload this page");
                    reload.clicked.connect(() => web.reload());
                    menu.add(reload);
                }

                return d.popover;
            }
        );
        var data = new ReaderData();
        data.web = tab.web;
        data.indicator = indicator;
        indicator.user_data = data;

        tab.indicators.add(indicator);
        tab.indicators_loaded(tab.indicators);
    }

    private Gtk.RadioButton add_theme(WebKit.WebView web, Gtk.Container menu,
            string human_name, string filename,
            Gtk.RadioButton? group = null) {
        var option = new Gtk.RadioButton.with_label_from_widget(group, human_name);
        option.toggled.connect(() => {
            (menu.get_ancestor(typeof(Gtk.Popover)) as Gtk.Popover).popdown();
            Liberate.apply_theme(web, filename);
        });

        menu.add(option);
        return option;
    }
}
