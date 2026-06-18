# Notice

This repository is a binary-based recovery of an installed x-ui deployment.

The recovered panel binary appears to be from `alireza0/x-ui` because the
installed management script referenced:

- `https://raw.githubusercontent.com/alireza0/x-ui/main/install.sh`
- `https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh`
- `https://github.com/alireza0/x-ui/raw/main/x-ui.sh`

The original source code was not present on the remote machine and cannot be
fully reconstructed from the stripped Go executable.

License status:

- x-ui panel binary and management scripts: license unknown from recovered
  installation files. Do not claim an open-source license until the original
  license is verified.
- Bundled Xray binary and files under `recovered/usr-local-x-ui/bin/` include
  the upstream `README.md` and `LICENSE` recovered from the host. That license
  file is Mozilla Public License 2.0 for Xray-core.

Sensitive data intentionally excluded:

- `/etc/x-ui/x-ui.db`
- `/usr/local/x-ui/bin/config.json`
- certificates, private keys, account passwords, subscriptions, and logs
