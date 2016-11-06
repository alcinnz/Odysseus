public class Odysseus.Application : Granite.Application {

    public BrowserWindow mainWindow;

    construct {
        application_id = "com.github.alcinnz.odysseus";
        flags = ApplicationFlags.FLAGS_NONE;
        /*Intl.setlocale (LocaleCategory.ALL, "");
        Intl.textdomain (Build.GETTEXT_PACKAGE);*/

        program_name = "Odysseus";
        app_years = "2016";

        /* TODO specify more metadata */
    }

    public override void activate () {
        if (mainWindow == null) {
            mainWindow = new BrowserWindow(this);
        }
        mainWindow.show_all();
    }

    /* TODO Handle HTTP(S) URLs */
}

public static int main(string[] args) {
    var application = new Odysseus.Application();
    return application.run(args);
}
