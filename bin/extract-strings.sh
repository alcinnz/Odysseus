#! /bin/sh

xgettext -d oddysseus -o po/oddysseus.pot --add-comments="/" --keyword="_" --keyword="N_" --keyword="C_:1c,2" --keyword="NC_:1c,2" --keyword="ngettext:1,2" --keyword="Q_:1g" --from-code=UTF-8 -LC# src/*.vala src/*/*.vala src/*/*/*.vala

intltool-extract --local --type=gettext/keys data/oddysseus.desktop
xgettext -d extra -o po/extra/extra.pot --add-comments="/" --no-location --from-code=UTF-8 --add-comments="/" --keyword="_" --keyword="N_" --keyword="C_:1c,2" --keyword="NC_:1c,2" --keyword="ngettext:1,2" --keyword="Q_:1g" tmp/oddysseus.desktop.h

intltool-extract --local --type=gettext/xml data/io.github.alcinnz.Oddysseus.appdata.xml
xgettext -d extra -o po/extra/extra.pot --add-comments="/" --no-location --from-code=UTF-8 -j --add-comments="/" --keyword="_" --keyword="N_" --keyword="C_:1c,2" --keyword="NC_:1c,2" --keyword="ngettext:1,2" --keyword="Q_:1g" tmp/io.github.alcinnz.Oddysseus.appdata.xml.h

bin/template-strings.py > tmp/templates.h
xgettext -d oddysseus -o po/oddysseus.pot --add-comments="/" --from-code=UTF-8 -j --add-comments="/" --keyword="_" --keyword="N_" --keyword="C_:1c,2" --keyword="NC_:1c,2" --keyword="ngettext:1,2" --keyword="Q_:1g" tmp/templates.h

#rm -r tmp
