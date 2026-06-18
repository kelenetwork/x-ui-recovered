# Recovery Report

Recovery date: 2026-06-19 GMT+8

Remote host:

- SSH target: `root@hinet.speedtest.sarl -p 22456`
- Hostname: `kele.com`
- OS: Debian GNU/Linux 12 (bookworm)
- Kernel: `Linux 6.1.0-44-amd64`
- Architecture: `x86_64`

Discovered x-ui paths:

- Service: `x-ui.service`
- Service unit: `/etc/systemd/system/x-ui.service`
- Install directory: `/usr/local/x-ui`
- Panel binary: `/usr/local/x-ui/x-ui`
- Management wrapper: `/usr/bin/x-ui`
- Bundled xray binary: `/usr/local/x-ui/bin/xray-linux-amd64`
- Runtime database: `/etc/x-ui/x-ui.db` (not copied)
- Runtime xray config: `/usr/local/x-ui/bin/config.json` (not copied)

Recovered versions:

- x-ui panel binary: `1.10.2`
- Xray: `26.2.6 (go1.25.7 linux/amd64)`

Source availability:

The Go source tree was not present on the remote host. The recovered panel
binary is a stripped Linux x86-64 executable, so the original source cannot be
fully restored from it. This repository is therefore a binary-based install
repository plus recovered scripts, unit files, schema, and documentation.

Recovered artifact checksums:

```text
1e1b92463c8e0a14c32ee09f462bc40ca3159927878b1ce02d3070c82fa6dab3  recovered/usr-local-x-ui/x-ui
4c93d0b66a078d15dffbd9f057311a7d6fa303ef81177760d9c2674a0b2f14f3  recovered/usr-local-x-ui/x-ui.sh
2f8ddcc62f9830226551f15f0ebb04191b4bc6eafcdd63ef722fd758f6c6b16e  systemd/x-ui.service
3f650abf1fc4a4fbf5abe7fc9990a2658020907cd984214e9c075b4b00989fea  recovered/usr-local-x-ui/bin/xray-linux-amd64
4b1405cd18013053638119a814d25188cb3b8b559cffd911a46318c27d6cb23d  recovered/usr-local-x-ui/bin/geosite.dat
5f7dc88ab98d562272c2b3696d42214f8259f61d4b970db93c007aba6054b04b  recovered/usr-local-x-ui/bin/geoip.dat
afb5e3d7ce91f8267ec812d785f7e9760e5b53619fb27ea3a66d4d8b0b3062a4  recovered/usr-local-x-ui/bin/geosite_IR.dat
3873ca8a201437214f2c702c70b4d5ce463ee3f964797545bff196a50ed7f652  recovered/usr-local-x-ui/bin/geoip_IR.dat
f0d422f07e5c14e491b8a5fa0ad704b53cdb92111dc4017906ed1c20d58acc0b  recovered/usr-bin/x-ui
```

Excluded sensitive files:

- `/etc/x-ui/x-ui.db`: contained real panel users, settings, inbounds, client
  traffic, subscriptions, and other runtime data. Only `docs/x-ui.schema.sql`
  was exported.
- `/usr/local/x-ui/bin/config.json`: generated runtime xray config; replaced
  by `examples/config.example.json`.
- Any certificates, private keys, logs, or account credentials.
