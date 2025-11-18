#!/usr/bin/env bash
set -euo pipefail

# scripts/scan_sbom.sh
#
# Usage:
#   ./scripts/scan_sbom.sh [optional-path-to-sbom]
#
# If no argument is provided, it defaults to:
#   prufwerk-sbom.spdx.json
#
# It will:
#   - Verify the SBOM file exists
#   - Create artifacts/sbom/ if needed
#   - Run Grype against the SBOM with:
#       - table output  -> artifacts/sbom/prufwerk-vulns-<timestamp>.txt
#       - json output   -> artifacts/sbom/prufwerk-vulns-<timestamp>.json

SBOM_PATH="${1:-prufwerk-sbom.spdx.json}"
OUT_DIR="artifacts/sbom"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

echo "[scan_sbom] SBOM path: $SBOM_PATH"
echo "[scan_sbom] Output dir: $OUT_DIR"
mkdir -p "$OUT_DIR"

if [ ! -f "$SBOM_PATH" ]; then
  echo "[scan_sbom] ERROR: SBOM file '$SBOM_PATH' not found." >&2
  echo "           Generate one with something like:" >&2
  echo "             syft dir:. -o spdx-json > prufwerk-sbom.spdx.json" >&2
  exit 1
fi

TABLE_OUT="$OUT_DIR/prufwerk-vulns-${TS}.txt"
JSON_OUT="$OUT_DIR/prufwerk-vulns-${TS}.json"

echo "[scan_sbom] Running grype (table output)..."
grype "sbom:${SBOM_PATH}" -o table | tee "$TABLE_OUT"

echo "[scan_sbom] Running grype (json output)..."
grype "sbom:${SBOM_PATH}" -o json > "$JSON_OUT"

echo "[scan_sbom] Done."
echo "  Table report: $TABLE_OUT"
echo "  JSON report : $JSON_OUT"
