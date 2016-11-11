/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016).
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
public class Odysseus.DownloadsBar : Gtk.Revealer {
    private Gtk.FlowBox mainbox;

    public DownloadsBar() {
        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        this.margin = 5;
        this.add(box);
        
        mainbox = new Gtk.FlowBox();
        mainbox.column_spacing = 10;
        mainbox.row_spacing = 10;
        box.pack_start(mainbox);
        
        var close_button = new Gtk.Button.from_icon_name("window-close");
        close_button.clicked.connect(() => {
            foreach (var entry in mainbox.get_children()) {
                entry.destroy();
            }

            set_reveal_child(false);
        });
        close_button.relief = Gtk.ReliefStyle.NONE;
        box.pack_end(close_button, false, false);
        
        set_reveal_child(false);
    }
    
    public void add_entry(Gtk.Widget widget) {
        set_reveal_child(true);
        mainbox.add(widget);
    }
}
