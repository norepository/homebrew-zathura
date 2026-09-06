#!/usr/bin/env python3
"""Recompute the sha256 of every url in Formula/*.rb, then build-test them."""

from __future__ import annotations

import hashlib
import re
import subprocess
import sys
import urllib.request
from pathlib import Path

# `url "..."` immediately followed by `sha256 "..."`. Group 1 is everything up
# to the digest, so the substitution rewrites the digest and nothing else.
# Formulae whose url carries options (synctex: `using: :git`) never match.
PAIR = re.compile(r'( *url "([^"]+)"\n *sha256 ")[^"]*')


def update(formula: Path) -> bool:
    def digest(match: re.Match[str]) -> str:
        url = match.group(2).replace("#{__dir__}", str(formula.resolve().parent))
        with urllib.request.urlopen(url, timeout=60) as response:
            return match.group(1) + hashlib.sha256(response.read()).hexdigest()

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

    for formula in formulae:
        subprocess.run(["brew", "reinstall", "--build-from-source", formula], check=True)


if __name__ == "__main__":
    main()
