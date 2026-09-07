# Zathura

Homebrew formulae to install Zathura and supporting PDF plugins on macOS.

## Tap this repository

```sh
brew tap homebrew-zathura/zathura
```

## Install zathura

> [!NOTE]
> If you want a comprehensive guide on installing zathura, check out [@ejmastnak](https://github.com/ejmastnak)'s guide [here](https://ejmastnak.com/tutorials/vim-latex/pdf-reader/#zathura-macos)

Zathura uses a plugin based system for supported document types
which means that you need install not only zathura itself,
but at least one plugin. At this moment zathura has 5 official plugins:

- `zathura-cb` for Comic Book Archive files (.cbr, .cbz, .cbt, etc.)
- `zathura-djvu` for DjVu files (.djvu, .djv)
- `zathura-pdf-mupdf` for PDF files (.pdf) via MuPDF backend
- `zathura-pdf-poppler` for PDF files (.pdf) via Poppler backend
- `zathura-ps` for PostScript files (.ps, .eps)

To use zathura as PDF viewer you need either `zathura-pdf-mupdf`
or `zathura-pdf-poppler` plugin. It is not recommended to install
both plugins since zathura will use only one of them, and which
one depends on the implementation and may change at any time.

### Install zathura

> [!warning]
> Installing zathura with `--HEAD` flag is deprecated and will not work. Please use the commands below.

```sh
brew install zathura
```

(or Optionally) with Synctex:

```sh
brew install zathura --with-synctex
```

(or Optionally) with the macOS title bar removal patch:

```sh
brew install zathura --with-no-titlebar
```

Built this way, `zathura -T file.pdf` (or `--no-titlebar`) opens a frameless,
rounded window. Without the flag zathura behaves as usual.

### Install plugins

Install all required plugins. Note that `zathura` requires either
`zathura-pdf-mupdf` or `zathura-pdf-poppler` plugin in order to
render PDFs.

```sh
brew install [zathura-cb] [zathura-djvu] [zathura-pdf-mupdf] [zathura-pdf-poppler] [zathura-ps]
```

If you only want the command line binary, link the plugins where
zathura looks for them (needed after installing new plugins):

```sh
d=$(brew --prefix zathura)/lib/zathura ; mkdir -p $d ; for n in cb djvu pdf-mupdf pdf-poppler ps ; do p=$(brew --prefix zathura-$n)/lib$n.dylib ; [[ -f $p ]] && ln -s $p $d ; done
```

If you want the app bundle, skip that step — the script below does it for you.

### App bundle

```sh
curl -fsSL https://raw.githubusercontent.com/norepository/homebrew-zathura/refs/heads/master/convert-into-app.sh | bash
```

This builds a **self-contained** `/Applications/Zathura.app`: every dylib,
plugin and GTK runtime file is copied inside the bundle, relinked to
`@executable_path` and ad-hoc signed. The app does not read anything from
`$(brew --prefix)` at runtime, so `brew upgrade` can no longer break it.

Once built, the Homebrew packages are only build artifacts and can be removed:

```sh
brew uninstall --force --ignore-dependencies zathura zathura-pdf-mupdf girara gtk+3
```

Re-run the script whenever you install a new plugin or update zathura
(re-install the formulae first, then rebuild the bundle).

To also get the command line, point it at the bundle:

```sh
ln -sf /Applications/Zathura.app/Contents/MacOS/zathura /usr/local/bin/zathura
```

The `warning: Found no plugins` line on startup is cosmetic: zathura probes
its compiled-in plugin directory before the bundle loads its own plugins.

## Copying to clipboard

Add the following to your `~/.config/zathura/zathurarc`:

```sh
set selection-clipboard clipboard
```

Thanks to [geigi](https://github.com/geigi) (see [#5](https://github.com/zegervdv/homebrew-zathura/issues/5))

# Uninstall

Homebrew will throw errors unless you uninstall plugins before Zathura.

```sh
brew uninstall --force zathura-pdf-mupdf
brew uninstall --ignore-dependencies --force girara
brew uninstall zathura
```

Optionally untap the repo

```sh
brew untap $(brew tap | grep zathura)
```

## Updating formulae

Maintainers: `python3 sync/main.py` rewrites the `sha256` of every formula from
its current `url`. See [sync/README.md](sync/README.md).

## Roadmap

- [x] Frameless windows (opt-in, `--with-no-titlebar`)
- [x] Better app bundle and icon
- [x] More plugin support (CB and EPUP formats, full list [here](https://archlinux.org/packages/?q=zathura-))
