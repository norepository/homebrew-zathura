"""Run with: python3 sync/test_main.py"""

from main import PAIR

TARBALL = '  url "https://example.com/x.tar.gz"\n  sha256 "old"\n'
GIT = '  url "https://github.com/jlaurens/synctex", using: :git, branch: "2024"\n  version "2024"\n'

assert PAIR.sub(lambda m: m.group(1) + "new", TARBALL).endswith('sha256 "new"\n')
assert PAIR.search(TARBALL).group(2) == "https://example.com/x.tar.gz"
assert PAIR.search(GIT) is None
print("ok")
