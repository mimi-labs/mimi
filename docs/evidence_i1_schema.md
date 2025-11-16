# I₁ Evidence Event Schema (v0)

Scope: events emitted by the Heimdall I₁ demo (scripts/demo_i1.sh) for Kyverno + cosign admission decisions.

## Common fields (from audit spine core)

- `event_id` — string, UUIDv4 or monotonic ID.
- `timestamp_utc` — string, RFC3339 UTC timestamp.
- `actor_type` — `"system"` for demo runs.
- `actor_id` — e.g. `"demo_i1.sh"` or `"i1log-cli"`.
- `source_ip` — optional; empty for local demo.
- `event_type` — e.g. `"ADMISSION_DECISION"`.
- `lane_state` — optional for I₁ (usually empty in v0).
- `decision` — `"ALLOW"` or `"DENY"`.
- `reason_codes` — array of strings, e.g. `["I1_NO_SIGNATURE"]`.
- `policy_hash` — string, hash or version of the Kyverno policy (may be placeholder in v0).
- `correlation_id` — string to group events from one demo run.
- `metadata` — free-form JSON object for extra context.

## I₁ demo–specific fields

- `k8s_object` — e.g. `"Deployment/heimdall"`.
- `image_ref` — e.g. `"docker.io/mimilabs/heimdall:latest"` or unsigned tag.
- `kyverno_policy` — e.g. `"require-signed-images-default"`.
- `cosign_verification_result` — `"VALID"`, `"NO_SIGNATURES"`, `"ERROR"`.
- `demo_step` — label like `"C6_SIGNED_PATH"` or `"C7_UNSIGNED_PATH"` mapping to the C1–C8 demo steps.

## JSONL format

- Each event is one JSON object per line.
- File layout for S1 I₁ demo:

  - `evidence/logs/i1/demo_i1_events.jsonl`

- Files are **append-only**; no in-place edits.

