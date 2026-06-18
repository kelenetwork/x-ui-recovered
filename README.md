# x-ui Recovered Binary Install Repository

This repository was recovered from an installed `x-ui` deployment on
`kele.com` on 2026-06-19 GMT+8. It is intended to keep the service installable
after the referenced upstream repository became unavailable.

Important: the original Go source code was not present on the server. The panel
binary is a stripped Linux x86-64 executable, so the source cannot be fully
reconstructed from it. This is a binary-based recovery repository.

## What Was Recovered

- x-ui panel binary: `recovered/usr-local-x-ui/x-ui`
- x-ui version reported by binary: `1.10.2`
- xray binary: `recovered/usr-local-x-ui/bin/xray-linux-amd64`
- xray version: `26.2.6`
- geo data files under `recovered/usr-local-x-ui/bin/`
- recovered management scripts:
  - `recovered/usr-local-x-ui/x-ui.sh`
  - `recovered/usr-bin/x-ui`
- systemd unit:
  - `systemd/x-ui.service`
  - `systemd/x-ui.service.template`
- SQLite schema only: `docs/x-ui.schema.sql`

## Sensitive Data Policy

The recovery intentionally does not include real runtime data:

- no `/etc/x-ui/x-ui.db`
- no `/usr/local/x-ui/bin/config.json`
- no certificates or private keys
- no panel usernames/passwords
- no subscription data or access logs

`examples/config.example.json` is a placeholder example, not the remote host's
live configuration.

## Install

Run on a Debian/Ubuntu-style system with `systemd`:

```bash
sudo bash install.sh
```

The installer copies files to:

- `/usr/local/x-ui`
- `/etc/systemd/system/x-ui.service`
- `/usr/bin/x-ui`
- `/etc/x-ui`

It then enables and restarts `x-ui.service`.

## Manage

```bash
x-ui status
x-ui settings
x-ui restart
x-ui log
x-ui version
```

The original recovered wrapper is preserved under `recovered/usr-bin/x-ui`, but
the installed wrapper from this repository is `scripts/x-ui`. It avoids calling
the deleted upstream install URLs.

## Upgrade

After replacing recovered artifacts in this repository with a newer trusted
build:

```bash
sudo bash upgrade.sh
```

The upgrade script copies repository files over the installed files and
restarts `x-ui.service`. It preserves `/etc/x-ui`.

## Uninstall

```bash
sudo bash uninstall.sh
```

For non-interactive removal:

```bash
sudo bash uninstall.sh --yes
```

## Provenance

The recovered script referenced these upstream URLs:

- `https://raw.githubusercontent.com/alireza0/x-ui/main/install.sh`
- `https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh`
- `https://github.com/alireza0/x-ui/raw/main/x-ui.sh`

See `docs/recovery-report.md` for host details, discovered paths, hashes, and
recovery scope.

## License

The x-ui panel binary and recovered x-ui shell scripts did not include a
verifiable license in the recovered installation. Their license is currently
unknown.

The bundled Xray component includes its recovered `README.md` and `LICENSE`
under `recovered/usr-local-x-ui/bin/`; that license file is Mozilla Public
License 2.0 for Xray-core.

Do not publish this as a formally open-source project until the original x-ui
license is verified.

## Publishing

This repository has only been initialized locally. Nothing has been pushed. A
GitHub repository URL is required before adding a remote and pushing.
