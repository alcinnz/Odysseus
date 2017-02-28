/**
* This file is part of Odysseus Web Browser (Copyright Adrian Cochrane 2017).
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

/** Cached loading for templates. */
namespace Oddysseus.Templating {
    private Gee.Map<string, Template>? template_cache = null;
    public Template get_for_resource(string resource) throws SyntaxError, Error {
        if (template_cache == null)
            template_cache = new Gee.HashMap<string, Template>();

        if (!template_cache.has_key(resource)) {
            if (!lib_initialized()) Std.register_standard_library();
            var bytes = resources_lookup_data(resource, 0);
            var parser = new Parser(bytes);
            try {
                template_cache[resource] = parser.parse();
            } catch (SyntaxError err) {
                int line_number;
                var cur_token = parser.get_current_token(out line_number);
                warning("Invalid syntax on line: %i for tag: %s message: %s",
                        line_number, ByteUtils.to_string(cur_token),
                        err.message);
                throw err;
            }
        }
        return template_cache[resource];
    }
    // NOTE in the future we may want to cap the number
    //      of templates in the cache.
}
