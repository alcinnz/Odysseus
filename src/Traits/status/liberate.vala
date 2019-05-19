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

    private void offer_readability(WebTab tab) {
        var indicator = new StatusIndicator(
            "com.github.bleakgrey.liberate", Status.DISABLED,
            _("Improve this page's readability"),
            (data) => {
                var web = data as WebKit.WebView;
                if (web == null) return null;

                var popover = new Gtk.Popover(null);
                var menu = new Gtk.Menu();
                popover.add(menu);

                var options = new SList<Gtk.RadioMenuItem>();
                /// Translators: name of a Reader Mode theme.
                add_theme(web, menu, options, _("Light"), "light");
                /// Translators: name of a Reader Mode theme.
                add_theme(web, menu, options, _("Moonlight"), "moonlight");
                /// Translators: name of a Reader Mode theme.
                add_theme(web, menu, options, _("Solarized"), "Solarized");

                return popover;
            }
        );
        indicator.user_data = tab.web;

        tab.indicators.add(indicator);
        tab.indicators_loaded(tab.indicators);
    }

    private void add_theme(WebKit.WebView web, Gtk.Menu menu,
            SList<Gtk.RadioMenuItem> options,
            string human_name, string filename) {
        var option = new Gtk.RadioMenuItem.with_label(options, human_name);
        option.toggled.connect(() => Liberate.read(web, filename));
        menu.add(option);
    }
}
