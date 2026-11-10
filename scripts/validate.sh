#!/usr/bin/env bash
# Check skill frontmatter, banned paths, secrets, em dashes, emoji, and shellcheck.

set -u
set -o pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT" || exit 1

status=0

if ! command -v shellcheck >/dev/null 2>&1; then
  echo "error: shellcheck is not installed" >&2
  status=1
else
  script=""
  found=0
  while IFS= read -r script; do
    found=1
    if ! shellcheck "$script"; then
      status=1
    fi
  done < <(find scripts skills -type f -name '*.sh' | sort)
  if [[ "$found" -eq 0 ]]; then
    echo "error: no shell scripts found" >&2
    status=1
  fi
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "error: python3 is not installed" >&2
  exit 1
fi

python3 - "$ROOT" <<'PY' || status=1
import re
import subprocess
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors = []

def fail(message):
    errors.append(message)

slug_re = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
home_re = re.compile("|".join(["/" + "Users/", "/" + "home/"]))
email_re = re.compile(r"(?<![A-Za-z0-9._%+-])[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}(?![A-Za-z])")
emdash = "\u2014"
emoji_re = re.compile(
    "["
    "\U0001F000-\U0001FAFF"
    "\U00002600-\U000027BF"
    "\U0001F1E6-\U0001F1FF"
    "\U00002300-\U000023FF"
    "\U00002B00-\U00002BFF"
    "\u200D"
    "\uFE0F"
    "]"
)
shape_patterns = [
    ("aws-access-key", re.compile(r"AKIA[0-9A-Z]{16}")),
    ("aws-temp-key", re.compile(r"ASIA[0-9A-Z]{16}")),
    ("aws-secret-key", re.compile(r"(?i)aws_secret(?:_access_key)?\s*[:=]\s*['\"]?[A-Za-z0-9/+=]{40}")),
    ("github-token", re.compile(r"gh[opusr]_[A-Za-z0-9]{36}")),
    ("github-fine-grained", re.compile(r"github_pat_[A-Za-z0-9_]{20,}")),
    ("openai-sk-prefixed", re.compile(r"sk-(?:proj|ant|svcacct)-[A-Za-z0-9_-]{10,}")),
    ("openai-sk-generic", re.compile(r"sk-[A-Za-z0-9_-]{20,}")),
    ("stripe-live", re.compile(r"(?:sk|rk)_live_[A-Za-z0-9]{16,}")),
    ("google-api", re.compile(r"AIza[0-9A-Za-z_-]{35}")),
    ("npm-token", re.compile(r"npm_[A-Za-z0-9]{36}")),
    ("slack-token", re.compile(r"xox[baprs]-[A-Za-z0-9-]{10,}")),
    ("slack-webhook", re.compile(r"https://hooks\.slack\.com/services/[A-Za-z0-9/]+")),
    ("jwt", re.compile(r"eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}")),
    (
        "pem-private-key",
        re.compile(
            r"-----BEGIN (?:(?:RSA |DSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY(?: BLOCK)?|PGP PRIVATE KEY BLOCK)-----"
        ),
    ),
    ("hex-key", re.compile(r"\b0x[0-9a-fA-F]{64}\b")),
    (
        "mnemonic",
        re.compile(
            r"(?i)\b(?:mnemonic|seed(?:[\s_-]?phrase)?|recovery[\s_-]?phrase)\b\s*[:=]\s*(?:[a-z]+\s+){11,23}[a-z]+\b"
        ),
    ),
    ("mnemonic-line", re.compile(r"(?m)^(?:[a-z]{3,8} ){11}[a-z]{3,8}$|^(?:[a-z]{3,8} ){23}[a-z]{3,8}$")),
    ("credentialed-url", re.compile(r"[a-z][a-z0-9+.-]*://[^/\s:]+:[^/\s@]+@[^/\s]+")),
    (
        "assigned-name",
        re.compile(
            r"(?i)[A-Z0-9_]*(?:SECRET|TOKEN|PASSWORD|PRIVATE_KEY|MNEMONIC)[A-Z0-9_]*\s*[:=]\s*\S+"
        ),
    ),
]
allow_exact = {"AKIA" + "IOSFODNN7EXAMPLE"}
allow_bits = (
    "example",
    "placeholder",
    "your-key-here",
    "your_key_here",
    "changeme",
    "not-a-real",
    "not_a_real",
    "fake-token",
    "fake_token",
    "password123",
    "test-api-key",
)

def allowed(token):
    if token in allow_exact:
        return True
    lowered = token.lower()
    return any(bit in lowered for bit in allow_bits)

def skill_body(text):
    if not text.startswith("---\n"):
        return None
    end = text.find("\n---\n", 4)
    if end < 0:
        return None
    body = text[end + 5 :]
    if body.startswith("\n"):
        body = body[1:]
    return body

