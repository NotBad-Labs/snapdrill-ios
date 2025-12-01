# Localization generation helper

This helper generates template `.xcstrings` files for additional locales based on the existing `Localizable.xcstrings`.

Files created:

- `NotBad/Resources/Localizable.zh-Hant.xcstrings` (Traditional Chinese)
- `NotBad/Resources/Localizable.ja.xcstrings` (Japanese placeholder)
- `NotBad/Resources/Localizable.ko.xcstrings` (Korean placeholder)

Usage

```bash
python3 tools/localization/generate_localization_files.py
```

Optional: install OpenCC for better Simplified->Traditional conversion:

```bash
python3 -m pip install --user opencc-python-reimplemented
```

If OpenCC is not installed, generated `zh-Hant` values will be identical to `zh-Hans` (you can re-run after installing OpenCC to regenerate). After generation, import the files into Xcode: `File > Import Localizations...` or add them to the project.
