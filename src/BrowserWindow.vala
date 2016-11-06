public class Odysseus.BrowserWindow : Gtk.Window {
    public weak Odysseus.Application app;

    public WebKit.WebView web;
    public Gtk.Button back;
    public Gtk.Button forward;
    public Gtk.Button reload;
    public Gtk.Entry addressbar;
    
    public BrowserWindow(Odysseus.Application ody_app) {
        this.app = ody_app;
        set_application(this.app);
        this.title = "(Loading)";
        this.set_size_request(900, 800);
        this.icon_name = "internet-web-browser";

        init_layout();
        register_events();
    }
    
    private void init_layout() {
        back = new Gtk.Button.from_icon_name ("go-previous");
        forward = new Gtk.Button.from_icon_name ("go-next");
        reload = new Gtk.Button.from_icon_name ("view-refresh");
        addressbar = new Gtk.Entry();
        
        Gtk.HeaderBar header = new Gtk.HeaderBar();
        header.show_close_button = true;
        header.pack_start(back);
        header.pack_start(forward);
        header.pack_start(reload);
        header.set_custom_title(addressbar);
        set_titlebar(header);
        
        web = new WebKit.WebView();
        add(web);
    }
    
    private void register_events() {
        show.connect(() => {
            web.load_uri ("https://ddg.gg/");
        });
        web.bind_property ("uri", this, "title");
    }
}
