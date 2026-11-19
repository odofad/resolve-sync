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

### Ubuntu (recommended)

```bash
sudo add-apt-repository ppa:odofad/stable
sudo apt update
sudo apt install resolve-sync
```

Packages are built for the active series (currently noble and resolute).

### Other systems / from source

```bash
curl -L -o resolve-sync.zip https://github.com/odofad/resolve-sync/archive/refs/heads/main.zip
unzip resolve-sync.zip
cd resolve-sync-main
chmod +x install.sh
./install.sh
```

(Or use a tagged release zip if you prefer a fixed version.)

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
- Detects (or asks for) the media owner user
- Sets group permissions on the media root (setgid, no ownership takeover)
- Installs a permission watcher that runs as the media owner
- Prepares `~/.ssh/authorized_keys`

The watcher uses `inotifywait` to fix group permissions whenever files are created or changed (including via SMB from Mac/Windows). It runs as the media owner user — no root required after setup.

Clients connect as the restricted user. The main system users still own the media folders.

## Host failover

If `REMOTE_HOST_BACKUP` is set, the script tries the primary host first, then falls back to the backup (e.g. LAN then VPN).

## Update

- **Ubuntu (deb):** `sudo apt update && sudo apt upgrade resolve-sync`
- **macOS / other:** `resolve-sync update` (downloads the latest GitHub release and reinstalls)

## Troubleshooting

### Permission denied on push/pull (rsync code 23)

If the watcher is running, this should be rare. If you still see:

```
rsync: [generator] delete_file: unlink(...) failed: Permission denied (13)
```

check that the watcher is active:

```bash
systemctl status resolve-sync-watch
```

You can also fix a project manually:

```bash
sudo -u <media-owner> /usr/local/bin/resolve-sync-fix-perms /path/to/project
```

## Decisions

- Push overwrites (no versioning except Timeline backups). Use ZFS snapshots if you need history.
- Project list via pure SSH from the client. Only first-level dirs with `Bins/` + `Assists/` are shown.
- All paths/host in sidecar config.
- Assists is last-write-wins.
- Numbered folders under Assists are optional suggestions.
- Server access is via a dedicated restricted user + group policy.
- Clients receive proxies by default. `--originals` pulls the full Bins when needed.
- Permission fixing is done by a user-level watcher, not by the restricted client.
