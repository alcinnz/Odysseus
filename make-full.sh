#! /bin/sh
python3 bin/extract-message.py

cd build
ninja io.github.alcinnz.Odysseus-pot
ninja extra-pot
ninja

echo "Successfully built Odysseus!"
echo "You may now commit your changes and ``sudo ninja install`` from ./build"
