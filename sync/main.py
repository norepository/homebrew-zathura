#!/usr/bin/env python3
"""Recompute the sha256 of every url in Formula/*.rb, then build-test them."""

from __future__ import annotations

import hashlib
import re
import subprocess
import sys
from pathlib import Path

# `url "..."` immediately followed by `sha256 "..."`. Group 1 is everything up
# to the digest, so the substitution rewrites the digest and nothing else.
# Formulae whose url carries options (synctex: `using: :git`) never match.
PAIR = re.compile(r'( *url "([^"]+)"\n *sha256 ")[^"]*')

# Rebuilt before the formulae that link them; everything else keeps its order.
FIRST = ("girara", "synctex", "zathura")


def update(formula: Path) -> bool:
    def digest(match: re.Match[str]) -> str:
        url = match.group(2).replace("#{__dir__}", str(formula.resolve().parent))
        # curl, not urllib: it handles both https and the file:// patch urls, and
        # does not depend on the CA bundle a python.org install ships without.
        body = subprocess.run(["curl", "-fsSL", url], capture_output=True, check=True).stdout
        return match.group(1) + hashlib.sha256(body).hexdigest()

    old = formula.read_text(encoding="utf-8")
    new = PAIR.sub(digest, old)
    if new == old:
        return False
    formula.write_text(new, encoding="utf-8")
    return True


def main() -> None:
    formulae = sorted((Path(__file__).resolve().parents[1] / "Formula").glob("*.rb"))
    if not formulae:
        sys.exit("No formula files found.")

    for formula in formulae:
        if update(formula):
            print(f"Updated sha256 in {formula}")

    # Only rebuild what is already installed: `brew reinstall` would otherwise
    # pull in every plugin, including both PDF backends at once.
    installed = subprocess.run(
        ["brew", "list", "--formula"], capture_output=True, text=True, check=True
    ).stdout.split()
    targets = [f for f in formulae if f.stem in installed]
    targets.sort(key=lambda f: FIRST.index(f.stem) if f.stem in FIRST else len(FIRST))

    for formula in targets:
        subprocess.run(["brew", "reinstall", "--build-from-source", formula], check=True)


if __name__ == "__main__":
    main()
