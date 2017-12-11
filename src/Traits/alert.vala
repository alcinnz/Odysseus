/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017).
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
/** This moderately improves the UI for JavaScript alerts/confirms/prompts.

I know this isn't the best UI but take up with webpages which use these APIs,
    I'm just trying to make it not quite so bad by reducing it's modality. */
namespace Odysseus.Traits {
    private async bool show_alert(WebTab tab, WebKit.ScriptDialog dlg,
            out bool confirm, out bool prompt) {
        // TODO Communicate page-level modality.

        var msg = dlg.get_message();
        var opts = new Overlay.InfoContainer.MessageOptions();
        switch (dlg.get_dialog_type()) {
            case WebKit.ScriptDialogType.ALERT:
                opts.type = Gtk.MessageType.INFO; opts.show_cancel = false;
                confirm = false; prompt = false;
                break;
            case WebKit.ScriptDialogType.CONFIRM:
                confirm = true; prompt = false;
                break;
            case WebKit.ScriptDialogType.PROMPT:
                opts.show_entry = true;
                opts.prefill = dlg.prompt_get_default_text();
                confirm = false; prompt = true;
                break;
            case WebKit.ScriptDialogType.BEFORE_UNLOAD_CONFIRM:
                opts.ok_text = "Leave"; opts.cancel_text = "Stay";
                confirm = true; prompt = false;
                break;
            default:
                error("Unreachable code");
        }

        return yield tab.info.message(msg, opts);
    }

    public void setup_alerts(WebTab tab) {
        tab.web.script_dialog.connect((dlg) => {
            var loop = new MainLoop();
            bool ret = true;
            bool confirm = true; bool prompt = false;

            // Disallow interacting with the page while dialog is active.
            tab.web.sensitive = false;
            tab.status = _("Close the message to continue interacting with this page");

            show_alert.begin(tab, dlg, (obj, res) => {
                ret = show_alert.end(res, out confirm, out prompt);
                loop.quit();
            });
            loop.run();

            // Dialog disappeared, reenable page.
            tab.web.sensitive = true;
            tab.status = tab.default_status;

            if (confirm) dlg.confirm_set_confirmed(ret);
            if (prompt && ret) dlg.prompt_set_text(tab.info.response);
            return true;
        });
    }
}
