# pCloud homebrew tap

A tap for homebrew to install pCloud Drive on Mac.

## Install

```bash
brew install --cask mkim797/homebrew-pcloud-m1/pcloud-m1
```

## Updating

1. Get key

```bash
echo `$(curl -s https://www.pcloud.com/how-to-install-pcloud-drive-mac-os-m1.html\?download\=macm1) | grep "'Mac M1':" | sed "s/[ ,:']*//g;s/MacM1//g" | tr -d '\t')`
```

2. Download latest pkg Version from https://www.pcloud.com/de/how-to-install-pcloud-drive-mac-os.html

3. Calculate SHA256 sum

```bash
shasum -a 256 pCloud\ Drive\ 3.11.6\ macFUSE.pkg
```

4. Update values (*version*, *sha256*, *code*, *pkg*) in cask formula
