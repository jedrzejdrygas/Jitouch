#!/bin/bash

set -euo pipefail

repo_dir="$(cd "$(dirname "$0")/.." && pwd)"
build_script="$repo_dir/scripts/build.sh"
build_dir="$repo_dir/build"
app_product="$build_dir/app/Release/Jitouch.app"
prefpane_product="$build_dir/prefpane/Release/Jitouch.prefPane"
preferences_file="$HOME/Library/Preferences/com.jitouch.Jitouch.plist"
launch_agent="$HOME/Library/LaunchAgents/com.jitouch.Jitouch.plist"
uid="$(id -u)"
dry_run=false
build_only=false
skip_build=false
reset_accessibility=true
install_mode="fresh"
backup_dir=""
settings_backup=""
old_install_stopped=false
old_install_removed=false
new_app_installed=false
preferences_restored=false
launch_agent_started=false

usage() {
    cat <<'EOF'
Usage: scripts/install.sh [options]

Options:
  --build-only              Build and verify without installing.
  --dry-run                 Show the detected path and planned actions.
  --skip-build              Install already-built products from build/.
  --no-accessibility-reset  Keep the existing Accessibility database entry.
  -h, --help                Show this help.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build-only) build_only=true ;;
        --dry-run) dry_run=true ;;
        --skip-build) skip_build=true ;;
        --no-accessibility-reset) reset_accessibility=false ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if [[ "$(uname -s)" != "Darwin" ]]; then
    echo "Jitouch can only be installed on macOS." >&2
    exit 1
fi

if [[ -d /Applications/Jitouch.app || \
      -d /Library/PreferencePanes/Jitouch.prefPane || \
      -d "$HOME/Library/PreferencePanes/Jitouch.prefPane" ]] || \
      pkgutil --pkg-info com.jitouch.Jitouch >/dev/null 2>&1; then
    install_mode="upgrade"
fi

if "$dry_run"; then
    echo "Install mode: $install_mode"
    if [[ "$install_mode" == "upgrade" ]]; then
        echo "Would export and checksum existing preferences before replacement."
        echo "Would restore gestures and preferences after installation."
    else
        echo "Would perform a fresh installation without backup or restore."
    fi
    "$skip_build" || echo "Would build and verify both products before changing the installation."
    echo "Would install /Applications/Jitouch.app and /Library/PreferencePanes/Jitouch.prefPane."
    "$reset_accessibility" && echo "Would reset Jitouch's Accessibility approval."
    echo "Would create and verify the per-user launch agent."
    exit 0
fi

if "$build_only"; then
    exec "$build_script"
fi

on_error() {
    exit_code=$?
    echo >&2
    echo "Installation failed (exit $exit_code)." >&2
    echo "Old installation stopped: $old_install_stopped" >&2
    echo "Old installation removed: $old_install_removed" >&2
    echo "New app installed: $new_app_installed" >&2
    echo "Preferences restored: $preferences_restored" >&2
    echo "Launch agent started: $launch_agent_started" >&2
    if [[ -n "$backup_dir" ]]; then
        echo "Backup retained at: $backup_dir" >&2
    fi
    exit "$exit_code"
}
trap on_error ERR

if ! "$skip_build"; then
    "$build_script"
fi

if [[ ! -d "$app_product" || ! -d "$prefpane_product" ]]; then
    echo "Verified build products are missing. Run scripts/build.sh first." >&2
    exit 1
fi
codesign --verify --deep --strict "$app_product"
codesign --verify --deep --strict "$prefpane_product"

