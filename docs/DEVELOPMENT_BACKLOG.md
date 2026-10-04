# Eris stabilization backlog

Baseline review: main at `018f4f01cdc6ae5c10a6ee37cc45c65c4d1134f6`, 4 October 2026.
The checked-off phases in PLAN.md are historical claims, not release validation.

## First implementation batch

- Remove sample memory seeding and the startup DB → sync → DB dependency cycle.
- Inject the SQLite path and mutation callback for isolated database regression tests.
- Carry the exact proposed calendar title/dates through a typed JSON payload.
- Surface calendar permission/save errors and retain failed proposals for retry.
- Prioritize explicit calendar commands over automatic note extraction.
- Resolve dates against one timezone; distinguish Saturday from Friday.
- Add missing Combine imports and use the Bluetooth option supported by the baseline SDK.
- Add macOS package tests and unsigned app builds in GitHub Actions.

Acceptance is recorded in the PR's validation results. These changes do not resolve
the full approval, privacy, synchronization or voice backlog below.

## Remaining order

1. One ActionCoordinator for both clients: payload binding, proposal expiry,
   single-use approval, rejection and idempotent execution. The current general
   SafeExecutionGate must not mark an unexecuted operation as executed.
2. Context-sharing preferences, minimum necessary outbound data and accurate
   privacy disclosures. Choose and verify the local encryption approach.
3. Server-side provider credentials and atomic quotas for the zero-setup product.
4. Persistent repositories for vault and other user data; no production sample
   records. Preserve an intentionally empty collection after restart.
5. Record-based content sync with timestamps, tombstones, local outbox and
   deterministic conflict handling. Reserve KVS for small preferences.
6. Shared ChatCoordinator: one current turn, history budget, cancellation and
   request/model snapshots; validate supported model names with the provider.
7. Explicit live/cached/estimated/demo/unavailable states for external data.
   Replace synthetic market/marine values and unsupported decision scores.
8. Audio lifecycle/isolation, permissions, interruption and Bluetooth device tests.
9. Signed archive, real iPhone/Mac smoke tests, truthful release metadata.

Keep the first release focused on chat, approved calendar entries, reliable notes
and push-to-talk. Defer new platform extensions until these flows are validated.
