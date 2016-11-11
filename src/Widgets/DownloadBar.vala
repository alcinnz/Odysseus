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
