# resolve-sync

Simple rsync-based sync tool for DaVinci Resolve project mags.

Pushes proxy-only Bins, bidirectional Assists, and Timeline backups over SSH.

## Status

Planning skeleton complete. Minimal implementation next.

## Layout

```
MasterFolder/                  (source)
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

RemoteFolder/                  (server)
├── ProjectA/
│   └── Timeline/
│       └── 2026-11-07_backup_TimelineName/
└── ProjectB/
```

A `bank/` template folder (in the repo) can be copied and renamed to start a new project. The numbered folders under Assists are suggestions only — editors may add more or skip them as long as assets stay inside Assists.

## Commands

- `resolve-sync setup` — interactive setup + SSH key install
- `resolve-sync new "ProjectName"` — create a new project from the bank template
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
| Assists   | Both ways              | Everything, last-write-wins      |
| Timeline  | One-way with backup    | Dated backup before overwrite    |

Proxy naming follows Resolve standard: `sourcefolder/Proxy/ClipName.mov`

## Decisions

- Push overwrites (no versioning except Timeline backups).
- Project list via pure SSH from the client.
- All paths/host in sidecar config.
- Assists is last-write-wins.
- Numbered folders under Assists are optional suggestions.
