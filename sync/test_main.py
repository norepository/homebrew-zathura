"""Run with: python3 sync/test_main.py"""

from pathlib import Path

from main import FIRST, PAIR

TARBALL = '  url "https://example.com/x.tar.gz"\n  sha256 "old"\n'
GIT = '  url "https://github.com/jlaurens/synctex", using: :git, branch: "2024"\n  version "2024"\n'

assert PAIR.sub(lambda m: m.group(1) + "new", TARBALL).endswith('sha256 "new"\n')
assert PAIR.search(TARBALL).group(2) == "https://example.com/x.tar.gz"
assert PAIR.search(GIT) is None

# girara/synctex/zathura rebuild before the plugins that link them.
alphabetical = [Path(f"{n}.rb") for n in ("girara", "synctex", "zathura-cb", "zathura-pdf-ps", "zathura")]
alphabetical.sort(key=lambda f: FIRST.index(f.stem) if f.stem in FIRST else len(FIRST))
assert [f.stem for f in alphabetical] == ["girara", "synctex", "zathura", "zathura-cb", "zathura-pdf-ps"]

print("ok")
