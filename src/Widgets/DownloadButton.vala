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
public class Oddysseus.DownloadButton : Oddysseus.ProgressBin {
    private WebKit.Download download;
    private bool completed; 
    
    private Gtk.Button button;
    private Gtk.Image fileicon;
    private Gtk.Label filename;
    private Gtk.Label filesize;
    private Gtk.Label remaining;
    
    private Gtk.Menu menu;
    private Gtk.MenuItem open_item;

    public DownloadButton(WebKit.Download download) {
        this.download = download;
        this.completed = false;
        
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
        
        filename = new Gtk.Label("[Download]");
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
        stdout.printf("Connecting download events\n");
        download.received_data.connect((len) => {
            update_data();
        });
        download.finished.connect(() => {
            update_data();
            remaining.label = "DONE";
            completed = true;
            open_item.sensitive = true;
            button.activate();
        });

        button.activate.connect(() => {
            if (completed) {
                Granite.Services.System.open_uri(download.destination);
            } else {
                show_menu(null);
            }
        });
        button.button_press_event.connect((evt) => {
            if (evt.button == Gdk.BUTTON_SECONDARY || !completed) {
                show_menu(evt);
            } else {
                button.activate();
            }
            return true;
        });
        
        this.destroy.connect(() => download.cancel());
    }
    private void update_data() {
        this.progress = download.estimated_progress;
        var mime = download.response.mime_type;
        fileicon.gicon = ContentType.get_icon(ContentType.from_mime_type(mime));
        filename.label = Filename.display_basename(download.destination);
        filesize.label = format_size(download.response.content_length);

        var progress = download.estimated_progress;
        var estimate = (download.get_elapsed_time()/progress) * (1-progress);
        remaining.label = format_time(estimate);
    }
    
    private static string format_time(double estimate) {
        if (estimate < 60) {
            return "%.0fs".printf(estimate);
        } else if (estimate < 120) {
            return "%.0fm".printf(estimate / 60);
        } else {
            return "%.0fh %.0fm".printf(estimate / 120, estimate / 60);
        }
    }


    private void create_menu() {
        menu = new Gtk.Menu();
        
        open_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.OPEN, null);
        open_item.activate.connect(() => {
            Granite.Services.System.open_uri(download.destination);
        });
        open_item.sensitive = false;
        menu.add(open_item);

        // FIXME Be nice to select alternative download locations
        /*var save_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.SAVE_AS,
                                                        null);
        save_item.activate.connect(() => {
            var chooser = new Gtk.FileChooserDialog(
                        "Save Download to:", // TODO translate
                        (Gtk.Window) get_toplevel(),
                        Gtk.FileChooserAction.SAVE,
                        Gtk.Stock.CANCEL, Gtk.ResponseType.CANCEL,
                        Gtk.Stock.SAVE_AS, Gtk.ResponseType.OK);
            chooser.set_filename(download.destination);

            if (chooser.run() == Gtk.ResponseType.OK) {
                download.set_destination(chooser.get_uri());
            }
            chooser.destroy();
        });
        menu.add(save_item);
        
        menu.add(new Gtk.SeparatorMenuItem());*/
        
        var cancel_item = new Gtk.ImageMenuItem.from_stock(Gtk.Stock.CANCEL,
                                                            null);
        cancel_item.activate.connect(() => this.destroy());
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
        menu.popup(null, null, null, button, activate_time);
    }
}
