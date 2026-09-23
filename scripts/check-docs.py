#!/usr/bin/env python3
"""Check the docs against docs/documentation-design/README.md.

Reports every problem; exits non-zero only with --strict.
Usage: scripts/check-docs.py [--strict]
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
BUDGETS = {"README.md": 150, "CLAUDE.md": 100}
FEATURE_BUDGET = 200
BULLET_CHARS = 300
SCANNED = ["*.md", "docs/**/*.md", ".claude/skills/**/*.md"]

LINK = re.compile(r"\]\(([^)\s]+)\)")
URL = re.compile(r"\(https?://[^)]*\)")
FENCE = re.compile(r"^\s*(```|~~~)")

problems = []


def report(path, msg):
    problems.append(f"{path.relative_to(ROOT)}: {msg}")


def lines_outside_fences(text):
    fenced = False
    for n, line in enumerate(text.splitlines(), 1):
        if FENCE.match(line):
            fenced = not fenced
        elif not fenced:
            yield n, line


def feature_docs():
    features = ROOT / "docs" / "features"
    return sorted(features.glob("*/README.md")) + sorted(features.glob("*.md"))


def description(path):
    m = re.match(r"^---\n(.*?)\n---\n", path.read_text(), re.S)
    if not m:
        return None
    d = re.search(r"^description:\s*(.+)$", m.group(1), re.M)
    return d.group(1).strip() if d else None


def check_budgets():
    for name, limit in BUDGETS.items():
        path = ROOT / name
        n = len(path.read_text().splitlines())
        if n > limit:
            report(path, f"{n} lines, budget {limit}")
    for path in feature_docs():
        n = len(path.read_text().splitlines())
        if n > FEATURE_BUDGET:
            report(path, f"{n} lines, budget {FEATURE_BUDGET}")


def check_descriptions():
    for path in feature_docs():
        d = description(path)
        if not d:
            report(path, "missing frontmatter `description`")
        elif len(d) > 250:
            report(path, f"description is {len(d)} chars, limit 250")


def check_changelog():
    path = ROOT / "CHANGELOG.md"
    text = path.read_text()
    unreleased = re.search(r"^## \[Unreleased\]\n(.*?)(?=^## |\Z)", text, re.S | re.M)
    if unreleased:
        for line in unreleased.group(1).splitlines():
            if line.startswith("- "):
                n = len(URL.sub("()", line))
                if n > BULLET_CHARS:
                    report(path, f"[Unreleased] bullet is {n} chars, limit {BULLET_CHARS}: {line[:60]}…")
    minors = []
    for v in re.findall(r"^## \[(\d+\.\d+)\.\d+\]", text, re.M):
        if v not in minors:
            minors.append(v)
    if len(minors) > 1:
        report(path, f"holds minors {', '.join(minors)}; run scripts/changelog-rollover.py")


def check_links():
    files = {p for pattern in SCANNED for p in ROOT.glob(pattern)}
    for path in sorted(files):
        for n, line in lines_outside_fences(path.read_text()):
            line = re.sub(r"`[^`]*`", "", line)  # links inside inline code are examples
            for target in LINK.findall(line):
                if re.match(r"^(https?:|mailto:|#)", target):
                    continue
                target = target.split("#")[0]
                if not (path.parent / target).exists():
                    report(path, f"line {n}: broken link {target}")


UUID = re.compile(r"\b[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}\b")


def check_placeholders():
    """Examples must use placeholder IDs (ver-1, 1234567890), never IDs copied from a real account."""
    docs = ROOT / "docs"
    for path in sorted(docs.rglob("*.md")):
        if "changelog" in path.parts:
            continue
        for n, line in enumerate(path.read_text().splitlines(), 1):
            for m in UUID.findall(line):
                if len(set(m.replace("-", ""))) > 2:  # 00000000-…-0001 style is fine
                    report(path, f"line {n}: real-looking UUID {m}; use a placeholder such as ver-1")


def main():
    check_budgets()
    check_descriptions()
    check_changelog()
    check_links()
    check_placeholders()
    for p in problems:
        print(p)
    print(f"{len(problems)} problem(s)")
    if problems and "--strict" in sys.argv:
        sys.exit(1)


if __name__ == "__main__":
    main()