def parse_frontmatter(text):
    if not text.startswith("---\n"):
        return None, "missing opening ---"
    lines = text.splitlines()
    try:
        end = lines.index("---", 1)
    except ValueError:
        return None, "missing closing ---"
    data = {}
    folded = set()
    i = 1
    while i < end:
        line = lines[i]
        if not line.strip():
            i += 1
            continue
        if line.startswith((" ", "\t")):
            return None, "unexpected indented frontmatter: " + line
        if ":" not in line:
            return None, "bad frontmatter line: " + line
        key, val = line.split(":", 1)
        key = key.strip()
        val = val.strip()
        if key in data:
            return None, "duplicate frontmatter key: " + key
        if val in {">-", ">", "|", "|-"}:
            folded.add(key)
            parts = []
            i += 1
            while i < end and (lines[i].startswith((" ", "\t")) or lines[i] == ""):
                parts.append(lines[i].strip())
                i += 1
            data[key] = " ".join(part for part in parts if part)
            continue
        if len(val) >= 2 and val[0] == val[-1] and val[0] in {'"', "'"}:
            val = val[1:-1]
        data[key] = val
        i += 1
    data["__folded__"] = folded
    return data, None

def tracked_files():
    try:
        result = subprocess.run(
            ["git", "ls-files", "-z"],
            cwd=root,
            check=False,
            capture_output=True,
        )
    except OSError:
        result = None
    if result is not None and result.returncode == 0:
        names = result.stdout.decode("utf-8", "surrogateescape").split("\0")
        return [root / name for name in names if name]
    found = []
    for path in root.rglob("*"):
        if ".git" in path.parts or not path.is_file():
            continue
        found.append(path)
    return found

def load_companies():
    path = root / "scripts" / "company-denylist.local"
    if not path.is_file():
        return []
    names = []
    for line in path.read_text(encoding="utf-8").splitlines():
        item = line.strip()
        if item and not item.startswith("#"):
            names.append(item.lower())
    return names

skill_dirs = sorted(p for p in (root / "skills").iterdir() if p.is_dir())
if not skill_dirs:
    fail("no skills found")

for skill_dir in skill_dirs:
    skill_file = skill_dir / "SKILL.md"
    if not skill_file.is_file():
        fail(f"{skill_dir}: missing SKILL.md")
        continue
    text = skill_file.read_text(encoding="utf-8")
    line_count = text.count("\n")
    if line_count > 250:
        fail(f"{skill_file.relative_to(root)}: {line_count} lines (limit 250)")
    data, err = parse_frontmatter(text)
    if err:
        fail(f"{skill_file.relative_to(root)}: {err}")
        continue
    name = data.get("name", "")
    description = data.get("description", "")
    folded = data.get("__folded__", set())
    if name != skill_dir.name:
        fail(f"{skill_file.relative_to(root)}: name {name!r} != folder {skill_dir.name!r}")
    if not slug_re.match(skill_dir.name):
        fail(f"{skill_dir.name}: folder name is not a kebab-case slug")
    if len(name) > 64:
        fail(f"{skill_file.relative_to(root)}: name is longer than 64 characters")
    if not description.strip():
        fail(f"{skill_file.relative_to(root)}: description is empty")
    if "description" in folded or "\n" in description:
        fail(f"{skill_file.relative_to(root)}: description must be one line")
    if "when" not in description.lower():
        fail(f"{skill_file.relative_to(root)}: description must say when to use the skill")
    if len(description) > 1024:
        fail(f"{skill_file.relative_to(root)}: description is longer than 1024 characters")

pref = root / "skills" / "engineering-preferences" / "SKILL.md"
rule = root / "rules" / "engineering-preferences.md"
if not pref.is_file():
    fail("missing skills/engineering-preferences/SKILL.md")
elif not rule.is_file():
    fail("missing rules/engineering-preferences.md")
else:
    body = skill_body(pref.read_text(encoding="utf-8"))
    rule_text = rule.read_text(encoding="utf-8")
    if body is None:
        fail("engineering-preferences: could not strip frontmatter")
    elif rule_text != body:
        fail(
            "rules/engineering-preferences.md does not match "
            "skills/engineering-preferences/SKILL.md (frontmatter removed)"
        )

companies = load_companies()
skill_text_roots = [root / "skills", root / "rules"]
skip_scan = {root / "scripts" / "company-denylist.local"}

