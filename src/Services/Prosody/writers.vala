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

/* Defines a number of "Writer" implementations,
        which is our version of a GLib.OutputStream.

    Essentially it works with Bytes instead of arrays
        & does not report IOErrors. */
namespace Oddysseus.Templating {
    /* "Captures" input and later writes it out to a new Bytes object.
        This is useful in templating,
        and when interfacing to APIs that require a Bytes object or similar. */
    public class CaptureWriter : Object, Writer {
        private List<Bytes> data = new List<Bytes>();
        private int length = 0;

        public async void write(Bytes text) {
            data.append(text);
            length += text.length;
        }

        public uint8[] grab(int extra_bytes = 0) {
            var ret = new uint8[length + extra_bytes];
            var builder = ArrayBuilder(ret);
            foreach (var block in data) {
                builder.append(block.get_data());
            }
            return ret;
        }

        public Bytes grab_data() {
            return new Bytes(grab());
        }

        public string grab_string() {
            var ret = grab(1);
            ret[ret.length - 1] = '\0';
            return (string) ret;
        }
    }

    /* This class may be useful if Prosody is used in another project.
    public class StdOutWriter : Object, Writer {
        public async void write(Bytes text) {
            stdout.write(text.get_data());
        }
    }*/

    /* Mainly used in the implementation of WebKit custom URI schemes.
        That API expects to receive data as an InputStream.

        To fullfill that requirement, this class fills a buffer provided by
        WebKit and hands it over when full. 

        Also the use of idleing ensures this doesn't block the Gtk UI
            when used on the mainthread. */
    public class InputStreamWriter : InputStream, Writer {
        private List<Bytes> data = new List<Bytes>();
        private bool closed = false;

        public async void write(Bytes text) {
            if (!closed) {
                data.append(text);

                // Encourage read & write cycles to alternate
                // Adjust the priority to keep only a few steps ahead of
                //      read_async().
                Idle.add(write.callback, data.length() > 4 ?
                        Priority.LOW : Priority.DEFAULT_IDLE);
                yield;
            }
            else error("Wrote to closed InputStreamWriter");
        }

        /* To be called in the Template.exec()'s completed callback,
            in order to ensure WebKit gets it's content. */
        public void close_write() {
            closed = true;
        }

        public override bool close(Cancellable? cancellable = null)
                throws IOError {
            closed = true;
            return true;
        }

        public override ssize_t read(uint8[] buffer,
                Cancellable? cancellable = null) throws IOError{
            var loop = new MainLoop();
            AsyncResult? result = null;
            read_async.begin(buffer, Priority.DEFAULT, cancellable,
                    (obj, res) => {
                result = res;
                loop.quit();
            });
            loop.run();
            return read_async.end(result);
        }

        public override async ssize_t read_async(uint8[]? buffer,
                int io_priority = Priority.DEFAULT,
                Cancellable? cancellable = null) throws IOError {
            if (buffer == null) return 0;

            var builder = ArrayBuilder(buffer);
            var bytes_read = 0;
            while (bytes_read < buffer.length) {
                // Ensures we have a buffer, and handle close_write() correctly.
                while (data.length() == 0 && !closed) {
                    // Has to be lower than Priority.DEFAULT_IDLE
                    //      as that will block the initial run of write().
                    // But it also has to be higher than Priority.LOW
                    //      to let it encourage us to go first. 
                    Idle.add(read_async.callback, Priority.LOW+1);
                    yield;
                }
                if (closed && data.length() == 0) break;

                // Fetch the data
                var chunk = data.data;
                var remaining = buffer.length - bytes_read;
                if (chunk.length > remaining) {
                    data.data = chunk.slice(remaining, chunk.length);
                    chunk = chunk.slice(0, remaining);
                } else {
                    data.remove_link(data);
                }

                // Read the data to the buffer
                builder.append(chunk.get_data());
                bytes_read += chunk.length;
            }

            return bytes_read;
        }
    }

    /* Copies bytes from a Writer into an uint8 array.
        Mainly serves to abstract away the unsafe casts necessary for
            calling Posix.memcpy(). */
    private struct ArrayBuilder {
        int write_head;
        public ArrayBuilder(uint8[] target) {
            write_head = (int) target;
        }

        // NOTE caller should ensure we don't write past the end of the array.
        //      or the program may segfault.
        public void append(uint8[] source) {
            Posix.memcpy((void*) write_head, (void*) source, source.length);
            write_head += source.length;
        }
    }
}
