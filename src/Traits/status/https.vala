/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2018).
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
/* Communicates that the connection to a page is secure, and
    (TODO) the certification for such. */
namespace Odysseus.Traits {
    public void report_https(Gee.List<StatusIndicator> indicators, WebKit.WebView web) {
        TlsCertificate cert;
        TlsCertificateFlags errors;

        if (!web.get_tls_info(out cert, out errors)) return;

        var msg = _("Your connection to %s is secure from eavesdroppers,") + "\n";
        msg += _("Your activity can be seen by the admins and hosting companies for this site.");
        StatusIndicator status;
        if (errors == 0)
            status = new StatusIndicator("security-high", Status.SECURE,
                    msg.printf(new Soup.URI(web.uri).host)
                );
        else status = new StatusIndicator("security-low", Status.ERROR,
                // FIXME provide more information about the error.
                _("Certificate validation failed! This site may be an imposter.")
            );

        if (TlsCertificateFlags.UNKNOWN_CA in errors)
            status.bullet_point(_("Unknown certificate authority"));
        if (TlsCertificateFlags.BAD_IDENTITY in errors)
            status.bullet_point(_("Wrong site named in certificate"));
        if (TlsCertificateFlags.NOT_ACTIVATED in errors)
            status.bullet_point(_("Not yet active certificate"));
        if (TlsCertificateFlags.EXPIRED in errors)
            status.bullet_point(_("Expired certificate"));
        if (TlsCertificateFlags.REVOKED in errors)
            status.bullet_point(_("Known bad certificate"));
        if (TlsCertificateFlags.INSECURE in errors)
            status.bullet_point(_("Broken encryption scheme."));
        if (TlsCertificateFlags.GENERIC_ERROR in errors)
            status.bullet_point(_("Unknown error…"));

        status.on_pressed = () => build_certificate_popover(status.text, cert);
        indicators.add(status);
    }

    private Gtk.Popover build_certificate_popover(string summary, TlsCertificate cert) {
        var ret = new Gtk.Popover(null);
        var grid = new Gtk.Grid();
        grid.orientation = Gtk.Orientation.VERTICAL;
        ret.add(grid);

        var header = new Gtk.Label(summary);
        header.margin = 20;
        grid.add(header);
        var scrolled = new Odysseus.Header.AutomaticScrollBox();
        grid.add(scrolled);
        var list = new Gtk.ListBox();
        scrolled.add(list);
        list.selection_mode = Gtk.SelectionMode.NONE;

        for (var chain = cert; chain != null; chain = cert.issuer) {
            var gcr = new Gcr.SimpleCertificate (chain.certificate.data);
            list.add(build_certificate_row(gcr));
        }

        return ret;
    }

    private Gtk.Widget build_certificate_row(Gcr.Certificate cert) {
        var ret = new Gtk.Grid();
        ret.column_spacing = 10; ret.row_spacing = 10;
        ret.attach(styled_label(cert.subject, "weight='bold' size='x-large'"), 0, 0);
        ret.attach(new Gtk.Image.from_gicon(cert.icon, Gtk.IconSize.LARGE_TOOLBAR), 1, 0);
        ret.attach(styled_label(cert.description), 0, 1, 2);
        var signature_style = "font='Daniel, cursive' underline='single'";
        ret.attach(styled_label(cert.issuer, signature_style), 0, 2);

        var expires_buf = new char[200];
        var format = Granite.DateTime.get_default_date_format(false, true, true);
        var expires_len = cert.expiry.strftime(expires_buf, format);
        var expires_str = (string) expires_buf[0:expires_len];
        ret.attach(styled_label(_("Expires %s").printf(expires_str)), 1, 2);

        return ret;
    }
    private Gtk.Label styled_label(string text, string style = "") {
        var ret = new Gtk.Label(text);
        ret.set_markup(Markup.printf_escaped("<span " + style + ">%s</span>", text));
        ret.justify = Gtk.Justification.LEFT;
        ret.halign = Gtk.Align.START;
        return ret;
    }
}
