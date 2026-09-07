class Zathura < Formula
  desc "PDF viewer"
  homepage "https://pwmt.org/projects/zathura/"
  url "https://github.com/pwmt/zathura/archive/refs/tags/2026.02.09.tar.gz"
  sha256 "ee890591608a79e75e9719054c4f29c4a611172484e93e43126651d3d5cd9477"
  license "Zlib"
  # No head: the mac-integration patch does not apply to the develop branch.

  livecheck do
    url :stable
    regex(/^v?(\d+(?:\.\d+)+)$/i)
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "sphinx-doc" => :build
  depends_on "adwaita-icon-theme"
  depends_on "gettext"
  depends_on "girara"
  depends_on "glib"
  depends_on "json-glib"
  depends_on "libmagic"
  depends_on "synctex" => :optional
  on_macos do
    depends_on "gtk+3"
    depends_on "gtk-mac-integration"
  end

  patch do
    url "file://#{__dir__}/../patches/mac-integration.diff"
    sha256 "7f75829c6094dfe576656620dd206491552a71c568afe8c38ec3d246ef1eb98f"
  end

  on_macos do
    option "with-no-titlebar", "Remove the title bar on macOS"

    if build.with? "no-titlebar"
      # Optionally remove the title bar on macOS with the "-T" or "--no-titlebar" arguments
      patch do
        url "file://#{__dir__}/../patches/no-titlebar.diff"
        sha256 "5243224b088bcbac7bfce93322d58b8bd23a6d4011d9395040ed1f897ae569ad"
      end
    end
  end

  def install
    # Set Homebrew prefix
    ENV["PREFIX"] = prefix

    mkdir "build" do
      system "meson", *std_meson_args, ".."
      system "ninja"
      system "ninja", "install"
    end
  end

  def caveats
    <<~EOS
      Zathura is, by default, only a command line tool. To build a self-contained
      /Applications/Zathura.app (bundles every dependency, survives brew upgrades), run:
        curl -fsSL https://raw.githubusercontent.com/homebrew-zathura/homebrew-zathura/refs/heads/master/convert-into-app.sh | bash
      Install your plugins (e.g. zathura-pdf-mupdf) first; afterwards these formulae
      can be uninstalled, the app keeps working.
    EOS
  end

  test do
    assert_match "zathura", shell_output("#{bin}/zathura --version")
  end
end
