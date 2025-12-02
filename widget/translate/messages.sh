#!/bin/bash

# Script to extract translatable strings from QML files
# Run this from the translate/ directory

PACKAGE="plasma_applet_com.github.soundcore.widget"
BASEDIR="../contents"
PROJECT="soundcore-widget"

echo "Extracting translatable strings..."

# Find all QML and JS files
find "$BASEDIR" -name "*.qml" -o -name "*.js" | sort > infiles.list

# Extract strings using xgettext
xgettext \
    --from-code=UTF-8 \
    --language=JavaScript \
    --kde \
    --ki18n \
    --ki18nc:1c,2 \
    --ki18np:1,2 \
    --ki18ncp:1c,2,3 \
    -o template.pot \
    --files-from=infiles.list \
    --package-name="$PROJECT" \
    --package-version="2.0" \
    --msgid-bugs-address="brigante@example.com"

rm infiles.list

if [ -f template.pot ]; then
    echo "✓ template.pot created successfully!"
    echo ""
    echo "To create a new translation:"
    echo "  msginit -i template.pot -o <lang>.po -l <lang>"
    echo ""
    echo "To update existing translations:"
    echo "  msgmerge -U <lang>.po template.pot"
    echo ""
    echo "To compile translations:"
    echo "  mkdir -p plasmoidlocale/<lang>/LC_MESSAGES"
    echo "  msgfmt <lang>.po -o plasmoidlocale/<lang>/LC_MESSAGES/$PACKAGE.mo"
else
    echo "✗ Error: template.pot was not created"
    exit 1
fi

