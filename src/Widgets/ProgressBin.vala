public class Odysseus.ProgressBin : Gtk.Bin {
    public Cairo.Pattern progressFill {get; set;}
    public double progress {get; set;}
    private Gdk.Window window; // A clear background to use

    public ProgressBin() {
        window = new Gdk.Window(null, Gdk.WindowAttr(), 0);
        window.set_background({0, green: 0, blue: 0, alpha: 0});
        
        progressFill = new Cairo.Pattern.rgba(0.7, 0.8, 1.0, 0.9);
        
        this.notify.connect((sender, property) => queue_draw());
    }

    public override bool draw(Cairo.Context cr) {
        var width = get_allocated_width();
        var height = get_allocated_height();
        // draw ontop of the background
        var child_ctx = get_child().get_style_context();
        child_ctx.render_background(cr, 0, 0, width, height);

        child_ctx.save();
        // TODO Works, at the moment, on elementary OS without this,
        //      but needs fixing.
        //      The goal: set a transparent background before rendering child.
        //child_ctx.set_background(window);
        
        // Render progress
        cr.rectangle(0, 0, width * progress, height);
        cr.set_source(progressFill);
        cr.fill();
        
        // but below the content
        get_child().draw(cr);
        child_ctx.restore();
        
        return true;
    }
}
