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

/** Exposes GTK's Icons to WebKit (and in particular internal pages). */
namespace Odysseus.Services {
    public void handle_sysicon_uri(WebKit.URISchemeRequest request) {
        var stream = new MemoryInputStream();
        var components = request.get_path().split("/");
        if (components.length != 2) {// Do we need to support fallbacks?
            request.finish(stream, 0, "image/png");
            return;
        }

        var size = int.parse(components[0]);
        var icon = components[1];

        uint8[] icon_buffer;
        try {
            // TODO What flags should I pass? I18n concerns?
            var pixbuf = Gtk.IconTheme.get_default().load_icon(icon, size, 0);
            pixbuf.save_to_buffer(out icon_buffer, "png");
        } catch (Error e) {
            request.finish_error(e);
            return;
        }

        stream.add_data(icon_buffer);
        request.finish(stream, icon_buffer.length, "image/png");
    }
}
