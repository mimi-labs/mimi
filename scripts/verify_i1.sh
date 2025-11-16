#!/usr/bin/env bash
set -euo pipefail

# S1 Day 3 — verify I1 evidence for Prufwerk

SIGNED_IMAGE="docker.io/seejovin93/prufwerk:latest"
EVIDENCE_DIR="evidence/logs/i1"

usage() {
  echo "Usage: $0 [evidence_file.jsonl]"
  echo
  echo "If no file is given, the script will pick the latest demo_i1_*.jsonl under ${EVIDENCE_DIR}."
}

# --- pick evidence file ---
EVIDENCE_FILE="${1:-}"

if [[ -z "${EVIDENCE_FILE}" ]]; then
  if [[ ! -d "${EVIDENCE_DIR}" ]]; then
    echo "[FATAL] Evidence directory ${EVIDENCE_DIR} does not exist."
    exit 1
  fi

  # pick latest demo_i1_*.jsonl by modification time (newest run)
  LATEST_FILE="$(ls -1t "${EVIDENCE_DIR}"/demo_i1_*.jsonl 2>/dev/null | head -n 1 || true)"
  if [[ -z "${LATEST_FILE}" ]]; then
    echo "[FATAL] No evidence files found under ${EVIDENCE_DIR}/demo_i1_*.jsonl"
    exit 1
  fi

  EVIDENCE_FILE="${LATEST_FILE}"
fi

if [[ ! -f "${EVIDENCE_FILE}" ]]; then
  echo "[FATAL] Evidence file not found: ${EVIDENCE_FILE}"
  exit 1
fi

echo "[I1 verify] Using evidence file: ${EVIDENCE_FILE}"

# --- basic stats ---
TOTAL_EVENTS="$(jq -s 'length' "${EVIDENCE_FILE}")"
echo "[I1 verify] Total events: ${TOTAL_EVENTS}"

if [[ "${TOTAL_EVENTS}" -eq 0 ]]; then
  echo "[FAIL] Evidence file has 0 events."
  exit 1
fi

# --- I1 checks ---

# 1) At least one ALLOW for the signed image
ALLOW_SIGNED_COUNT="$(jq -s --arg img "${SIGNED_IMAGE}" \
  'map(select(.decision == "ALLOW" and .image_ref == $img)) | length' \
  "${EVIDENCE_FILE}")"

echo "[I1 verify] ALLOW for signed image (${SIGNED_IMAGE}): ${ALLOW_SIGNED_COUNT}"

if [[ "${ALLOW_SIGNED_COUNT}" -lt 1 ]]; then
  echo "[FAIL] No ALLOW event found for signed image ${SIGNED_IMAGE}."
  exit 1
fi

# 2) No ALLOW for any unsigned-* image (tags containing 'unsigned-')
BAD_UNSIGNED_ALLOWS="$(jq -s \
  'map(select(.decision == "ALLOW" and (.image_ref // "" | test("unsigned-")))) | length' \
  "${EVIDENCE_FILE}")"

echo "[I1 verify] ALLOW events for unsigned-* images (should be 0): ${BAD_UNSIGNED_ALLOWS}"

if [[ "${BAD_UNSIGNED_ALLOWS}" -gt 0 ]]; then
  echo "[FAIL] Found ${BAD_UNSIGNED_ALLOWS} ALLOW event(s) for unsigned-* images. Violates I1."
  exit 1
fi

# 3) At least one DENY for an unsigned-* image
UNSIGNED_DENIES="$(jq -s \
  'map(select(.decision == "DENY" and (.image_ref // "" | test("unsigned-")))) | length' \
  "${EVIDENCE_FILE}")"

echo "[I1 verify] DENY events for unsigned-* images: ${UNSIGNED_DENIES}"

if [[ "${UNSIGNED_DENIES}" -lt 1 ]]; then
  echo "[FAIL] No DENY event found for unsigned-* images. Expected at least one."
  exit 1
fi

# --- correlation_id sanity (non-fatal warning) ---
CORR_UNIQUE_COUNT="$(jq -s 'map(.correlation_id // empty) | unique | length' "${EVIDENCE_FILE}")"
echo "[I1 verify] Unique correlation_id count (non-fatal check): ${CORR_UNIQUE_COUNT}"

if [[ "${CORR_UNIQUE_COUNT}" -gt 1 ]]; then
  echo "[WARN] Evidence file contains multiple correlation_id values. File may contain multiple runs."
fi

echo "[PASS] I1 verification succeeded for evidence file: ${EVIDENCE_FILE}"
exit 0
