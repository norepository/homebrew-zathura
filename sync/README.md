# sync-tool

Use this when you update the version for zathura, girara, or any of the plugins. It will update the hashes for you automatically.

## Usage

```bash
python3 sync/main.py
```

It rewrites the hashes, then `brew reinstall --build-from-source` on every formula.
