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
/** This moderately improves the UI for JavaScript alerts/confirms/prompts.

I know this isn't the best UI but take up with webpages which use these APIs,
    I'm just trying to make it not quite so bad by reducing it's modality. */
namespace Oddysseus.Traits {
    private async void show_alert(WebTab tab, WebKit.ScriptDialog dlg) {
        tab.paused = true; // Communicate page-level modality.

        var msg = dlg.get_message();
        InfoContainer.MessageOptions opts = new InfoContainer.MessageOptions();
        switch (dlg.get_dialog_type()) {
            case WebKit.ScriptDialogType.ALERT:
                opts.type = Gtk.MessageType.INFO; opts.show_cancel = false;
                break;
            case WebKit.ScriptDialogType.CONFIRM:
                break;
            case WebKit.ScriptDialogType.PROMPT:
                opts.show_entry = true;
                opts.prefill = dlg.prompt_get_default_text();
                break;
            case WebKit.ScriptDialogType.BEFORE_UNLOAD_CONFIRM:
                opts.ok_text = "Leave"; opts.cancel_text = "Stay";
                break;
        }
        dlg.confirm_set_confirmed(yield tab.info.message(msg, opts));
        dlg.prompt_set_text(tab.info.response);
        
        tab.paused = false;
    }

    public void setup_alerts(WebTab tab) {
        tab.web.script_dialog.connect((dlg) => {
            show_alert.begin(tab, dlg);
            return true;
        });
    }
}
