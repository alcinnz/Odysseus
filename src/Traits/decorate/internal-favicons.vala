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
/* Detects when a page is internal, and uses special syntax embedded in the
    page's title to determine it's favicon as WebKit refuses to give us the
    correct favicon. */
namespace Odysseus.Traits {
    /* Makes it easier to put symbolic icons in tabbar & non-symbolic in addressbar. */
    errordomain Availability {UNAVAILABLE}
    private Icon choose_icon(string spec, string suffix = "") throws Error {
        var theme = Gtk.IconTheme.get_default();

        var icons = spec.split_set(" \t\r\n");
        for (var i = 0; i < icons.length; i++) icons[i] = icons[i] + suffix;

        var icon = theme.choose_icon(icons, 16, Gtk.IconLookupFlags.GENERIC_FALLBACK);
        if (icon == null) throw new Availability.UNAVAILABLE("");

        return icon.load_icon();
    }

    private void setup_internal_favicons(WebTab tab) {
        var web = tab.web;
        web.notify["title"].connect((pspec) => {
            var title = tab.web.title.chug();
            if (title[0] != '[') return;

            // Extract icon from title & set it on the tab
            var splitat = title.index_of_char(']');
            if (splitat < 0) return;
            var icons = title[1:splitat];

            try {
                var colour = Gdk.RGBA();
                colour.parse("#666");
                tab.icon = choose_icon(icons, "-symbolic");
                tab.coloured_icon = choose_icon(icons);
                tab.label = title[splitat+1:title.length].strip();
            } catch (Error err) {}
        });
    }
}
