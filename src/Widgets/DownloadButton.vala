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
public class Odysseus.DownloadButton : Odysseus.ProgressBin {
    private Odysseus.Download download;
    
    private Gtk.Button button;
    private Gtk.Image fileicon;
    private Gtk.Label filename;
    private Gtk.Label filesize;
    private Gtk.Label remaining;
    
    private Gtk.Menu menu;
    private Gtk.MenuItem open_item;
    private Gtk.CheckMenuItem open_automatic_item;

    public DownloadButton(Odysseus.Download download) {
        this.download = download;
        this.sensitive = true;
        
        setup_ui();
        connect_events();
        create_menu();
        show_all();
    }
    
    private void setup_ui() {
        // NOTE I'm populating the values as data comes in,
        // because we don't know enough yet.
        button = new Gtk.Button();
        add(button);
        
        var container = new Gtk.Grid();
        button.add(container);

        fileicon = new Gtk.Image.from_icon_name("document-save-as",
                        Gtk.IconSize.LARGE_TOOLBAR);
        container.attach(fileicon, 0, 0, 1, 2);
        
        filename = new Gtk.Label(_("[Download]"));
        filename.get_style_context().add_class("h3");
        filename.halign = Gtk.Align.CENTER;
        container.attach(filename, 1, 0, 2, 1);
        
        filesize = new Gtk.Label("-");
        filesize.halign = Gtk.Align.START;
        container.attach(filesize, 1, 1, 1, 1);
        
        remaining = new Gtk.Label("-");
        remaining.halign = Gtk.Align.END;
        container.attach(remaining, 2, 1, 1, 1);
    }
    
    private void connect_events() {
        download.received_data.connect(() =>  update_data());

        button.activate.connect(() => {
            if (download.completed) download.open();
            else show_menu(null);
        });
        button.button_press_event.connect((evt) => {
            if (evt.button == Gdk.BUTTON_SECONDARY || !download.completed)
                show_menu(evt);
            else
                download.open();
            return true;
        });
        download.cancel.connect(() => this.destroy());
    }
    private void update_data() {
        var inner_d = download.download;
        this.progress = inner_d.estimated_progress;
        fileicon.gicon = download.icon;
        filename.label = Filename.display_basename(download.destination);
        filesize.label = format_size(inner_d.response.content_length);
        if (!download.completed)
            remaining.label = download.estimate();
        else
            remaining.label = _("DONE");
    }


    private void create_menu() {
        menu = new Gtk.Menu();

        open_item = new Gtk.MenuItem.with_mnemonic(_("_Open"));
        open_item.activate.connect(() => download.open());
        open_item.sensitive = false;
        menu.add(open_item);

        open_automatic_item = new Gtk.CheckMenuItem.with_mnemonic(_("Open _Automatically"));
        open_automatic_item.active = true;
        menu.add(open_automatic_item);

        // TRANSLATORS _ precedes shortcut key
        var save_item = new Gtk.MenuItem.with_mnemonic(_("_Save As"));
        save_item.activate.connect(() => {
            var win = get_toplevel() as BrowserWindow;
            if (win == null) return;
            foreach (var uri in win.prompt_file(Gtk.FileChooserAction.SAVE, _("_Save As"),
                    download.destination))
                download.destination = uri;
        });
        menu.add(save_item);
        
        menu.add(new Gtk.SeparatorMenuItem());

        var cancel_item = new Gtk.MenuItem.with_mnemonic(_("_Cancel"));
        cancel_item.activate.connect(() => download.cancel());
        menu.add(cancel_item);
        
        menu.show_all();
    }

    private void show_menu(Gdk.EventButton? evt) {
        uint button = 0;
        uint32 activate_time = Gtk.get_current_event_time();
        
        if (evt != null) {
            button = evt.button;
            activate_time = evt.get_time();
        }
        open_item.sensitive = download.completed;
        open_automatic_item.sensitive = !download.completed;
        open_automatic_item.active = download.auto_open;
        menu.popup(null, null, null, button, activate_time);
    }
}
