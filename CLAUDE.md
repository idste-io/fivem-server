# CLAUDE.md

Guidance for Claude Code in this repo, whether cloned locally or opened
directly on the VPS via VS Code Remote-SSH.

## What this is

FiveM GTA5 RP server config, resources, and custom mods. Server ID `vq3rbm5`,
IP `187.124.93.157:30120`. Production path: `/opt/fivem-server` on VPS
`root@187.124.93.157`.

## If you are running directly on the VPS (opened via Remote-SSH)

You're already on the machine — skip anything that says "ssh into the server".

```bash
bash scripts/update.sh          # deploy latest (also auto-runs from eonexis's update.sh Step 9k-fivem)
bash scripts/new-mod.sh <name>  # scaffold a new mod from resources/[custom]/example-mod
```

## Structure

```
server.cfg                 — main config (enable mods via ensure lines)
license.cfg                — license key, gitignored, VPS-only
resources/
  [system]/                — FiveM system resources
  [managers]/               — spawnmanager etc.
  [gameplay]/               — chat, playernames etc.
  [custom]/                 — all Eonexis custom mods (loading-screen live, example-mod = template)
```

## Related

- Deployed alongside `idste-io/eonexis` on the same VPS; eonexis's update script
  triggers a FiveM sync/deploy as one of its steps.
- FiveM Hub page in the webapp: `https://eonexis.invoxio.work/#/fivem`
