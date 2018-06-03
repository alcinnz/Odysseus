/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2016).
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
public class Odysseus.ProgressBin : Gtk.Bin {
    public Cairo.Pattern progressFill {get; set;}
    public double progress {get; set;}

    public ProgressBin() {
        var c = Gdk.RGBA();
        c.parse("#8cd5ff");
        progressFill = new Cairo.Pattern.rgba(c.red, c.green, c.blue, 0.8);
        
        this.notify.connect((sender, property) => queue_draw());
    }

    public override bool draw(Cairo.Context cr) {
        var width = get_allocated_width();
        var height = get_allocated_height();
        
        // Render progress
        cr.rectangle(0, 0, width * progress, height);
        cr.set_source(progressFill);
        cr.fill();
        
        // but below the content
        get_child().draw(cr);
        
        return true;
    }
}
