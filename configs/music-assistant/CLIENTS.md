# Music Assistant client installation

The companion app discovers `weckerAA` through mDNS. If discovery is not
available, enter `http://weckerAA:8095` during the app's first-run setup.

## macOS

Use the maintained Homebrew tap:

```sh
brew tap music-assistant/tap
brew install --cask music-assistant/tap/music-assistant
```

The upstream `.dmg` is the alternative for either Apple Silicon or Intel Macs.

## Windows

Download and run the `.msi` installer from the upstream desktop-app releases.
The `.exe` installer is an alternative when MSI installation is unavailable.

## Linux

Use the native release artifact for the installed distribution and architecture:

- Debian/Ubuntu: `.deb`
- Fedora/RHEL: `.rpm`
- Flatpak-capable systems: `.flatpak`
- Arch: `music-assistant-desktop-bin` from the AUR
- Other distributions: AppImage

For Arch with an AUR helper:

```sh
yay -S music-assistant-desktop-bin
```

The desktop app has built-in updates. It is currently upstream alpha software;
use the web UI at `http://weckerAA:8095` if its native playback features are
not needed or a release is unavailable for the device.

## Mobile

The official Android and iOS clients are beta and are installed through their
respective testing channels. A browser pointed at the web UI is the fallback
for every mobile device.

## Upstream

- https://github.com/music-assistant/desktop-app/releases/latest
- https://www.music-assistant.io/companion-app/
- https://www.music-assistant.io/mobile/
