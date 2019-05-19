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

                Liberate.read(web);
                d.indicator.status = Status.ACTIVE;

                var popover = new Gtk.Popover(null);
                var menu = new Gtk.Grid();
                menu.orientation = Gtk.Orientation.VERTICAL;
                popover.add(menu);

                /// Translators: name of a Reader Mode theme.
                add_theme(web, menu, _("Light"), "light");
                /// Translators: name of a Reader Mode theme.
                add_theme(web, menu, _("Moonlight"), "moonlight");
                /// Translators: name of a Reader Mode theme.
                add_theme(web, menu, _("Solarized"), "Solarized");

                return popover;
            }
        );
        var data = new ReaderData();
        data.web = tab.web;
        data.indicator = indicator;
        indicator.user_data = data;

        tab.indicators.add(indicator);
        tab.indicators_loaded(tab.indicators);
    }

    private void add_theme(WebKit.WebView web, Gtk.Container menu,
            string human_name, string filename) {
        var option = new Gtk.Button.with_label(human_name);
        option.clicked.connect(() => Liberate.read(web, filename));
        option.relief = Gtk.ReliefStyle.NONE;
        menu.add(option);
    }
}
