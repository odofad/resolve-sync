# resolve-sync

Simple rsync-based sync tool for DaVinci Resolve project mags.

Pushes proxy-only Bins, bidirectional Assists, and Timeline backups over SSH. Server keeps the raws; clients get proxies by default.

## Layout

```
MasterFolder/                  (client SOURCE_ROOT)
├── ProjectA/
│   ├── Bins/…/Proxy/Clip001.mov
│   ├── Assists/
│   │   ├── 01_Music/
│   │   ├── 02_SFX/
│   │   ├── 03_GFX/
│   │   ├── 04_Stock/
│   │   └── 05_Transcripts/
│   └── Timeline/
└── ProjectB/

RemoteFolder/                  (server REMOTE_ROOT)
├── ProjectA/
│   ├── Bins/…/Proxy/…          (proxies)
│   ├── Bins/…/*.MXF            (raws — stay on server)
│   ├── Assists/
│   └── Timeline/
└── ProjectB/
```

A valid project has both `Bins/` and `Assists/` at the top level. The numbered folders under Assists are suggestions only.

A `bank/` template is included. `resolve-sync new` copies it to start a new project.

## Install

### Linux (deb / PPA)
```bash
sudo add-apt-repository ppa:odofad/stable
sudo apt update
sudo apt install resolve-sync
```

### macOS (client only)
```bash
curl -L -o resolve-sync.zip https://github.com/odofad/resolve-sync/archive/refs/tags/v0.2.0.zip
unzip resolve-sync.zip
cd resolve-sync-0.2.0
chmod +x install-macos.sh
./install-macos.sh
```

## Commands

| Command | Description |
|---------|-------------|
| `setup` | Interactive client setup. Writes config and optionally installs an SSH key. |
| `setup-server` | Prepare the restricted media user and group on the server (run as root). |
| `new <Name>` | Create a new project from the bank template. |
| `push [Project]` | Push proxies + Assists. No argument lists local valid projects. |
| `pull [Project] [--originals]` | Pull proxies (default) or full Bins. No argument lists server projects. |
| `delete <Project>` | Delete a project from the client. Prompts to sync back first. |
| `update` | Update. On Linux prints apt instructions; on macOS downloads the latest release. |
| `test` | Self-test (config, paths, bank, SSH). |
| `--help` | Show the manual. |

Most commands refuse to run if the config is missing and tell you to run `setup`.

## Config

Preferred path: `~/.config/resolve-sync/config`  
Legacy fallback: `~/.resolve-sync.conf` (still read if present)

`setup` always writes to the new path.

```
SOURCE_ROOT=/path/to/local/MasterFolder
REMOTE_ROOT=/path/to/server/media
REMOTE_HOST=resolvesync@server
REMOTE_HOST_BACKUP=resolvesync@vpn-server   # optional
SSH_OPTS="-o BatchMode=yes"
```

## Sync rules

| Folder | Direction | Content |
|--------|-----------|---------|
| Bins | Client ↔ Server | Proxies only (`**/Proxy/*.mov`) by default. `--originals` pulls full Bins. Raws stay on the server. |
| Assists | Both ways | Everything, last-write-wins. |
| Timeline | One-way | Dated backup before overwrite (simplified). |

Proxy naming follows the Resolve standard: `sourcefolder/Proxy/ClipName.mov`.

## Server setup

`setup-server` (run as root on the Linux server):

- Creates a restricted user (default `resolvesync`)
- Creates a group (default `media`) and adds existing users to it
- Sets group permissions on the media root (setgid, no ownership takeover)
- Prepares `~/.ssh/authorized_keys`

Clients connect as that user. The main system users still own the media folders.

## Host failover

If `REMOTE_HOST_BACKUP` is set, the script tries the primary host first, then falls back to the backup (e.g. LAN then VPN).

## Update

- **Linux (deb):** `sudo apt update && sudo apt upgrade resolve-sync`
- **macOS:** `resolve-sync update` (downloads the latest GitHub release and reinstalls)

## Decisions

- Push overwrites (no versioning except Timeline backups). Use ZFS snapshots if you need history.
- Project list via pure SSH from the client. Only first-level dirs with `Bins/` + `Assists/` are shown.
- All paths/host in sidecar config.
- Assists is last-write-wins.
- Numbered folders under Assists are optional suggestions.
- Server access is via a dedicated restricted user + group policy.
- Clients receive proxies by default. `--originals` pulls the full Bins when needed.
