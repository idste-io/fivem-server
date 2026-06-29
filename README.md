# fivem-server — Eonexis

FiveM GTA5 RP server config, resources, and custom mods for Eonexis.

**Server ID:** `vq3rbm5` · **IP:** `187.124.93.157:30120`

---

## Quick deploy

```bash
# Deploy latest to VPS
ssh root@187.124.93.157 "bash /opt/fivem-server/scripts/update.sh"

# Create a new mod from template
bash scripts/new-mod.sh my-mod-name
```

## Structure

```
server.cfg                    — main config (enable mods by uncommenting ensure lines)
license.cfg                   — license key (gitignored, VPS only)
resources/
  [system]/                   — FiveM system resources
  [managers]/                 — spawnmanager etc.
  [gameplay]/                 — chat, playernames etc.
  [custom]/                   — ALL Eonexis custom mods
    loading-screen/           — branded loading screen (live)
    example-mod/              — template — copy to start a new mod
    eonexis-hud/              — custom HUD (in progress)
    eonexis-notify/           — branded notifications (in progress)
    eonexis-multichar/        — character select screen (in progress)
    eonexis-spawn/            — spawn screen (in progress)
    eonexis-rules/            — /rules command (in progress)
    eonexis-welcomegift/      — new player starter kit (in progress)
    eonexis-discord/          — Discord invite for new players (in progress)
scripts/
  update.sh                   — pull GitHub → sync to /opt/fivem → restart
  new-mod.sh                  — scaffold a new mod from example-mod
```

---

## Mod Roadmap

### Phase 0 — Infrastructure ✅
- FiveM server, systemd, firewall, loading screen, update script

### Phase 1 — Framework + Database
- [ ] MariaDB on VPS
- [ ] oxmysql
- [ ] ox_lib
- [ ] qb-core

### Phase 2 — Player Identity
- [ ] qb-multicharacter / eonexis-multichar
- [ ] qb-spawn / eonexis-spawn
- [ ] qb-appearance + fivem-appearance

### Phase 3 — HUD + UI + Voice
- [ ] eonexis-hud (custom branded HUD)
- [ ] ox_inventory (grid inventory)
- [ ] pma-voice (proximity voice)
- [ ] lb-phone (in-game smartphone)
- [ ] eonexis-notify (branded notifications)

### Phase 4 — Economy
- [ ] qb-banking + qb-atm
- [ ] qb-shops

### Phase 5 — Legal Jobs
- [ ] qb-policejob
- [ ] qb-ambulancejob
- [ ] qb-mechanicjob
- [ ] qb-taxijob
- [ ] qb-burgershot
- [ ] qb-trucker

### Phase 6 — Vehicles
- [ ] qb-garages + qb-vehiclekeys
- [ ] qb-vehicleshop
- [ ] LegacyFuel
- [ ] qb-vehiclefailure
- [ ] Custom vehicle pack

### Phase 7 — Housing
- [ ] qb-apartments
- [ ] qb-houses + qb-interior

### Phase 8 — Criminal
- [ ] PolyZone (dependency)
- [ ] qb-drugs
- [ ] qb-heist + qb-houserobbery
- [ ] qb-carjacking + qb-chopshop
- [ ] qb-prison
- [ ] qb-gangs

### Phase 9 — Immersion
- [ ] qb-weathersync
- [ ] qb-hunger + qb-thirst
- [ ] qb-target (world interactions)
- [ ] qb-radialmenu
- [ ] qb-smallresources

### Phase 10 — Admin
- [ ] qb-adminmenu
- [ ] qb-logs (Discord webhooks)
- [ ] qb-report
- [ ] Anticheat

### Phase 11 — Custom Eonexis Mods
- [x] loading-screen
- [ ] eonexis-hud
- [ ] eonexis-notify
- [ ] eonexis-multichar
- [ ] eonexis-spawn
- [ ] eonexis-rules
- [ ] eonexis-welcomegift
- [ ] eonexis-discord

---

## txAdmin panel

`http://187.124.93.157:40120` — first-run setup PIN in server logs:
```bash
ssh root@187.124.93.157 "journalctl -u fivem -n 50 | grep -i pin"
```

## VS Code (Remote)

Install **Remote - SSH** extension → connect `root@187.124.93.157` → open `/opt/fivem-server/`
Recommended extensions: `.vscode/extensions.json`
