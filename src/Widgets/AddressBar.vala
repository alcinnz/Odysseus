/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2016).
*
* Oddysseus is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Oddysseus is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with Oddysseus.  If not, see <http://www.gnu.org/licenses/>.
*/
public class Oddysseus.AddressBar : Gtk.Entry {
    public AddressBar() {
        this.margin_start = 20;
        this.margin_end = 20;
    }

    /* While there's more planned here,
        at the moment I just need this class to customize sizing */
    public override void get_preferred_width(out int min_width, out int nat_width) {
        nat_width = 848; // Something large, so it fills this space if possible
    }
}
