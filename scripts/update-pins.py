#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path

SHA1_RE = re.compile(r"^[0-9a-f]{40}$")

def run_git(args: list[str], cwd: Path | None = None) -> str:
    p = subprocess.run(
        ["git", *args],
        cwd=str(cwd) if cwd else None,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
        check=False,
    )
    if p.returncode != 0:
        raise RuntimeError(p.stderr.strip() or f"git {' '.join(args)} failed")
    return p.stdout.strip()

def find_repo_root(explicit_repo: str | None) -> Path:
    if explicit_repo:
        return Path(explicit_repo).expanduser().resolve()
    return Path(run_git(["rev-parse", "--show-toplevel"])).resolve()

def latest_rev(url: str, ref: str) -> str:
    out = run_git(["ls-remote", url, ref])
    if not out:
        raise RuntimeError(f"ls-remote returned empty: {url} {ref}")
    sha = out.splitlines()[0].split()[0]
    if not SHA1_RE.match(sha):
        raise RuntimeError(f"unexpected sha: {sha}")
    return sha

def load_pins(path: Path) -> dict:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        raise RuntimeError(f"pins file not found: {path}")
    except json.JSONDecodeError as e:
        raise RuntimeError(f"pins file is not valid json: {path} ({e})")

def save_pins(path: Path, data: dict) -> None:
    path.write_text(json.dumps(data, indent=2, sort_keys=True) + "\n", encoding="utf-8")

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("name", nargs="?", help="update only this pin name (default: all)")
    ap.add_argument("--repo", help="dotfiles repo root (default: auto detect by git)")
    ap.add_argument("--pins", help="pins json path (default: <repo>/pins/repos.json)")
    ns = ap.parse_args()

    try:
        repo_root = find_repo_root(ns.repo)
        pins_path = Path(ns.pins).expanduser().resolve() if ns.pins else (repo_root / "pins" / "repos.json")

        pins = load_pins(pins_path)
        if not isinstance(pins, dict):
            raise RuntimeError("pins json must be an object at top level")

        targets = [ns.name] if ns.name else list(pins.keys())
        if not targets:
            print("no pins to update", file=sys.stderr)
            return 1

        changed = False
        for name in targets:
            if name not in pins:
                raise RuntimeError(f"unknown pin name: {name}")

            entry = pins[name]
            url = entry.get("url")
            ref = entry.get("ref")
            old = entry.get("rev")

            if not isinstance(url, str) or not url:
                raise RuntimeError(f"{name}: url is missing")
            if not isinstance(ref, str) or not ref:
                raise RuntimeError(f"{name}: ref is missing")

            new = latest_rev(url, ref)
            if old == new:
                print(f"{name}: unchanged ({old})")
                continue

            pins[name]["rev"] = new
            print(f"{name}: {old} -> {new}")
            changed = True

        if changed:
            save_pins(pins_path, pins)
        return 0

    except RuntimeError as e:
        print(str(e), file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())