for path in tracked_files():
    if path in skip_scan or not path.is_file():
        continue
    if path.suffix.lower() in {".png", ".jpg", ".jpeg", ".gif", ".webp", ".pdf"}:
        continue
    try:
        text = path.read_text(encoding="utf-8")
    except (UnicodeError, OSError):
        fail(f"{path.relative_to(root)}: not utf-8 text")
        continue
    rel = path.relative_to(root)
    for lineno, line in enumerate(text.splitlines(), 1):
        if home_re.search(line):
            fail(f"{rel}:{lineno}: hardcoded home path")
        for mail in email_re.finditer(line):
            fail(f"{rel}:{lineno}: email address")
        for company in companies:
            if company in line.lower():
                fail(f"{rel}:{lineno}: company denylist match")
        for label, pattern in shape_patterns:
            for match in pattern.finditer(line):
                if allowed(match.group(0)):
                    continue
                fail(f"{rel}:{lineno}: possible secret ({label})")
    in_skill_text = any(path == skill_root or skill_root in path.parents for skill_root in skill_text_roots)
    if in_skill_text:
        for lineno, line in enumerate(text.splitlines(), 1):
            if emdash in line:
                fail(f"{rel}:{lineno}: em dash")
            if emoji_re.search(line):
                fail(f"{rel}:{lineno}: emoji")

def pattern_map():
    return {label: pattern for label, pattern in shape_patterns}

def expect_hit(label, sample):
    pattern = pattern_map()[label]
    match = pattern.search(sample)
    if match is None:
        return label + " did not match its sample"
    if allowed(match.group(0)):
        return label + " allowlist accepted a sample that is not a teaching token"
    return None

def self_test():
    forty = "A" * 40
    words = " ".join(["alpha"] * 12)
    samples = [
        ("aws-access-key", "AKIA" + "IOSFODNN7REALKEY"),
        ("aws-temp-key", "ASIA" + "IOSFODNN7REALKEY"),
        ("github-token", "ghp_" + ("a" * 36)),
        ("github-token", "gho_" + ("b" * 36)),
        ("github-token", "ghs_" + ("c" * 36)),
        ("github-fine-grained", "github_pat_" + ("d" * 22)),
        ("openai-sk-prefixed", "sk-proj-" + ("e" * 20)),
        ("openai-sk-prefixed", "sk-ant-api03-" + ("f" * 20)),
        ("openai-sk-prefixed", "sk-svcacct-" + ("g" * 20)),
        ("openai-sk-generic", "sk-" + ("h" * 20)),
        ("stripe-live", "sk_live_" + ("i" * 16)),
        ("stripe-live", "rk_live_" + ("j" * 16)),
        ("google-api", "AIza" + ("k" * 35)),
        ("npm-token", "npm_" + ("m" * 36)),
        ("slack-token", "xoxb-" + ("n" * 12)),
        ("slack-webhook", "https://hooks.slack.com/services/" + "T0/B0/secretvalue"),
        ("jwt", "eyJ" + ("a" * 10) + "." + ("b" * 10) + "." + ("c" * 10)),
        ("pem-private-key", "-----BEGIN " + "RSA PRIVATE KEY-----"),
        ("pem-private-key", "-----BEGIN " + "ENCRYPTED PRIVATE KEY-----"),
        ("pem-private-key", "-----BEGIN " + "PGP PRIVATE KEY BLOCK-----"),
        ("hex-key", "0x" + ("ab" * 32)),
        ("mnemonic-line", words),
    ]
    aws_name = "aws_" + "secret_access_key"
    samples.append(("aws-secret-key", aws_name + "=" + forty))
    mem_word = "mnem" + "onic"
    samples.append((mem_word, mem_word + ": " + words))
    samples.append(("credentialed-url", "postgres://user:" + "s3cret@" + "db.internal"))
    built = "DB_" + "SECRET"
    samples.append(("assigned-name", built + "=" + ("p" * 8)))
    seen = set()
    for label, sample in samples:
        seen.add(label)
        problem = expect_hit(label, sample)
        if problem:
            return problem
    missing = [label for label, _pattern in shape_patterns if label not in seen]
    if missing:
        return "self-test missing patterns: " + ", ".join(missing)
    planted = "gh" + "p_" + ("a" * 36)
    line = "placeholder " + planted
    match = pattern_map()["github-token"].search(line)
    if match is None or allowed(match.group(0)):
        return "allowlist used the surrounding line instead of the token"
    if not allowed("AKIA" + "IOSFODNN7EXAMPLE"):
        return "allowlist rejected the AWS documentation example key"
    if allowed("AKIA" + "IOSFODNN7REALKEY"):
        return "allowlist accepted a key that is not a teaching example"
    address = "ada@" + "example.com"
    if email_re.search(address) is None:
        return "email check missed a constructed address"
    names = ["zz" + "qqcorp"]
    if "zzqqcorp" not in "see zzqqcorp today".lower() or names[0] not in "see zzqqcorp today":
        return "company denylist check failed"
    if names[0] in "nothing to see here":
        return "company denylist matched a clean line"
    return None

self_error = self_test()
if self_error:
    fail("secret scanner self-test: " + self_error)

if errors:
    for message in errors:
        print("error: " + message)
    sys.exit(1)
print(f"validate: {len(skill_dirs)} skills ok")
print(f"validate: secret self-tests ok ({len(shape_patterns)} patterns)")
PY

if [[ "$status" -ne 0 ]]; then
  exit "$status"
fi

echo "validate: shellcheck ok"
exit 0
