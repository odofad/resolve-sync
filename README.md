# resolve-sync

Simple rsync-based sync tool for DaVinci Resolve project mags.

Pushes proxy-only Bins, bidirectional Stock, and Timeline backups over SSH.

## Status

Planning skeleton complete. Minimal implementation next.

## Layout

```
MasterFolder/                  (source)
├── ProjectA/
│   ├── Bins/…/Proxy/Clip001.mov
│   ├── Stock/
│   └── Timeline/
└── ProjectB/

RemoteFolder/                  (server)
├── ProjectA/
│   └── Timeline/
│       └── 2026-11-07_backup_TimelineName/
└── ProjectB/
```

## Commands

- `resolve-sync setup` — interactive setup + SSH key install
- `resolve-sync push [ProjectName]` — push from source
- `resolve-sync pull [ProjectName]` — pull on remote

## Config

Sidecar file (`~/.resolve-sync.conf`):

```
SOURCE_ROOT=/path/to/MasterFolder
REMOTE_ROOT=/path/to/RemoteFolder
REMOTE_HOST=user@server
SSH_OPTS=-o BatchMode=yes
```

See `resolve-sync.conf.example`.

## Sync rules

| Folder    | Direction              | Content                          |
|-----------|------------------------|----------------------------------|
| Bins      | One-way (source → server) | `**/Proxy/*.mov` only            |
| Stock     | Both ways              | Everything, last-write-wins      |
| Timeline  | One-way with backup    | Dated backup before overwrite    |

Proxy naming follows Resolve standard: `sourcefolder/Proxy/ClipName.mov`

## Decisions

- Push overwrites (no versioning except Timeline backups).
- Project list via pure SSH from the client.
- All paths/host in sidecar config.
- Stock is last-write-wins.