if [[ "$install_mode" == "upgrade" ]]; then
    backup_dir="$repo_dir/backups/jitouch-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"
    settings_backup="$backup_dir/com.jitouch.Jitouch.xml"

    if defaults export com.jitouch.Jitouch "$settings_backup" >/dev/null 2>&1; then
        if [[ -f "$preferences_file" ]]; then
            cp "$preferences_file" "$backup_dir/com.jitouch.Jitouch.plist"
        fi
    else
        settings_backup=""
        if [[ -f "$preferences_file" ]]; then
            cp "$preferences_file" "$backup_dir/com.jitouch.Jitouch.plist"
            plutil -convert xml1 -o "$backup_dir/com.jitouch.Jitouch.xml" "$preferences_file"
            settings_backup="$backup_dir/com.jitouch.Jitouch.xml"
        fi
    fi
    if [[ -f "$launch_agent" ]]; then
        cp "$launch_agent" "$backup_dir/com.jitouch.Jitouch.launchagent.plist"
    fi
    backup_files=("$backup_dir"/*)
    if [[ -e "${backup_files[0]}" ]]; then
        shasum -a 256 "${backup_files[@]}" > "$backup_dir/SHA256SUMS"
    fi
    echo "Backup created at $backup_dir"
fi

launchctl bootout "gui/$uid" "$launch_agent" 2>/dev/null || true
killall Jitouch 2>/dev/null || true
old_install_stopped=true

sudo rm -rf /Applications/Jitouch.app /Library/PreferencePanes/Jitouch.prefPane
rm -rf "$HOME/Library/PreferencePanes/Jitouch.prefPane"
old_install_removed=true
sudo ditto "$app_product" /Applications/Jitouch.app
sudo ditto "$prefpane_product" /Library/PreferencePanes/Jitouch.prefPane
sudo chown -R root:wheel /Applications/Jitouch.app /Library/PreferencePanes/Jitouch.prefPane
sudo pkgutil --forget com.jitouch.Jitouch >/dev/null 2>&1 || true
new_app_installed=true

if [[ "$install_mode" == "upgrade" && -n "$settings_backup" ]]; then
    if ! defaults import com.jitouch.Jitouch "$settings_backup"; then
        fallback_preferences="$backup_dir/com.jitouch.Jitouch.plist"
        if [[ ! -f "$fallback_preferences" ]]; then
            echo "Preference restore failed and no fallback plist exists." >&2
            exit 1
        fi
        cp "$fallback_preferences" "$preferences_file"
    fi
    defaults read com.jitouch.Jitouch >/dev/null
    plutil -lint "$preferences_file" >/dev/null
    preferences_restored=true
fi

if "$reset_accessibility"; then
    tccutil reset Accessibility com.jitouch.Jitouch
fi

mkdir -p "$HOME/Library/LaunchAgents" "$HOME/Library/Logs"
rm -f "$launch_agent"
plutil -create xml1 "$launch_agent"
plutil -insert Label -string com.jitouch.Jitouch.agent "$launch_agent"
plutil -insert Program -string /Applications/Jitouch.app/Contents/MacOS/Jitouch "$launch_agent"
plutil -insert RunAtLoad -bool true "$launch_agent"
plutil -insert KeepAlive -bool true "$launch_agent"
plutil -insert ProcessType -string Interactive "$launch_agent"
plutil -insert StandardErrorPath -string "$HOME/Library/Logs/com.jitouch.Jitouch.log" "$launch_agent"
plutil -insert StandardOutPath -string /dev/null "$launch_agent"
plutil -insert Umask -integer 63 "$launch_agent"
plutil -lint "$launch_agent" >/dev/null

launchctl bootstrap "gui/$uid" "$launch_agent"
sleep 1
launch_state="$(launchctl print "gui/$uid/com.jitouch.Jitouch.agent")"
grep -q 'state = running' <<<"$launch_state"
grep -q 'program = /Applications/Jitouch.app/Contents/MacOS/Jitouch' <<<"$launch_state"
launch_pid="$(awk '/^[[:space:]]*pid = / { print $3; exit }' <<<"$launch_state")"
if [[ -z "$launch_pid" ]]; then
    echo "Launch agent is running but did not report a PID." >&2
    exit 1
fi
running_command="$(ps -p "$launch_pid" -o command=)"
case "$running_command" in
    /Applications/Jitouch.app/Contents/MacOS/Jitouch*) ;;
    *) echo "Unexpected running executable: $running_command" >&2; exit 1 ;;
esac
launch_agent_started=true

echo "Installed and verified /Applications/Jitouch.app"
echo "Installed and verified /Library/PreferencePanes/Jitouch.prefPane"
if [[ "$install_mode" == "upgrade" ]]; then
    if "$preferences_restored"; then
        echo "Restored existing gestures and preferences. Backup: $backup_dir"
    else
        echo "No existing preferences were found. Backup directory: $backup_dir"
    fi
else
    echo "Completed fresh installation."
fi
if "$reset_accessibility"; then
    echo "Re-enable /Applications/Jitouch.app in System Settings > Privacy & Security > Accessibility."
fi
