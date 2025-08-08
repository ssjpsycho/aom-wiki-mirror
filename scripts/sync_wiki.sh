#!/usr/bin/env bash
set -euo pipefail

# Mirror https://wiki.alliesofmajesty.com into a local folder (default: site/wiki)
# Usage: scripts/sync_wiki.sh [OUTPUT_DIR]
BASE_URL="https://wiki.alliesofmajesty.com"
OUT_DIR="${1:-site/wiki}"

TMP_DIR="$(mktemp -d)"
USER_AGENT="GitHubActionsBot/1.0 (+https://github.com/${GITHUB_REPOSITORY:-}) wget"

mkdir -p "$OUT_DIR"

echo "Mirroring $BASE_URL to temporary directory: $TMP_DIR"
set +e
wget \
  --mirror \
  --convert-links \
  --adjust-extension \
  --page-requisites \
  --no-parent \
  --domains=wiki.alliesofmajesty.com \
  --user-agent="$USER_AGENT" \
  --wait=1 --random-wait \
  --restrict-file-names=windows \
  --timestamping \
  --execute robots=on \
  --directory-prefix="$TMP_DIR" \
  "$BASE_URL" 2>&1 | tee wget.log
status=${PIPESTATUS[0]}
set -e

# Ignore exit code 8 (404 errors) but fail for other errors
if [ "$status" -ne 0 ] && [ "$status" -ne 8 ]; then
  echo "wget failed with exit code $status" >&2
  exit "$status"
fi

# Log 404s as warnings
grep -F "ERROR 404" wget.log | sed 's/^/::warning::/' || true

echo "Syncing into repository directory: $OUT_DIR"
rsync -a --delete "$SRC_DIR"/ "$OUT_DIR"/

echo "Sync complete."
