# Jitouch — Firefox horizontal swipe fork

This source-only fork of [Jitouch](https://github.com/JitouchApp/Jitouch) allows
configured three-finger horizontal trackpad swipes to run in Firefox. Upstream
Jitouch excludes both Safari and Firefox from those gestures; this fork retains
Safari's special handling but lets Jitouch dispatch the user's configured action
in Firefox.

The change addresses the behavior reported in
[JitouchApp/Jitouch#45](https://github.com/JitouchApp/Jitouch/issues/45).

No application bundle, installer package, or other binary release is distributed
by this repository. Users build the application locally from source.

## Requirements

- macOS 12 or newer.
- Full Xcode, selected with `xcode-select`.
- Xcode's license and first-launch component installation completed.
- Administrator access only when installing into `/Applications` and
  `/Library/PreferencePanes`.

If Xcode command-line tools still point at the standalone tools, run:

```sh
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -license accept
sudo xcodebuild -runFirstLaunch
```

## Build from source

Building never modifies an existing Jitouch installation:

```sh
./scripts/build.sh
```

Products are written to:

```text
build/app/Release/Jitouch.app
build/prefpane/Release/Jitouch.prefPane
```

Use `./scripts/build.sh --no-clean` for an incremental build. Set
`MACOSX_DEPLOYMENT_TARGET` to override the default target of macOS 12.0.

## Install the local build

```sh
./scripts/install.sh
```

The installer builds and verifies both products before changing the installed
copy. It then chooses one of two paths:

- **Existing installation:** exports and checksums the complete Jitouch
  preference domain, retains the original plist and launch agent, installs the
  replacement, and restores all gestures and preferences.
- **Fresh installation:** skips backup and restoration and installs cleanly.

Useful options:

```text
--build-only              Build and verify without installing
--dry-run                 Report the detected path and planned actions
--skip-build              Install products already present under build/
--no-accessibility-reset  Preserve the current Accessibility database entry
```

Run `./scripts/install.sh --help` for the complete usage text.

## Accessibility permission

Local builds are ad-hoc signed. A rebuild can therefore have a different signing
identity from the previously authorized binary. By default, the installer resets
only Jitouch's stale Accessibility record after replacing the app.

After installation, enable `/Applications/Jitouch.app` under:

**System Settings → Privacy & Security → Accessibility**

If gestures still do not respond, remove any old Jitouch entry, add the app from
`/Applications`, and restart it:

```sh
launchctl kickstart -k "gui/$(id -u)/com.jitouch.Jitouch.agent"
```

Runtime diagnostics are written to:

```text
~/Library/Logs/com.jitouch.Jitouch.log
```

## Compatibility notes

- This fork changes horizontal three-finger trackpad swipes in Firefox only.
- Safari retains upstream behavior because it handles the gesture itself.
- The project uses Apple's private `MultitouchSupport` framework and deprecated
  preference-pane APIs. Future macOS or Xcode releases may require source changes.
- Builds include the architectures selected by the Xcode project. The build
  script verifies the resulting bundles but does not notarize them.
- The settings preference pane remains available for gesture configuration, while
  the runtime application is installed as `/Applications/Jitouch.app`.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development, verification, and issue
reporting guidance.

## License and attribution

Jitouch is licensed under the [GNU General Public License v3.0](LICENSE). Original
copyright notices remain intact. See [NOTICE.md](NOTICE.md) and
[CHANGELOG.md](CHANGELOG.md) for this fork's modifications.
