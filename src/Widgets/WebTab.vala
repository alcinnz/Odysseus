public class Odysseus.WebTab : Granite.Widgets.Tab {
    public WebKit.WebView web; // To allow it to be wrapped in layout views. 
    public WebTab(Granite.Widgets.DynamicNotebook parent,
                  WebKit.WebView? related = null,
                  string uri = "https://ddg.gg/") {
        if (related != null) {
            this.web = (WebKit.WebView) related.new_with_related_view();
        } else {
            this.web = new WebKit.WebView();
        }
        var container = new Gtk.Overlay();
        container.add(this.web);
        this.page = container;
        
        web.bind_property("title", this, "label");
        web.notify["favicon"].connect((sender, property) => {
            var fav = BrowserWindow.surface_to_pixbuf(web.get_favicon());
            icon = fav.scale_simple(16, 16, Gdk.InterpType.BILINEAR);
        });
        web.bind_property("is-loading", this, "working");

        web.create.connect((nav_action) => {
            var tab = new WebTab(parent, web, nav_action.get_request().uri);
            parent.insert_tab(tab, -1);
            parent.current = tab;
            return tab.web;
        });
        
        web.load_uri(uri);
        // This fixes favicon loading
        web.web_context.set_favicon_database_directory(null);
    }
}
