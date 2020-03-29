/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016-2020).
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
public class Odysseus.Header.AddressBar : TokenizedEntry {
    private Gee.List<Gtk.Widget> statusbuttons = new Gee.ArrayList<Gtk.Widget>();

    public void show_indicators(Gee.List<StatusIndicator> indicators) {
        foreach (var widget in statusbuttons) widget.destroy();
        statusbuttons.clear();

        foreach (var indicator in indicators) {
            var statusbutton = indicator.build_ui();
            this.add(statusbutton);
            statusbuttons.add(statusbutton);
        }
        show_all();
    }
}
