# Music Assistant

Music Assistant is deployed only on the Linux host named `weckerAA`. It is not
installed by the main dotfiles installer, so developer machines and client
devices never accidentally become music servers.

## Server: weckerAA

The supported standalone deployment is in `weckerAA/compose.yaml`. It uses
host networking because Music Assistant needs direct layer-2 access for mDNS,
uPnP, AirPlay, Chromecast, DLNA, Sonos, and similar players.

On `weckerAA`:

```sh
cp configs/music-assistant/weckerAA/.env.example \
  configs/music-assistant/weckerAA/.env
# Edit .env to point at persistent data and the host-mounted music library.
scripts/music-assistant-server up
```

Use `scripts/music-assistant-server update`, `status`, or `logs` for normal
operations. The wrapper refuses to run on any host other than `weckerAA` and
requires Linux, preventing an unsupported Docker Desktop deployment.

Back up `MA_DATA_DIR`; it contains the server database and provider settings.
Mount any NAS share on the host, then set `MA_MUSIC_DIR` to that mounted path.
The container receives it read-only. Do not add the privileges required for
in-container SMB/NFS mounting unless that is explicitly needed.

The UI is available at `http://weckerAA:8095` (or the server's LAN IP). Client
devices must be on the same layer-2 network and able to reach the server's
stream port, `8097` by default.

## Clients

No client-side configuration is stored in dotfiles: the official clients
discover the server with mDNS, and their first-run setup can use
`http://weckerAA:8095` when discovery is unavailable.

Install the official desktop companion app from its GitHub releases using the
native package for the device:

| Device type | Package |
| --- | --- |
| macOS (Intel or Apple Silicon) | `.dmg` |
| Windows | `.msi` |
| Debian/Ubuntu Linux | `.deb` |
| Other Linux distributions | AppImage or `.rpm` |

The desktop client is upstream alpha software, so it is intentionally not
included in the global installer or pinned in this repository. It provides
native audio playback, media controls, and system-tray support. Android and
iOS official clients are beta and are installed through their respective
testing channels; a browser at the server URL remains a fully supported
zero-install client.

Upstream references:

- https://www.music-assistant.io/installation/
- https://www.music-assistant.io/companion-app/
- https://www.music-assistant.io/mobile/
