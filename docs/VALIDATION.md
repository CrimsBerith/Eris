# Build and regression validation

On macOS with Xcode 16.4 and XcodeGen installed, run:

```sh
bash scripts/verify_project.sh
```

This runs ErisCore XCTest, generates the Xcode project when XcodeGen is available,
builds the macOS app and iOS simulator target without signing, and checks the
presence of icon, privacy manifest and entitlement files. GitHub Actions runs
the package tests and both builds as separate steps for pull requests and pushes
to main, on macOS 15 / Xcode 16.4. The XCTest step has a five-minute limit so a
hung test does not consume the entire workflow runtime.
SDK 26 Liquid Glass symbols are compiled only with the bundled Swift 6.2+
toolchain; Xcode 16 uses the existing glassmorphism fallback.

Database regression tests use temporary SQLite files and no iCloud callback.
Calendar action tests use a recording adapter, so they do not create real events.
They cover exact proposal dates and quoted titles, invalid payload rejection,
save failure propagation, command routing, timezone boundaries and Saturday parsing.
Other existing engine tests still use shared in-process state and should be
isolated as part of the next validation work.

Passing these checks is not a release approval. Before shipping, verify a signed
archive, calendar permission denial and successful writes on real devices,
voice interruptions/Bluetooth, and two-device sync behavior. The broader approval
gate, content sync merge, privacy controls and encryption work remain open.

## Device smoke checks for calendar approval

1. Start with a fresh app profile. The notes list should be empty without sample
   architecture or budget records, and startup should not trigger a sync write.
2. Ask for a meeting tomorrow at 14:30. Include a quoted word in its title.
3. Approve it and compare the title, date and duration with the actual Calendar event.
4. Deny Calendar access in system settings and approve another event. The app
   must show a failure and retain the proposal for retry; it must not say it saved it.
5. Restore access and retry. After a confirmed successful save, the proposal disappears.
