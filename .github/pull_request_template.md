## Summary

Describe the user-visible behavior and why the change is needed.

## Verification

- [ ] `bash -n scripts/build.sh scripts/install.sh`
- [ ] `./scripts/build.sh`
- [ ] `git diff --check`
- [ ] Fresh-install behavior considered
- [ ] Existing preferences preserved on upgrade
- [ ] User-facing changes documented in `CHANGELOG.md`

## Scope

- [ ] No generated applications, preference panes, packages, logs, or backups are included
- [ ] Original copyright and GPL notices remain intact
