/**
* This file is part of Oddysseus Web Browser (Copyright Adrian Cochrane 2017).
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
/** InfoContainer is a wrapper around Gtk.InfoBar which shows and hides it
    above some other content.

Used by select traits (Alert & Permit). */
public class Oddysseus.InfoContainer : Gtk.Grid {
    private Gtk.InfoBar info;
    private Gtk.Revealer revealer;
    private Gtk.Label body;
    private Gtk.Entry entry;
    private weak Gtk.Button ok_button;
    private weak Gtk.Button cancel_button;

    public string response {
        get {return entry.text;}
        set {entry.text = value;}
    }
    
    construct {
        this.body = new Gtk.Label(null);

        this.entry = new Gtk.Entry();

        var container = new Gtk.FlowBox();
        container.add(this.body);
        container.add(this.entry);
        
        this.info = new Gtk.InfoBar();
        this.info.get_content_area().add(container);
        this.info.show_close_button = false;
        this.info.close.connect(() => {this.revealer.reveal_child = false;});

        this.ok_button = this.info.add_button("OK", 1);
        this.cancel_button = this.info.add_button("Cancel", 0);
        
        this.revealer = new Gtk.Revealer();
        this.revealer.add(this.info);
        this.revealer.reveal_child = false;
        this.revealer.transition_type = Gtk.RevealerTransitionType.SLIDE_DOWN;
        
        this.orientation = Gtk.Orientation.VERTICAL;
        this.add(this.revealer);
    }

    public class MessageOptions {
        public string prefill = "";
        public Gtk.MessageType type = Gtk.MessageType.QUESTION;
        public bool show_cancel = true; public bool show_entry = false;
        public string ok_text = "OK"; public string cancel_text = "Cancel";
    }
    
    public async bool message(string msg, MessageOptions opts) {
        body.label = msg;
        entry.text = opts.prefill;
        info.message_type = opts.type;
        cancel_button.visible = opts.show_cancel;
        entry.visible = opts.show_entry;
        ok_button.label = opts.ok_text;
        cancel_button.label = opts.cancel_text;

        revealer.reveal_child = true;

        var response = 1;
        var handler = info.response.connect((id) => {
            response = id;
            message.callback();
        });
        yield;
        info.disconnect(handler);
        info.close();

        return (bool) response;
    }
}
