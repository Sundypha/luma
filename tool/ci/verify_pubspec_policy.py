#!/usr/bin/env python3
"""Fail if pubspec.yaml files violate monorepo dependency policy (NFR-03/NFR-04).

- Forbids git: dependencies (any key).
- Allows path: only when the resolved path stays under apps/ or packages/ in this repo.
"""

from __future__ import annotations

import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parents[2]
ALLOWED_PREFIXES = ("apps/", "packages/")


def _iter_pubspecs() -> list[Path]:
    paths: list[Path] = []
    for sub in ("apps", "packages"):
        root = REPO_ROOT / sub
        if not root.is_dir():
            continue
        paths.extend(sorted(root.rglob("pubspec.yaml")))
    root_pub = REPO_ROOT / "pubspec.yaml"
    if root_pub.is_file():
        paths.append(root_pub)
    return paths


def _relative_under_repo(target: Path) -> str | None:
    try:
        rel = target.resolve().relative_to(REPO_ROOT.resolve())
    except ValueError:
        return None
    return rel.as_posix()


def _check_path_dep(pubspec_file: Path, dep_name: str, rel_path: str, section: str) -> list[str]:
    errors: list[str] = []
    base = pubspec_file.parent
    resolved = (base / rel_path).resolve()
    rel = _relative_under_repo(resolved)
    if rel is None:
        errors.append(
            f"{pubspec_file.relative_to(REPO_ROOT)}: [{section}] {dep_name} -> path '{rel_path}' "
            f"resolves outside the repository."
        )
        return errors
    if not rel.startswith(ALLOWED_PREFIXES) and rel != "pubspec.yaml":
        # Root pubspec.yaml is allowed; other paths must be under apps/ or packages/
        if pubspec_file.resolve() != REPO_ROOT / "pubspec.yaml":
            errors.append(
                f"{pubspec_file.relative_to(REPO_ROOT)}: [{section}] {dep_name} -> path '{rel_path}' "
                f"resolves to '{rel}' (must be under apps/ or packages/)."
            )
    return errors


def _scan_pubspec(path: Path) -> list[str]:
    errors: list[str] = []
    raw = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        return [f"{path.relative_to(REPO_ROOT)}: invalid YAML root"]

    for section in ("dependencies", "dev_dependencies", "dependency_overrides"):
        block = raw.get(section)
        if not isinstance(block, dict):
            continue
        for name, spec in block.items():
            if name == "flutter" or spec is None:
                continue
            if isinstance(spec, str):
                continue  # version constraint from pub.dev
            if not isinstance(spec, dict):
                continue
            if "git" in spec:
                errors.append(
                    f"{path.relative_to(REPO_ROOT)}: [{section}] '{name}' uses forbidden git: dependency."
                )
            if "path" in spec:
                p = spec["path"]
                if not isinstance(p, str):
                    errors.append(
                        f"{path.relative_to(REPO_ROOT)}: [{section}] '{name}' has non-string path."
                    )
                else:
                    errors.extend(_check_path_dep(path, name, p, section))
    return errors


def main() -> int:
    all_errors: list[str] = []
    for pubspec in _iter_pubspecs():
        all_errors.extend(_scan_pubspec(pubspec))
    if all_errors:
        print("verify_pubspec_policy: FAILED", file=sys.stderr)
        for line in all_errors:
            print(f"  {line}", file=sys.stderr)
        return 1
    print("verify_pubspec_policy: OK")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
