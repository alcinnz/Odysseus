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
/** Recolour often third-party icons to use the elementary colour scheme.
    https://elementary.io/docs/human-interface-guidelines#color

For third party icons this reduces obtrusiveness whilst maintaining a
    recognizable shape. At the same it can be used with built-in icons for an
    extra channel of communication.

The latter isn't used yet.*/
namespace Odysseus.ImageUtil {
    public Gdk.Pixbuf recolour(Gdk.Pixbuf source, string colour) {
        // White is often used to define the shape via it's "whitespace".
        // This preprocessing step maintains that function.
        var mask = source.add_alpha(true, 255, 255, 255);

        // Cairo has a handy mask() method for this.
        var dest = new Cairo.ImageSurface(Cairo.Format.ARGB32,
                source.width, source.height);
        var ctx = new Cairo.Context(dest);
        var g_colour = Gdk.RGBA();
        g_colour.parse(colour);
        Gdk.cairo_set_source_rgba(ctx, g_colour);
        ctx.mask_surface(Gdk.cairo_surface_create_from_pixbuf(mask, 0, null), 0, 0);


        return Gdk.pixbuf_get_from_surface(dest, 0, 0, source.width, source.height);
    }

    // GDK does provide a utility for this,
    // but it requires me to specify size information I do not have.
    public static Gdk.Pixbuf? surface_to_pixbuf(Cairo.Surface surface) {
        try {
            var loader = new Gdk.PixbufLoader.with_mime_type("image/png");
            surface.write_to_png_stream((data) => {
                try {
                    loader.write((uint8[]) data);
                } catch (Error e) {
                    return Cairo.Status.DEVICE_ERROR;
                }
                return Cairo.Status.SUCCESS;
            });
            var pixbuf = loader.get_pixbuf();
            loader.close();
            return pixbuf;
        } catch (Error e) {
            return null;
        }
    }
}
