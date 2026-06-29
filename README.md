# fivem-server

Config and resources for the FiveM (GTA 5) server running on `187.124.93.157`.

## Structure

```
server.cfg          — main server config (set sv_licenseKey before first run)
resources/          — FiveM resources managed here
scripts/update.sh   — pull latest + restart server
```

## First-time setup

1. Get a license key at https://keymaster.fivem.net
2. Set `sv_licenseKey` in `server.cfg`
3. Push to this repo

## Deploy / update

```bash
ssh root@187.124.93.157 "bash /opt/fivem/scripts/update.sh"
```

## Web panel (txAdmin)

```
http://187.124.93.157:40120
```

First run will show a setup PIN in the server logs:

```bash
ssh root@187.124.93.157 "journalctl -u fivem -n 50 | grep pin"
```

## Ports

| Port | Protocol | Purpose |
|------|----------|---------|
| 30120 | TCP+UDP | Game traffic |
| 40120 | TCP | txAdmin web panel |
