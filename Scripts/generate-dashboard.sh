#!/bin/zsh

set -euo pipefail

echo "📊 Generating Coverage Dashboard"

ARTIFACTS_DIR=${ARTIFACTS_DIR:-"local_artifacts"}
COVERAGE_JSON=${COVERAGE_JSON:-"${ARTIFACTS_DIR}/coverage-local.json"}
OUTPUT_MD=${OUTPUT_MD:-"docs/dashboard.md"}
SNAPSHOT_DIR=${SNAPSHOT_DIR:-"docs/coverage"}

# Keep default consistent with Scripts/check-quality.sh
EXCLUDE_REGEX=${COVERAGE_EXCLUDE_REGEX:-'NotBad/NotBad/Presentation/(.*/)?Views/.*\.swift'}

mkdir -p "$(dirname "$OUTPUT_MD")"

if [[ ! -f "$COVERAGE_JSON" ]]; then
  echo "⚠️ Coverage JSON not found at $COVERAGE_JSON; creating minimal dashboard."
  cat > "$OUTPUT_MD" << 'EOF'
# NotBad Quality Dashboard

No coverage data available yet. Run the unit tests to generate `local_artifacts/coverage-local.json`.
EOF
  echo "✅ Dashboard generated at $OUTPUT_MD"
  exit 0
fi

python3 - "$COVERAGE_JSON" "$EXCLUDE_REGEX" "$SNAPSHOT_DIR" > "$OUTPUT_MD" << 'PY'
import json, sys, re, glob, os
from datetime import datetime

coverage_path = sys.argv[1]
exclude_regex = sys.argv[2]
snap_dir = sys.argv[3]

def compute_coverage(path, exclude=None):
    with open(path, 'r') as f:
        data = json.load(f)
    total = 0
    covered = 0
    pat = re.compile(exclude) if exclude else None
    for target in data.get('targets', []):
        for file in target.get('files', []):
            p = file.get('path', '')
            if pat and p and pat.search(p):
                continue
            total += int(file.get('executableLines', 0))
            covered += int(file.get('coveredLines', 0))
    pct = (covered / total * 100.0) if total > 0 else 0.0
    return pct, covered, total

overall_pct, overall_cov, overall_total = compute_coverage(coverage_path, exclude=None)
logic_pct, logic_cov, logic_total = compute_coverage(coverage_path, exclude=exclude_regex)

# approximate test count from xcresult if present next to coverage JSON
def find_xcresult_dir():
    candidates = [
        os.path.join(os.getcwd(), 'TestResults.xcresult'),
    ]
    for c in candidates:
        if os.path.isdir(c):
            return c
    return None

def try_count_tests(xcresult):
    # Heuristic placeholder: count occurrences of "Test suite '" in logs if available
    try:
        log = os.path.join(xcresult, 'Info.plist')
        return None if not os.path.isfile(log) else None
    except Exception:
        return None

tests_count = try_count_tests(find_xcresult_dir())

# Build time best-effort from environment or file mtime
generated_ts = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
try:
    mtime = datetime.fromtimestamp(os.path.getmtime(coverage_path)).strftime('%Y-%m-%d %H:%M:%S')
except Exception:
    mtime = generated_ts

def human_time_from_snapshot_name(name):
    # expects coverage-YYYYmmdd-HHMMSS.json
    try:
        ts = name.rsplit('coverage-', 1)[1].rsplit('.json', 1)[0]
        dt = datetime.strptime(ts, '%Y%m%d-%H%M%S')
        return dt.strftime('%Y-%m-%d %H:%M:%S')
    except Exception:
        return name

# collect historical overall coverage trend (latest 10)
trend_rows = []
snapshots = sorted(glob.glob(os.path.join(snap_dir, 'coverage-*.json')))
for snap in snapshots[-10:]:
    pct, _, _ = compute_coverage(snap, exclude=None)
    trend_rows.append((snap, pct))

print('# NotBad Quality Dashboard')
print()
print(f'Generated: {generated_ts}')
print()
print('## Coverage Summary')
print()
print(f'- Overall coverage: {overall_pct:.2f}% ({overall_cov}/{overall_total} lines)')
print(f'- Logic-only coverage (Views excluded): {logic_pct:.2f}% ({logic_cov}/{logic_total} lines)')
if tests_count is not None:
    print(f'- Tests executed: {tests_count}')
print(f'- Coverage JSON mtime: {mtime}')
print()
print('## Recent Coverage Trend (overall)')
print()
if trend_rows:
    print('| Snapshot | Coverage |')
    print('|---|---:|')
    for path, pct in trend_rows:
        name = os.path.basename(path)
        ts = human_time_from_snapshot_name(name)
        print(f'| {ts} | {pct:.2f}% |')
else:
    print('No historical snapshots found. They will be created by the quality check script.')

print()
print('## How to regenerate')
print()
print('1. Run unit tests via the quality script to produce coverage:')
print('   - `zsh Scripts/check-quality.sh`')
print('2. Generate this dashboard:')
print('   - `zsh Scripts/generate-dashboard.sh`')

# Recent commits (last 5)
print()
print('## Recent Commits (last 5)')
print()
try:
    import subprocess
    out = subprocess.check_output(['git', 'log', '--pretty=%h %s', '-n', '5'], text=True).strip()
    if out:
        for line in out.splitlines():
            print(f'- {line}')
    else:
        print('No commits found.')
except Exception:
    print('Git log unavailable in this environment.')
PY

echo "✅ Dashboard generated at $OUTPUT_MD"
