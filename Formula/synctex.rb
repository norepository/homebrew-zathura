class Synctex < Formula
  desc "Parser libary for synctex"
  homepage "https://github.com/jlaurens/synctex"
  url "https://github.com/jlaurens/synctex", using: :git, revision: "d37a5a59091b6a1bda387e68dd9431a7a750f419", branch: "2024"
  version "2024"
  license "MIT"
  head "https://github.com/jlaurens/synctex.git", branch: "main"

  livecheck do
    url :stable
    regex(/^(\d{4})$/i)
  end

  depends_on "zlib"

  def install
    flags = ["-Wall", "-I.", "-lz", "-shared"]
    flags += ["-fPIC"] if OS.linux?
    system ENV.cc.to_s, *flags, "synctex_parser.c", "synctex_parser_utils.c", "-o", "libsynctex.dylib"

    lib.install "libsynctex.dylib"
    (include/"synctex").install "synctex_parser.h", "synctex_parser_utils.h", "synctex_version.h"

    (lib/"pkgconfig").mkpath
    (lib/"pkgconfig/synctex.pc").write <<~EOS
      prefix=#{prefix}
      exec_prefix=#{prefix}
      libdir=#{lib}
      includedir=#{include}

      Name: synctex
      Description: SyncTeX parser library
      Version: 1.21.0
      Requires.private: zlib
      Libs: -L${libdir} -lsynctex
      Cflags: -I${includedir}/synctex
    EOS
  end
end
