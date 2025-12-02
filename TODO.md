# TODO - Soundcore Plasma Widget

## 🌍 Translations (i18n)

The widget now supports internationalization. Current status:

### ✅ Completed
- [x] English (en) - Source language
- [x] Italian (it) - Fully translated

### 📝 To Do
- [ ] German (de)
- [ ] French (fr)
- [ ] Spanish (es)
- [ ] Portuguese (pt)
- [ ] Russian (ru)
- [ ] Chinese (zh)
- [ ] Japanese (ja)

### How to Add a New Translation

1. **Copy the template:**
   ```bash
   cd widget/translate
   cp en.po <lang>.po
   ```

2. **Edit the `.po` file:**
   - Update the header (Language, Language-Team, etc.)
   - Translate each `msgstr` field

3. **Compile the translation:**
   ```bash
   mkdir -p plasmoidlocale/<lang>/LC_MESSAGES
   msgfmt <lang>.po -o plasmoidlocale/<lang>/LC_MESSAGES/plasma_applet_com.github.soundcore.widget.mo
   ```

4. **Update `metadata.json`:**
   Add localized Name and Description:
   ```json
   "Name[<lang>]": "Translated Name",
   "Description[<lang>]": "Translated Description"
   ```

5. **Submit a Pull Request!**

## 🔧 Features

### Planned
- [ ] Support for custom equalizer profiles
- [ ] Multiple device management
- [ ] Quick presets switching
- [ ] Integration with KDE Connect

### Ideas
- [ ] MPRIS integration for media controls
- [ ] Auto-switch sound modes based on application
- [ ] Battery low notifications

## 🐛 Known Issues

- Battery level is reported in 6 levels (0-5), converted to percentages
- Some headphone models may have different feature sets

## 📋 Contributing

Contributions are welcome! Feel free to:
- 🌍 Add translations
- 🐛 Report bugs
- 💡 Suggest features
- 🔧 Submit pull requests

