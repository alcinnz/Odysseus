public class Odysseus.AddressBar : Gtk.Entry {
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
