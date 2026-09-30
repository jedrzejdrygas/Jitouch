# Contributing

Contributions should stay focused, reviewable, and compatible with the upstream
Jitouch codebase.

## Development setup

1. Install full Xcode and complete its first-launch setup.
2. Run `./scripts/build.sh` from the repository root.
3. Use `./scripts/install.sh --dry-run` before testing an installation.
4. Install with `./scripts/install.sh` and re-enable Accessibility permission.

The build must succeed without a paid Apple Developer identity. Repository scripts
therefore build with Xcode signing disabled and apply an ad-hoc signature locally.

## Before submitting a change

Run:

```sh
bash -n scripts/build.sh scripts/install.sh
./scripts/build.sh
git diff --check
```

For installer changes, exercise both paths when practical:

- A fresh user or machine with no Jitouch installation.
- An existing installation with customized trackpad and Magic Mouse gestures.

Confirm that the upgrade path creates a checksummed backup, restores the complete
preference domain, points the launch agent at `/Applications/Jitouch.app`, and
reports the service as running.

## Scope and style

- Keep the Firefox behavior change small and separate from installation policy.
- Do not commit `.app`, `.prefPane`, package, DerivedData, log, or backup artifacts.
- Preserve upstream copyright and GPL notices.
- Document user-visible behavior in `CHANGELOG.md`.
- Avoid unrelated modernization unless it fixes a demonstrated compatibility
  problem.

## Reporting bugs

Use the bug-report issue form and include macOS, Firefox, Xcode, hardware type,
gesture configuration, installation path, and relevant log excerpts. Remove any
private information from logs before posting them.
